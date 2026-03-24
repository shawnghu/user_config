# mkdir /workspace
# git clone user config
sudo adduser --disabled-password --gecos "" shawnghu
sudo adduser shawnghu sudo

sudo ln -sf /workspace /home/shawnghu

sudo chown -R shawnghu /workspace
sudo chown -R shawnghu /home/shawnghu/
sudo chgrp -R shawnghu /workspace
sudo chgrp -R shawnghu /home/shawnghu/
sudo -u shawnghu mkdir /home/shawnghu/.ssh
sudo cp ~/.ssh/authorized_keys /home/shawnghu/.ssh/authorized_keys
sudo chmod 600 /home/shawnghu/.ssh/authorized_keys
sudo chown shawnghu /home/shawnghu/.ssh/authorized_keys
sudo chgrp shawnghu /home/shawnghu/.ssh/authorized_keys

curl -LO https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info
sudo tic -xe alacritty,alacritty-direct alacritty.info
sudo sed -i 's/^#*StrictModes.*/StrictModes no/' /etc/ssh/sshd_config
sudo service ssh reload
