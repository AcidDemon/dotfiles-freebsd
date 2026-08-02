export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# XDG base directories. Everything below expands these, so they must be defined
# first. Without them CARGO_HOME, GOPATH, PYENV_ROOT and friends expanded to
# root-level paths (/.cargo, /.go, /.pyenv), which is why `cargo build` failed
# with "failed to create directory /.cargo/registry/cache: Permission denied".
# XDG_RUNTIME_DIR is deliberately not set here -- see ~/.zprofile for why it
# must not use pam_xdg's directory.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

export WORKSPACE="$HOME/Workspace"
export RECON="$WORKSPACE/recon"
export REPOS="$WORKSPACE/repos"
export GHREPOS="$REPOS/github.com"
export GLREPOS="$REPOS/gitlab.com"
export NOTES="$HOME/Workspace/notes"

export CDPATH=".:$REPOS:$GHREPOS:$GHREPOS/$USER:$GLREPOS:$GLREPOS/$USER:$WORKSPACE:$RECON:$HOME"

export GOBIN="$HOME/.local/bin"
export GOPATH="$XDG_DATA_HOME/.go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"

export CARGO_HOME="$XDG_DATA_HOME/.cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/.rust"

export GNUPGHOME="$HOME/.gnupg"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export GTK_RC_FILES="$XDG_CONFIG_HOME/gtk-1.0/gtkrc"
export PYENV_ROOT="$XDG_DATA_HOME/.pyenv"
export PYTHONPYCACHEPREFIX="$XDG_CACHE_HOME/python"
export PYTHONUSERBASE="$XDG_DATA_HOME/.python"
export PYTHON_HISTORY="$XDG_STATE_HOME/python/history"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"
export WORKON_HOME="$XDG_DATA_HOME/.virtualenvs"
export LESS="-R --quiet"
export LESSOPEN="| /home/acid/bin/lessopen-bat %s"
export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=${XDG_CONFIG_HOME}/java -Dawt.useSystemAAFontSettings=lcd -Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel"
