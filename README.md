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
