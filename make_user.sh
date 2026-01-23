sudo adduser --disabled-password --gecos "" shawnghu
sudo adduser shawnghu sudo
echo 'shawnghu ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/shawnghu
if [ "$(du -sb /home/shawnghu | cut -f1)" -lt 1000000 ]; then
        rm -rf /home/shawnghu
else
    echo "Error: /home/shawnghu contains 1MB or more of data" >&2
    exit 1
fi

sudo ln -sf /workspace /home/shawnghu
sudo -u shawnghu mkdir /home/shawnghu/.ssh
sudo cp ~/.ssh/authorized_keys /home/shawnghu/.ssh/authorized_keys
sudo chmod 600 /home/shawnghu/.ssh/authorized_keys
sudo chown shawnghu /home/shawnghu/.ssh/authorized_keys
sudo chgrp shawnghu /home/shawnghu/.ssh/authorized_keys



