#!/bin/bash -xe
exec > >(tee /var/log/pritunl-install-data.log|logger -t user-data -s 2>/dev/console) 2>&1

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin:/root/bin
echo "Pritunl Installing"

export VERSION=1.32.3571.58

sudo yum -y update
# RHEL and Oracle Linux EPEL
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm oracle-epel-release-el8
sudo yum -y install oracle-epel-release-el8
sudo yum-config-manager --enable ol8_developer_EPEL
# SSM Agent
sudo rpm -i https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm

# MongoDB
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

sudo yum install -y mongodb-database-tools mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod

# Install dependencies
sudo yum groupinstall 'Development Tools'
sudo yum -y install openssl-devel bzip2-devel libffi libffi-devel sqlite-devel xz-devel \
      zlib-devel gcc git openvpn openssl net-tools iptables psmisc ca-certificates \
      selinux-policy selinux-policy-devel wget nano tar policycoreutils-python-utils \
      bridge-utils

# Install python
cd ~
wget https://www.python.org/ftp/python/3.9.17/Python-3.9.17.tar.xz
tar xf Python-3.9.17.tar.xz
cd ./Python-3.9.17
mkdir /usr/lib/pritunl
./configure --prefix=/usr --libdir=/usr/lib --enable-optimizations --enable-ipv6 --enable-loadable-sqlite-extensions --disable-shared --with-lto --with-platlibdir=lib
make DESTDIR="/usr/lib/pritunl" install
/usr/lib/pritunl/usr/bin/python3 -m ensurepip --upgrade
/usr/lib/pritunl/usr/bin/python3 -m pip install --upgrade pip

# Install GO
wget https://go.dev/dl/go1.20.5.linux-arm64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xf go1.20.5.linux-arm64.tar.gz
rm -f go1.20.5.linux-arm64.tar.gz

tee -a ~/.bashrc << EOF
export GOPATH=\$HOME/go
export GO111MODULE=off
export PATH=/usr/local/go/bin:\$PATH
EOF
source ~/.bashrc
go env -w GO111MODULE=off

# Build Pritunl from source
sudo systemctl stop pritunl || true
sudo rm -rf /usr/lib/pritunl

sudo mkdir -p /usr/lib/pritunl
sudo mkdir -p /var/lib/pritunl
sudo virtualenv-3 /usr/lib/pritunl

GOPROXY=direct go install github.com/pritunl/pritunl-web@latest
GOPROXY=direct go install github.com/pritunl/pritunl-dns@latest
sudo rm /usr/bin/pritunl-dns
sudo rm /usr/bin/pritunl-web
sudo cp -f ~/go/bin/pritunl-dns /usr/bin/pritunl-dns
sudo cp -f ~/go/bin/pritunl-web /usr/bin/pritunl-web

go get -v -u github.com/pritunl/pritunl-dns
go get -v -u github.com/pritunl/pritunl-web
sudo cp -f ~/go/bin/pritunl-dns /usr/bin/pritunl-dns
sudo cp -f ~/go/bin/pritunl-web /usr/bin/pritunl-web

wget https://github.com/pritunl/pritunl/archive/refs/tags/$VERSION.tar.gz
tar xf $VERSION.tar.gz
rm $VERSION.tar.gz
cd ./pritunl-$VERSION
/usr/lib/pritunl/bin/python setup.py build
sudo /usr/lib/pritunl/usr/bin/pip3 install --require-hashes -r requirements.txt
sudo /usr/lib/pritunl/usr/bin/python3 setup.py install
sudo ln -sf /usr/lib/pritunl/usr/bin/pritunl /usr/bin/pritunl

# Configure Selinux
cd selinux8
ln -s /usr/share/selinux/devel/Makefile
make
sudo make load
sudo cp pritunl.pp /usr/share/selinux/packages/pritunl.pp
sudo cp pritunl_dns.pp /usr/share/selinux/packages/pritunl_dns.pp
sudo cp pritunl_web.pp /usr/share/selinux/packages/pritunl_web.pp

sudo semodule -i /usr/share/selinux/packages/pritunl.pp /usr/share/selinux/packages/pritunl_dns.pp /usr/share/selinux/packages/pritunl_web.pp
sudo restorecon -v -R /tmp/pritunl* || true
sudo restorecon -v -R /run/pritunl* || true
sudo restorecon -v /etc/systemd/system/pritunl.service || true
sudo restorecon -v /usr/lib/systemd/system/pritunl.service || true
sudo restorecon -v /etc/systemd/system/pritunl-web.service || true
sudo restorecon -v /usr/lib/systemd/system/pritunl-web.service || true
sudo restorecon -v /usr/lib/pritunl/bin/pritunl || true
sudo restorecon -v /usr/lib/pritunl/bin/python || true
sudo restorecon -v /usr/lib/pritunl/bin/python3 || true
sudo restorecon -v /usr/lib/pritunl/bin/python3.6 || true
sudo restorecon -v /usr/lib/pritunl/bin/python3.9 || true
sudo restorecon -v /usr/lib/pritunl/usr/bin/pritunl || true
sudo restorecon -v /usr/lib/pritunl/usr/bin/python || true
sudo restorecon -v /usr/lib/pritunl/usr/bin/python3 || true
sudo restorecon -v /usr/lib/pritunl/usr/bin/python3.6 || true
sudo restorecon -v /usr/lib/pritunl/usr/bin/python3.9 || true
sudo restorecon -v /usr/bin/pritunl-web || true
sudo restorecon -v /usr/bin/pritunl-dns || true
sudo restorecon -v -R /var/lib/pritunl || true
sudo restorecon -v /var/log/pritunl* || true

sudo groupadd -r pritunl-web || true
sudo useradd -r -g pritunl-web -s /sbin/nologin -c 'Pritunl web server' pritunl-web || true

cd ../../
sudo rm -rf ./pritunl-$VERSION

sudo systemctl daemon-reload
sudo systemctl start pritunl
sudo systemctl enable pritunl

######################

echo "* hard nofile 64000" >> /etc/security/limits.conf
echo "* soft nofile 64000" >> /etc/security/limits.conf
echo "root hard nofile 64000" >> /etc/security/limits.conf
echo "root soft nofile 64000" >> /etc/security/limits.conf

cat <<EOF >/etc/sysconfig/iptables
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
EOF

echo -e 'server time1.google.com iburst\nserver time2.google.com iburst\nserver time3.google.com iburst\nserver time4.google.com iburst' >> /etc/chrony.conf
systemctl restart chronyd
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
