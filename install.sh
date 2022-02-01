#! /bin/bash
# https://www.shellhacks.com/yes-no-bash-script-prompt-confirmation/
# If firewalld problems add this to sources.list and reinstall: deb http://deb.debian.org/debian buster-backports main
# NOTE: Remove the above when done.

# Hazelcast
iptablever=$(/usr/sbin/iptables --version)
if [[ ! "$iptablever" == "iptables v1.8.5 (nf_tables)" ]]
then
  echo firewalld and iptables version 1.8.5 or higher is required to run this script.
  echo please install from deb http://deb.debian.org/debian buster-backports main
  echo using apt-get upgrade iptables/buster-backports
  exit 1
fi

HERE=$(pwd)
apt-get update
apt -y install wget openjdk-11-jdk maven

mkdir /media/common 2> /dev/null
mount -t cifs //10.4.222.20/common /media/common -o username=fakeuser,noexec,password=FakePassword1! 2> /dev/null

cd /opt/ || return

cp -r /media/common/hazelcast-4.2.1 ./ 2> /dev/null
ln -s /opt/hazelcast-4.2.1 hazelcast

cd "$HERE" || return
cp hazelcast.service /etc/systemd/system/
cp hazelcast.sh /bin/
systemctl daemon-reload
systemctl enable hazelcast.service
service hazelcast start

firewall-cmd --permanent --direct --add-rule ipv4 filter IN_public_allow 1 -d 224.2.2.3 -j ACCEPT 2> /dev/null
firewall-cmd --permanent --add-port=5701-5801/tcp --zone=public 2> /dev/null
firewall-cmd --permanent --add-port=54327/udp --zone=public 2> /dev/null
firewall-cmd --reload 2> /dev/null


# Jet

cd /opt || return
cp -r /media/common/hazelcast-jet-4.5-slim ./ 2> /dev/null
mv hazelcast-jet-4.5-slim hazelcast-jet-4.5
ln -s /opt/hazelcast-jet-4.5 hazelcast-jet
cd hazelcast-jet/lib || return
wget https://github.com/hazelcast/hazelcast-jet/releases/download/v4.5/hazelcast-jet-python-4.5-jar-with-dependencies.jar
cd ../bin || return
chmod +x ./jet*
cd "$HERE" || return
cp jet.service /etc/systemd/system
cp jet.sh /bin/
systemctl daemon-reload
systemctl enable jet.service
service jet start

firewall-cmd --permanent --add-port=5802-5901/tcp --zone=public 2> /dev/null
firewall-cmd --reload