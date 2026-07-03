./make_user.sh
apt update

apt install -y ripgrep less sudo tmux
curl -LO https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info
tic -xe alacritty,alacritty-direct alacritty.info
sed -i 's/^#*StrictModes.*/StrictModes no/' /etc/ssh/sshd_config
service ssh reload

