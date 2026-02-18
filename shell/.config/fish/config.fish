abbr -a yr 'cal -y'
abbr -a c cargo
abbr -a e hx
abbr -a m make
switch (uname -s)
    case Darwin
        abbr -a o open
    case Linux
        abbr -a o xdg-open
end
abbr -a g git

if test (uname -s) = Linux; and command -v xclip >/dev/null
    function pbcopy
        xclip -selection clipboard
    end
    function pbpaste
        xclip -selection clipboard -o
    end
end

if status is-interactive
    if test -d ~/dev/others/base16/templates/fish-shell
        set fish_function_path $fish_function_path ~/dev/others/base16/templates/fish-shell/functions
        builtin source ~/dev/others/base16/templates/fish-shell/conf.d/base16.fish
    end
    switch $TERM
        case linux
            :
        case '*'
            if ! set -q TMUX
                # ensure that the new tmux _also_ starts fish
                exec tmux set-option -g default-shell (which fish) ';' new-session
            end
    end
end

if command -v eza >/dev/null
    abbr -a l eza
    abbr -a ls eza
    abbr -a ll 'eza -l'
    abbr -a la 'eza -la'
else
    abbr -a l ls
    abbr -a ll 'ls -l'
    abbr -a la 'ls -la'
end

if test -f /usr/share/autojump/autojump.fish
    source /usr/share/autojump/autojump.fish
end

function remote_alacritty
    # https://gist.github.com/costis/5135502
    set fn (mktemp)
    infocmp alacritty >$fn
    scp $fn $argv[1]":alacritty.ti"
    ssh $argv[1] tic "alacritty.ti"
    ssh $argv[1] rm "alacritty.ti"
end

# Type - to move up to top parent dir which is a repository
function d
    while test $PWD != /
        if test -d .git
            break
        end
        cd ..
    end
end

# Fish git prompt
set __fish_git_prompt_showuntrackedfiles yes
set __fish_git_prompt_showdirtystate yes
set __fish_git_prompt_showstashstate ''
set __fish_git_prompt_showupstream none
set -g fish_prompt_pwd_dir_length 3

# colored man output
# from http://linuxtidbits.wordpress.com/2009/03/23/less-colors-for-man-pages/
setenv LESS_TERMCAP_mb \e'[01;31m' # begin blinking
setenv LESS_TERMCAP_md \e'[01;38;5;74m' # begin bold
setenv LESS_TERMCAP_me \e'[0m' # end mode
setenv LESS_TERMCAP_se \e'[0m' # end standout-mode
setenv LESS_TERMCAP_so \e'[38;5;246m' # begin standout-mode - info box
setenv LESS_TERMCAP_ue \e'[0m' # end underline
setenv LESS_TERMCAP_us \e'[04;38;5;146m' # begin underline

setenv FZF_DEFAULT_COMMAND 'fd --type file --follow'
setenv FZF_CTRL_T_COMMAND 'fd --type file --follow'
setenv FZF_DEFAULT_OPTS '--height 20%'

function fish_user_key_bindings
    bind \cz 'fg 2>/dev/null'
    if functions -q fzf_key_bindings
        fzf_key_bindings
    end
end

function fish_prompt
    set_color brblack
    echo -n "["(date "+%H:%M")"] "
    set_color blue
    echo -n (hostname -s)
    if [ $PWD != $HOME ]
        set_color brblack
        echo -n ':'
        set_color yellow
        echo -n (basename $PWD)
    end
    set_color green
    printf '%s ' (__fish_git_prompt)
    set_color red
    echo -n '| '
    set_color normal
end

function fish_greeting
    echo

    switch (uname -s)
        case Darwin
            echo -e " \e[1mOS: \e[0;32m"(sw_vers -productName)" "(sw_vers -productVersion)"\e[0m"
            echo -e " \e[1mUptime: \e[0;32m"(uptime | sed 's/.*up //' | sed 's/,.*//')"\e[0m"
            echo -e " \e[1mHostname: \e[0;32m"(hostname -s)"\e[0m"
            echo -e " \e[1mDisk usage:\e[0m"
            echo
            echo -ne (df -h / | tail -1 | awk '{printf "\\t%s / %4s %4s  %s\\n", $3, $2, $5, $9}')
            echo
            echo -e " \e[1mNetwork:\e[0m"
            echo
            for iface in (ifconfig -lu)
                set ip (ifconfig $iface 2>/dev/null | grep 'inet ' | awk '{print $2}')
                if test -n "$ip"
                    printf "\t\e[36m%s\e[0m %s\n" $iface $ip
                end
            end
            echo

        case Linux
            echo -e (uname -ro | awk '{print " \\\\e[1mOS: \\\\e[0;32m"$0"\\\\e[0m"}')
            echo -e (uptime -p | sed 's/^up //' | awk '{print " \\\\e[1mUptime: \\\\e[0;32m"$0"\\\\e[0m"}')
            echo -e (uname -n | awk '{print " \\\\e[1mHostname: \\\\e[0;32m"$0"\\\\e[0m"}')
            echo -e " \\e[1mDisk usage:\\e[0m"
            echo
            echo -ne (\
				df -l -h | grep -E 'dev/(nvme|sdb)' | \
				awk '{printf "\\\\t%s / %4s %4s  %s\\\\n\n", $3, $2, $5, $6}' | \
				paste -sd ''\
			)
            echo
            echo -e " \\e[1mNetwork:\\e[0m"
            echo
            echo -ne (\
				ip addr show up scope global | \
					grep -E ': <|inet' | \
					sed \
						-e 's/^[[:digit:]]\+: //' \
						-e 's/: <.*//' \
						-e 's/.*inet[[:digit:]]* //' \
						-e 's/\/.*//'| \
					awk 'BEGIN {i=""} /\.|:/ {print i" "$0"\\\n"; next} // {i = $0}' | \
					sort | \
					column -t -R1 | \
					sed 's/ \([^ ]\+\)$/ \\\e[4m\1/' | \
					sed 's/m\(\(10\.\|172\.\(1[6-9]\|2[0-9]\|3[01]\)\|192\.168\.\).*\)/m\\\e[24m\1/' | \
					sed 's/^\( *[^ ]\+\)/\\\e[36m\1/' | \
					sed 's/\(\(en\|em\|eth\)[^ ]* .*\)/\\\e[39m\1/' | \
					sed 's/\(wl[^ ]* .*\)/\\\e[35m\1/' | \
					sed 's/\(ww[^ ]* .*\).*/\\\e[33m\1/' | \
					sed 's/$/\\\e[0m/' | \
					sed 's/^/\t/' \
				)
            echo
    end

    set r (random 0 100)
    if [ $r -lt 5 ] # only occasionally show backlog (5%)
        echo -e " \e[1mBacklog\e[0;32m"
        set_color blue
        echo "  [project] <description>"
        echo
    end

    set_color normal
    echo -e " \e[1mTODOs\e[0;32m"
    echo
    if [ $r -lt 10 ]
        # unimportant, so show rarely
        set_color cyan
        # echo "  [project] <description>"
    end
    if [ $r -lt 25 ]
        # back-of-my-mind, so show occasionally
        set_color green
        # echo "  [project] <description>"
    end
    if [ $r -lt 50 ]
        # upcoming, so prompt regularly
        set_color yellow
        # echo "  [project] <description>"
    end

    # urgent, so prompt always
    set_color red
    # echo "  [project] <description>"

    echo

    if test -s ~/todo
        set_color magenta
        cat todo | sed 's/^/ /'
        echo
    end

    set_color normal
end

function jjpr --wraps='jj show' --description 'Opens the PR for a change in Linear' --argument-names change
    linctl pr view (gh pr view (jj bookmark list -T name -r $change) --json number -q '.number')
end
