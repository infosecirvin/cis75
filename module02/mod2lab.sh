#!/bin/bash
#ContainerizedVirus script
#Made by Juan Soberanes
#sudo check
if ! [ $(id -u) = 0 ]; then echo "Please run this script as sudo or root"; exit 1 ; fi

apt update
apt install vinagre linux-headers-gcp virtualbox apt-transport-https ca-certificates curl software-properties-common -y

#-------Docker-------
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt update
apt-cache policy docker-ce > docker-ce.log
apt install docker-ce -y
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

#Download required files
cat > /home/baccc2/container/Installwindowsxp.sh <<EOF
#####This is all done inside of the container####
#Update and Upgrade the Ubuntu System and Repositories
apt update 
apt install virtualbox -y 
apt install virtualbox-dkms -y
apt install linux-headers-gcp -y
apt install linux-headers-generic -y 
cd /home/baccc2/container/
#Import VM 
VBoxManage import winxp_1.ova
#Set Password
VBoxManage modifyvm winxp_1 --vrdeproperty VNCPassword=secret
#Start Windows XP
VBoxHeadless -v on -startvm winxp_1
EOF

cat > /home/baccc2/container/Dockerfile <<EOF
FROM ubuntu:bionic
WORKDIR /home/baccc2/container/
EXPOSE 3389
COPY winxp_1.ova .
COPY Installwindowsxp.sh .
RUN chmod +x Installwindowsxp.sh
EOF

cd /home/baccc2/container/
systemctl unmask docker
systemctl start docker
docker pull ubuntu:bionic
docker stop winxp_1
docker rm winxp_1
docker build --tag winxp_1 .
docker run --rm -it --privileged=true -p 3389:3389 --name winxp_1 winxp_1:latest /bin/sh -c "./Installwindowsxp.sh"
