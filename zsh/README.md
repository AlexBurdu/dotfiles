# zsh configuration

* Install oh my zsh from https://ohmyz.sh/

```shell
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

* Ensure you have a Nerd Font installed to aloow icons and glyphs
  rendering. Download nerd fonts from https://www.nerdfonts.com/

* Install powerlevel10k theme. Follow the commands from
  https://github.com/romkatv/powerlevel10k.

```shell
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

* Run the repo's setup from its root and answer yes to Zsh, to
  symlink the configuration files into the home directory.

```shell
./setup.sh
```

* Reload zsh configuration

```shell
exec zsh
```

## Machine-specific shell config

`zshrc` sources every `~/.config/zsh/*.zsh` last, so anything linked
there overrides what is above it.

This repo carries none of those files. Shell config that belongs to one
kind of machine — work aliases, personal PATH entries, anything that
cannot be published — lives in an overlay repo, whose manifest links it
into `~/.config/zsh/`. `~/.config/zsh` is a real directory, not a
symlink into this checkout, which is what makes that possible. See the
Overlays section of the [repo README](../README.md).
