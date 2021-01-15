alias cdr="cd /pelion-build"
alias cdh="cd /mnt/home"
alias v="ls -la"

# Docker for Mac does not correctly map the socket permissions and owner
# making it unusable in the default state except by root
[ -n "$SSH_AUTH_SOCK" ] && sudo chown user $SSH_AUTH_SOCK
