#!/bin/bash -xe
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin:/root/bin:/usr/local/go/bin
echo "Pritunl Installing"

sudo yum -y update
# RHEL and Oracle Linux EPEL
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm oracle-epel-release-el8
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

# Install dependencies
sudo yum -y groupinstall 'Development Tools'
sudo yum -y install ipset iptables nano openssl-devel bzip2-devel libffi libffi-devel sqlite-devel xz-devel \
      zlib-devel gcc git openvpn openssl net-tools iptables psmisc ca-certificates \
      selinux-policy selinux-policy-devel selinux-policy-targeted wget nano tar policycoreutils-python-utils \
      bridge-utils wireguard-tools

# Install python
yum -y install python39 python39-devel python39-pip
ln -s /bin/python3.9 /bin/python
ln -s /bin/pip3.9 /bin/pip
python -m ensurepip --upgrade
python -m pip install --upgrade pip

# Install GO
wget https://go.dev/dl/go1.20.5.linux-arm64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xf go1.20.5.linux-arm64.tar.gz
rm -f go1.20.5.linux-arm64.tar.gz

tee -a ~/.bashrc << EOF
export PATH=\$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin:/root/bin:/usr/local/go/bin
export HOME=/root
EOF
tee -a /home/rocky/.bashrc << EOF
export PATH=\$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin:/root/bin:/usr/local/go/bin
EOF

export HOME=/root

GO111MODULE=on GOPROXY=direct go install github.com/pritunl/pritunl-web@latest 
GO111MODULE=on GOPROXY=direct go install github.com/pritunl/pritunl-dns@latest
GO111MODULE=on GOPROXY=direct go install github.com/pritunl/pritunl-link@latest
sudo cp -f ~/go/bin/pritunl-dns /usr/bin/pritunl-dns && cp -f ~/go/bin/pritunl-web /usr/bin/pritunl-web
sudo cp -f ~/go/bin/pritunl-link /usr/bin/pritunl-link

export VERSION=1.32.3571.58

mkdir /usr/lib/pritunl && cd "$_"
wget https://github.com/pritunl/pritunl/archive/refs/tags/$VERSION.tar.gz
tar xf $VERSION.tar.gz && rm -f $VERSION.tar.gz && mv ./pritunl-$VERSION/* . && rm -rf ./pritunl-$VERSION
python setup.py build
sudo pip install --require-hashes -r requirements.txt
sudo python setup.py install
sudo ln -sf /usr/local/bin/pritunl /usr/bin/pritunl

# Configure Selinux
cd selinux8
ln -s /usr/share/selinux/devel/Makefile
make
sudo make load
sudo cp pritunl.pp /usr/share/selinux/packages/pritunl.pp
sudo cp pritunl_dns.pp /usr/share/selinux/packages/pritunl_dns.pp
sudo cp pritunl_web.pp /usr/share/selinux/packages/pritunl_web.pp
sudo semodule -i /usr/share/selinux/packages/pritunl.pp /usr/share/selinux/packages/pritunl_dns.pp /usr/share/selinux/packages/pritunl_web.pp

sudo groupadd -r pritunl-web || true
sudo useradd -r -g pritunl-web -s /sbin/nologin -c 'Pritunl web server' pritunl-web || true

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

cd /tmp
git clone https://github.com/mongodb/mongodb-selinux
cd mongodb-selinux/selinux 
cat > selinux_nfc.patch <<EOF
--- mongodb.te.orig	2023-03-27 15:50:01.215714756 +0200
+++ mongodb.te	2023-03-27 15:50:57.510360567 +0200
@@ -65,6 +65,16 @@
 allow mongod_t var_run_t:dir { open read getattr lock search ioctl add_name remove_name write };
 type_transition mongod_t var_run_t:dir mongod_runtime_t;
 
+require {
+	type var_lib_nfs_t;
+	type autofs_t;
+	type mongod_t;
+	class dir search;
+}
+#============= mongod_t ==============
+allow mongod_t autofs_t:dir search;
+allow mongod_t var_lib_nfs_t:dir search;
+
 # this is required to create mongodb-XXXXX.sock files
 files_rw_generic_tmp_dir(mongod_t)
 fs_manage_tmpfs_sockets(mongod_t)
EOF
git apply selinux_nfc.patch && cd ..
make
sudo make install

sudo systemctl enable --now mongod

sudo systemctl daemon-reload
sudo systemctl enable pritunl --now

reboot
