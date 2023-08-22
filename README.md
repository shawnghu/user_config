# user_config
holds conf files for bash, vim, tmux

### Vim
`sudo apt install vim`

- copy the .vimrc here into homedir
clone Vundle:

`git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim`

- start a session of vim and then run :PluginInstall

### Tmux
`sudo apt install tmux`

- copy the .tmux.conf from here into homedir
- install tmux plugin manager: 
`git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`

- inside tmux, install plugins with Ctrl-b + I (capital I)

### Bash
- copy the .bashrc and .bash_profile from here into homedir


# Misc Ubuntu setup

### Disable Mouse Acceleration 
`sudo apt install gnome-tweaks`
Navigate to the new "Tweaks" application and then change the mouse settings to "Flat"

### Chrome
Most extensions should be handled by sync automatically by Chrome.
Install the Morpheon Dark thme; just google for it.

### Install OpenConnect
`sudo apt-get install network-manager-openconnect openconnect network-manager-openconnect-gnome`
connect with `sudo openconnect yourvpn.example.com`

### Git SSH keys
Surprisingly, you just have to generate a new key and then put the public half of it in Github.
Generate a new key with `ssh-keygen -t ed25519 -C "shawn-g-hu@example.com"`

### Elide password check / login to machines with ssh key
On the machine for which you want to log in, ensure that ssh is configured to accept public key authentication:
(I think this is true by default, but you can add `PubkeyAuthentication yes` and `AddKeysToAgent yes` to ~/.ssh/config.)

Place your public key as a line in ~/.ssh/authorized_keys.

### Setup SSH server on your own machine
`sudo apt-get install openssh-server openssh-client`

### Autosync
Do the inverse of the above to allow your remote machine to login to your current computer by SSH key.

To programmatically send my (dynamic) IP to my desktop (which has a static IP, or which in VPN can be resolved by hostname),
I setup sync_ip.sh to run in my crontab every minute.
`cp sync_ip.sh ~/cron_jobs/sync_ip.sh`
`crontab -e`
and add the entry:
`* * * * * ~/cron_jobs/sync_ip.sh`

Then, we can use the autosync.sh script to sync files automatically; example usage: `./autosync.sh ~/sync_dir hostname`

Note that automated use of the ssh keys for scp may fail silently if the ssh keys are protected by a password.
See https://superuser.com/questions/264820/bash-using-scp-in-cron-job-fails-but-runs-succesfully-when-run-from-command-li.
You can use `ssh-keygen -p` to remove the password.

