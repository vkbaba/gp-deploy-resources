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

- セグメント1のインターナルIPアドレス
    
    SDW1_IP_ADDR="10.198.104.2"
    
- セグメント2のインターナルIPアドレス
    
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

インストールスクリプト完了後、VM をシャットダウンし、Terraform スクリプトを実行します。Greenplum の作成が完了したら、マスターにgpadmin でログインして、下記コマンドを実行してサービスを立ち上げればGreenplum のインストールは完了です。 

```
gpinitsystem -a -I gpinitsystem_config -p gp_guc_config
```

### 結果の例

```
[root@gp-blog-template ~]# sudo bash gp_install.sh
Repodata is over 2 weeks old. Install yum-cron? Or run: yum makecache fast
Removed symlink /etc/systemd/system/multi-user.target.wants/firewalld.service.
Removed symlink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service.
Created symlink from /etc/systemd/system/firewalld.service to /dev/null.
Removed symlink /etc/systemd/system/multi-user.target.wants/tuned.service.
Created symlink from /etc/systemd/system/tuned.service to /dev/null.
Removed symlink /etc/systemd/system/multi-user.target.wants/chronyd.service.
Created symlink from /etc/systemd/system/chronyd.service to /dev/null.
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.xmission.com
 * extras: opencolo.mm.fcix.net
 * updates: mirrors.raystedman.org
base                                                                                                                                                                                            | 3.6 kB  00:00:00     
extras                                                                                                                                                                                          | 2.9 kB  00:00:00     
updates                                                                                                                                                                                         | 2.9 kB  00:00:00     
(1/2): extras/7/x86_64/primary_db                                                                                                                                                               | 250 kB  00:00:00     
(2/2): updates/7/x86_64/primary_db                                                                                                                                                              |  22 MB  00:00:00     
Resolving Dependencies
--> Running transaction check
---> Package ntp.x86_64 0:4.2.6p5-29.el7.centos.2 will be installed
--> Processing Dependency: ntpdate = 4.2.6p5-29.el7.centos.2 for package: ntp-4.2.6p5-29.el7.centos.2.x86_64
--> Processing Dependency: libopts.so.25()(64bit) for package: ntp-4.2.6p5-29.el7.centos.2.x86_64
--> Running transaction check
---> Package autogen-libopts.x86_64 0:5.18-5.el7 will be installed
---> Package ntpdate.x86_64 0:4.2.6p5-29.el7.centos.2 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

=======================================================================================================================================================================================================================
 Package                                                Arch                                          Version                                                        Repository                                   Size
=======================================================================================================================================================================================================================
Installing:
 ntp                                                    x86_64                                        4.2.6p5-29.el7.centos.2                                        base                                        549 k
Installing for dependencies:
 autogen-libopts                                        x86_64                                        5.18-5.el7                                                     base                                         66 k
 ntpdate                                                x86_64                                        4.2.6p5-29.el7.centos.2                                        base                                         87 k

Transaction Summary
=======================================================================================================================================================================================================================
Install  1 Package (+2 Dependent packages)

Total download size: 701 k
Installed size: 1.6 M
Downloading packages:
(1/3): autogen-libopts-5.18-5.el7.x86_64.rpm                                                                                                                                                    |  66 kB  00:00:00     
(2/3): ntpdate-4.2.6p5-29.el7.centos.2.x86_64.rpm                                                                                                                                               |  87 kB  00:00:00     
(3/3): ntp-4.2.6p5-29.el7.centos.2.x86_64.rpm                                                                                                                                                   | 549 kB  00:00:00     
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                  947 kB/s | 701 kB  00:00:00     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : autogen-libopts-5.18-5.el7.x86_64                                                                                                                                                                   1/3 
  Installing : ntpdate-4.2.6p5-29.el7.centos.2.x86_64                                                                                                                                                              2/3 
  Installing : ntp-4.2.6p5-29.el7.centos.2.x86_64                                                                                                                                                                  3/3 
  Verifying  : ntpdate-4.2.6p5-29.el7.centos.2.x86_64                                                                                                                                                              1/3 
  Verifying  : ntp-4.2.6p5-29.el7.centos.2.x86_64                                                                                                                                                                  2/3 
  Verifying  : autogen-libopts-5.18-5.el7.x86_64                                                                                                                                                                   3/3 

Installed:
  ntp.x86_64 0:4.2.6p5-29.el7.centos.2                                                                                                                                                                                 

Dependency Installed:
  autogen-libopts.x86_64 0:5.18-5.el7                                                                     ntpdate.x86_64 0:4.2.6p5-29.el7.centos.2                                                                    

Complete!
Created symlink from /etc/systemd/system/multi-user.target.wants/ntpd.service to /usr/lib/systemd/system/ntpd.service.
Generating public/private rsa key pair.
Created directory '/root/.ssh'.
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:~~~ root@gp-blog-template
The key's randomart image is:
+---[RSA 2048]----+
~~~
+----[SHA256]-----+
# localhost:22 SSH-2.0-OpenSSH_7.4
meta-data=/dev/sdb               isize=512    agcount=4, agsize=1048576 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=4194304, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
Filesystem                           Size  Used Avail Use% Mounted on
devtmpfs                             908M     0  908M   0% /dev
tmpfs                                920M     0  920M   0% /dev/shm
tmpfs                                920M  8.9M  911M   1% /run
tmpfs                                920M     0  920M   0% /sys/fs/cgroup
/dev/mapper/centos_gp--jumpbox-root   14G  2.1G   12G  16% /
/dev/sda1                           1014M  151M  864M  15% /boot
tmpfs                                184M     0  184M   0% /run/user/0
/dev/sdb                              16G   33M   16G   1% /gpdata
Generating public/private rsa key pair.
Created directory '/home/gpadmin/.ssh'.
Your identification has been saved in /home/gpadmin/.ssh/id_rsa.
Your public key has been saved in /home/gpadmin/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:~~~ gpadmin@gp-blog-template
The key's randomart image is:
+---[RSA 2048]----+
~~~
+----[SHA256]-----+
# localhost:22 SSH-2.0-OpenSSH_7.4
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.xmission.com
 * extras: opencolo.mm.fcix.net
 * updates: mirrors.raystedman.org
Resolving Dependencies
--> Running transaction check
---> Package libcgroup-tools.x86_64 0:0.41-21.el7 will be installed
--> Processing Dependency: libcgroup(x86-64) = 0.41-21.el7 for package: libcgroup-tools-0.41-21.el7.x86_64
--> Processing Dependency: libcgroup.so.1(CGROUP_0.42)(64bit) for package: libcgroup-tools-0.41-21.el7.x86_64
--> Processing Dependency: libcgroup.so.1(CGROUP_0.40)(64bit) for package: libcgroup-tools-0.41-21.el7.x86_64
--> Processing Dependency: libcgroup.so.1(CGROUP_0.39)(64bit) for package: libcgroup-tools-0.41-21.el7.x86_64
--> Processing Dependency: libcgroup.so.1(CGROUP_0.38)(64bit) for package: libcgroup-tools-0.41-21.el7.x86_64
--> Processing Dependency: libcgroup.so.1(CGROUP_0.37)(64bit) for package: libcgroup-tools-0.41-21.el7.x86_64
--> Processing Dependency: libcgroup.so.1(CGROUP_0.35)(64bit) for package: libcgroup-tools-0.41-21.el7.x86_64
--> Processing Dependency: libcgroup.so.1(CGROUP_0.34)(64bit) for package: libcgroup-tools-0.41-21.el7.x86_64
--> Processing Dependency: libcgroup.so.1(CGROUP_0.33)(64bit) for package: libcgroup-tools-0.41-21.el7.x86_64
--> Processing Dependency: libcgroup.so.1(CGROUP_0.32.1)(64bit) for package: libcgroup-tools-0.41-21.el7.x86_64
--> Processing Dependency: libcgroup.so.1(CGROUP_0.32)(64bit) for package: libcgroup-tools-0.41-21.el7.x86_64
--> Processing Dependency: libcgroup.so.1()(64bit) for package: libcgroup-tools-0.41-21.el7.x86_64
--> Running transaction check
---> Package libcgroup.x86_64 0:0.41-21.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

=======================================================================================================================================================================================================================
 Package                                                   Arch                                             Version                                               Repository                                      Size
=======================================================================================================================================================================================================================
Installing:
 libcgroup-tools                                           x86_64                                           0.41-21.el7                                           base                                            99 k
Installing for dependencies:
 libcgroup                                                 x86_64                                           0.41-21.el7                                           base                                            66 k

Transaction Summary
=======================================================================================================================================================================================================================
Install  1 Package (+1 Dependent package)

Total download size: 166 k
Installed size: 391 k
Downloading packages:
(1/2): libcgroup-0.41-21.el7.x86_64.rpm                                                                                                                                                         |  66 kB  00:00:00     
(2/2): libcgroup-tools-0.41-21.el7.x86_64.rpm                                                                                                                                                   |  99 kB  00:00:00     
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                  255 kB/s | 166 kB  00:00:00     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : libcgroup-0.41-21.el7.x86_64                                                                                                                                                                        1/2 
  Installing : libcgroup-tools-0.41-21.el7.x86_64                                                                                                                                                                  2/2 
  Verifying  : libcgroup-0.41-21.el7.x86_64                                                                                                                                                                        1/2 
  Verifying  : libcgroup-tools-0.41-21.el7.x86_64                                                                                                                                                                  2/2 

Installed:
  libcgroup-tools.x86_64 0:0.41-21.el7                                                                                                                                                                                 

Dependency Installed:
  libcgroup.x86_64 0:0.41-21.el7                                                                                                                                                                                       

Complete!
Created symlink from /etc/systemd/system/sysinit.target.wants/cgconfig.service to /usr/lib/systemd/system/cgconfig.service.
grep: /home/gpadmin/hosts-all: No such file or directory
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.xmission.com
 * extras: opencolo.mm.fcix.net
 * updates: mirrors.raystedman.org
Package wget-1.14-18.el7_6.1.x86_64 already installed and latest version
Resolving Dependencies
--> Running transaction check
---> Package dstat.noarch 0:0.7.2-12.el7 will be installed
---> Package sos.noarch 0:3.9-5.el7.centos.11 will be installed
--> Processing Dependency: python2-futures for package: sos-3.9-5.el7.centos.11.noarch
--> Processing Dependency: python-six for package: sos-3.9-5.el7.centos.11.noarch
--> Processing Dependency: libxml2-python for package: sos-3.9-5.el7.centos.11.noarch
--> Processing Dependency: bzip2 for package: sos-3.9-5.el7.centos.11.noarch
---> Package tree.x86_64 0:1.6.0-10.el7 will be installed
--> Running transaction check
---> Package bzip2.x86_64 0:1.0.6-13.el7 will be installed
---> Package libxml2-python.x86_64 0:2.9.1-6.el7_9.6 will be installed
--> Processing Dependency: libxml2 = 2.9.1-6.el7_9.6 for package: libxml2-python-2.9.1-6.el7_9.6.x86_64
---> Package python-six.noarch 0:1.9.0-2.el7 will be installed
---> Package python2-futures.noarch 0:3.1.1-5.el7 will be installed
--> Running transaction check
---> Package libxml2.x86_64 0:2.9.1-6.el7.5 will be updated
---> Package libxml2.x86_64 0:2.9.1-6.el7_9.6 will be an update
--> Finished Dependency Resolution

Dependencies Resolved

=======================================================================================================================================================================================================================
 Package                                                Arch                                          Version                                                     Repository                                      Size
=======================================================================================================================================================================================================================
Installing:
 dstat                                                  noarch                                        0.7.2-12.el7                                                base                                           163 k
 sos                                                    noarch                                        3.9-5.el7.centos.11                                         updates                                        549 k
 tree                                                   x86_64                                        1.6.0-10.el7                                                base                                            46 k
Installing for dependencies:
 bzip2                                                  x86_64                                        1.0.6-13.el7                                                base                                            52 k
 libxml2-python                                         x86_64                                        2.9.1-6.el7_9.6                                             updates                                        247 k
 python-six                                             noarch                                        1.9.0-2.el7                                                 base                                            29 k
 python2-futures                                        noarch                                        3.1.1-5.el7                                                 base                                            29 k
Updating for dependencies:
 libxml2                                                x86_64                                        2.9.1-6.el7_9.6                                             updates                                        668 k

Transaction Summary
=======================================================================================================================================================================================================================
Install  3 Packages (+4 Dependent packages)
Upgrade             ( 1 Dependent package)

Total download size: 1.7 M
Downloading packages:
Delta RPMs disabled because /usr/bin/applydeltarpm not installed.
(1/8): bzip2-1.0.6-13.el7.x86_64.rpm                                                                                                                                                            |  52 kB  00:00:00     
(2/8): python-six-1.9.0-2.el7.noarch.rpm                                                                                                                                                        |  29 kB  00:00:00     
(3/8): libxml2-python-2.9.1-6.el7_9.6.x86_64.rpm                                                                                                                                                | 247 kB  00:00:00     
(4/8): python2-futures-3.1.1-5.el7.noarch.rpm                                                                                                                                                   |  29 kB  00:00:00     
(5/8): libxml2-2.9.1-6.el7_9.6.x86_64.rpm                                                                                                                                                       | 668 kB  00:00:00     
(6/8): sos-3.9-5.el7.centos.11.noarch.rpm                                                                                                                                                       | 549 kB  00:00:00     
(7/8): dstat-0.7.2-12.el7.noarch.rpm                                                                                                                                                            | 163 kB  00:00:00     
(8/8): tree-1.6.0-10.el7.x86_64.rpm                                                                                                                                                             |  46 kB  00:00:00     
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                  2.3 MB/s | 1.7 MB  00:00:00     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : python-six-1.9.0-2.el7.noarch                                                                                                                                                                       1/9 
  Installing : python2-futures-3.1.1-5.el7.noarch                                                                                                                                                                  2/9 
  Updating   : libxml2-2.9.1-6.el7_9.6.x86_64                                                                                                                                                                      3/9 
  Installing : libxml2-python-2.9.1-6.el7_9.6.x86_64                                                                                                                                                               4/9 
  Installing : bzip2-1.0.6-13.el7.x86_64                                                                                                                                                                           5/9 
  Installing : sos-3.9-5.el7.centos.11.noarch                                                                                                                                                                      6/9 
  Installing : dstat-0.7.2-12.el7.noarch                                                                                                                                                                           7/9 
  Installing : tree-1.6.0-10.el7.x86_64                                                                                                                                                                            8/9 
  Cleanup    : libxml2-2.9.1-6.el7.5.x86_64                                                                                                                                                                        9/9 
  Verifying  : bzip2-1.0.6-13.el7.x86_64                                                                                                                                                                           1/9 
  Verifying  : libxml2-2.9.1-6.el7_9.6.x86_64                                                                                                                                                                      2/9 
  Verifying  : tree-1.6.0-10.el7.x86_64                                                                                                                                                                            3/9 
  Verifying  : libxml2-python-2.9.1-6.el7_9.6.x86_64                                                                                                                                                               4/9 
  Verifying  : sos-3.9-5.el7.centos.11.noarch                                                                                                                                                                      5/9 
  Verifying  : dstat-0.7.2-12.el7.noarch                                                                                                                                                                           6/9 
  Verifying  : python2-futures-3.1.1-5.el7.noarch                                                                                                                                                                  7/9 
  Verifying  : python-six-1.9.0-2.el7.noarch                                                                                                                                                                       8/9 
  Verifying  : libxml2-2.9.1-6.el7.5.x86_64                                                                                                                                                                        9/9 

Installed:
  dstat.noarch 0:0.7.2-12.el7                                           sos.noarch 0:3.9-5.el7.centos.11                                           tree.x86_64 0:1.6.0-10.el7                                          

Dependency Installed:
  bzip2.x86_64 0:1.0.6-13.el7                    libxml2-python.x86_64 0:2.9.1-6.el7_9.6                    python-six.noarch 0:1.9.0-2.el7                    python2-futures.noarch 0:3.1.1-5.el7                   

Dependency Updated:
  libxml2.x86_64 0:2.9.1-6.el7_9.6                                                                                                                                                                                     

Complete!
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.xmission.com
 * extras: opencolo.mm.fcix.net
 * updates: mirrors.raystedman.org
Resolving Dependencies
--> Running transaction check
---> Package epel-release.noarch 0:7-11 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

=======================================================================================================================================================================================================================
 Package                                                  Arch                                               Version                                          Repository                                          Size
=======================================================================================================================================================================================================================
Installing:
 epel-release                                             noarch                                             7-11                                             extras                                              15 k

Transaction Summary
=======================================================================================================================================================================================================================
Install  1 Package

Total download size: 15 k
Installed size: 24 k
Downloading packages:
epel-release-7-11.noarch.rpm                                                                                                                                                                    |  15 kB  00:00:00     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : epel-release-7-11.noarch                                                                                                                                                                            1/1 
  Verifying  : epel-release-7-11.noarch                                                                                                                                                                            1/1 

Installed:
  epel-release.noarch 0:7-11                                                                                                                                                                                           

Complete!
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
epel/x86_64/metalink                                                                                                                                                                            |  28 kB  00:00:00     
 * base: mirrors.xmission.com
 * epel: mirrors.sonic.net
 * extras: opencolo.mm.fcix.net
 * updates: mirrors.raystedman.org
epel                                                                                                                                                                                            | 4.7 kB  00:00:00     
(1/3): epel/x86_64/group_gz                                                                                                                                                                     |  99 kB  00:00:00     
(2/3): epel/x86_64/updateinfo                                                                                                                                                                   | 1.0 MB  00:00:00     
(3/3): epel/x86_64/primary_db                                                                                                                                                                   | 7.0 MB  00:00:00     
Resolving Dependencies
--> Running transaction check
---> Package jq.x86_64 0:1.6-2.el7 will be installed
--> Processing Dependency: libonig.so.5()(64bit) for package: jq-1.6-2.el7.x86_64
--> Running transaction check
---> Package oniguruma.x86_64 0:6.8.2-2.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

=======================================================================================================================================================================================================================
 Package                                              Arch                                              Version                                                  Repository                                       Size
=======================================================================================================================================================================================================================
Installing:
 jq                                                   x86_64                                            1.6-2.el7                                                epel                                            167 k
Installing for dependencies:
 oniguruma                                            x86_64                                            6.8.2-2.el7                                              epel                                            181 k

Transaction Summary
=======================================================================================================================================================================================================================
Install  1 Package (+1 Dependent package)

Total download size: 348 k
Installed size: 1.0 M
Downloading packages:
warning: /var/cache/yum/x86_64/7/epel/packages/jq-1.6-2.el7.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID 352c64e5: NOKEY                                                       ]  0.0 B/s |    0 B  --:--:-- ETA 
Public key for jq-1.6-2.el7.x86_64.rpm is not installed
(1/2): jq-1.6-2.el7.x86_64.rpm                                                                                                                                                                  | 167 kB  00:00:00     
(2/2): oniguruma-6.8.2-2.el7.x86_64.rpm                                                                                                                                                         | 181 kB  00:00:00     
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                  668 kB/s | 348 kB  00:00:00     
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
Importing GPG key 0x352C64E5:
 Userid     : "Fedora EPEL (7) <epel@fedoraproject.org>"
 Fingerprint: 91e9 7d7c 4a5e 96f1 7f3e 888f 6a2f aea2 352c 64e5
 Package    : epel-release-7-11.noarch (@extras)
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : oniguruma-6.8.2-2.el7.x86_64                                                                                                                                                                        1/2 
  Installing : jq-1.6-2.el7.x86_64                                                                                                                                                                                 2/2 
  Verifying  : oniguruma-6.8.2-2.el7.x86_64                                                                                                                                                                        1/2 
  Verifying  : jq-1.6-2.el7.x86_64                                                                                                                                                                                 2/2 

Installed:
  jq.x86_64 0:1.6-2.el7                                                                                                                                                                                                

Dependency Installed:
  oniguruma.x86_64 0:6.8.2-2.el7                                                                                                                                                                                       

Complete!
--2023-08-19 22:26:18--  ~~~
Resolving ~~~ ...
Connecting to ~~~ connected.
HTTP request sent, awaiting response... 200 OK
Length: 153454692 (146M)
Saving to: ‘gp.rpm’

100%[=============================================================================================================================================================================>] 153,454,692 76.8MB/s   in 1.9s   

2023-08-19 22:26:20 (76.8 MB/s) - ‘gp.rpm’ saved [153454692/153454692]

Loaded plugins: fastestmirror
Examining ./gp.rpm: greenplum-db-6-6.24.3-1.el7.x86_64
Marking ./gp.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package greenplum-db-6.x86_64 0:6.24.3-1.el7 will be installed
--> Processing Dependency: apr for package: greenplum-db-6-6.24.3-1.el7.x86_64
Loading mirror speeds from cached hostfile
 * base: mirrors.xmission.com
 * epel: mirrors.sonic.net
 * extras: opencolo.mm.fcix.net
 * updates: mirrors.raystedman.org
--> Processing Dependency: apr-util for package: greenplum-db-6-6.24.3-1.el7.x86_64
--> Processing Dependency: krb5-devel for package: greenplum-db-6-6.24.3-1.el7.x86_64
--> Processing Dependency: libyaml for package: greenplum-db-6-6.24.3-1.el7.x86_64
--> Processing Dependency: net-tools for package: greenplum-db-6-6.24.3-1.el7.x86_64
--> Processing Dependency: perl for package: greenplum-db-6-6.24.3-1.el7.x86_64
--> Processing Dependency: rsync for package: greenplum-db-6-6.24.3-1.el7.x86_64
--> Processing Dependency: zip for package: greenplum-db-6-6.24.3-1.el7.x86_64
--> Processing Dependency: libevent for package: greenplum-db-6-6.24.3-1.el7.x86_64
--> Running transaction check
---> Package apr.x86_64 0:1.4.8-7.el7 will be installed
---> Package apr-util.x86_64 0:1.5.2-6.el7_9.1 will be installed
---> Package krb5-devel.x86_64 0:1.15.1-55.el7_9 will be installed
--> Processing Dependency: libkadm5(x86-64) = 1.15.1-55.el7_9 for package: krb5-devel-1.15.1-55.el7_9.x86_64
--> Processing Dependency: krb5-libs(x86-64) = 1.15.1-55.el7_9 for package: krb5-devel-1.15.1-55.el7_9.x86_64
--> Processing Dependency: libverto-devel for package: krb5-devel-1.15.1-55.el7_9.x86_64
--> Processing Dependency: libselinux-devel for package: krb5-devel-1.15.1-55.el7_9.x86_64
--> Processing Dependency: libcom_err-devel for package: krb5-devel-1.15.1-55.el7_9.x86_64
--> Processing Dependency: keyutils-libs-devel for package: krb5-devel-1.15.1-55.el7_9.x86_64
---> Package libevent.x86_64 0:2.0.21-4.el7 will be installed
---> Package libyaml.x86_64 0:0.1.4-11.el7_0 will be installed
---> Package net-tools.x86_64 0:2.0-0.25.20131004git.el7 will be installed
---> Package perl.x86_64 4:5.16.3-299.el7_9 will be installed
--> Processing Dependency: perl-libs = 4:5.16.3-299.el7_9 for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Socket) >= 1.3 for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Scalar::Util) >= 1.10 for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl-macros for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl-libs for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(threads::shared) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(threads) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(constant) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Time::Local) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Time::HiRes) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Storable) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Socket) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Scalar::Util) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Pod::Simple::XHTML) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Pod::Simple::Search) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Getopt::Long) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Filter::Util::Call) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(File::Temp) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(File::Spec::Unix) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(File::Spec::Functions) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(File::Spec) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(File::Path) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Exporter) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Cwd) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Carp) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: libperl.so()(64bit) for package: 4:perl-5.16.3-299.el7_9.x86_64
---> Package rsync.x86_64 0:3.1.2-12.el7_9 will be installed
---> Package zip.x86_64 0:3.0-11.el7 will be installed
--> Running transaction check
---> Package keyutils-libs-devel.x86_64 0:1.5.8-3.el7 will be installed
---> Package krb5-libs.x86_64 0:1.15.1-50.el7 will be updated
---> Package krb5-libs.x86_64 0:1.15.1-55.el7_9 will be an update
---> Package libcom_err-devel.x86_64 0:1.42.9-19.el7 will be installed
---> Package libkadm5.x86_64 0:1.15.1-55.el7_9 will be installed
---> Package libselinux-devel.x86_64 0:2.5-15.el7 will be installed
--> Processing Dependency: libsepol-devel(x86-64) >= 2.5-10 for package: libselinux-devel-2.5-15.el7.x86_64
--> Processing Dependency: pkgconfig(libsepol) for package: libselinux-devel-2.5-15.el7.x86_64
--> Processing Dependency: pkgconfig(libpcre) for package: libselinux-devel-2.5-15.el7.x86_64
---> Package libverto-devel.x86_64 0:0.2.5-4.el7 will be installed
---> Package perl-Carp.noarch 0:1.26-244.el7 will be installed
---> Package perl-Exporter.noarch 0:5.68-3.el7 will be installed
---> Package perl-File-Path.noarch 0:2.09-2.el7 will be installed
---> Package perl-File-Temp.noarch 0:0.23.01-3.el7 will be installed
---> Package perl-Filter.x86_64 0:1.49-3.el7 will be installed
---> Package perl-Getopt-Long.noarch 0:2.40-3.el7 will be installed
--> Processing Dependency: perl(Pod::Usage) >= 1.14 for package: perl-Getopt-Long-2.40-3.el7.noarch
--> Processing Dependency: perl(Text::ParseWords) for package: perl-Getopt-Long-2.40-3.el7.noarch
---> Package perl-PathTools.x86_64 0:3.40-5.el7 will be installed
---> Package perl-Pod-Simple.noarch 1:3.28-4.el7 will be installed
--> Processing Dependency: perl(Pod::Escapes) >= 1.04 for package: 1:perl-Pod-Simple-3.28-4.el7.noarch
--> Processing Dependency: perl(Encode) for package: 1:perl-Pod-Simple-3.28-4.el7.noarch
---> Package perl-Scalar-List-Utils.x86_64 0:1.27-248.el7 will be installed
---> Package perl-Socket.x86_64 0:2.010-5.el7 will be installed
---> Package perl-Storable.x86_64 0:2.45-3.el7 will be installed
---> Package perl-Time-HiRes.x86_64 4:1.9725-3.el7 will be installed
---> Package perl-Time-Local.noarch 0:1.2300-2.el7 will be installed
---> Package perl-constant.noarch 0:1.27-2.el7 will be installed
---> Package perl-libs.x86_64 4:5.16.3-299.el7_9 will be installed
---> Package perl-macros.x86_64 4:5.16.3-299.el7_9 will be installed
---> Package perl-threads.x86_64 0:1.87-4.el7 will be installed
---> Package perl-threads-shared.x86_64 0:1.43-6.el7 will be installed
--> Running transaction check
---> Package libsepol-devel.x86_64 0:2.5-10.el7 will be installed
---> Package pcre-devel.x86_64 0:8.32-17.el7 will be installed
---> Package perl-Encode.x86_64 0:2.51-7.el7 will be installed
---> Package perl-Pod-Escapes.noarch 1:1.04-299.el7_9 will be installed
---> Package perl-Pod-Usage.noarch 0:1.63-3.el7 will be installed
--> Processing Dependency: perl(Pod::Text) >= 3.15 for package: perl-Pod-Usage-1.63-3.el7.noarch
--> Processing Dependency: perl-Pod-Perldoc for package: perl-Pod-Usage-1.63-3.el7.noarch
---> Package perl-Text-ParseWords.noarch 0:3.29-4.el7 will be installed
--> Running transaction check
---> Package perl-Pod-Perldoc.noarch 0:3.20-4.el7 will be installed
--> Processing Dependency: perl(parent) for package: perl-Pod-Perldoc-3.20-4.el7.noarch
--> Processing Dependency: perl(HTTP::Tiny) for package: perl-Pod-Perldoc-3.20-4.el7.noarch
---> Package perl-podlators.noarch 0:2.5.1-3.el7 will be installed
--> Running transaction check
---> Package perl-HTTP-Tiny.noarch 0:0.033-3.el7 will be installed
---> Package perl-parent.noarch 1:0.225-244.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

=======================================================================================================================================================================================================================
 Package                                                    Arch                                       Version                                                       Repository                                   Size
=======================================================================================================================================================================================================================
Installing:
 greenplum-db-6                                             x86_64                                     6.24.3-1.el7                                                  /gp                                         612 M
Installing for dependencies:
 apr                                                        x86_64                                     1.4.8-7.el7                                                   base                                        104 k
 apr-util                                                   x86_64                                     1.5.2-6.el7_9.1                                               updates                                      92 k
 keyutils-libs-devel                                        x86_64                                     1.5.8-3.el7                                                   base                                         37 k
 krb5-devel                                                 x86_64                                     1.15.1-55.el7_9                                               updates                                     273 k
 libcom_err-devel                                           x86_64                                     1.42.9-19.el7                                                 base                                         32 k
 libevent                                                   x86_64                                     2.0.21-4.el7                                                  base                                        214 k
 libkadm5                                                   x86_64                                     1.15.1-55.el7_9                                               updates                                     180 k
 libselinux-devel                                           x86_64                                     2.5-15.el7                                                    base                                        187 k
 libsepol-devel                                             x86_64                                     2.5-10.el7                                                    base                                         77 k
 libverto-devel                                             x86_64                                     0.2.5-4.el7                                                   base                                         12 k
 libyaml                                                    x86_64                                     0.1.4-11.el7_0                                                base                                         55 k
 net-tools                                                  x86_64                                     2.0-0.25.20131004git.el7                                      base                                        306 k
 pcre-devel                                                 x86_64                                     8.32-17.el7                                                   base                                        480 k
 perl                                                       x86_64                                     4:5.16.3-299.el7_9                                            updates                                     8.0 M
 perl-Carp                                                  noarch                                     1.26-244.el7                                                  base                                         19 k
 perl-Encode                                                x86_64                                     2.51-7.el7                                                    base                                        1.5 M
 perl-Exporter                                              noarch                                     5.68-3.el7                                                    base                                         28 k
 perl-File-Path                                             noarch                                     2.09-2.el7                                                    base                                         26 k
 perl-File-Temp                                             noarch                                     0.23.01-3.el7                                                 base                                         56 k
 perl-Filter                                                x86_64                                     1.49-3.el7                                                    base                                         76 k
 perl-Getopt-Long                                           noarch                                     2.40-3.el7                                                    base                                         56 k
 perl-HTTP-Tiny                                             noarch                                     0.033-3.el7                                                   base                                         38 k
 perl-PathTools                                             x86_64                                     3.40-5.el7                                                    base                                         82 k
 perl-Pod-Escapes                                           noarch                                     1:1.04-299.el7_9                                              updates                                      52 k
 perl-Pod-Perldoc                                           noarch                                     3.20-4.el7                                                    base                                         87 k
 perl-Pod-Simple                                            noarch                                     1:3.28-4.el7                                                  base                                        216 k
 perl-Pod-Usage                                             noarch                                     1.63-3.el7                                                    base                                         27 k
 perl-Scalar-List-Utils                                     x86_64                                     1.27-248.el7                                                  base                                         36 k
 perl-Socket                                                x86_64                                     2.010-5.el7                                                   base                                         49 k
 perl-Storable                                              x86_64                                     2.45-3.el7                                                    base                                         77 k
 perl-Text-ParseWords                                       noarch                                     3.29-4.el7                                                    base                                         14 k
 perl-Time-HiRes                                            x86_64                                     4:1.9725-3.el7                                                base                                         45 k
 perl-Time-Local                                            noarch                                     1.2300-2.el7                                                  base                                         24 k
 perl-constant                                              noarch                                     1.27-2.el7                                                    base                                         19 k
 perl-libs                                                  x86_64                                     4:5.16.3-299.el7_9                                            updates                                     690 k
 perl-macros                                                x86_64                                     4:5.16.3-299.el7_9                                            updates                                      44 k
 perl-parent                                                noarch                                     1:0.225-244.el7                                               base                                         12 k
 perl-podlators                                             noarch                                     2.5.1-3.el7                                                   base                                        112 k
 perl-threads                                               x86_64                                     1.87-4.el7                                                    base                                         49 k
 perl-threads-shared                                        x86_64                                     1.43-6.el7                                                    base                                         39 k
 rsync                                                      x86_64                                     3.1.2-12.el7_9                                                updates                                     408 k
 zip                                                        x86_64                                     3.0-11.el7                                                    base                                        260 k
Updating for dependencies:
 krb5-libs                                                  x86_64                                     1.15.1-55.el7_9                                               updates                                     810 k

Transaction Summary
=======================================================================================================================================================================================================================
Install  1 Package  (+42 Dependent packages)
Upgrade             (  1 Dependent package)

Total size: 627 M
Total download size: 15 M
Downloading packages:
Delta RPMs disabled because /usr/bin/applydeltarpm not installed.
(1/43): apr-util-1.5.2-6.el7_9.1.x86_64.rpm                                                                                                                                                     |  92 kB  00:00:00     
(2/43): keyutils-libs-devel-1.5.8-3.el7.x86_64.rpm                                                                                                                                              |  37 kB  00:00:00     
(3/43): krb5-devel-1.15.1-55.el7_9.x86_64.rpm                                                                                                                                                   | 273 kB  00:00:00     
(4/43): libkadm5-1.15.1-55.el7_9.x86_64.rpm                                                                                                                                                     | 180 kB  00:00:00     
(5/43): krb5-libs-1.15.1-55.el7_9.x86_64.rpm                                                                                                                                                    | 810 kB  00:00:00     
(6/43): apr-1.4.8-7.el7.x86_64.rpm                                                                                                                                                              | 104 kB  00:00:00     
(7/43): libverto-devel-0.2.5-4.el7.x86_64.rpm                                                                                                                                                   |  12 kB  00:00:00     
(8/43): libcom_err-devel-1.42.9-19.el7.x86_64.rpm                                                                                                                                               |  32 kB  00:00:00     
(9/43): libyaml-0.1.4-11.el7_0.x86_64.rpm                                                                                                                                                       |  55 kB  00:00:00     
(10/43): libevent-2.0.21-4.el7.x86_64.rpm                                                                                                                                                       | 214 kB  00:00:00     
(11/43): pcre-devel-8.32-17.el7.x86_64.rpm                                                                                                                                                      | 480 kB  00:00:00     
(12/43): perl-5.16.3-299.el7_9.x86_64.rpm                                                                                                                                                       | 8.0 MB  00:00:00     
(13/43): perl-Carp-1.26-244.el7.noarch.rpm                                                                                                                                                      |  19 kB  00:00:00     
(14/43): libselinux-devel-2.5-15.el7.x86_64.rpm                                                                                                                                                 | 187 kB  00:00:00     
(15/43): perl-Exporter-5.68-3.el7.noarch.rpm                                                                                                                                                    |  28 kB  00:00:00     
(16/43): perl-File-Path-2.09-2.el7.noarch.rpm                                                                                                                                                   |  26 kB  00:00:00     
(17/43): perl-File-Temp-0.23.01-3.el7.noarch.rpm                                                                                                                                                |  56 kB  00:00:00     
(18/43): net-tools-2.0-0.25.20131004git.el7.x86_64.rpm                                                                                                                                          | 306 kB  00:00:00     
(19/43): perl-Filter-1.49-3.el7.x86_64.rpm                                                                                                                                                      |  76 kB  00:00:00     
(20/43): perl-Getopt-Long-2.40-3.el7.noarch.rpm                                                                                                                                                 |  56 kB  00:00:00     
(21/43): perl-Pod-Escapes-1.04-299.el7_9.noarch.rpm                                                                                                                                             |  52 kB  00:00:00     
(22/43): perl-PathTools-3.40-5.el7.x86_64.rpm                                                                                                                                                   |  82 kB  00:00:00     
(23/43): perl-Pod-Perldoc-3.20-4.el7.noarch.rpm                                                                                                                                                 |  87 kB  00:00:00     
(24/43): libsepol-devel-2.5-10.el7.x86_64.rpm                                                                                                                                                   |  77 kB  00:00:00     
(25/43): perl-Pod-Usage-1.63-3.el7.noarch.rpm                                                                                                                                                   |  27 kB  00:00:00     
(26/43): perl-HTTP-Tiny-0.033-3.el7.noarch.rpm                                                                                                                                                  |  38 kB  00:00:00     
(27/43): perl-Socket-2.010-5.el7.x86_64.rpm                                                                                                                                                     |  49 kB  00:00:00     
(28/43): perl-Pod-Simple-3.28-4.el7.noarch.rpm                                                                                                                                                  | 216 kB  00:00:00     
(29/43): perl-Text-ParseWords-3.29-4.el7.noarch.rpm                                                                                                                                             |  14 kB  00:00:00     
(30/43): perl-Time-HiRes-1.9725-3.el7.x86_64.rpm                                                                                                                                                |  45 kB  00:00:00     
(31/43): perl-Scalar-List-Utils-1.27-248.el7.x86_64.rpm                                                                                                                                         |  36 kB  00:00:00     
(32/43): perl-Time-Local-1.2300-2.el7.noarch.rpm                                                                                                                                                |  24 kB  00:00:00     
(33/43): perl-libs-5.16.3-299.el7_9.x86_64.rpm                                                                                                                                                  | 690 kB  00:00:00     
(34/43): perl-constant-1.27-2.el7.noarch.rpm                                                                                                                                                    |  19 kB  00:00:00     
(35/43): perl-macros-5.16.3-299.el7_9.x86_64.rpm                                                                                                                                                |  44 kB  00:00:00     
(36/43): perl-parent-0.225-244.el7.noarch.rpm                                                                                                                                                   |  12 kB  00:00:00     
(37/43): perl-podlators-2.5.1-3.el7.noarch.rpm                                                                                                                                                  | 112 kB  00:00:00     
(38/43): perl-threads-shared-1.43-6.el7.x86_64.rpm                                                                                                                                              |  39 kB  00:00:00     
(39/43): rsync-3.1.2-12.el7_9.x86_64.rpm                                                                                                                                                        | 408 kB  00:00:00     
(40/43): perl-Storable-2.45-3.el7.x86_64.rpm                                                                                                                                                    |  77 kB  00:00:00     
(41/43): zip-3.0-11.el7.x86_64.rpm                                                                                                                                                              | 260 kB  00:00:00     
(42/43): perl-threads-1.87-4.el7.x86_64.rpm                                                                                                                                                     |  49 kB  00:00:00     
(43/43): perl-Encode-2.51-7.el7.x86_64.rpm                                                                                                                                                      | 1.5 MB  00:00:01     
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                  6.2 MB/s |  15 MB  00:00:02     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Updating   : krb5-libs-1.15.1-55.el7_9.x86_64                                                                                                                                                                   1/45 
  Installing : apr-1.4.8-7.el7.x86_64                                                                                                                                                                             2/45 
  Installing : apr-util-1.5.2-6.el7_9.1.x86_64                                                                                                                                                                    3/45 
  Installing : libkadm5-1.15.1-55.el7_9.x86_64                                                                                                                                                                    4/45 
  Installing : 1:perl-parent-0.225-244.el7.noarch                                                                                                                                                                 5/45 
  Installing : perl-HTTP-Tiny-0.033-3.el7.noarch                                                                                                                                                                  6/45 
  Installing : perl-podlators-2.5.1-3.el7.noarch                                                                                                                                                                  7/45 
  Installing : perl-Pod-Perldoc-3.20-4.el7.noarch                                                                                                                                                                 8/45 
  Installing : 1:perl-Pod-Escapes-1.04-299.el7_9.noarch                                                                                                                                                           9/45 
  Installing : perl-Encode-2.51-7.el7.x86_64                                                                                                                                                                     10/45 
  Installing : perl-Text-ParseWords-3.29-4.el7.noarch                                                                                                                                                            11/45 
  Installing : perl-Pod-Usage-1.63-3.el7.noarch                                                                                                                                                                  12/45 
  Installing : 4:perl-macros-5.16.3-299.el7_9.x86_64                                                                                                                                                             13/45 
  Installing : perl-threads-1.87-4.el7.x86_64                                                                                                                                                                    14/45 
  Installing : 4:perl-Time-HiRes-1.9725-3.el7.x86_64                                                                                                                                                             15/45 
  Installing : perl-Exporter-5.68-3.el7.noarch                                                                                                                                                                   16/45 
  Installing : perl-constant-1.27-2.el7.noarch                                                                                                                                                                   17/45 
  Installing : perl-Socket-2.010-5.el7.x86_64                                                                                                                                                                    18/45 
  Installing : perl-Time-Local-1.2300-2.el7.noarch                                                                                                                                                               19/45 
  Installing : perl-Carp-1.26-244.el7.noarch                                                                                                                                                                     20/45 
  Installing : perl-Storable-2.45-3.el7.x86_64                                                                                                                                                                   21/45 
  Installing : perl-threads-shared-1.43-6.el7.x86_64                                                                                                                                                             22/45 
  Installing : perl-PathTools-3.40-5.el7.x86_64                                                                                                                                                                  23/45 
  Installing : perl-Scalar-List-Utils-1.27-248.el7.x86_64                                                                                                                                                        24/45 
  Installing : 1:perl-Pod-Simple-3.28-4.el7.noarch                                                                                                                                                               25/45 
  Installing : perl-File-Temp-0.23.01-3.el7.noarch                                                                                                                                                               26/45 
  Installing : perl-File-Path-2.09-2.el7.noarch                                                                                                                                                                  27/45 
  Installing : perl-Filter-1.49-3.el7.x86_64                                                                                                                                                                     28/45 
  Installing : 4:perl-libs-5.16.3-299.el7_9.x86_64                                                                                                                                                               29/45 
  Installing : perl-Getopt-Long-2.40-3.el7.noarch                                                                                                                                                                30/45 
  Installing : 4:perl-5.16.3-299.el7_9.x86_64                                                                                                                                                                    31/45 
  Installing : libcom_err-devel-1.42.9-19.el7.x86_64                                                                                                                                                             32/45 
  Installing : zip-3.0-11.el7.x86_64                                                                                                                                                                             33/45 
  Installing : pcre-devel-8.32-17.el7.x86_64                                                                                                                                                                     34/45 
  Installing : libyaml-0.1.4-11.el7_0.x86_64                                                                                                                                                                     35/45 
  Installing : libsepol-devel-2.5-10.el7.x86_64                                                                                                                                                                  36/45 
  Installing : libselinux-devel-2.5-15.el7.x86_64                                                                                                                                                                37/45 
  Installing : libevent-2.0.21-4.el7.x86_64                                                                                                                                                                      38/45 
  Installing : net-tools-2.0-0.25.20131004git.el7.x86_64                                                                                                                                                         39/45 
  Installing : libverto-devel-0.2.5-4.el7.x86_64                                                                                                                                                                 40/45 
  Installing : rsync-3.1.2-12.el7_9.x86_64                                                                                                                                                                       41/45 
  Installing : keyutils-libs-devel-1.5.8-3.el7.x86_64                                                                                                                                                            42/45 
  Installing : krb5-devel-1.15.1-55.el7_9.x86_64                                                                                                                                                                 43/45 
  Installing : greenplum-db-6-6.24.3-1.el7.x86_64                                                                                                                                                                44/45 
  Cleanup    : krb5-libs-1.15.1-50.el7.x86_64                                                                                                                                                                    45/45 
  Verifying  : perl-HTTP-Tiny-0.033-3.el7.noarch                                                                                                                                                                  1/45 
  Verifying  : libselinux-devel-2.5-15.el7.x86_64                                                                                                                                                                 2/45 
  Verifying  : keyutils-libs-devel-1.5.8-3.el7.x86_64                                                                                                                                                             3/45 
  Verifying  : rsync-3.1.2-12.el7_9.x86_64                                                                                                                                                                        4/45 
  Verifying  : perl-threads-shared-1.43-6.el7.x86_64                                                                                                                                                              5/45 
  Verifying  : 4:perl-Time-HiRes-1.9725-3.el7.x86_64                                                                                                                                                              6/45 
  Verifying  : krb5-devel-1.15.1-55.el7_9.x86_64                                                                                                                                                                  7/45 
  Verifying  : perl-threads-1.87-4.el7.x86_64                                                                                                                                                                     8/45 
  Verifying  : perl-Exporter-5.68-3.el7.noarch                                                                                                                                                                    9/45 
  Verifying  : perl-constant-1.27-2.el7.noarch                                                                                                                                                                   10/45 
  Verifying  : perl-PathTools-3.40-5.el7.x86_64                                                                                                                                                                  11/45 
  Verifying  : 4:perl-macros-5.16.3-299.el7_9.x86_64                                                                                                                                                             12/45 
  Verifying  : greenplum-db-6-6.24.3-1.el7.x86_64                                                                                                                                                                13/45 
  Verifying  : 1:perl-parent-0.225-244.el7.noarch                                                                                                                                                                14/45 
  Verifying  : perl-Socket-2.010-5.el7.x86_64                                                                                                                                                                    15/45 
  Verifying  : libverto-devel-0.2.5-4.el7.x86_64                                                                                                                                                                 16/45 
  Verifying  : apr-util-1.5.2-6.el7_9.1.x86_64                                                                                                                                                                   17/45 
  Verifying  : apr-1.4.8-7.el7.x86_64                                                                                                                                                                            18/45 
  Verifying  : perl-File-Temp-0.23.01-3.el7.noarch                                                                                                                                                               19/45 
  Verifying  : net-tools-2.0-0.25.20131004git.el7.x86_64                                                                                                                                                         20/45 
  Verifying  : 1:perl-Pod-Simple-3.28-4.el7.noarch                                                                                                                                                               21/45 
  Verifying  : perl-Time-Local-1.2300-2.el7.noarch                                                                                                                                                               22/45 
  Verifying  : 1:perl-Pod-Escapes-1.04-299.el7_9.noarch                                                                                                                                                          23/45 
  Verifying  : perl-Carp-1.26-244.el7.noarch                                                                                                                                                                     24/45 
  Verifying  : krb5-libs-1.15.1-55.el7_9.x86_64                                                                                                                                                                  25/45 
  Verifying  : libevent-2.0.21-4.el7.x86_64                                                                                                                                                                      26/45 
  Verifying  : perl-Storable-2.45-3.el7.x86_64                                                                                                                                                                   27/45 
  Verifying  : perl-Scalar-List-Utils-1.27-248.el7.x86_64                                                                                                                                                        28/45 
  Verifying  : libsepol-devel-2.5-10.el7.x86_64                                                                                                                                                                  29/45 
  Verifying  : perl-Pod-Usage-1.63-3.el7.noarch                                                                                                                                                                  30/45 
  Verifying  : perl-Encode-2.51-7.el7.x86_64                                                                                                                                                                     31/45 
  Verifying  : libyaml-0.1.4-11.el7_0.x86_64                                                                                                                                                                     32/45 
  Verifying  : perl-Pod-Perldoc-3.20-4.el7.noarch                                                                                                                                                                33/45 
  Verifying  : perl-podlators-2.5.1-3.el7.noarch                                                                                                                                                                 34/45 
  Verifying  : pcre-devel-8.32-17.el7.x86_64                                                                                                                                                                     35/45 
  Verifying  : 4:perl-5.16.3-299.el7_9.x86_64                                                                                                                                                                    36/45 
  Verifying  : perl-File-Path-2.09-2.el7.noarch                                                                                                                                                                  37/45 
  Verifying  : zip-3.0-11.el7.x86_64                                                                                                                                                                             38/45 
  Verifying  : libkadm5-1.15.1-55.el7_9.x86_64                                                                                                                                                                   39/45 
  Verifying  : perl-Filter-1.49-3.el7.x86_64                                                                                                                                                                     40/45 
  Verifying  : perl-Getopt-Long-2.40-3.el7.noarch                                                                                                                                                                41/45 
  Verifying  : perl-Text-ParseWords-3.29-4.el7.noarch                                                                                                                                                            42/45 
  Verifying  : libcom_err-devel-1.42.9-19.el7.x86_64                                                                                                                                                             43/45 
  Verifying  : 4:perl-libs-5.16.3-299.el7_9.x86_64                                                                                                                                                               44/45 
  Verifying  : krb5-libs-1.15.1-50.el7.x86_64                                                                                                                                                                    45/45 

Installed:
  greenplum-db-6.x86_64 0:6.24.3-1.el7                                                                                                                                                                                 

Dependency Installed:
  apr.x86_64 0:1.4.8-7.el7                 apr-util.x86_64 0:1.5.2-6.el7_9.1           keyutils-libs-devel.x86_64 0:1.5.8-3.el7     krb5-devel.x86_64 0:1.15.1-55.el7_9      libcom_err-devel.x86_64 0:1.42.9-19.el7
  libevent.x86_64 0:2.0.21-4.el7           libkadm5.x86_64 0:1.15.1-55.el7_9           libselinux-devel.x86_64 0:2.5-15.el7         libsepol-devel.x86_64 0:2.5-10.el7       libverto-devel.x86_64 0:0.2.5-4.el7    
  libyaml.x86_64 0:0.1.4-11.el7_0          net-tools.x86_64 0:2.0-0.25.20131004git.el7 pcre-devel.x86_64 0:8.32-17.el7              perl.x86_64 4:5.16.3-299.el7_9           perl-Carp.noarch 0:1.26-244.el7        
  perl-Encode.x86_64 0:2.51-7.el7          perl-Exporter.noarch 0:5.68-3.el7           perl-File-Path.noarch 0:2.09-2.el7           perl-File-Temp.noarch 0:0.23.01-3.el7    perl-Filter.x86_64 0:1.49-3.el7        
  perl-Getopt-Long.noarch 0:2.40-3.el7     perl-HTTP-Tiny.noarch 0:0.033-3.el7         perl-PathTools.x86_64 0:3.40-5.el7           perl-Pod-Escapes.noarch 1:1.04-299.el7_9 perl-Pod-Perldoc.noarch 0:3.20-4.el7   
  perl-Pod-Simple.noarch 1:3.28-4.el7      perl-Pod-Usage.noarch 0:1.63-3.el7          perl-Scalar-List-Utils.x86_64 0:1.27-248.el7 perl-Socket.x86_64 0:2.010-5.el7         perl-Storable.x86_64 0:2.45-3.el7      
  perl-Text-ParseWords.noarch 0:3.29-4.el7 perl-Time-HiRes.x86_64 4:1.9725-3.el7       perl-Time-Local.noarch 0:1.2300-2.el7        perl-constant.noarch 0:1.27-2.el7        perl-libs.x86_64 4:5.16.3-299.el7_9    
  perl-macros.x86_64 4:5.16.3-299.el7_9    perl-parent.noarch 1:0.225-244.el7          perl-podlators.noarch 0:2.5.1-3.el7          perl-threads.x86_64 0:1.87-4.el7         perl-threads-shared.x86_64 0:1.43-6.el7
  rsync.x86_64 0:3.1.2-12.el7_9            zip.x86_64 0:3.0-11.el7                    

Dependency Updated:
  krb5-libs.x86_64 0:1.15.1-55.el7_9                                                                                                                                                                                   

Complete!
Generate gpinitsystem
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
ベースVM のhosts ファイルの設定と整合性をとる必要があるため、Terraform 側でセグメントのインターナルIP アドレス(gp_sdw1_internal_ip, gp_sdw2_internal_ip)を変更した場合は、gp_install.sh 側のIP アドレス(SDW1_IP_ADDR, SDW2_IP_ADDR)を変更して再インストールするか、ベースVM の設定を忘れずに変更すること。

## demo-psql.md

動作確認用のデモシナリオです。

