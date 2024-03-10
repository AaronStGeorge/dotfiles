# dotfiles

## `tmux.conf`
Minimal tmux configuration.

### Install
Create a symbolic link in your `$HOME` directory
```sh
$ ln -s tmux.conf $HOME/.tmux.conf
```

## `bashrc_common`
`bashrc_common` contains the configuration and aliases I would like on any computer. 
Machine specific configuration should be in a regular `.bashrc` file not stored in git.

### Install
Create a symbolic link in your `$HOME` directory
```sh
$ ln -s $PWD/bashrc_common $HOME/.bashrc_common
```
To load `bashrc_common`, append the following to your regular, machine specific, `.bashrc` file
```bash
# source common bashrc from https://github.com/AaronStGeorge/dotfiles
if [[ -f $HOME/.bashrc_common ]]; then
  source $HOME/.bashrc_common
fi
```
