set fish_greeting

###############################################################################
# Command Line Shortcuts
###############################################################################

# Path Shortcuts
alias d="cd ~/Dropbox"
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"

# Command/App Shortcuts
alias h="history"
alias ls="lsd"
alias l="ls -l"
alias la="ls -a"
alias lla="ls -la"
alias lt="ls --tree"
alias o="open"
alias v="code"

# List all files colorized in long format
# alias l="ls -lF"

# List all files colorized in long format, including dot files
# alias la="ls -laF"

# List only directories
# alias lsd="ls -lF | grep --color=never '^d'"

# Always use color output for `ls`
# alias ls="command ls"

# Enable aliases to be sudo’ed
# alias sudo='sudo '

# Get week number
# alias week='date +%V'

# Stopwatch
# alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'

# Trim new lines and copy to clipboard
alias c="tr -d '\n' | pbcopy"

# URL-de/encode strings
# alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'
alias urldecode='python -c "import sys; import urllib.parse as up; print(up.unquote_plus(sys.argv[1]))"'
alias urlencode='python -c "import sys; import urllib.parse as up; print(up.quote_plus(sys.argv[1]))"'

# Merge PDF files
# Usage: `mergepdf -o output.pdf input{1,2,3}.pdf`
# alias mergepdf='/System/Library/Automator/Combine\ PDF\ Pages.action/Contents/Resources/join.py'

# Ring the terminal bell, and put a badge on Terminal.app’s Dock icon
# (useful when executing time-consuming commands)
# alias badge="tput bel"

# Intuitive map function
# For example, to list all directories that contain a certain file:
# find . -name .gitattributes | map dirname
# alias map="xargs -n1"

# Reload the shell (i.e. invoke as a login shell)
alias reload="exec $SHELL -l"


###############################################################################
# Networking
###############################################################################

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# View HTTP traffic
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# Make HTTP methods into command line commands (One of @janmoesen’s ProTip™s)
for method in GET HEAD POST PUT DELETE TRACE OPTIONS
  alias "$method"="lwp-request -m '$method'"
end

###############################################################################
# Desktop
###############################################################################

# Show/hide hidden files in Finder
alias showfiles="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hidefiles="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# Hide/show desktop icons
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

# Spotlight
alias spotoff="sudo mdutil -a -i off"
alias spoton="sudo mdutil -a -i on"

# Lock the screen (when going AFK)
alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"


###############################################################################
# Fixes / Cleanups
###############################################################################

# Easy Update
# OS X software updates, Homebrew, Ruby gems, NPM, etc
alias update='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup; sudo npm update npm -g; sudo npm update -g; sudo gem update --system; sudo gem update'

# Recursively delete `.DS_Store` files
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"

# Empty the Trash on all mounted volumes and the main HDD
# Also, clear Apple’s System Logs to improve shell startup speed
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl"

# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"

# Flush Directory Service cache
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"

# Clean up LaunchServices to remove duplicates in the “Open With” menu
alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"

# Reload Launchpad
# http://www.defaults-write.com/active-defaults-setting-for-os-x-launchpad/#.U_issVNdUeM
alias fixlaunchpad="defaults write com.apple.dock ResetLaunchPad -bool true; killall Dock"
