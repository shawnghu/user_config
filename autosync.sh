# usage: ./autosync.sh sync_dir ip-file ssh-keyname
while inotifywait -r -e modify,create,delete,move $1; do
    rsync -avz -e "ssh -i $3" $1/ $(cat $2):$1
done
