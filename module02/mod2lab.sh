#!/bin/bash
#ContainerizedVirus script
#Made by Juan Soberanes
#updated 8/30 with new changes
#sudo check
if ! [ $(id -u) = 0 ]; then echo "Please run this script as sudo or root"; exit 1 ; fi

apt update
apt install vinagre linux-headers-gcp virtualbox apt-transport-https ca-certificates curl wget software-properties-common -y

#---RDP-----
useramount=2
username="baccc"
password="baccc"
LOG="/tmp/rdp_build.log"

apt install xfce4 -y
apt install xrdp -y
apt install -y build-essential gdb python3 remmina firefox python3-pip docker.io containerd zip unzip openjdk-11-jre icoutils &>> ${LOG} 

echo "Creating Users..."
counter=1
secondcounter=$useramount
while  [ $counter -le $useramount ]
do
        useradd -s /bin/bash -m ${username}${counter}
        usermod -aG ${username}${counter} ${username}${counter}
        echo ${username}${counter}:${password}${secondcounter} | chpasswd
        ((counter++))
        ((secondcounter--))
        echo "User ${username}${counter}:${password}${secondcounter} created!" &>> ${LOG}
done

#enable RDP
sed -i '7i\echo xfce4-session >~/.xsession\' /etc/xrdp/startwm.sh
service xrdp restart
#Make the primary account sudo to install the container
usermod -aG sudo baccc2
#Change the default rdp port number Change 3389 to 3391
sed -i 's/3389/3391/1' /etc/xrdp/xrdp.ini
#rdp blue screen issue
sed -i '14 a unset DBUS_SESSION_BUS_ADDRESS' /etc/xrdp/startwm.sh
sed -i '15 a unset XDG_RUNTIME_DIR' /etc/xrdp/startwm.sh
sed -i '16 a . $HOME/.profile' /etc/xrdp/startwm.sh
#Load up Docker and the container
mkdir /home/baccc2/container/
#Download vm from bucket #This here is not transffering the file to the folder. It is a log of wget
wget https://storage.googleapis.com/malware-container/winxp_1.ova
#This should fix it
mv winxp_1.ova /home/baccc2/container/
