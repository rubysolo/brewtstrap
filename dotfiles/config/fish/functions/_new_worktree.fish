function _new_worktree --description 'Shared helper: _new_worktree <type> <name>'
    # All the real work lives in `wt` (dotfiles/bin/wt, linked to ~/.local/bin)
    # so that non-fish shells — and coding agents, which get a bare zsh/bash —
    # can create properly provisioned worktrees too. Keeping the logic in a
    # fish function made it invisible to everything except an interactive fish
    # session, and agents silently fell back to raw `git worktree add`, skipping
    # bin/worktree-setup and its per-worktree DB/port provisioning.
    #
    # `wt` prints the worktree path on stdout and everything else on stderr; a
    # child process can't change our cwd, so the `cd` is the one piece that has
    # to stay here.
    if test (count $argv) -ne 2
        echo (set_color red)"Usage: _new_worktree <type> <name>"(set_color normal) >&2
        echo (set_color brblack)"  e.g. _new_worktree feat 1234-xyz"(set_color normal) >&2
        return 1
    end

    # Two calls, not one: create the worktree, cd into it, and only then run the
    # slow provisioning. Provisioning is minutes of `mix setup` (deps, database,
    # seeds, a 56 MB asset toolchain) with long silent stretches, and it reads as
    # a hang often enough that it gets Ctrl-C'd. With one call that Ctrl-C killed
    # `wt` before it printed the path, so this `cd` never ran and you ended up
    # back where you started. Now the cd has already happened: an interrupt only
    # costs the provisioning, and `bin/worktree-setup` is idempotent, so
    # re-running it in place finishes the job.
    # `--no-provision` exits 3 when the worktree already existed — switching to
    # one you already have must not re-run the hook.
    set -l worktree_path (wt --no-provision $argv[1] $argv[2])
    set -l create_status $status
    if test $create_status -ne 0 -a $create_status -ne 3
        return $create_status
    end

    cd $worktree_path
    or return $status

    if test $create_status -eq 0
        wt --provision-only $argv[1] $argv[2] >/dev/null
    end
end
