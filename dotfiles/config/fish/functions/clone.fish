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
    printf "gitdir: ./.bare\n" > .git; or return 1

    git worktree add -b main main origin/main; or return 1
    git -C main branch --set-upstream-to=origin/main main; or return 1

    mkdir -p main/.vscode
    if test -f main/.vscode/settings.json
        printf "%s\n" "main/.vscode/settings.json already exists, skipping..." >&2
    else
        echo  > main/.vscode/settings.json '{'
        echo >> main/.vscode/settings.json '    "window.title": "${dirty}${activeEditorShort}${separator}$dir_name → ${rootName}"'
        echo >> main/.vscode/settings.json '}'
    end

    printf "Cloned %s into %s and set up worktree 'main' tracking origin/main\n" $repo $dir_name
end
