# dotfiles

## `bashrc_common`
Machine specific configuration should be in a regular `.bashrc` file not stored in git.
`bashrc_common` contains configuration and aliases I would like on *any* computer, work or personal.


### Install
Create a symbolic link in your `$HOME` directory to the `dotfiles` directory by running the following *in* the dotfiles directory.
```sh
$ ln -s $PWD $HOME/.dotfiles
```
To load `bashrc_common`, append the following to your regular, machine specific, `.bashrc` file.
```bash
# source common bashrc from https://github.com/AaronStGeorge/dotfiles ==========
if [[ -f $HOME/.dotfiles/bashrc_common ]]; then
    # export WORK_APPROPRIATE_PS1=1
    source $HOME/.dotfiles/bashrc_common
fi
```

## `scripts`
Random one off command line utilities.

### Install
Assuming you've installed `bashrc_common` using the directions above, install scripts by updating the `PATH` environment variable in your `.bashrc`.
```bash
export PATH="$HOME/.dotfiles/scripts:$PATH"
```

### `mkdevcontainer`
Generates a `.devcontainer/<name>/devcontainer.json` in the current directory
from a generic container template under `dockerfiles/` — run it in any folder
under `~/Dev`, then "Reopen in Container" in VS Code.
```sh
$ cd ~/Dev/some/project
$ mkdevcontainer ubuntu2404                     # agent configs mounted
$ mkdevcontainer ubuntu2404 --no-agent-configs  # ...not mounted
```

What the generated container gets:
- The whole host `~/Dev` tree bind-mounted (same path layout in-container),
  opening at the folder you ran the tool in.
- `~/.ssh` (read-only), `~/.gitconfig`, and `~/.config/git` bind-mounted.
- `~/.claude` and `~/.codex` bind-mounted by default (opt out with
  `--no-agent-configs`; trusted single-user machines only).
- A container user matching your host user/UID/GID, `privileged` mode +
  setuid bubblewrap for agent sandboxes, Claude Code + Codex CLIs installed,
  and ROCm GPU devices passed through when present on the host.

Notes:
- On networks with TLS interception (corporate proxies), stage the corporate
  root CA `.crt` files into `dockerfiles/<name>/certs/` before building —
  see the comment in the Dockerfile. They are gitignored.
