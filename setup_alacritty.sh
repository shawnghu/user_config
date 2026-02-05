SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

sudo apt install alacritty

# Build and install tabbed
cd "$SCRIPT_DIR/tabbed" && sudo make clean install

# Install wrapper script and set as default terminal
sudo cp "$SCRIPT_DIR/tabbed-alacritty.sh" /usr/local/bin/tabbed-alacritty
sudo chmod +x /usr/local/bin/tabbed-alacritty
gsettings set org.gnome.desktop.default-applications.terminal exec 'tabbed-alacritty'
gsettings set org.gnome.desktop.default-applications.terminal exec-arg ''
