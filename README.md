# gp-resource-hub

VMware Greenplum 6 をvSphere 上にインストールする際のリソース集です。

## 動作確認済みバージョン
- vSphere 8.0U1 
- vSAN 8.0U1
- CentOS7
- greenplum-db-6.24.3-rhel7-x86_64
- Mirrorless deployment

## gp_install.sh

VMware Greenplum をvSphere 上のCentOS7 にインストールする際に使います。

### 使い方

スクリプト前半部の変数を環境に合わせて変更して実行します。スクリプトの各処理はドキュメントの節番号を記載していますので、必要に応じて参照してください。

https://docs.vmware.com/en/VMware-Greenplum/6/greenplum-database/vsphere-deploying-byo-template-mirrorless.html

変更する変数は下記の通りです。

- NTP サーバーのアドレス
    
    NTP_SERVER_ADDRESS="10.198.104.250"
    
- 仮想マシンのメモリサイズ(GB)
    
    MEMORY_SIZE=2
    
- セグメントの数。変更する場合はセグメントのIP アドレスを追加したうえで#15.2 のhosts ファイル編集処理も変更してください。
    
    SEGMENT_COUNT=2
    
- ネットワークインターフェース名
    
    NW_INTERFACE_NAME="ens192"
    
- gpadmin のパスワード
    
    GPADMIN_PASSWORD="$YOUR_PASSWORD"  

- セグメント1のIPアドレス
    
    SDW1_IP_ADDR="10.198.104.2"
    
- セグメント2のIPアドレス
    
    SDW2_IP_ADDR="10.198.104.3"
    
- Tanzu Network のUAA API Token で、取得方法は下記参照

    https://tanzu.vmware.com/developer/guides/tanzu-network-gs/
    
    TANZU_NW_UAA_API_TOKEN="YOUR_TANZU_NW_UAA_API_TOKEN"
    
- Greenplum DB の RPM パッケージのダウンロードURL
    
    DOWNLOAD_URL="https://network.tanzu.vmware.com/api/v2/products/vmware-greenplum/
    releases/1290496/product_files/1483329/download"

<!-- 画像 -->
![image](images/gp_package.png)

```
sudo bash gp_install.sh
```
### 結果の例

```

```

## gp_vm_prerequisite_checker.sh

VMware Greenplum をCentOS7 上にインストールするための前提条件が満たされているかをチェックします。gp_install.sh を使わず手動でインストールした場合の最終チェックのお供として使ってください。

### 使い方

変更する変数は下記の通りです。

- 仮想マシンのメモリサイズ(GB)
    
    MEMORY_SIZE=2

```
sudo bash gp_vm_prerequisite_checker.sh
```

### 結果の例

```
[root@greenplum-db-base-vm ~]# sudo bash ./gp_vm_prerequisite_checker.sh 
PASSED: The SELinux status is correctly set to 'disabled'.
PASSED: The firewalld is correctly set to 'disabled'.
PASSED: The tuned is correctly set to 'disabled'.
PASSED: The chronyd is correctly set to 'disabled'.
PASSED: The cgconfig.service is correctly set to 'enabled'.
PASSED: The ntpd is correctly set to 'enabled'.
PASSED: NTP is properly configured with 2 server(s). Server details:
*10.128.152.81   10.188.26.21     3 u  140  256  375    0.161   61.695  30.746
 10.198.104.15   .STEP.          16 u   89  256    0    0.172  -138.15   0.000
PASSED: The /dev/sdb mount point is correctly set to '/gpdata'.
PASSED: The fstab entry for /dev/sdb is correctly set to '/dev/sdb /gpdata/ xfs rw,nodev,noatime,inode64 0 0'.
PASSED: The Owner of /gpdata/master is correctly set to 'gpadmin'.
PASSED: The Group of /gpdata/master is correctly set to 'gpadmin'.
PASSED: The Owner of /gpdata/primary is correctly set to 'gpadmin'.
PASSED: The Group of /gpdata/primary is correctly set to 'gpadmin'.
PASSED: The Presence of parameter transparent_hugepage=never in /proc/cmdline is correctly set to 'Present'.
PASSED: The Presence of parameter elevator=deadline in /proc/cmdline is correctly set to 'Present'.
PASSED: The ulimit -n is correctly set to '524288'.
PASSED: The ulimit -u is correctly set to '131072'.
PASSED: The Owner of /sys/fs/cgroup/cpu/gpdb is correctly set to 'gpadmin'.
PASSED: The Group of /sys/fs/cgroup/cpu/gpdb is correctly set to 'gpadmin'.
PASSED: The Owner of /sys/fs/cgroup/cpuacct/gpdb is correctly set to 'gpadmin'.
PASSED: The Group of /sys/fs/cgroup/cpuacct/gpdb is correctly set to 'gpadmin'.
PASSED: The Owner of /sys/fs/cgroup/cpuset/gpdb is correctly set to 'gpadmin'.
PASSED: The Group of /sys/fs/cgroup/cpuset/gpdb is correctly set to 'gpadmin'.
PASSED: The Owner of /sys/fs/cgroup/memory/gpdb is correctly set to 'gpadmin'.
PASSED: The Group of /sys/fs/cgroup/memory/gpdb is correctly set to 'gpadmin'.
PASSED: The Value of vm/min_free_kbytes is correctly set to '943718'.
PASSED: The Value of vm/overcommit_memory is correctly set to '2'.
PASSED: The Value of vm/overcommit_ratio is correctly set to '95'.
PASSED: The Value of net/ipv4/ip_local_port_range is correctly set to '10000    65535'.
PASSED: The Value of kernel/shmall is correctly set to '3932160'.
PASSED: The Value of kernel/shmmax is correctly set to '16106127360'.
PASSED: The Value of vm/dirty_background_ratio is correctly set to '3'.
PASSED: The Value of vm/dirty_ratio is correctly set to '10'.
PASSED: Passwordless SSH login for gpadmin on localhost is enabled.
PASSED: The The readahead value for /dev/sdb is correctly set to '16384'.
PASSED: /etc/rc.d/rc.local contains '/sbin/blockdev'.
PASSED: The The output of the command 'ethtool -g ens192' is correctly set to '4096'.
PASSED: /etc/rc.d/rc.local contains '/sbin/ethtool'.
PASSED: The MTU size for ens192 is correctly set to '9000'.
PASSED: /etc/rc.d/rc.local contains '/sbin/ip link'.
PASSED: The Owner of /home/gpadmin/.bashrc is correctly set to 'gpadmin'.
PASSED: The Group of /home/gpadmin/.bashrc is correctly set to 'gpadmin'.
PASSED: /home/gpadmin/.bashrc contains 'source /usr/local/greenplum-db/greenplum_path.sh'.
PASSED: The Owner of /usr/local/greenplum-db is correctly set to 'gpadmin'.
PASSED: The Group of /usr/local/greenplum-db is correctly set to 'gpadmin'.
PASSED: The Owner of /usr/local/greenplum-db-6.24.3 is correctly set to 'gpadmin'.
PASSED: The Group of /usr/local/greenplum-db-6.24.3 is correctly set to 'gpadmin'.
PASSED: The expected entry "gpadmin ALL=(ALL) NOPASSWD: ALL" is in the sudoers file.
PASSED: The apr installation is correctly set to 'installed'.
PASSED: The apr-util installation is correctly set to 'installed'.
PASSED: The dstat installation is correctly set to 'installed'.
PASSED: The greenplum-db-6 installation is correctly set to 'installed'.
PASSED: The krb5-devel installation is correctly set to 'installed'.
PASSED: The libcgroup-tools installation is correctly set to 'installed'.
PASSED: The libevent installation is correctly set to 'installed'.
PASSED: The libyaml installation is correctly set to 'installed'.
PASSED: The net-tools installation is correctly set to 'installed'.
PASSED: The ntp installation is correctly set to 'installed'.
PASSED: The perl installation is correctly set to 'installed'.
PASSED: The rsync installation is correctly set to 'installed'.
PASSED: The sos installation is correctly set to 'installed'.
PASSED: The tree installation is correctly set to 'installed'.
PASSED: The wget installation is correctly set to 'installed'.
PASSED: The which installation is correctly set to 'installed'.
PASSED: The zip installation is correctly set to 'installed'.

Please make sure theses name resolution settings are correct:
Contents of /etc/hosts:
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

10.198.104.15   mdw
10.198.104.16   sdw1
10.198.104.11   sdw2

Contents of /home/gpadmin/hosts-all:
mdw
sdw1
sdw2

Contents of /home/gpadmin/hosts-segments:
sdw1
sdw2
```


## main.tf

マスターとセグメントに対して静的IP アドレスを割り当てる際に使うTerraform のサンプルコードです。ドキュメント中のサンプルスクリプトでは、指定したネットワークセグメントに応じて自動的にIP アドレスがアサインされる仕様になっています。また、vApp の機能を使って一部パラメータをvSphere から渡しているのですが(guestinfo. で始まるパラメータ)、このサンプルではその部分は削除することで、vApp の設定の必要なく、Terraform とクローンのベースとなる仮想マシンの設定だけで完結するようにしています。

### 使い方

スクリプト前半部の変数を環境に合わせて変更して実行します。変更する変数は下記の通りです。


- vSphere の管理者ユーザーのアカウント
```
variable "vsphere_user" {
  default = "administrator@vsphere.local"
}
```

- vSphere の管理者ユーザーのパスワード
```
variable "vsphere_password" {
  default = "$VC_PASSWORD"
}
```

- vCenter のアドレス (FQDN またはIP アドレス)
```
variable "vsphere_server" {
  description = "Enter the address of the vCenter, either as an FQDN (preferred) or an IP address"
  default = "$VC_ADDRESS"
}
```

- デプロイ先のデータセンター名
```
variable "vsphere_datacenter" {
  default = "$DC_NAME"
}
```

- デプロイ先のクラスタ名
```
variable "vsphere_compute_cluster" {
  default = "$CLUSTER_NAME"
}
```

- デプロイ先のデータストア名
```
variable "vsphere_datastore" {
  default = "$DATASTORE_NAME"
}
```

- デプロイする仮想マシンに割り当てるストレージポリシー
```
variable "vsphere_storage_policy" {
  description = "Enter the custom name for your storage policy defined during Setting Up VMware vSphere Storage/Encryption"
  default = "$POLICY_NAME"
}
```

- クローンのベースとなる仮想マシンの名前
```
variable "base_vm_name" {
  description = "Base VM with vmware-tools and Greenplum installed"
  default = "greenplum-db-base-vm"
}
```

- デプロイ先のリソースプール名
```
variable "resource_pool_name" {
  description= "The name of a dedicated resource pool for Greenplum VMs which will be created by Terraform"
  default = "greenplum"
}
```

- デプロイする仮想マシンやリソースプール名のプレフィックス
```
variable "prefix" {
  description= "A customizable prefix name for the resource pool, Greenplum VMs, and affinity rules which will be created by Terraform"
  default = "gpv"
}
```

- デプロイする仮想マシンが接続される外部ネットワークのポートグループ名
```
variable "gp_virtual_external_network" {
  default = "$PORTGROUP_NAME"
}
```

- デプロイする仮想マシンが接続される内部ネットワークのポートグループ名
```
variable "gp_virtual_internal_network" {
  default = "$PORTGROUP_NAME"
}
```

- デプロイする仮想マシンが接続されるETL/バックアップネットワークのポートグループ名
```
variable "gp_virtual_etl_bar_network" {
  default = "$PORTGROUP_NAME"
}
```

- デプロイする仮想マシンが接続される外部ネットワークのゲートウェイアドレス
```
variable "gp_virtual_external_gateway" {
  description = "Gateway for the gp-virtual-external network, e.g. 10.0.0.1"
  default = "$GW_ADDRESS"
}
```

- デプロイする仮想マシンのDNS サーバーのアドレス
```
variable "dns_servers" {
  type = list(string)
  description = "The DNS servers for the routable network, e.g. 8.8.8.8"
  default = ["$DNS_ADDRESS"]
}
```

- セグメントの数
```
variable "segment_count" {
  default = 2
}
```

- 各ネットワークのサブネットマスク
```
variable "gp_external_ipv4_netmask" {
  description = "Netmask bitcount, e.g. 24"
  default = 24
}

variable "gp_internal_ipv4_netmask" {
  description = "Netmask bitcount, e.g. 24"
  default = 24
}

variable "gp_etl_ipv4_netmask" {
  description = "Netmask bitcount, e.g. 24"
  default = 24
}
```

- マスターのIP アドレス
```
variable "gp_mdw_external_ip" {
  type = string
  default = "10.10.10.10"
}

variable "gp_mdw_internal_ip" {
  type = string
  default = "10.10.10.11"
}

variable "gp_mdw_etl_ip" {
  type = string
  default = "10.10.10.12"
}
```

- セグメント1のIP アドレス
```
variable "gp_sdw1_internal_ip" {
  type = string
  default = "10.10.10.13"
}

variable "gp_sdw1_etl_ip" {
  type = string
  default = "10.10.10.14"
}
```

セグメント2のIP アドレス
```
variable "gp_sdw2_internal_ip" {
  type = string
  default = "10.10.10.15"
}

variable "gp_sdw2_etl_ip" {
  type = string
  default = "10.10.10.16"
}
```
ベースVM のhosts ファイルの設定と整合性をとる必要があるため、Terraform 側でIP アドレスを変更した場合は、gp_install.sh のIP アドレスを変更して再インストールするか、ベースVM の設定を忘れずに変更すること。

## demo-psql.md

動作確認用のデモシナリオです。

