#!/bin/bash
sudo su
yum install -y nfs-utils
systemctl enable nfs --now
echo "192.168.56.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
systemctl daemon-reload
systemctl restart remote-fs.target
systemctl enable remote-fs.target
shutdown -r now

