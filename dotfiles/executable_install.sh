#/bin/bash
# Meant to be run from within the ~/dotfiles folder
# assumes presence of git, flathub, flatpak and brew

declare -a fonts=("Iosevka.tar.xz" "IosevkaTerm.tar.xz")

for font in "${fonts[@]}"; do
  if [[ ! -f $font ]]; then
    curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font
  fi
  tar -xvf $font -C ~/.local/share/fonts &
done

# Install wezterm
flatpak install flathub org.wezfurlong.wezterm &

if [[ -e Brewfile ]]; then
  brew bundle install &
fi

if [[ -e ../.config/nvim/ ]]; then
  # move neovim config out of the way
  mv ~/.config/nvim{,.bak}

  # Move neovim stuff out of the way
  mv ~/.local/share/nvim{,.bak}
  mv ~/.local/state/nvim{,.bak}
  mv ~/.cache/nvim{,.bak}
  # clone
  git clone https://github.com/LazyVim/starter ~/.config/nvim &
  # fetch lazyvim packages and quit
  nvim --headless -c q!
fi

# Changes the state of .coonfig/nvim as well as other dotfiles, incl. wezterm
# config.
chezmoi init --apply brettlyons
