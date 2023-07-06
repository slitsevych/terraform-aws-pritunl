#!/bin/bash -xe
exec > >(tee /var/log/pritunl-install-data.log|logger -t user-data -s 2>/dev/console) 2>&1

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin:/root/bin
echo "Pritunl Installing"

sudo yum -y update
sudo yum -y install oracle-epel-release-el8
sudo yum-config-manager --enable ol8_developer_EPEL

yum groupinstall 'Development Tools'
yum install -y openvpn wget
yum install golang
yum -y install net-tools psmisc git bridge-utils
yum install -y libffi libffi-devel
yum install python2 python2-devel python2-pip

echo "* hard nofile 64000" >> /etc/security/limits.conf
echo "* soft nofile 64000" >> /etc/security/limits.conf
echo "root hard nofile 64000" >> /etc/security/limits.conf
echo "root soft nofile 64000" >> /etc/security/limits.conf

sudo tee /etc/yum.repos.d/mongodb-org-6.0.repo << EOF
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/6.0/aarch64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF

sudo tee /etc/yum.repos.d/mongodb-database-tools-6.0.repo << EOF
[mongodb-database-tools-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/6.0/arm64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF

yum install -y mongodb-database-tools mongodb-org

export VERSION=1.32.3571.58

tee -a ~/.bashrc << EOF
export GOPATH=\$HOME/go
export PATH=/usr/local/go/bin:\$PATH
EOF
source ~/.bashrc

go env -w GO111MODULE=off

mkdir pritunl && cd pritunl
go get -u github.com/pritunl/pritunl-dns
go get -u github.com/pritunl/pritunl-web
sudo ln -s ~/go/bin/pritunl-dns /usr/bin/pritunl-dns
sudo ln -s ~/go/bin/pritunl-web /usr/bin/pritunl-web

wget https://github.com/pritunl/pritunl/archive/refs/tags/$VERSION.tar.gz
cd pritunl-$VERSION






yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
rpm -i https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm


cat <<EOF >/etc/sysconfig/iptables
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
EOF

echo -e 'server time1.google.com iburst\nserver time2.google.com iburst\nserver time3.google.com iburst\nserver time4.google.com iburst' >> /etc/chrony.conf

systemctl enable mongod pritunl chronyd
systemctl disable dnf-makecache.timer

cat <<EOF > /etc/logrotate.d/pritunl
/var/log/mongodb/*.log {
  daily
  missingok
  rotate 60
  compress
  delaycompress
  copytruncate
  notifempty
}
EOF

reboot
