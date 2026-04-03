# mkdir /workspace
# git clone user config
sudo adduser --disabled-password --gecos "" shawnghu
sudo adduser shawnghu sudo

rm -rf /home/shawnghu
sudo ln -sf /workspace /home/shawnghu

sudo chown -R shawnghu:shawnghu /workspace /home/shawnghu/ .
sudo -u shawnghu mkdir /home/shawnghu/.ssh
if id ubuntu &>/dev/null; then
    sudo cp /home/ubuntu/.ssh/authorized_keys /home/shawnghu/.ssh/authorized_keys
else
    sudo cp ~/.ssh/authorized_keys /home/shawnghu/.ssh/authorized_keys
fi
sudo chmod 600 /home/shawnghu/.ssh/authorized_keys
sudo chown shawnghu:shawnghu /home/shawnghu/.ssh/authorized_keys

curl -LO https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info
sudo tic -xe alacritty,alacritty-direct alacritty.info
sudo sed -i 's/^#*StrictModes.*/StrictModes no/' /etc/ssh/sshd_config
sudo service ssh reload
