## provider setup
terraform {
	required_providers {
		vsphere	= "~> 2.0"
		avi	= {
			source  = "vmware/avi"
			version = ">= 20.1.6"
		}
	}
}
provider "vsphere" {
	vsphere_server		= var.vcenter_server
	user			= var.vcenter_username
	password		= var.vcenter_password
	allow_unverified_ssl	= true
}
provider "avi" {
	avi_controller		= var.avi_server
	avi_username		= var.avi_username
	avi_password		= var.avi_password
	avi_version		= var.avi_version
	avi_tenant		= "admin"
}

## vsphere objects
data "vsphere_datacenter" "datacenter" {
	name          = var.datacenter
}
data "vsphere_compute_cluster" "cmp" {
	name          = "cmp"
	datacenter_id = data.vsphere_datacenter.datacenter.id
}
data "vsphere_compute_cluster" "mgmt" {
	name          = "mgmt"
	datacenter_id = data.vsphere_datacenter.datacenter.id
}

## avi objects
data "avi_tenant" "tenant" {
	name = "admin"
}
data "avi_cloud" "default" {
        name = "Default-Cloud"
}

## create a vip IP pool in Default-Cloud to break a circular cloud_ref dependency
## this is required to bootstrap a network object and IP pool to create the ipam profile
## Default-Cloud is not used for service engine or virtual service placement
resource "avi_network" "ls-vip-pool" {
        name			= "ls-vip-pool"
	cloud_ref		= data.avi_cloud.default.id
	dhcp_enabled		= false
	ip6_autocfg_enabled	= false
	configured_subnets {
		prefix {
			ip_addr {
				addr = "172.16.20.0"
				type = "V4"
			}
			mask = 24
		}
		static_ip_ranges {
			type  = "STATIC_IPS_FOR_VIP"
			range {
				begin {
					addr = "172.16.20.101"
					type = "V4"
				}
				end {
					addr = "172.16.20.199"
					type = "V4"
				}
			}
		}
	}
}

