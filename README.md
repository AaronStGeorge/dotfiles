# dotfiles

## `tmux.conf`
Minimal tmux configuration.

### Install
Create an alias to dotfiles in home directory
```sh
$ ln -s path/to/dotfiles/tmux.conf $HOME/.tmux.conf
```

## `bashrc_common`
`bashrc_common` contains the configuration and aliases I would like on any computer. 
Machine specific configuration should be in a regular `.bashrc` file which isn't stored in git.

### Install
Create an alias to dotfiles in home directory
```sh
$ ln -s path/to/dotfiles/.bashrc_common $HOME/.bashrc_common
```
Append the following to any existing `.bashrc` file to source this one
```bash
# source common bashrc from https://github.com/AaronStGeorge/dotfiles
if [ -f $HOME/.bashrc_common ]; then
  source $HOME/.bashrc_common
fi
```
