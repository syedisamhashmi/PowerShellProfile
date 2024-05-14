echo "Syncing packages"
sudo pacman -Syyu;

sudo pacman -S                \
  core/cronie                 \
  core/man                    \
  core/mkinitcpio             \
  extra/arandr                \
  extra/bat                   \
  extra/bluez                 \
  extra/bluez-utils           \
  extra/neofetch              \
  extra/noto-fonts-emoji      \ # For emojis
  extra/piper                 \ # For mouse button mappings
  extra/pulseaudio            \
  extra/pulsemixer            \
  extra/python-build          \
  extra/python-installer      \
  extra/python-pyusb          \
  extra/python-wheel          \
  extra/ranger                \
  extra/ripgrep               \
  extra/scrot                 \
  extra/slop                  \
  extra/tree                  \
  extra/ttc-iosevka           \
  extra/wget                  \
  extra/wimlib                \
;
