function cleanup_merged_worktrees --description 'Report local branches/worktrees and remove the merged ones'
    set -l reset   (set_color normal)
    set -l bold    (set_color --bold)
    set -l cyan    (set_color cyan)
    set -l yellow  (set_color yellow)
    set -l green   (set_color green)
    set -l red     (set_color red)
    set -l magenta (set_color magenta)
    set -l dim     (set_color brblack)

    set -l dry_run 0
    set -l detect_squash 0
    set -l force 0
    for arg in $argv
        switch $arg
            case --dry-run -n
                set dry_run 1
            case --squash -s
                set detect_squash 1
            case --force -f
                set force 1
            case '*'
                echo $red"Usage: cleanup_merged_worktrees [--dry-run|-n] [--squash|-s] [--force|-f]"$reset >&2
                return 2
        end
    end

    if not git rev-parse --git-dir >/dev/null 2>&1
        echo $red"✖ Not inside a git repository"$reset >&2
        return 1
    end

    for cmd in git awk
        if not type -q $cmd
            echo $red"✖ Missing dependency: $cmd"$reset >&2
            return 1
        end
    end

    # Select the forge CLI from the repo's remote (gh for GitHub, glab for GitLab).
    # The forge is optional: without one, branches are classified from local
    # history alone and none of them can show PR state.
    set -l forge (_forge_kind)

    # Resolve the default branch the way clone.fish does (origin/HEAD),
    # falling back to main.
    set -l base (
        git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null \
        | string replace -r '^origin/' ''
    )
    test -z "$base"; and set base main

    # Local main only moves when the main worktree pulls, so it can lag.
    # Merge detection checks both refs: local catches merges not yet pushed,
    # origin catches merges not yet pulled. Ahead/behind is measured against
    # origin — what a PR compares to and what you'd rebase onto — falling
    # back to local. No fetch happens here: origin is as fresh as the last
    # fetch.
    set -l merge_refs
    git show-ref --verify --quiet refs/heads/$base; and set -a merge_refs $base
    git show-ref --verify --quiet refs/remotes/origin/$base; and set -a merge_refs origin/$base
    set -l cmp $merge_refs[-1]

    set -l mode_label "apply"
    test $dry_run -eq 1; and set mode_label "dry-run"
    set -l scan_source "local history"
    test -n "$forge"; and set scan_source "$forge + local history"
    set -l cmp_label ''
    test -n "$cmp"; and set cmp_label ", vs $cmp"
    echo $cyan"🧹 Worktrees & branches ($scan_source$cmp_label, $mode_label)"$reset

    # ── Forge: every PR/MR by the current user, any state ────────────────
    # One query for all states, reduced to a branch → PR lookup (parallel
    # lists). The loop below walks *local* branches, so a merged PR whose
    # branch is already gone never shows up. A branch with several PRs
    # resolves to its open one, otherwise the newest (both CLIs list newest
    # first).
    set -l forge_rows
    switch $forge
        case ''
            echo $yellow"⚠ No forge resolved from remote — PR state unavailable (set FORGE_KIND to gh or glab)"$reset
        case gh
            if not type -q gh
                echo $red"✖ Missing dependency: gh"$reset >&2
                return 1
            end
            set forge_rows (
                gh pr list --state all --author @me --limit 500 \
                    --json number,state,headRefName,headRefOid,url \
                    --jq '.[] | [.headRefName, (.state | ascii_downcase), .number, .headRefOid, .url] | @tsv'
            )
            or echo $yellow"⚠ gh query failed — PR state unavailable"$reset
        case glab
            for cmd in glab jq
                if not type -q $cmd
                    echo $red"✖ Missing dependency: $cmd (required for GitLab)"$reset >&2
                    return 1
                end
            end
            set forge_rows (
                glab mr list --all --author @me -P 100 -F json \
                | jq -r '.[] | [.source_branch, (if .state == "opened" then "open" else .state end), .iid, .sha, .web_url] | @tsv'
            )
            or echo $yellow"⚠ glab query failed — MR state unavailable"$reset
    end

    set -l pr_branch
    set -l pr_state
    set -l pr_num
    set -l pr_oid
    set -l pr_url
    for row in $forge_rows
        set -l f (string split \t -- $row)
        test (count $f) -ge 3; or continue
        set -l i (contains -i -- $f[1] $pr_branch)
        if test -z "$i"
            set -a pr_branch $f[1]
            set -a pr_state $f[2]
            set -a pr_num $f[3]
            set -a pr_oid "$f[4]"
            set -a pr_url "$f[5]"
        else if test "$f[2]" = open; and test "$pr_state[$i]" != open
            set pr_state[$i] $f[2]
            set pr_num[$i] $f[3]
            set pr_oid[$i] "$f[4]"
            set pr_url[$i] "$f[5]"
        end
    end

    # ── Local state ──────────────────────────────────────────────────────
    set -l current_branch (git branch --show-current)
    set -l protected main master develop $base $current_branch

    set -l branches
    for b in (git for-each-ref refs/heads --format '%(refname:short)')
        contains -- $b $protected; or set -a branches $b
    end

    if test (count $branches) -eq 0
        echo $dim"  no local branches besides $base"$reset
        return 0
    end

    # `--merged` is a cheap ancestry walk: it finds true merge commits and
    # fast-forwards — the "merge a worktree without ever opening a PR"
    # workflow — but not squash/rebase merges (the tip is no longer an
    # ancestor). Those are opt-in via --squash.
    set -l local_merged
    for ref in $merge_refs
        set -a local_merged (git branch --merged $ref --format '%(refname:short)')
    end

    # branch → worktree path, as "branch\tpath" rows (substr keeps paths
    # containing spaces intact).
    set -l wt_rows (
        git worktree list --porcelain \
        | awk '
            $1 == "worktree" { w = substr($0, 10) }
            $1 == "branch"   { sub("^refs/heads/", "", $2); print $2 "\t" w }
        '
    )
    # Worktrees git considers locked — a long-running / AFK agent can lock its
    # worktree to claim it. Never reclaim a locked worktree unless forced.
    set -l locked_worktrees (
        git worktree list --porcelain \
        | awk '
            $1 == "worktree" { w = substr($0, 10) }
            $1 == "locked"   { print w }
        '
    )
    set -l current_wt (pwd -P)

    # ── Pass 1: classify every local branch ──────────────────────────────
    # kind: merged | open | closed | none. label is the PR column; note, when
    # set on a merged branch, is why it must be kept anyway.
    set -l kinds
    set -l labels
    set -l notes
    set -l urls
    for b in $branches
        set -l kind none
        set -l label "no PR"
        set -l note ''
        set -l url ''
        set -l i (contains -i -- $b $pr_branch)

        if test -n "$i"
            set kind $pr_state[$i]
            set label "$pr_state[$i] #$pr_num[$i]"
            set url "$pr_url[$i]"
            # Anything other than open/merged (closed, GitLab's locked) is
            # reported but never cleaned on the forge's say-so.
            contains -- $kind open merged; or set kind closed

            # A merged PR only vouches for the commit it merged. If the local
            # branch has moved past that head — new work on a reused branch
            # name, or commits added after the merge — keep it. A head that
            # isn't available locally (rewritten on the forge, never
            # fetched) trusts the PR.
            set -l oid $pr_oid[$i]
            if test $kind = merged; and test -n "$oid"; and git cat-file -e "$oid^{commit}" 2>/dev/null
                if not git merge-base --is-ancestor $b $oid
                    set -l extra (git rev-list --count $oid..$b)
                    set note "kept: $extra commit(s) since merge"
                end
            end
        end

        if test $kind = none; or test $kind = closed
            # A branch that never got a commit of its own is trivially an
            # ancestor of base — "merged" by --merged — yet it's usually a
            # fresh worktree nobody has started in. The reflog tells them
            # apart: nothing but "branch: Created from …" (and renames)
            # means no work ever landed. Without a reflog, fall back to the
            # tip still sitting exactly on base. PR-less only; a PR means
            # work.
            set -l fresh 0
            if test -z "$i"; and contains -- $b $local_merged
                set -l reflog (git reflog show --format=%gs refs/heads/$b 2>/dev/null)
                if test (count $reflog) -gt 0
                    string match -qvr '^(branch: Created from |Branch: renamed )' -- $reflog; or set fresh 1
                else if contains -- (git rev-parse $b) (git rev-parse $merge_refs)
                    set fresh 1
                end
            end

            if test $fresh -eq 1
                set note fresh
            else if contains -- $b $local_merged
                set kind merged
                set label "merged (local)"
            else if test $detect_squash -eq 1; and test -n "$cmp"
                # Patch-equivalence: the branch has commits and every one
                # already has an equivalent in base (every `git cherry` line
                # '-', none '+').
                set -l cherry (git cherry $cmp $b 2>/dev/null)
                if test (count $cherry) -gt 0; and not string match -rq '^\+' -- $cherry
                    set kind merged
                    set label "squashed (local)"
                end
            end
        end

        set -a kinds $kind
        set -a labels $label
        set -a notes "$note"
        set -a urls "$url"
    end

    set -l w_branch 0
    for b in $branches
        set w_branch (math max $w_branch, (string length -- $b))
    end
    set -l w_label 0
    for l in $labels
        set w_label (math max $w_label, (string length -- $l))
    end

    set -l n_cleaned 0
    set -l n_kept 0
    set -l n_open 0
    set -l n_closed 0
    set -l n_none 0
    set -l teardown_hooks 0
    set -l failures 0

    # ── Pass 2: act on merged branches, report the rest ──────────────────
    for want in merged open closed none
        for idx in (seq (count $branches))
            test $kinds[$idx] = $want; or continue
            set -l b $branches[$idx]
            set -l wts
            for r in $wt_rows
                set -l p (string split -m 1 \t -- $r)
                test "$p[1]" = "$b"; and set -a wts $p[2]
            end

            set -l icon
            set -l color
            set -l detail

            switch $want
                case merged
                    set -l keep "$notes[$idx]"
                    if test -z "$keep"
                        for wt in $wts
                            if test "$wt" = "$current_wt"
                                set keep "kept: current worktree"
                            else if test $force -eq 0
                                # Refuse to reclaim a worktree that's still in
                                # use. The classic false positive: an agent
                                # created a branch but hasn't committed yet, so
                                # its tip is still base — trivially "merged" —
                                # while the real work sits uncommitted. A lock
                                # is an even stronger "hands off". --force
                                # overrides both.
                                if contains -- $wt $locked_worktrees
                                    set keep "kept: worktree locked"
                                else if test -n "$(git -C $wt status --porcelain 2>/dev/null)"
                                    set keep "kept: uncommitted changes"
                                end
                            end
                        end
                    end

                    if test -n "$keep"
                        set icon ⚠
                        set color $yellow
                        set detail $keep
                        set n_kept (math $n_kept + 1)
                    else
                        set -l ok 1
                        set -l ran_hook 0
                        for wt in $wts
                            # Let the project reclaim its own per-worktree
                            # resources (databases, ports, volumes, …) while
                            # the worktree still exists. Best-effort — a
                            # failing hook is reported but never blocks removal.
                            if test -x $wt/bin/worktree-teardown
                                set ran_hook 1
                                set teardown_hooks (math $teardown_hooks + 1)
                                if test $dry_run -eq 0
                                    pushd $wt
                                    if not ./bin/worktree-teardown
                                        echo $red"✖ teardown hook failed: $wt"$reset >&2
                                        set failures (math $failures + 1)
                                    end
                                    popd
                                end
                            end
                            if test $dry_run -eq 0; and not git worktree remove --force "$wt"
                                set ok 0
                            end
                        end
                        if test $ok -eq 1; and test $dry_run -eq 0
                            git branch -D "$b" >/dev/null 2>&1; or set ok 0
                        end

                        set -l what branch
                        test (count $wts) -gt 0; and set what "worktree + branch"
                        test $ran_hook -eq 1; and set what "$what (+ teardown)"
                        if test $ok -eq 0
                            set icon ✖
                            set color $red
                            set detail "failed to remove $what"
                            set failures (math $failures + 1)
                        else
                            set icon ✔
                            set color $green
                            if test $dry_run -eq 1
                                set detail "would remove $what"
                            else
                                set detail "removed $what"
                            end
                            set n_cleaned (math $n_cleaned + 1)
                        end
                    end
                case open closed none
                    switch $want
                        case open
                            set icon ●
                            set color $cyan
                            set n_open (math $n_open + 1)
                        case closed
                            set icon ✗
                            set color $magenta
                            set n_closed (math $n_closed + 1)
                        case none
                            set icon ○
                            set color $reset
                            set n_none (math $n_none + 1)
                    end
                    # "behind\tahead" relative to cmp (origin/main when present).
                    set -l lr
                    test -n "$cmp"; and set lr (git rev-list --left-right --count $cmp...$b | string split \t)
                    set -l bits
                    if test "$notes[$idx]" = fresh
                        # Its tip is base's commit, so report when the branch
                        # was created (oldest reflog entry), not that date.
                        set -a bits "fresh, no commits yet"
                        test -n "$lr"; and set -a bits "$lr[1] behind"
                        set -l created (
                            git reflog show --date=relative --format=%gd refs/heads/$b 2>/dev/null \
                            | tail -n 1 | string replace -rf '.*@\{(.*)\}$' 'created $1'
                        )
                        set -a bits $created
                    else
                        test -n "$lr"; and set -a bits "$lr[2] ahead" "$lr[1] behind"
                        set -a bits (git log -1 --format=%cr $b)
                    end
                    if test (count $wts) -eq 0
                        set -a bits "no worktree"
                    else if test -n "$(git -C $wts[1] status --porcelain 2>/dev/null)"
                        set -a bits "uncommitted changes"
                    end
                    set detail (string join ' · ' -- $bits)
            end

            # Pad the plain label first, then turn its "#N" into an OSC 8
            # hyperlink (⌘-click in Ghostty/iTerm) — the escapes are
            # zero-width, so padding them would misalign the columns. Only
            # on a terminal, so piped output stays plain text.
            set -l label (string pad -r -w $w_label -- $labels[$idx])
            if test -n "$urls[$idx]"; and isatty stdout
                set -l num (string match -r '#\d+' -- $labels[$idx])
                set -l around (string split -m 1 -- $num $label)
                set label $around[1](printf '\e]8;;%s\e\\\\%s\e]8;;\e\\\\' $urls[$idx] $num)$around[2]
            end

            echo "  "$color$icon$reset" "$bold(string pad -r -w $w_branch -- $b)$reset"  "$color$label$reset"  "$dim$detail$reset
        end
    end

    if test $dry_run -eq 0
        git worktree prune >/dev/null 2>&1
    end

    set -l cleaned_label cleaned
    test $dry_run -eq 1; and set cleaned_label "to clean"
    set -l summary
    test $n_cleaned -gt 0; and set -a summary "$n_cleaned $cleaned_label"
    test $n_kept -gt 0; and set -a summary "$n_kept kept"
    test $n_open -gt 0; and set -a summary "$n_open open PR"
    test $n_closed -gt 0; and set -a summary "$n_closed closed"
    test $n_none -gt 0; and set -a summary "$n_none without PR"
    test $teardown_hooks -gt 0; and set -a summary "$teardown_hooks teardown hook(s)"
    test $failures -gt 0; and set -a summary "$failures failed"
    echo
    echo $cyan(string join ' · ' -- $summary)$reset

    test $failures -eq 0
end
