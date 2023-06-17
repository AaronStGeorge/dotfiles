# prompt ======================================================================

# Assumes https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh is installed.
export PS1_BASE="\\w:\[\e[31m\]\$(__git_ps1 ' (%s)')\[\e[m\]"
export PS1_PROMPT=" 🐑💨 "

export PS1="$PS1_BASE$PS1_PROMPT"

# aliases =====================================================================

alias gco="git checkout"
# Assumes that git-completion.bash has been sourced 
# https://git-scm.com/book/en/v1/Git-Basics-Tips-and-Tricks.
# source: https://stackoverflow.com/questions/9869227/git-autocomplete-in-bash-aliases
__git_complete gco _git_checkout
alias goc="git checkout"
__git_complete goc _git_checkout
alias gs="git status"

# source other configs ========================================================

# source work bashrc if it exists
[[ -s ~/.bashrc_work ]] && source ~/.bashrc_work

# source home bashrc if it exists
[[ -s ~/.bashrc_home ]] && source ~/.bashrc_home

