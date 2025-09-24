# ~/.bashrc: executed by bash(1) for non-login shells.
#PS1='\[$(tput setaf 15)\][\[$(tput setaf 15)\] \s \V \[$(tput setaf 15)\]| \[$(tput setaf 15)\]\d, \[$(tput setaf 15)\]\t \[$(tput setaf 15)\]| \[$(tput setaf 15)\]\w\[$(tput setaf 15)\] ]\n\[$(tput setaf 15)\]\u\[$(tput setaf 15)\]@\[$(tput setaf 15)\]\H\[$(tput setaf 15)\]: '

PS1='\[$(tput setaf 15)\][\[$(tput setaf 39)\] \s \V \[$(tput setaf 15)\]| \[$(tput setaf 45)\]\d, \[$(tput setaf 51)\]\t \[$(tput setaf 15)\]| \[$(tput setaf 195)\]\w\[$(tput setaf 15)\] ]\n\[$(tput setaf 87)\]\u\[$(tput setaf 15)\]@\[$(tput setaf 69)\]\H\[$(tput setaf 15)\]: '

if [ "$EUID" -eq 0 ]; then
    PS1='\[$(tput setaf 196)\][ROOT] '"$PS1"
fi

# Source user aliases if present
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# History settings for security and usability
export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=10000
export HISTFILESIZE=20000
shopt -s histappend

# Safe PATH setting (add user bin first)
export PATH="$HOME/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Only run interactive commands in interactive shells
case $- in *i*) ;; *) return;; esac

# Set terminal window title (optional, for xterm/rxvt)
case $TERM in
    xterm*|rxvt*)
        PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
        ;;
esac

# FZF key bindings (if installed)
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Set up fzf key bindings and fuzzy completion
# eval "$(fzf --bash)"

# Bash input enhancements
if [ -t 1 ]; then
    bind 'set enable-bracketed-paste on'
    bind 'TAB':menu-complete
    bind 'set show-all-if-ambiguous on'
    bind 'set menu-complete-display-prefix on'
fi

# Colorized ls and related aliases
export COLOR_OPTIONS='--color=auto'
eval "$(dircolors)"
alias ls='ls $COLOR_OPTIONS'
alias ll='ls $COLOR_OPTIONS -l'
alias la='ls $COLOR_OPTIONS -lA'
alias l='ls $COLOR_OPTIONS -lACF'
alias dir='dir $COLOR_OPTIONS'
alias vdir='vdir $COLOR_OPTIONS'
alias grep='grep $COLOR_OPTIONS'
alias fgrep='fgrep $COLOR_OPTIONS'
alias egrep='egrep $COLOR_OPTIONS'
alias diff='diff $COLOR_OPTIONS'
alias ip='ip $COLOR_OPTIONS'

# Safer file operations
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias back='cd -'

# Security and update helpers
alias update='sudo su -s /bin/bash root -c "apt update && apt full-upgrade -y && apt auto-remove -y"'
alias pubip='curl ipinfo.io/ip'
alias clear-history='history -c; echo > ~/.bash_history'
alias ebash='vim ~/.bashrc'
