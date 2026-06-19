function clone --description 'Clone a repository and set up with worktrees'
    if not set -q argv[1]
        echo "Usage: clone <repo-url> [directory-name]"
        return 1
    end

    set repo $argv[1]
    set dir_name

    if set -q argv[2]
        set dir_name $argv[2]
    else
        set normalized_repo (string trim --right --chars='/' -- $repo)
        set dir_name (string replace -r '^.*[:/]' '' -- $normalized_repo)
        set dir_name (string replace -r '\.git$' '' -- $dir_name)
    end

    if test -z "$dir_name"
        echo "Could not determine directory name from repo URL: $repo"
        return 1
    end

    mkdir -- $dir_name; or return 1
    cd -- $dir_name; or return 1

    git clone --bare $repo .bare; or return 1
    git -C .bare config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"; or return 1
    git -C .bare fetch origin; or return 1
    printf "gitdir: ./.bare\n" > .git; or return 1

    # `git clone --bare` already creates local branches for every remote head,
    # so check out the existing default branch instead of creating a new one.
    set default_branch (git -C .bare symbolic-ref --short HEAD); or return 1

    git worktree add $default_branch $default_branch; or return 1
    git -C $default_branch branch --set-upstream-to=origin/$default_branch >/dev/null 2>&1

    mkdir -p $default_branch/.vscode
    if test -f $default_branch/.vscode/settings.json
        printf "%s\n" "$default_branch/.vscode/settings.json already exists, skipping..." >&2
    else
        echo  > $default_branch/.vscode/settings.json '{'
        echo >> $default_branch/.vscode/settings.json "    \"window.title\": \"\${dirty}\${activeEditorShort}\${separator}$dir_name → \${rootName}\""
        echo >> $default_branch/.vscode/settings.json '}'
    end

    printf "Cloned %s into %s and set up worktree '%s' tracking origin/%s\n" $repo $dir_name $default_branch $default_branch
end
