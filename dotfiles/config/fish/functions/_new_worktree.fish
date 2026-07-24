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

    set -l worktree_path (wt $argv[1] $argv[2])
    or return $status

    cd $worktree_path
end
