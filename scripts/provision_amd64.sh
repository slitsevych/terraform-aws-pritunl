#!/bin/bash -xe
exec > >(tee /var/log/pritunl-install-data.log|logger -t user-data -s 2>/dev/console) 2>&1

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin:/root/bin
echo "Pritunl Installing"

sudo yum -y update
# RHEL and Oracle Linux EPEL
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm oracle-epel-release-el8
sudo yum -y install oracle-epel-release-el8
sudo yum-config-manager --enable ol8_developer_EPEL
# SSM Agent
sudo rpm -i https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm

sudo tee /etc/yum.repos.d/mongodb-org-6.0.repo << EOF
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF

tee /etc/yum.repos.d/pritunl.repo << EOF
[pritunl]
name=Pritunl Repository
baseurl=https://repo.pritunl.com/stable/yum/oraclelinux/8/
gpgcheck=1
enabled=1
EOF

systemctl disable firewalld
systemctl stop firewalld

cd /tmp
cat > mongodb_cgroup_memory.te <<EOF
module mongodb_cgroup_memory 1.0;

require {
    type cgroup_t;
    type mongod_t;
    class dir search;
    class file { getattr open read };
}

#============= mongod_t ==============
allow mongod_t cgroup_t:dir search;
allow mongod_t cgroup_t:file { getattr open read };
EOF
checkmodule -M -m -o mongodb_cgroup_memory.mod mongodb_cgroup_memory.te
semodule_package -o mongodb_cgroup_memory.pp -m mongodb_cgroup_memory.mod
sudo semodule -i mongodb_cgroup_memory.pp

cat > mongodb_proc_net.te <<EOF
module mongodb_proc_net 1.0;

require {
    type proc_net_t;
    type mongod_t;
    class file { open read };
}

#============= mongod_t ==============
allow mongod_t proc_net_t:file { open read };
EOF

checkmodule -M -m -o mongodb_proc_net.mod mongodb_proc_net.te
semodule_package -o mongodb_proc_net.pp -m mongodb_proc_net.mod
sudo semodule -i mongodb_proc_net.pp

sudo yum install -y mongodb-org
sudo systemctl enable mongod --now

# Import signing key from keyserver
gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 7568D9BB55FF9E5287D586017AE645C0CF8E292A
gpg --armor --export 7568D9BB55FF9E5287D586017AE645C0CF8E292A > key.tmp; sudo rpm --import key.tmp; rm -f key.tmp
# Alternative import from download if keyserver offline
sudo rpm --import https://raw.githubusercontent.com/pritunl/pgp/master/pritunl_repo_pub.asc
# Install updated openvpn package from pritunl
sudo yum --allowerasing install pritunl-openvpn
sudo yum -y install pritunl wireguard-tools
sudo systemctl daemon-reload
sudo systemctl start pritunl
sudo systemctl enable pritunl

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

yum install -y chrony
echo -e 'server time1.google.com iburst\nserver time2.google.com iburst\nserver time3.google.com iburst\nserver time4.google.com iburst' >> /etc/chrony.conf
systemctl enable chronyd
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
