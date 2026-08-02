mkcd() { mkdir -p -- "$1" && cd -- "$1" || return; }

sless() { bat --color=always --style=plain --decorations=never --paging=never "$@" | less -R; }

function clone() {
  local output repo_dir
  output="$(clone -d "$REPOS" -u "$USER" -r "github.com" "$@" 2>&1 | tee /dev/tty)"
  repo_dir="$(echo "$output" | tail -n 1)"
  [[ -d "$repo_dir" ]] && cd "$repo_dir" || return 1
}

function pathappend() {
  declare arg
  for arg in "$@"; do
    test -d "$arg" || continue
    PATH=${PATH//":$arg:"/:}
    PATH=${PATH/#"$arg:"/}
    PATH=${PATH/%":$arg"/}
    export PATH="${PATH:+"$PATH:"}$arg"
  done
}

function pathprepend() {
  for arg in "$@"; do
    test -d "$arg" || continue
    PATH=${PATH//:"$arg:"/:}
    PATH=${PATH/#"$arg:"/}
    PATH=${PATH/%":$arg"/}
    export PATH="$arg${PATH:+":${PATH}"}"
  done
}

pathprepend \
  "$CARGO_HOME/bin" \
  "$GOBIN" \
  "$HOME/.local/bin"

pathappend \
  /usr/local/sbin \
  /usr/local/bin \
  /usr/sbin \
  /usr/bin \
  /sbin \
  /bin
