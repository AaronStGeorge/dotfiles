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
# source common bashrc from https://github.com/AaronStGeorge/dotfiles
if [[ -f $HOME/.dotfiles/bashrc_common ]]; then
  source $HOME/.dotfiles/bashrc_common
fi
```
Add the scripts to your `$PATH` by adding the following to your `.bashrc` file.
```bash
export PATH="$HOME/.dotfiles/scripts:$PATH"
```
