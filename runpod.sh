./make_user.sh
sudo apt update
sudo apt install -y ripgrep less
curl -LO https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info
sudo tic -xe alacritty,alacritty-direct alacritty.info
sudo sed -i 's/^#*StrictModes.*/StrictModes no/' /etc/ssh/sshd_config
sudo service ssh reload

