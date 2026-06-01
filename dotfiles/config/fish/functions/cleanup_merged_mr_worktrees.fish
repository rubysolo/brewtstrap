function cleanup_merged_mr_worktrees --description 'Remove merged MR branches and their worktrees'
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l yellow (set_color yellow)
    set -l green  (set_color green)
    set -l red    (set_color red)
    set -l dim    (set_color brblack)

    set -l dry_run 0
    if test (count $argv) -gt 1
        echo $red"Usage: cleanup_merged_mr_worktrees [--dry-run|-n]"$reset >&2
        return 2
    end
    if test (count $argv) -eq 1
        switch $argv[1]
            case --dry-run -n
                set dry_run 1
            case '*'
                echo $red"Usage: cleanup_merged_mr_worktrees [--dry-run|-n]"$reset >&2
                return 2
        end
    end

    for cmd in git glab jq awk sort
        if not type -q $cmd
            echo $red"✖ Missing dependency: $cmd"$reset >&2
            return 1
        end
    end

    if not git rev-parse --git-dir >/dev/null 2>&1
        echo $red"✖ Not inside a git repository"$reset >&2
        return 1
    end

    set -l mode_label "apply"
    if test $dry_run -eq 1
        set mode_label "dry-run"
    end

    echo $cyan"🧹 Scanning merged MRs ($mode_label)"$reset

    set -l branches (
        glab mr list -M --author @me -F json \
        | jq -r '.[] | .source_branch? // empty' \
        | string trim \
        | string match -rv '^$' \
        | sort -u
    )

    if test (count $branches) -eq 0
        echo $yellow"⚠ No merged MR source branches found for @me"$reset
        return 0
    end

    set -l removed_worktrees 0
    set -l removed_branches 0
    set -l skipped_branches 0
    set -l skipped_worktrees 0
    set -l failures 0
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
    echo "  failures:          $failures"

    if test $failures -gt 0
        return 1
    end
end
