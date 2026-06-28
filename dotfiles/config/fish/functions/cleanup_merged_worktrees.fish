function cleanup_merged_worktrees --description 'Remove merged PR/MR branches and their worktrees'
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l yellow (set_color yellow)
    set -l green  (set_color green)
    set -l red    (set_color red)
    set -l dim    (set_color brblack)

    set -l dry_run 0
    set -l detect_squash 0
    for arg in $argv
        switch $arg
            case --dry-run -n
                set dry_run 1
            case --squash -s
                set detect_squash 1
            case '*'
                echo $red"Usage: cleanup_merged_worktrees [--dry-run|-n] [--squash|-s]"$reset >&2
                return 2
        end
    end

    if not git rev-parse --git-dir >/dev/null 2>&1
        echo $red"✖ Not inside a git repository"$reset >&2
        return 1
    end

    # Select the forge CLI from the repo's remote (gh for GitHub, glab for GitLab).
    # The forge is optional: if the remote isn't a recognized host we just skip
    # the merged-PR query and rely on local history alone (sources 2 & 3 below).
    set -l forge (_forge_kind)

    for cmd in git awk sort
        if not type -q $cmd
            echo $red"✖ Missing dependency: $cmd"$reset >&2
            return 1
        end
    end

    set -l mode_label "apply"
    if test $dry_run -eq 1
        set mode_label "dry-run"
    end

    set -l scan_source "local history"
    test -n "$forge"; and set scan_source "$forge + local history"
    echo $cyan"🧹 Scanning merged branches via $scan_source ($mode_label)"$reset

    # ── Source 1: the forge ──────────────────────────────────────────────
    # Each forge reports the merged branches authored by the current user.
    # gh exposes --jq natively; glab needs an external jq pass. Skipped
    # entirely when no forge could be resolved from the remote.
    set -l forge_branches
    switch $forge
        case ''
            echo $yellow"⚠ No forge resolved from remote — scanning local history only (set FORGE_KIND to gh or glab to include merged PRs)"$reset
        case gh
            if not type -q gh
                echo $red"✖ Missing dependency: gh"$reset >&2
                return 1
            end
            set forge_branches (
                gh pr list --state merged --author @me \
                    --json headRefName --jq '.[].headRefName' \
                | string trim \
                | string match -rv '^$' \
                | sort -u
            )
        case glab
            for cmd in glab jq
                if not type -q $cmd
                    echo $red"✖ Missing dependency: $cmd (required for GitLab)"$reset >&2
                    return 1
                end
            end
            set forge_branches (
                glab mr list -M --author @me -F json \
                | jq -r '.[] | .source_branch? // empty' \
                | string trim \
                | string match -rv '^$' \
                | sort -u
            )
    end

    # ── Source 2: branches merged into the default branch locally ────────
    # Catches the "merge a worktree without ever opening a PR" workflow,
    # which the forge query above can never see. Resolve the default branch
    # the way clone.fish does (origin/HEAD), falling back to main.
    set -l base (
        git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null \
        | string replace -r '^origin/' ''
    )
    test -z "$base"; and set base main

    set -l current_branch (git branch --show-current)
    set -l protected main master develop $base $current_branch

    # `--merged` is a cheap ancestry walk: it finds true merge commits and
    # fast-forwards, but not squash/rebase merges (the tip is no longer an
    # ancestor). Those are opt-in via --squash below.
    set -l local_merged
    if git show-ref --verify --quiet refs/heads/$base
        for b in (git branch --merged $base --format '%(refname:short)')
            contains -- $b $protected; or set -a local_merged $b
        end
    end

    # ── Source 3 (opt-in): squash/rebase merges, detected by patch equiv ──
    # `git cherry` is per-branch diff work, so only run it when asked. A
    # branch counts as merged if it has commits and every one already has a
    # patch-equivalent in the base (every line prefixed '-', none '+').
    set -l local_squashed
    if test $detect_squash -eq 1; and git show-ref --verify --quiet refs/heads/$base
        for b in (git branch --format '%(refname:short)')
            contains -- $b $protected; and continue
            contains -- $b $local_merged; and continue
            contains -- $b $forge_branches; and continue
            set -l cherry (git cherry $base $b 2>/dev/null)
            test (count $cherry) -gt 0; or continue
            string match -rq '^\+' -- $cherry; and continue
            set -a local_squashed $b
        end
    end

    # Combine into a single, order-preserving, de-duplicated work list.
    set -l branches
    for b in $forge_branches $local_merged $local_squashed
        contains -- $b $branches; or set -a branches $b
    end

    if test (count $branches) -eq 0
        echo $yellow"⚠ No merged branches found (forge or local)"$reset
        return 0
    end

    set -l removed_worktrees 0
    set -l removed_branches 0
    set -l skipped_branches 0
    set -l skipped_worktrees 0
    set -l failures 0
    set -l teardown_hooks 0
    set -l local_only 0
    set -l current_wt (pwd -P)

    for branch in $branches
        set -l branch_ref refs/heads/$branch

        # Attribute each branch to the source that surfaced it, so the log
        # makes clear *why* a branch with no PR is being cleaned up.
        set -l source_label
        if contains -- $branch $forge_branches
            set source_label "merged PR"
        else if contains -- $branch $local_merged
            set source_label "merged locally — no PR"
            set local_only (math $local_only + 1)
        else
            set source_label "squash-merged locally — no PR"
            set local_only (math $local_only + 1)
        end
        echo $bold"• $branch"$reset" "$dim"($source_label)"$reset
        set -l wt_paths (
            git worktree list --porcelain \
            | awk -v b="$branch_ref" '
                $1 == "worktree" { w = $2 }
                $1 == "branch" && $2 == b { print w }
            '
        )

        for wt in $wt_paths
            if test "$wt" = "$current_wt"
                echo $yellow"⚠ skipping current worktree: $wt"$reset
                set skipped_worktrees (math $skipped_worktrees + 1)
                continue
            end

            # Let the project reclaim its own per-worktree resources (databases,
            # ports, volumes, …) via its teardown hook, while the worktree still
            # exists. Best-effort — a failing hook is reported but never blocks
            # removal. Projects without the hook just get the worktree/branch
            # removed, as before.
            if test -x $wt/bin/worktree-teardown
                if test $dry_run -eq 1
                    echo $dim"  would run teardown hook: $wt/bin/worktree-teardown"$reset
                    set teardown_hooks (math $teardown_hooks + 1)
                else
                    pushd $wt
                    if ./bin/worktree-teardown
                        set teardown_hooks (math $teardown_hooks + 1)
                    else
                        echo $red"✖ teardown hook failed: $wt"$reset >&2
                        set failures (math $failures + 1)
                    end
                    popd
                end
            end

            if test $dry_run -eq 1
                echo $dim"  would remove worktree: $wt"$reset
                set removed_worktrees (math $removed_worktrees + 1)
            else
                if git worktree remove --force "$wt"
                    echo $dim"  removed worktree: $wt"$reset
                    set removed_worktrees (math $removed_worktrees + 1)
                else
                    echo $red"✖ Failed to remove worktree: $wt"$reset >&2
                    set failures (math $failures + 1)
                end
            end
        end

        if git show-ref --verify --quiet $branch_ref
            if test $dry_run -eq 1
                echo $dim"  would delete branch: $branch"$reset
                set removed_branches (math $removed_branches + 1)
            else
                if git branch -D "$branch" >/dev/null 2>&1
                    echo $green"✔ deleted branch: "$bold$branch$reset
                    set removed_branches (math $removed_branches + 1)
                else
                    echo $red"✖ Failed to delete branch: $branch"$reset >&2
                    set failures (math $failures + 1)
                end
            end
        else
            echo $dim"  skip (missing local branch): $branch"$reset
            set skipped_branches (math $skipped_branches + 1)
        end
    end

    if test $dry_run -eq 0
        git worktree prune >/dev/null 2>&1
    end

    echo
    echo $cyan"Summary"$reset
    echo "  worktrees removed: $removed_worktrees"
    echo "  worktrees skipped: $skipped_worktrees"
    echo "  branches deleted:  $removed_branches"
    echo "  branches skipped:  $skipped_branches"
    echo "  merged w/o PR:     $local_only"
    echo "  teardown hooks:    $teardown_hooks"
    echo "  failures:          $failures"

    if test $failures -gt 0
        return 1
    end
end
