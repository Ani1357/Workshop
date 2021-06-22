#Bash script for testing before using ansible(to be deleted)

sudo mkdir /data

sudo bash -c 'echo "/data    *(rw,no_root_squash)"> /etc/exports'

sudo systemctl enable --now nfs-server

sudo exportfs -a
