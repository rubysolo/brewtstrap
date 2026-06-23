function _forge_kind --description 'Echo the forge CLI (gh|glab) for a repo, based on its remote'
    # Override escape hatch for ambiguous hosts (self-hosted GHE/GitLab on a
    # custom domain). Set FORGE_KIND to gh or glab to force a choice.
    if set -q FORGE_KIND
        echo $FORGE_KIND
        return 0
    end

    # Resolve a remote the same way the worktree helpers do: prefer origin,
    # otherwise fall back to the first configured remote.
    set -l remote_name origin
    if not git remote get-url $remote_name >/dev/null 2>&1
        set remote_name (git remote | head -n 1)
    end

    set -l url (git remote get-url $remote_name 2>/dev/null)
    switch $url
        case '*github.com*'
            echo gh
        case '*gitlab*'
            echo glab
        case '*'
            # Unknown host — let the caller decide how to handle it.
            return 1
    end
end
