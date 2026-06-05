function _new_worktree --description 'Shared helper: _new_worktree <type> <name>'
    # Color helpers
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l yellow (set_color yellow)
    set -l green  (set_color green)
    set -l red    (set_color red)
    set -l dim    (set_color brblack)

    if test (count $argv) -ne 2
        echo $red"Usage: _new_worktree <type> <name>"$reset >&2
        echo $dim"  e.g. _new_worktree feature 1234-xyz"$reset >&2
        return 1
    end

    set -l type $argv[1]
    set -l name $argv[2]
    set -l branch_name $type/$name

    # Find the shared repo root regardless of which worktree we're called from.
    # git rev-parse --git-common-dir always points to the bare repo (.bare).
    set -l git_common (git rev-parse --git-common-dir 2>/dev/null)
    if test $status -ne 0
        echo $red"✖  Not inside a git repository"$reset >&2
        return 1
    end
    set -l repo_root (path normalize $git_common/..)

    set -l worktree_path $repo_root/$type/$name

    if test -d $worktree_path
        echo $cyan"🔍  Existing worktree detected: "$bold$branch_name$reset
        echo $dim"  → "$worktree_path$reset
        cd $worktree_path
        return 0
    end

    echo $yellow"⚙  Setting up new worktree: "$bold$branch_name$reset
    echo $dim"  → "$worktree_path$reset

    # Create the type directory (feature/, chore/, fix/) if it doesn't exist yet.
    mkdir -p $repo_root/$type

    # Branch resolution order:
    # 1) Existing local branch
    # 2) Existing remote branch (create local tracking branch)
    # 3) Create a new branch from main
    set -l remote_name origin
    if not git remote get-url $remote_name >/dev/null 2>&1
        set remote_name (git remote | head -n 1)
    end

    if git show-ref --verify --quiet refs/heads/$branch_name
        git worktree add $worktree_path $branch_name
    else if test -n "$remote_name"; and git ls-remote --exit-code --heads $remote_name $branch_name >/dev/null 2>&1
        # Ensure the remote-tracking ref exists locally before creating the worktree.
        git fetch --no-tags $remote_name $branch_name >/dev/null 2>&1
        git worktree add --track -b $branch_name $worktree_path $remote_name/$branch_name
    else
        git worktree add -b $branch_name $worktree_path main
    end

    if test $status -ne 0
        echo $red"✖  git worktree add failed — worktree not created"$reset >&2
        return 1
    end

    # Copy selected files from the main worktree, if they exist.
    set -l files_to_copy \
        .vscode/settings.json \
        .mise.local.toml

    for rel_path in $files_to_copy
        set -l src $repo_root/main/$rel_path
        set -l dest $worktree_path/$rel_path
        if test -f $src
            mkdir -p (path dirname $dest)
            cp $src $dest
            echo $dim"📋  Copied $rel_path"$reset
        else
            echo $yellow"⚠  $src not found — skipping $rel_path copy"$reset
        end
    end

    echo $green"✔  Ready"$reset
    cd $worktree_path
end
