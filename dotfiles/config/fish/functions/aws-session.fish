function aws-session --description "Mint temporary MFA'd AWS credentials into <nick>:aws:session"
    argparse --name=aws-session 'd/duration=' 'h/help' -- $argv
    or return 2

    if set -q _flag_help; or test (count $argv) -ne 1
        printf '%s\n' \
            "usage: aws-session <nickname> [-d SECONDS]" \
            "" \
            "  Reads <nick>:aws:mfa for a one-time code and <nick>:aws for the long-lived" \
            "  keys, exchanges them with STS, and stores the temporary credentials as the" \
            "  env pack <nick>:aws:session (default 12h)." \
            "" \
            "  Costs two Touch IDs. After that:  skrt exec <nick>:aws:session -- <command>" >&2
        return 2
    end

    set -l nick $argv[1]
    set -l duration 43200 # 12h; an IAM user may go to 129600 (36h)
    set -q _flag_duration; and set duration $_flag_duration

    set -l base $nick:aws
    set -l mfa $nick:aws:mfa
    set -l session $nick:aws:session

    # 👆 1 — the one-time code. It is short-lived and single-use, so handing it to the aws
    # CLI as an argument is acceptable in a way the seed behind it never would be.
    set -l code (skrt get $mfa)
    or return $status

    # skrt has no expiry concept yet, so park it in the label: `skrt list` then shows when
    # the session dies without a prompt. AWS's own Expiration is a second or two later.
    set -l expires (date -u -v"+"$duration"S" "+%Y-%m-%dT%H:%MZ")

    # 👆 2 — the long-lived keys, injected into the aws CLI's environment and nowhere else.
    # AWS_MFA_SERIAL is read inside the child, since that is the only place it exists. The
    # temporary credentials go straight from STS into skrt: no shell variable, no file, no
    # terminal. If any stage fails, `skrt set` refuses the empty input *before* --replace
    # drops anything, so the previous session survives.
    skrt exec $base -- sh -c '
        aws sts get-session-token \
            --serial-number "$AWS_MFA_SERIAL" \
            --token-code "$1" \
            --duration-seconds "$2"' sh $code $duration \
        | jq -e '{
            AWS_ACCESS_KEY_ID:     .Credentials.AccessKeyId,
            AWS_SECRET_ACCESS_KEY: .Credentials.SecretAccessKey,
            AWS_SESSION_TOKEN:     .Credentials.SessionToken
          }' \
        | skrt set $session --kind env --replace --label "expires $expires"

    for s in $pipestatus
        if test $s -ne 0
            echo "aws-session: failed (exit $s) — $session left as it was" >&2
            return $s
        end
    end

    echo "aws-session: $session ready, expires $expires" >&2
    echo "             skrt exec $session -- <command>" >&2
end
