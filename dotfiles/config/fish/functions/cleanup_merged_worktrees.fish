function cleanup_merged_worktrees --description 'Remove merged PR/MR branches and their worktrees'
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l yellow (set_color yellow)
    set -l green  (set_color green)
    set -l red    (set_color red)
    set -l dim    (set_color brblack)

    set -l dry_run 0
    if test (count $argv) -gt 1
        echo $red"Usage: cleanup_merged_worktrees [--dry-run|-n]"$reset >&2
        return 2
    end
    if test (count $argv) -eq 1
        switch $argv[1]
            case --dry-run -n
                set dry_run 1
            case '*'
                echo $red"Usage: cleanup_merged_worktrees [--dry-run|-n]"$reset >&2
                return 2
        end
    end

    if not git rev-parse --git-dir >/dev/null 2>&1
        echo $red"✖ Not inside a git repository"$reset >&2
        return 1
    end

    # Select the forge CLI from the repo's remote (gh for GitHub, glab for GitLab).
    set -l forge (_forge_kind)
    if test -z "$forge"
        echo $red"✖ Could not determine forge from remote — set FORGE_KIND to gh or glab"$reset >&2
        return 1
    end

    for cmd in git $forge awk sort
        if not type -q $cmd
            echo $red"✖ Missing dependency: $cmd"$reset >&2
            return 1
        end
    end

    set -l mode_label "apply"
    if test $dry_run -eq 1
        set mode_label "dry-run"
    end

    echo $cyan"🧹 Scanning merged branches via $forge ($mode_label)"$reset

    # Each forge reports the merged branches authored by the current user.
    # gh exposes --jq natively; glab needs an external jq pass.
    set -l branches
    switch $forge
        case gh
            set branches (
                gh pr list --state merged --author @me \
                    --json headRefName --jq '.[].headRefName' \
                | string trim \
                | string match -rv '^$' \
                | sort -u
            )
        case glab
            if not type -q jq
                echo $red"✖ Missing dependency: jq"$reset >&2
                return 1
            end
            set branches (
                glab mr list -M --author @me -F json \
                | jq -r '.[] | .source_branch? // empty' \
                | string trim \
                | string match -rv '^$' \
                | sort -u
            )
    end

    if test (count $branches) -eq 0
        echo $yellow"⚠ No merged branches found for @me"$reset
        return 0
    end

    set -l removed_worktrees 0
    set -l removed_branches 0
    set -l skipped_branches 0
    set -l skipped_worktrees 0
    set -l failures 0
    set -l teardown_hooks 0
    set -l current_wt (pwd -P)

    for branch in $branches
        set -l branch_ref refs/heads/$branch
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
    echo "  teardown hooks:    $teardown_hooks"
    echo "  failures:          $failures"

    if test $failures -gt 0
        return 1
    end
end
