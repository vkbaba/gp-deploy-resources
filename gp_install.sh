#!/bin/bash

# This script follows the document below
# https://docs.vmware.com/en/VMware-Greenplum/6/greenplum-database/vsphere-deploying-byo-template-mirrorless.html

# NTP server address
NTP_SERVER_ADDRESS="10.198.104.250"
# VM memory size (GB)
MEMORY_SIZE=2
# Number of segment VM
SEGMENT_COUNT=2
# Network interface name
NW_INTERFACE_NAME="ens192"
# Password of gpadmin
GPADMIN_PASSWORD="$YOUR_PASSWORD"  
# Assume that the number of segment VM is 2, so please modify these values and #15.2 if you need.
# IP address of segment 1 (sdw1)
SDW1_IP_ADDR="10.198.104.2"
# IP address of segment 2 (sdw2)
SDW2_IP_ADDR="10.198.104.3"
# See https://tanzu.vmware.com/developer/guides/tanzu-network-gs/
TANZU_NW_UAA_API_TOKEN="YOUR_TANZU_NW_UAA_API_TOKEN"
# greenplum-db-6.24.3-rhel7-x86_64.rpm
DOWNLOAD_URL="https://network.tanzu.vmware.com/api/v2/products/vmware-greenplum/releases/1290496/product_files/1483329/download"


# Function to prevent duplicate entries when script executed more than once
entry_exists() {
    local file="$1"
    local pattern="$2"

    grep -q "$pattern" $file
}

#3.1 Disable SELinux by editing the /etc/selinux/config file. Change the value of the SELINUX parameter in the configuration file as follows:
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config

#3.2 Check that the System Security Services Daemon (SSSD) is installed:
if yum list sssd | grep -i "Installed Packages"; then
    if ! entry_exists "/etc/sssd/sssd.conf" "selinux_provider=none"; then
        echo "selinux_provider=none" >> /etc/sssd/sssd.conf
    fi
fi

#3.3 Disable the Firewall service:
systemctl stop firewalld
systemctl disable firewalld
systemctl mask --now firewalld

#3.4 Disable the Tuned daemon:
systemctl stop tuned
systemctl disable tuned
systemctl mask --now tuned

#3.5 Disable Chrony:
systemctl stop chronyd
systemctl disable chronyd
systemctl mask --now chronyd

#4 Back up the boot files:
cp /etc/default/grub /etc/default/grub-backup
cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg-backup

#5.1 Disable Transparent Huge Page (THP):
grubby --update-kernel=ALL --args="transparent_hugepage=never"

#5.2 Add the parameter elevator=deadline:
grubby --update-kernel=ALL --args="elevator=deadline"


#6 Install and enable the ntp daemon:
yum install -y ntp
systemctl enable ntpd

#7.1 Not needed

#7.2 Add an entry for each server to /etc/ntp.conf:
if [ -z "$NTP_SERVER_ADDRESS" ]; then
    echo "Error: NTP_SERVER_ADDRESS is not provided."
elif ! entry_exists "/etc/ntp.conf" "server $NTP_SERVER_ADDRESS"; then
    echo "server $NTP_SERVER_ADDRESS" >> /etc/ntp.conf
fi

#7.3 Add the master and standby to the list of servers after datacenter NTP servers in /etc/ntp.conf:
if ! entry_exists "/etc/ntp.conf" "server mdw"; then
    echo "server mdw" >> /etc/ntp.conf
fi
#8.1 Create the configuration file /etc/sysctl.d/10-gpdb.conf and paste in the following kernel optimization parameters:
cat <<EOF > /etc/sysctl.d/10-gpdb.conf
kernel.msgmax = 65536
kernel.msgmnb = 65536
kernel.msgmni = 2048
kernel.sem = 500 2048000 200 40960
kernel.shmmni = 1024
kernel.sysrq = 1
net.core.netdev_max_backlog = 2000
net.core.rmem_max = 4194304
net.core.wmem_max = 4194304
net.core.rmem_default = 4194304
net.core.wmem_default = 4194304
net.ipv4.tcp_rmem = 4096 4224000 16777216
net.ipv4.tcp_wmem = 4096 4224000 16777216
net.core.optmem_max = 4194304
net.core.somaxconn = 10000
net.ipv4.ip_forward = 0
net.ipv4.tcp_congestion_control = cubic
net.ipv4.tcp_tw_recycle = 0
net.core.default_qdisc = fq_codel
net.ipv4.tcp_mtu_probing = 0
net.ipv4.conf.all.arp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.ip_local_port_range = 10000 65535
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_syncookies = 1
vm.overcommit_memory = 2
vm.overcommit_ratio = 95
vm.swappiness = 10
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
vm.zone_reclaim_mode = 0
EOF

#8.2.1 Determine the value of the RAM in bytes by creating the variable $RAM_IN_BYTES. For example, for a 30GB RAM virtual machine, run the following:
RAM_IN_BYTES=$(($MEMORY_SIZE * 1024 * 1024 * 1024))

#8.2.2 Define the following parameters that depend on the variable $RAM_IN_BYTES that you just created, and append them to the file /etc/sysctl.d/10-gpdb.conf by running the following commands:
FILE_PATH="/etc/sysctl.d/10-gpdb.conf"
if ! entry_exists "$FILE_PATH" "vm.min_free_kbytes"; then
    echo "vm.min_free_kbytes = $(($RAM_IN_BYTES * 3 / 100 / 1024))" >> $FILE_PATH
fi
if ! entry_exists "$FILE_PATH" "kernel.shmall"; then
    echo "kernel.shmall = $(($RAM_IN_BYTES / 2 / 4096))" >> $FILE_PATH
fi
if ! entry_exists "$FILE_PATH" "kernel.shmmax"; then
    echo "kernel.shmmax = $(($RAM_IN_BYTES / 2))" >> $FILE_PATH
fi


#8.2.3 If your virtual machine RAM is less than or equal to 64 GB, run the following commands
if [ $RAM_IN_BYTES -le 68719476736 ]; then
    if ! entry_exists "$FILE_PATH" "vm.dirty_background_ratio"; then
        echo "vm.dirty_background_ratio = 3" >> $FILE_PATH
    fi
    if ! entry_exists "$FILE_PATH" "vm.dirty_ratio"; then
        echo "vm.dirty_ratio = 10" >> $FILE_PATH
    fi
else
#8.2.4
    if ! entry_exists "$FILE_PATH" "vm.dirty_background_ratio"; then
        echo "vm.dirty_background_ratio = 0" >> $FILE_PATH
    fi
    if ! entry_exists "$FILE_PATH" "vm.dirty_ratio"; then
        echo "vm.dirty_ratio = 0" >> $FILE_PATH
    fi
    if ! entry_exists "$FILE_PATH" "vm.dirty_background_bytes"; then
        echo "vm.dirty_background_bytes = 1610612736 # 1.5GB" >> $FILE_PATH
    fi
    if ! entry_exists "$FILE_PATH" "vm.dirty_bytes"; then
        echo "vm.dirty_bytes = 4294967296 # 4GB" >> $FILE_PATH
    fi
fi

#9.1 Edit /etc/ssh/sshd_config file and update following options:
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^ChallengeResponseAuthentication .*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^UsePAM .*/UsePAM yes/' /etc/ssh/sshd_config
if ! entry_exists "/etc/ssh/sshd_config" "MaxStartups 100"; then
    echo "MaxStartups 100" >> "/etc/ssh/sshd_config"
fi
if ! entry_exists "/etc/ssh/sshd_config" "MaxSessions 100"; then
    echo "MaxSessions 100" >> "/etc/ssh/sshd_config"
fi

#9.2 Create ssh keys to allow passwordless login with root by running the following commands:
if [ ! -f /root/.ssh/id_rsa ]; then
    ssh-keygen -f /root/.ssh/id_rsa -N ""
fi
chmod 700 /root/.ssh
cd /root/.ssh/
cat id_rsa.pub > authorized_keys
chmod 600 authorized_keys
ssh-keyscan -t rsa localhost > known_hosts
key=$(cat known_hosts)
for i in mdw $(seq -f "sdw%g" 1 $SEGMENT_COUNT); do
    echo ${key} | sed -e "s/localhost/${i}/" >> known_hosts
done
chmod 644 known_hosts

#10.1 Ensure that the directory exists before creating the file:
mkdir -p /etc/security/limits.d

#10.2 Append the following contents to the end of /etc/security/limits.d/20-nproc.conf:
if ! entry_exists "/etc/security/limits.d/20-nproc.conf" "* soft nofile 524288"; then
    echo "* soft nofile 524288" >> /etc/security/limits.d/20-nproc.conf
fi
if ! entry_exists "/etc/security/limits.d/20-nproc.conf" "* hard nofile 524288"; then
    echo "* hard nofile 524288" >> /etc/security/limits.d/20-nproc.conf
fi
if ! entry_exists "/etc/security/limits.d/20-nproc.conf" "* soft nproc 131072"; then
    echo "* soft nproc 131072" >> /etc/security/limits.d/20-nproc.conf
fi
if ! entry_exists "/etc/security/limits.d/20-nproc.conf" "* hard nproc 131072"; then
    echo "* hard nproc 131072" >> /etc/security/limits.d/20-nproc.conf
fi

#11 Create the base mount point /gpdata for the virtual machine data drive:
mkdir -p /gpdata
if ! entry_exists "/etc/fstab" "/dev/sdb /gpdata/ xfs rw,nodev,noatime,inode64 0 0"; then
    mkfs.xfs /dev/sdb
    mount -t xfs -o rw,noatime,nodev,inode64 /dev/sdb /gpdata/
    df -kh
    echo "/dev/sdb /gpdata/ xfs rw,nodev,noatime,inode64 0 0" >> /etc/fstab
fi
mkdir -p /gpdata/primary
mkdir -p /gpdata/master

#12.1 Update the file content:
if ! entry_exists "/etc/rc.d/rc.local" "/sbin/blockdev --setra 16384 /dev/sdb"; then
    echo "/sbin/blockdev --setra 16384 /dev/sdb" >> /etc/rc.d/rc.local
fi
if ! entry_exists "/etc/rc.d/rc.local" "/sbin/ip link set $NW_INTERFACE_NAME mtu 9000"; then
    echo "/sbin/ip link set $NW_INTERFACE_NAME mtu 9000" >> /etc/rc.d/rc.local
fi
if ! entry_exists "/etc/rc.d/rc.local" "/sbin/ethtool --set-ring $NW_INTERFACE_NAME rx-jumbo 4096"; then
    echo "/sbin/ethtool --set-ring $NW_INTERFACE_NAME rx-jumbo 4096" >> /etc/rc.d/rc.local
fi


#12.2 Make the file executable:
chmod +x /etc/rc.d/rc.local

#13.1 Execute the following steps in order to create the user gpadmin in the group gpadmin:
if ! id -u gpadmin &>/dev/null; then
    if ! getent group gpadmin &>/dev/null; then
        groupadd gpadmin
    fi
    useradd -g gpadmin -m gpadmin
    echo "gpadmin:$GPADMIN_PASSWORD" | chpasswd
else
    echo "User gpadmin already exists!"
fi

#13.2 Not needed

#13.3 Create the file /home/gpadmin/.bashrc for gpadmin with the following content:
cat << EOF > /home/gpadmin/.bashrc
### .bashrc

### Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

### User specific aliases and functions

### If Greenplum has been installed, then add Greenplum-specific commands to the path
if [ -f /usr/local/greenplum-db/greenplum_path.sh ]; then
    source /usr/local/greenplum-db/greenplum_path.sh
fi
EOF

#13.4 Change the ownership of /home/gpadmin/.bashrc to gpadmin:gpadmin:
chown gpadmin:gpadmin /home/gpadmin/.bashrc

#13.5 Change the ownership of the /gpdata directory to gpadmin:gpadmin:
chown -R gpadmin:gpadmin /gpdata

#13.6 Create ssh keys for passwordless login as gpadmin user:
su - gpadmin -c "ssh-keygen -t rsa -N '' -f /home/gpadmin/.ssh/id_rsa"
su - gpadmin -c "chmod 700 /home/gpadmin/.ssh; cat /home/gpadmin/.ssh/id_rsa.pub > /home/gpadmin/.ssh/authorized_keys; chmod 600 /home/gpadmin/.ssh/authorized_keys"
su - gpadmin -c "ssh-keyscan -t rsa localhost > /home/gpadmin/.ssh/known_hosts"

su - gpadmin -c "
key=\$(cat /home/gpadmin/.ssh/known_hosts)
for i in mdw \$(seq -f 'sdw%g' 1 $SEGMENT_COUNT); do
    echo \${key} | sed -e 's/localhost/\${i}/' >> /home/gpadmin/.ssh/known_hosts
done
chmod 644 /home/gpadmin/.ssh/known_hosts
"
#14.1 Install the cgroup configuration package:
yum install -y libcgroup-tools

#14.2 Verify that the directory /etc/cgconfig.d exists:
mkdir -p /etc/cgconfig.d

#14.3 Create the cgroups configuration file /etc/cgconfig.d/10-gpdb.conf for Greenplum:
cat << EOF > /etc/cgconfig.d/10-gpdb.conf
group gpdb {
    perm {
        task {
            uid = gpadmin;
            gid = gpadmin;
        }
        admin {
            uid = gpadmin;
            gid = gpadmin;
        }
    }
    cpu {
    }
    cpuacct {
    }
    cpuset {
    }
    memory {
    }
}
EOF

cgconfigparser -l /etc/cgconfig.d/10-gpdb.conf
systemctl enable cgconfig.service

#15.1 Not needed

#15.2 update-etc-host.sh asign segments' IP addresses automaticaly so set static IP addresses.
if ! entry_exists "/etc/hosts" "sdw1" && [ -n "${SDW1_IP_ADDR}" ]; then
    echo "${SDW1_IP_ADDR}   sdw1" >> /etc/hosts
fi

if ! entry_exists "/etc/hosts" "sdw2" && [ -n "${SDW2_IP_ADDR}" ]; then
    echo "${SDW2_IP_ADDR}   sdw2" >> /etc/hosts
fi


#16 Create two files hosts-all and hosts-segments under /home/gpadmin. Replace 32 with your number of primary segment virtual machines as necessary.
if ! entry_exists /home/gpadmin/hosts-all "mdw"; then
    echo mdw > /home/gpadmin/hosts-all
fi

if [ ! -f /home/gpadmin/hosts-segments ]; then
    > /home/gpadmin/hosts-segments
fi

for i in $(seq 1 $SEGMENT_COUNT); do
    if ! entry_exists /home/gpadmin/hosts-all "sdw${i}"; then
        echo "sdw${i}" >> /home/gpadmin/hosts-all
    fi
    if ! entry_exists /home/gpadmin/hosts-segments "sdw${i}"; then
        echo "sdw${i}" >> /home/gpadmin/hosts-segments
    fi
done
chown gpadmin:gpadmin /home/gpadmin/hosts*

# Adding Greenplum Database Service
#1 Create the directory gpv directory in /etc/:
mkdir -p /etc/gpv
#2 Create the service log directory:
mkdir -p /var/log/gpv
chmod a+rwx /var/log/gpv
#3 Create a service file /etc/gpv/gpdb-service and paste in the following contents:
cat << 'EOF' > /etc/gpv/gpdb-service
#!/bin/bash

set -e
echo ==========================================================
echo [the begin timestamp is: $(date)]

if [ -d /gpdata/master/gpseg* ]; then
  POSTMASTER_FILE_PATH=$(ls -d /gpdata/master/gpseg*)
  printf -v PGCTL_OPTION ' -D %s -w -t 120 -o " %s " ' ${POSTMASTER_FILE_PATH} "-E"
elif [ -d /gpdata/primary/gpseg* ]; then
  POSTMASTER_FILE_PATH=$(ls -d /gpdata/primary/gpseg*)
  printf -v PGCTL_OPTION ' -D %s -w -t 120 ' ${POSTMASTER_FILE_PATH}
else
  echo the current cluster might not be initialized by gpinitsystem
  echo we cannot find /gpdata/master/gpseg* or /gpdata/primary/gpseg*
  echo please double check the cluster is initialized
  echo and then restart the gpdb.service again.
  exit 1
fi

echo POSTMASTER_FILE_PATH is ${POSTMASTER_FILE_PATH}
echo PGCTL_OPTION is ${PGCTL_OPTION}

echo about to $1 ...

case "$1" in
  start)
    if [ ! -z "$(ps -ef | grep postgres | grep gpseg)" ]; then
      echo there is an existing postmaster running by somebody else, stop it
      /usr/local/greenplum-db/bin/pg_ctl -w -D ${POSTMASTER_FILE_PATH} --mode=fast stop
    fi

    echo clean-up left-over files if any
    rm -f /tmp/.s.PGSQL.*
    rm -f ${POSTMASTER_FILE_PATH}/postmaster.pid

    echo starting new postmaster ...
    eval /usr/local/greenplum-db/bin/pg_ctl ${PGCTL_OPTION} start
    echo postmaster is started

    echo extracting postmaster pid...
    touch /home/gpadmin/.gpv.postmaster.pid
    POSTMASTER_PID=$(head -1 ${POSTMASTER_FILE_PATH}/postmaster.pid)
    echo ${POSTMASTER_PID} > /home/gpadmin/.gpv.postmaster.pid
    echo $(date) >> /home/gpadmin/.gpv.postmaster.pid
    echo remembered the postmaster pid as ${POSTMASTER_PID}
    ;;
  stop)
    echo stopping postmaster with pid $(cat /home/gpadmin/.gpv.postmaster.pid) ...
    /usr/local/greenplum-db/bin/pg_ctl -w -D ${POSTMASTER_FILE_PATH} --mode=fast stop
    echo postmaster is stopped
    ;;
  *)
    echo "Usage: $0 {start|stop}"
esac

echo [the end timestamp is: $(date)]

exit 0
EOF

#4 Make the file executable:
chmod +x /etc/gpv/gpdb-service

#5 Create a service file /etc/systemd/system/gpdb.service and paste in the following contents:
cat << EOF > /etc/systemd/system/gpdb.service
Description=Greenplum Service

[Service]
Type=forking
User=gpadmin
LimitNOFILE=524288
LimitNPROC=131072
ExecStart=/bin/bash -l -c "/etc/gpv/gpdb-service start 2>&1 | tee -a /var/log/gpv/gpdb-service.log"
ExecStop=/bin/bash -l -c "/etc/gpv/gpdb-service stop 2>&1 | tee -a /var/log/gpv/gpdb-service.log"
TimeoutStartSec=120
Restart=always
PIDFile=/home/gpadmin/.gpv.postmaster.pid
RestartSec=1s

[Install]
WantedBy=multi-user.target
EOF

# Installing the Greenplum Database Software
#1 #2 Install greenplum after install other packages

#3 Install the following yum packages for better supportability:
yum install -y dstat sos tree wget

#1 Download the latest version of the Greenplum Database Server 6 for RHEL 7 from VMware Tanzu Network.
# Use API insted of scp command. See https://network.pivotal.io/docs/api
yum -y install epel-release
yum -y install jq
ACCESS_TOKEN=$(curl -s -X POST https://network.tanzu.vmware.com/api/v2/authentication/access_tokens -d '{"refresh_token": "'"$TANZU_NW_UAA_API_TOKEN"'"}' | jq -r '.access_token') 
ACTUAL_DOWNLOAD_URL=$(curl -s -X GET $DOWNLOAD_URL -H "Authorization: Bearer $ACCESS_TOKEN" | sed 's/&amp;/\&/g' | grep -oP '<a href="\K[^"]+' )
wget -O "gp.rpm" $ACTUAL_DOWNLOAD_URL
#2 Move the downloaded binary in to the virtual machine and install Greenplum:
yum install -y ./gp.rpm

# Other necessary settings
# https://docs.vmware.com/en/VMware-Greenplum/6/greenplum-database/install_guide-install_gpdb.html
chown -R gpadmin:gpadmin /usr/local/greenplum*
chgrp -R gpadmin /usr/local/greenplum*

# Prevent timeout of gpssh systemctl 
if ! entry_exists "/etc/sudoers" "gpadmin ALL=(ALL) NOPASSWD: ALL"; then
    echo "gpadmin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

# Deploying a Greenplum Database Cluster
#2 Create the Greenplum GUC (global user configuration) file gp_guc_config and paste in the following contents:.

MEMORY_MB=$(( MEMORY_SIZE * 1024 ))

cat << EOF > /home/gpadmin/gp_guc_config
### Interconnect Settings
gp_interconnect_queue_depth=16
gp_interconnect_snd_queue_depth=16

# Since you have one segment per VM and less competing workloads per VM,
# you can set the memory limit for resource group higher than the default
gp_resource_group_memory_limit=0.85

# This value should be 5% of the total RAM on the VM
statement_mem=$(( MEMORY_MB * 5 / 100 ))MB

# This value should be set to 25% of the total RAM on the VM
max_statement_mem=$(( MEMORY_MB * 25 / 100 ))MB

# This value should be set to 85% of the total RAM on the VM
gp_vmem_protect_limit=$(( MEMORY_MB * 85 / 100 ))

# Since you have less I/O bandwidth, you can turn this parameter on
gp_workfile_compression=on

# Mirrorless GUCs
wal_level=minimal
max_wal_senders=0
wal_keep_segments=0
max_replication_slots=0
gp_dispatch_keepalives_idle=20
gp_dispatch_keepalives_interval=20
gp_dispatch_keepalives_count=44
EOF

chown gpadmin:gpadmin /home/gpadmin/gp_guc_config

#3 Create the Greenplum configuration script create_gpinitsystem_config.sh and paste in the following contents:
#4 Run the script to generate the configuration file for gpinitsystem. Replace 32 with the number of primary segments as necessary.

# setup the gpinitsystem config
primary_array() {
  num_primary_segments=$1
  array=""
  newline=$'\n'
  # master has db_id 0, primary starts with db_id 1, primaries are always odd
  for i in $( seq 0 $(( num_primary_segments - 1 )) ); do
    content_id=${i}
    db_id=$(( i + 1 ))
    array+="sdw${db_id}~sdw${db_id}~6000~/gpdata/primary/gpseg${content_id}~${db_id}~${content_id}${newline}"
  done
  echo "${array}"
}

create_gpinitsystem_config() {
    num_primary_segments=$1
    echo "Generate gpinitsystem"

    cat <<EOF > /home/gpadmin/gpinitsystem_config
ARRAY_NAME="Greenplum Data Platform"
TRUSTED_SHELL=ssh
CHECK_POINT_SEGMENTS=8
ENCODING=UNICODE
SEG_PREFIX=gpseg
HEAP_CHECKSUM=on
HBA_HOSTNAMES=0
QD_PRIMARY_ARRAY=mdw~mdw~5432~/gpdata/master/gpseg-1~0~-1
declare -a PRIMARY_ARRAY=(
$( primary_array ${num_primary_segments} )
)
EOF

}
num_primary_segments="$SEGMENT_COUNT"
if [ -z "$num_primary_segments" ]; then
    echo "Usage: bash create_gpinitsystem_config.sh <num_primary_segments>"
else
    create_gpinitsystem_config ${num_primary_segments}
fi

chown gpadmin:gpadmin /home/gpadmin/gpinitsystem_config
