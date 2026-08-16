#!/bin/bash
echo "Installing Java..."
yum install java -y
echo "Adding the Minecraft user/groups permissions..."
groupadd minecraft -r -U ec2-user
useradd mcsvc -M -r -s /usr/sbin/nologin -g minecraft
mkdir /opt/minecraft
chown mcsvc:minecraft /opt/minecraft/
chmod 775 /opt/minecraft
mv ec2setup-mcsvc.sh /
chmod 775 /ec2setup-mcsvc.sh
su mcsvc -s /bin/bash /ec2setup-mcsvc.sh
echo "Installing Minecraft auto-start service..."
mv minecraft.service /usr/lib/systemd/system/
chown root:root /usr/lib/systemd/system/minecraft.service
systemctl daemon-reload
systemctl enable minecraft
echo "Cleaning up..."
rm -f ec2setup.sh /ec2setup-mcsvc.sh
echo "Rebooting system..."
reboot
