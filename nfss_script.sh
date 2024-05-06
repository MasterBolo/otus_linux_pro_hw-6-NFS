#!/bin/bash
sudo su
yum install -y nfs-utils
firewall-cmd --add-service="nfs3"
firewall-cmd --add-service="rpc-bind"
firewall-cmd --add-service="mountd"
firewall-cmd --runtime-to-permanent
firewall-cmd --reload
systemctl enable nfs --now
mkdir -p /srv/share/uplоad
chown -R nfsnobody:nfsnobody /srv/share
chmod 0777 /srv/share/uplоad
cat << EOF > /etc/exports 
/srv/share 192.168.56.11/32(rw,sync,root_squash)
EOF
exportfs -r
cd /srv/share/uplоad
touch check_file
shutdown -r now
