# sshe HOST: ssh with the local aliases loaded in the remote shell.
local host="$1"
local local_tmp remote_tmp
local_tmp=$(mktemp)
remote_tmp="/tmp/.aliases_$$"
alias | sed 's/^/alias /' >| "$local_tmp"
scp -q "$local_tmp" "$host:$remote_tmp"
rm -f "$local_tmp"
ssh -t "$host" "
  if command -v zsh >/dev/null 2>&1; then
    d=\$(mktemp -d)
    printf '%s\n' 'source \$HOME/.zshrc 2>/dev/null' 'source $remote_tmp' > \"\$d/.zshrc\"
    ZDOTDIR=\$d zsh
    rm -rf \"\$d\"
  else
    bash --init-file $remote_tmp
  fi
  rm -f $remote_tmp
"
