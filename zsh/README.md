# zsh configuration

* Install oh my zsh from https://ohmyz.sh/

```shell
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

* Ensure you have a Nerd Font installed to aloow icons and glyphs rendering. Download nerd fonts from https://www.nerdfonts.com/

* Install powerlevel10k theme. Follow the commands from https://github.com/romkatv/powerlevel10k.

```shell

```shell
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

* Run the setup bash script to symlink the configuration files to the home directory.

```shell
bash setup.sh
```

* Reload zsh configuration

```shell
exec zsh
```
