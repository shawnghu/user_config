sudo adduser shawnghu sudo
sudo -u shawnghu mkdir ~/.ssh
sudo cp ~/.ssh/authorized_keys /home/shawnghu/.ssh/authorized_keys
sudo chmod 755 /home/shawnghu/.ssh/authorized_keys
sudo chown shawnghu /home/shawnghu/.ssh/authorized_keys
sudo chgrp shawnghu /home/shawnghu/.ssh/authorized_keys


