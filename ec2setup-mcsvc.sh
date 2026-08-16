#!/bin/bash
cd /opt/minecraft/
umask 002
echo "Downloading Minecraft Server 26.2..."
wget https://piston-data.mojang.com/v1/objects/823e2250d24b3ddac457a60c92a6a941943fcd6a/server.jar
echo "Starting Minecraft Server..."
java -Xmx1536M -Xms1536M -jar server.jar nogui
echo "Accepting the EULA..."
echo "eula=true" > eula.txt
echo "Creating FIFO for server management..."
mkfifo serverinput