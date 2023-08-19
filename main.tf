##########################################
# terraform variables
# Please customize based on customer needs
##########################################
variable "vsphere_user" {
  default = "administrator@vsphere.local"
}
variable "vsphere_password" {
  default = "$VC_PASSWORD"
}
variable "vsphere_server" {
  description = "Enter the address of the vCenter, either as an FQDN (preferred) or an IP address"
  default = "$VC_ADDRESS"
}
variable "vsphere_datacenter" {
  default = "$DC_NAME"
}
variable "vsphere_compute_cluster" {
  default = "$CLUSTER_NAME"
}
variable "vsphere_datastore" {
  default = "$DATASTORE_NAME"
}
variable "vsphere_storage_policy" {
  description = "Enter the custom name for your storage policy defined during Setting Up VMware vSphere Storage/Encryption"
  default = "$POLICY_NAME"
}
variable "base_vm_name" {
  description = "Base VM with vmware-tools and Greenplum installed"
  default = "greenplum-db-base-vm"
}
variable "resource_pool_name" {
  description= "The name of a dedicated resource pool for Greenplum VMs which will be created by Terraform"
  default = "greenplum"
}
variable "prefix" {
  description= "A customizable prefix name for the resource pool, Greenplum VMs, and affinity rules which will be created by Terraform"
  default = "gpv"
}
variable "gp_virtual_external_network" {
  default = "$PORTGROUP_NAME"
}
variable "gp_virtual_internal_network" {
  default = "$PORTGROUP_NAME"
}
variable "gp_virtual_etl_bar_network" {
  default = "$PORTGROUP_NAME"
}
variable "gp_virtual_external_gateway" {
  description = "Gateway for the gp-virtual-external network, e.g. 10.0.0.1"
  default = "$GW_ADDRESS"
}
variable "dns_servers" {
  type = list(string)
  description = "The DNS servers for the routable network, e.g. 8.8.8.8"
  default = ["$DNS_ADDRESS"]
}

# The number of segment host (1 or 2)
variable "segment_count" {
  default = 2
}

# Netmask for mdw, sdw1, and sdw2
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

# Static ip addresses for mdw, sd21, and sdw2
# If you change the ip adresses below, please change the hosts, and check the hosts-segments, and hosts-all files in the base vm 
# mdw
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

# sdw1
variable "gp_sdw1_internal_ip" {
  type = string
  default = "10.10.10.13"
}

variable "gp_sdw1_etl_ip" {
  type = string
  default = "10.10.10.14"
}

# sdw2
variable "gp_sdw2_internal_ip" {
  type = string
  default = "10.10.10.15"
}

variable "gp_sdw2_etl_ip" {
  type = string
  default = "10.10.10.16"
}



######################
# terraform scripts
# PLEASE DO NOT CHANGE
######################
provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

# all of these things need to be known for a deploy to work
data "vsphere_datacenter" "dc" {
  name          = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "gp_virtual_external_network" {
  name          = var.gp_virtual_external_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "gp_virtual_internal_network" {
  name          = var.gp_virtual_internal_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

# vSphere distributed port group for ETL, backup and restore traffic
data "vsphere_network" "gp_virtual_etl_bar_network" {
  name          = var.gp_virtual_etl_bar_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vsphere_compute_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_storage_policy" "policy" {
  name = var.vsphere_storage_policy
}

# this points at the template created by the image folder
data "vsphere_virtual_machine" "template" {
  name          = var.base_vm_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

locals {
  # gp_virtual_internal_ip_cidr = "${data.vsphere_virtual_machine.template.vapp[0].properties["guestinfo.internal_ip_cidr"]}"
  # deployment_type = contains(keys(data.vsphere_virtual_machine.template.vapp[0].properties), "guestinfo.deployment_type") ? "${data.vsphere_virtual_machine.template.vapp[0].properties["guestinfo.deployment_type"]}" : "mirrored"
  # primary_segment_count = "${data.vsphere_virtual_machine.template.vapp[0].properties["guestinfo.primary_segment_count"]}"
  # segment_count = local.deployment_type == "mirrored" ? local.primary_segment_count * 2: local.primary_segment_count
  memory = data.vsphere_virtual_machine.template.memory
  memory_reservation = data.vsphere_virtual_machine.template.memory / 2
  num_cpus = data.vsphere_virtual_machine.template.num_cpus
  root_disk_size_in_gb = data.vsphere_virtual_machine.template.disks[0].size
  data_disk_size_in_gb = data.vsphere_virtual_machine.template.disks[1].size
  # segment_gp_virtual_internal_ipv4_offset = 2
  # segment_gp_virtual_etl_bar_ipv4_offset = 2
  # gp_virtual_internal_ipv4_netmask = parseint(regex("/(\\d+)$", local.gp_virtual_internal_ip_cidr)[0], 10)
  # master_internal_ip = cidrhost(local.gp_virtual_internal_ip_cidr, 11)#(pow(2,(32 - local.gp_virtual_internal_ipv4_netmask))-1)-5)
  # standby_internal_ip = cidrhost(local.gp_virtual_internal_ip_cidr, 1)#(pow(2,(32 - local.gp_virtual_internal_ipv4_netmask))-1)-4)
  # gp_virtual_etl_bar_ipv4_netmask = parseint(regex("/(\\d+)$", var.gp_virtual_etl_bar_ipv4_cidr)[0], 10)
  # master_etl_bar_ip = cidrhost(var.gp_virtual_etl_bar_ipv4_cidr, 12)#(pow(2,(32 - local.gp_virtual_etl_bar_ipv4_netmask))-1)-5)
  # standby_etl_bar_ip = cidrhost(var.gp_virtual_etl_bar_ipv4_cidr, 2)#(pow(2,(32 - local.gp_virtual_etl_bar_ipv4_netmask))-1)-4)
}

resource "vsphere_resource_pool" "pool" {
  name                    = "${var.prefix}-${var.resource_pool_name}"
  parent_resource_pool_id = data.vsphere_compute_cluster.compute_cluster.resource_pool_id
}

resource "vsphere_virtual_machine" "segment_hosts" {
  count = var.segment_count #local.segment_count
  name = format("%s-sdw-%0.3d", var.prefix, count.index + 1)
  resource_pool_id = vsphere_resource_pool.pool.id
  wait_for_guest_net_routable = false
  wait_for_guest_net_timeout = 0
  guest_id = data.vsphere_virtual_machine.template.guest_id
  datastore_id = data.vsphere_datastore.datastore.id
  storage_policy_id = data.vsphere_storage_policy.policy.id
  scsi_controller_count = 2

  memory = local.memory
  memory_reservation = local.memory_reservation
  num_cpus = local.num_cpus
  cpu_share_level = "normal"
  memory_share_level = "normal"

  network_interface {
    network_id = data.vsphere_network.gp_virtual_internal_network.id
  }

  network_interface {
    network_id = data.vsphere_network.gp_virtual_etl_bar_network.id
  }

  swap_placement_policy = "vmDirectory"
  enable_disk_uuid = "true"
  disk {
    label = "disk0"
    size  = local.root_disk_size_in_gb
    unit_number = 0
    eagerly_scrub = true
    thin_provisioned = false
    datastore_id = data.vsphere_datastore.datastore.id
    storage_policy_id = data.vsphere_storage_policy.policy.id
  }

  disk {
    label = "disk1"
    size  = local.data_disk_size_in_gb
    unit_number = 1
    eagerly_scrub = true
    thin_provisioned = false
    datastore_id = data.vsphere_datastore.datastore.id
    storage_policy_id = data.vsphere_storage_policy.policy.id
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "sdw${count.index + 1}"
        domain    = "local"
      }

      network_interface {
        ipv4_address = count.index==0 ? var.gp_sdw1_internal_ip : var.gp_sdw2_internal_ip
        #ipv4_address = var.gp_sdw_internal_ip  #cidrhost(local.gp_virtual_internal_ip_cidr, count.index + 8)#local.segment_gp_virtual_internal_ipv4_offset)
        ipv4_netmask = var.gp_internal_ipv4_netmask
      }

      network_interface {
        ipv4_address = count.index==0 ? var.gp_sdw1_etl_ip : var.gp_sdw2_etl_ip
        #ipv4_address = var.gp_sdw_etl_ip # cidrhost(var.gp_virtual_etl_bar_ipv4_cidr, count.index + 6)#local.segment_gp_virtual_etl_bar_ipv4_offset)
        ipv4_netmask = var.gp_etl_ipv4_netmask
      }
    }
  }
  #vapp {
  #  properties = data.vsphere_virtual_machine.template.vapp[0].properties
  #}
}

resource "vsphere_virtual_machine" "master_hosts" {
  count = 1 #local.deployment_type == "mirrored" ? 2 : 1
  name = count.index == 0 ? format("%s-mdw", var.prefix) : count.index == 1 ? format("%s-smdw", var.prefix) : format("%s-smdw-%d", var.prefix, count.index)
  resource_pool_id = vsphere_resource_pool.pool.id
  wait_for_guest_net_routable = false
  wait_for_guest_net_timeout = 0
  guest_id = data.vsphere_virtual_machine.template.guest_id
  datastore_id = data.vsphere_datastore.datastore.id
  storage_policy_id = data.vsphere_storage_policy.policy.id

  memory = local.memory
  memory_reservation = local.memory_reservation
  num_cpus = local.num_cpus
  cpu_share_level = "normal"
  memory_share_level = "normal"

  network_interface {
    network_id = data.vsphere_network.gp_virtual_internal_network.id
  }

  network_interface {
    network_id = data.vsphere_network.gp_virtual_etl_bar_network.id
  }

  network_interface {
    network_id = data.vsphere_network.gp_virtual_external_network.id
  }

  swap_placement_policy = "vmDirectory"
  enable_disk_uuid = "true"

  disk {
    label = "disk0"
    size  = local.root_disk_size_in_gb
    unit_number = 0
    eagerly_scrub = true
    thin_provisioned = false
    datastore_id = data.vsphere_datastore.datastore.id
    storage_policy_id = data.vsphere_storage_policy.policy.id
  }

  disk {
    label = "disk1"
    size  = local.data_disk_size_in_gb
    unit_number = 1
    eagerly_scrub = true
    thin_provisioned = false
    datastore_id = data.vsphere_datastore.datastore.id
    storage_policy_id = data.vsphere_storage_policy.policy.id
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      linux_options {
        # master is always the first
        # standby master is always the second
        host_name = count.index == 0 ? format("mdw") : format("smdw")
        domain    = "local"
      }

      network_interface {
        ipv4_address = var.gp_mdw_internal_ip # count.index == 0 ? local.master_internal_ip : local.standby_internal_ip
        ipv4_netmask = var.gp_internal_ipv4_netmask
      }

      network_interface {
        ipv4_address = var.gp_mdw_etl_ip #count.index == 0 ? local.master_etl_bar_ip : local.standby_etl_bar_ip
        ipv4_netmask = var.gp_external_ipv4_netmask
      }

      network_interface {
        ipv4_address = var.gp_mdw_external_ip #var.gp_virtual_external_ipv4_addresses[count.index]
        ipv4_netmask = var.gp_external_ipv4_netmask
      }

      ipv4_gateway = var.gp_virtual_external_gateway
      dns_server_list = var.dns_servers
    }
  }

  #vapp {
  #  properties = data.vsphere_virtual_machine.template.vapp[0].properties
  #}
}

resource "vsphere_compute_cluster_vm_anti_affinity_rule" "master_vm_anti_affinity_rule" {
    count               = 0 #local.deployment_type == "mirrored" ? 1 : 0
    enabled             = true
    mandatory           = true
    compute_cluster_id  = data.vsphere_compute_cluster.compute_cluster.id
    name                = format("%s-master-vm-anti-affinity-rule", var.prefix)
    virtual_machine_ids = toset(vsphere_virtual_machine.master_hosts.*.id)
}

resource "vsphere_compute_cluster_vm_anti_affinity_rule" "segment_vm_anti_affinity_rule" {
    count               = 0 #local.deployment_type == "mirrored" ? var.segment_count / 2 : 0 #local.deployment_type == "mirrored" ? local.segment_count / 2 : 0
    enabled             = true
    mandatory           = true
    compute_cluster_id  = data.vsphere_compute_cluster.compute_cluster.id
    name                = format("%s-segment-vm-anti-affinity-rule-sdw%0.3d-sdw%0.3d", var.prefix, count.index*2+1, count.index*2+2)
    virtual_machine_ids = [
        element(vsphere_virtual_machine.segment_hosts.*.id, count.index*2),
        element(vsphere_virtual_machine.segment_hosts.*.id, count.index*2+1),
    ]
}

