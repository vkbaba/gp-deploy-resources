#!/bin/bash

# VM memory size (GB)
MEMORY_SIZE=2

report_result() {
    local item=$1
    local expected=$2
    local actual=$3

    if [ "$actual" = "$expected" ]; then
        echo "PASSED: The $item is correctly set to '$expected'."
    else
        echo "ERROR: The $item is '$actual', but we expected it to be '$expected'."
    fi
}

check_selinux_status() {
    actual_status=$(sestatus | grep "SELinux status:" | awk '{print $3}')
    expected_status="disabled"
    report_result "SELinux status" "$expected_status" "$actual_status"
}

# Function to check if a service has the expected status and print a message
check_service_status() {
    service=$1
    expected_status=$2
    actual_status=$(systemctl is-enabled $service 2>/dev/null)

    if [ "$expected_status" = "disabled" ] && [[ "$actual_status" = "masked"  || -z "$actual_status" ]] ; then
        report_result "$service" "$expected_status" "disabled"
    else
        report_result "$service" "$expected_status" "$actual_status"
    fi
}


# Function to check if at least one NTP server is configured
check_ntp_servers() {
    # Extract the lines for remote NTP servers
    server_lines=$(ntpq -pn | grep -P '^[ *+.-]\d')

    # Count the number of servers
    server_count=$(echo "$server_lines" | wc -l)

    if (( server_count >= 1 )); then
        echo "PASSED: NTP is properly configured with $server_count server(s). Server details:"
        echo "$server_lines"
    else
        echo "ERROR: No NTP servers are configured."
        exit 1
    fi
}


check_device_mount_and_fstab() {
    device="/dev/sdb"
    expected_mountpoint="/gpdata"
    fstab_entry="$device $expected_mountpoint/ xfs rw,nodev,noatime,inode64 0 0"

    actual_mountpoint=$(lsblk $device -no MOUNTPOINT)
    report_result "$device mount point" "$expected_mountpoint" "$actual_mountpoint"

    actual_fstab_entry=$(grep -Fx "$fstab_entry" /etc/fstab || echo "")
    report_result "fstab entry for $device" "$fstab_entry" "$actual_fstab_entry"
}

check_directory_owner_and_group() {
    directory_pattern=$1
    expected_owner=$2
    expected_group=$3

    # Create an array with the directory paths that match the pattern
    directories=( $directory_pattern )

    # If the array is empty, there are no matching directories
    if [ ${#directories[@]} -eq 0 ]; then
        echo "ERROR: No directories match the pattern $directory_pattern."
        return
    fi

    # Check each directory that matches the pattern
    for directory in "${directories[@]}"; do
        if [ ! -d "$directory" ]; then
            report_result "Existence of $directory" "exists" "does not exist"
            continue
        fi 

        actual_owner=$(stat -c %U $directory 2>/dev/null)
        report_result "Owner of $directory" "$expected_owner" "$actual_owner"

        actual_group=$(stat -c %G $directory 2>/dev/null)
        report_result "Group of $directory" "$expected_group" "$actual_group"
    done
}

check_file_owner_and_group() {
    file=$1
    expected_owner=$2
    expected_group=$3

    if [ ! -f "$file" ]; then
        report_result "Existence of $file" "exists" "does not exist"
        return
    fi 

    actual_owner=$(stat -c %U $file 2>/dev/null)
    report_result "Owner of $file" "$expected_owner" "$actual_owner"

    actual_group=$(stat -c %G $file 2>/dev/null)
    report_result "Group of $file" "$expected_group" "$actual_group"
}

check_file_content() {
    file=$1
    expected_content=$2

    if ! grep -q "$expected_content" "$file"; then
        echo "ERROR: $file does not contain '$expected_content'."
    else
        echo "PASSED: $file contains '$expected_content'."
    fi
}


check_kernel_params() {
    param=$1
    if grep -q "$param" /proc/cmdline; then
        actual_param="Present"
    else
        actual_param="Not Present"
    fi
    report_result "Presence of parameter $param in /proc/cmdline" "Present" "$actual_param"
}



check_ulimit_values() {
    option=$1
    expected_value=$2
    actual_value=$(ulimit -$option)
    report_result "ulimit -$option" "$expected_value" "$actual_value"
}




check_installed_packages() {
    packages=("apr" "apr-util" "dstat" "greenplum-db-6" "krb5-devel" "libcgroup-tools"
              "libevent" "libyaml" "net-tools" "ntp" "perl" "rsync" "sos" "tree" "wget" 
              "which" "zip")

    installed_packages=($(rpm -qa))

    for package in "${packages[@]}"; do
        if printf '%s\n' "${installed_packages[@]}" | grep -q "$package"; then
            report_result "$package installation" "installed" "installed"
        else
            report_result "$package installation" "installed" "not installed"
        fi
    done
}


check_cgroup_directories() {
    cgroup_mount_point=$(grep -w 'cgroup' /proc/mounts | head -n1 | awk '{print $2}')
    expected_owner="gpadmin"
    expected_group="gpadmin"
    directories=("cpu/gpdb" "cpuacct/gpdb" "cpuset/gpdb" "memory/gpdb")
    for dir in "${directories[@]}"; do
        path="$cgroup_mount_point/$dir"

        if [ ! -e "$path" ]; then
            report_result "Existence of $path" "Exists" "Not Exists"
            continue
        fi 

        actual_owner=$(stat -c %U "$path" 2>/dev/null || echo "Not Exists")
        actual_group=$(stat -c %G "$path" 2>/dev/null || echo "Not Exists")

        report_result "Owner of $path" "$expected_owner" "$actual_owner"
        report_result "Group of $path" "$expected_group" "$actual_group"
    done
}


check_sys_param() {
    ram_in_gb=$1

    RAM_IN_BYTES=$(($ram_in_gb * 1024 * 1024 * 1024))

    expected_min_free_kbytes=$(($RAM_IN_BYTES * 3 / 100 / 1024))
    expected_overcommit_memory=2
    expected_overcommit_ratio=95
    expected_ip_local_port_range="10000	65535"
    expected_shmall=$(($RAM_IN_BYTES / 2 / 4096))
    expected_shmmax=$(($RAM_IN_BYTES / 2))

    if [ $ram_in_gb -le 64 ]; then
        expected_dirty_background_ratio=3
        expected_dirty_ratio=10
    else
        expected_dirty_background_ratio=0
        expected_dirty_ratio=0
        expected_dirty_background_bytes=1610612736
        expected_dirty_bytes=4294967296
    fi

    param_check() {
        param=$1
        expected_value=$2
        actual_value=$(cat /proc/sys/$param)

        report_result "Value of $param" "$expected_value" "$actual_value"
    }

    param_check "vm/min_free_kbytes" "$expected_min_free_kbytes"
    param_check "vm/overcommit_memory" "$expected_overcommit_memory"
    param_check "vm/overcommit_ratio" "$expected_overcommit_ratio"
    param_check "net/ipv4/ip_local_port_range" "$expected_ip_local_port_range"
    param_check "kernel/shmall" "$expected_shmall"
    param_check "kernel/shmmax" "$expected_shmmax"
    param_check "vm/dirty_background_ratio" "$expected_dirty_background_ratio"
    param_check "vm/dirty_ratio" "$expected_dirty_ratio"
    if [ $ram_in_gb -gt 64 ]; then
        param_check "vm/dirty_background_bytes" "$expected_dirty_background_bytes"
        param_check "vm/dirty_bytes" "$expected_dirty_bytes"
    fi
}


ssh_passwordless_test() {
    user=$1
    hostname=$2

    # Attempt SSH login, output will be directed to /dev/null
    ssh -o BatchMode=yes -o ConnectTimeout=5 -i /home/$user/.ssh/id_rsa $user@$hostname echo 'SSH login successful!' >/dev/null 2>&1

    # Check the exit status of the SSH command
    if [ $? -eq 0 ]; then
        echo "PASSED: Passwordless SSH login for $user on $hostname is enabled."
    else
        echo "ERROR: Passwordless SSH login for $user on $hostname is not enabled."
    fi
}


check_readahead_value() {
    device="/dev/sdb"
    expected_value=$1
    actual_value=$(blockdev --getra $device)

    report_result "The readahead value for $device" "$expected_value" "$actual_value"
}

check_rx_jumbo() {
    expected_output=$1
    actual_output=$(/sbin/ethtool -g ens192 | grep -A3 "Current hardware settings:" | grep "RX Jumbo" | awk '{print $3}')

    report_result "The output of the command 'ethtool -g ens192'" "$expected_output" "$actual_output"
}

check_mtu_size() {
    network_device=$1
    expected_mtu_size=$2
    actual_mtu_size=$(ip link show $network_device | grep -oP 'mtu \K[^\s]+')

    report_result "MTU size for $network_device" "$expected_mtu_size" "$actual_mtu_size"
}

check_sudoers_entry() {
    expected_entry=$1

    # Use the visudo command with the -c (check) option to check the sudoers file
    visudo -cf /etc/sudoers > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR: The sudoers file is not valid."
        return
    fi

    # Check if the expected entry is in the sudoers file
    if ! grep -qxF "$expected_entry" /etc/sudoers; then
        echo "ERROR: The expected entry \"$expected_entry\" is not in the sudoers file."
    else
        echo "PASSED: The expected entry \"$expected_entry\" is in the sudoers file."
    fi
}

check_selinux_status
check_service_status firewalld disabled
check_service_status tuned disabled
check_service_status chronyd disabled
check_service_status cgconfig.service enabled
check_service_status ntpd enabled
check_ntp_servers
check_device_mount_and_fstab
check_directory_owner_and_group "/gpdata/master" "gpadmin" "gpadmin"
# Comment out the following line if you are not using standby master
# check_directory_owner "/gpdata/mirror" "gpadmin" "gpadmin"
# check_directory_owner "/gpdata/primary" "gpadmin" "gpadmin"
check_directory_owner_and_group "/gpdata/primary" "gpadmin" "gpadmin"
check_kernel_params "transparent_hugepage=never"
check_kernel_params "elevator=deadline"
check_ulimit_values "n" 524288
check_ulimit_values "u" 131072
check_cgroup_directories
check_sys_param $MEMORY_SIZE
ssh_passwordless_test gpadmin localhost
check_readahead_value 16384
check_file_content "/etc/rc.d/rc.local"  "/sbin/blockdev"
check_rx_jumbo 4096
check_file_content "/etc/rc.d/rc.local"  "/sbin/ethtool"
check_mtu_size ens192 9000
check_file_content "/etc/rc.d/rc.local"  "/sbin/ip link"

check_file_owner_and_group "/home/gpadmin/.bashrc" "gpadmin" "gpadmin"
check_file_content "/home/gpadmin/.bashrc" "source /usr/local/greenplum-db/greenplum_path.sh"

# This test only checks the ownership of the top-level directory
check_directory_owner_and_group "/usr/local/greenplum*" "gpadmin" "gpadmin"
# Without this setting `gpssh -f /home/gpadmin/hosts-all "sudo systemctl enable gpdb.service"` shows an authentication error
check_sudoers_entry "gpadmin ALL=(ALL) NOPASSWD: ALL"

# It may take a few minutes for the packages to be installed (~3 minutes)
check_installed_packages
# Output hosts info 
echo -e "\nPlease make sure theses name resolution settings are correct:"
echo "Contents of /etc/hosts:"
cat /etc/hosts
echo -e "\nContents of /home/gpadmin/hosts-all:"
cat /home/gpadmin/hosts-all
echo -e "\nContents of /home/gpadmin/hosts-segments:"
cat /home/gpadmin/hosts-segments
