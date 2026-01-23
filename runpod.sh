./make_user.sh
sudo apt install -y ripgrep npm less
curl -LO https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info
sudo tic -xe alacritty,alacritty-direct alacritty.info
sudo sed -i 's/^#*StrictModes.*/StrictModes no/' /etc/ssh/sshd_config
sudo service ssh reload

