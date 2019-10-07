provider "libvirt" {
    uri = "qemu+ssh://vmm@gollum-p1.qa.suse.de/system"
}

variable "host_ips" {
  description = "IP addresses of the nodes"
  default     = ["172.30.100.2", "172.30.100.3"]
}

variable "macs" {
  description = "The mac addresses of the nodes"
  default     = ["52:54:00:E2:64:F7", "52:54:00:A2:FF:35"]
}

resource "libvirt_volume" "volume" {
    source       = "http://download.suse.de/ibs/Devel:/SAP:/Terraform:/Images/images/SLES4SAP-15_SP0-JeOS.x86_64.qcow2"
    name         = "varkoly-test-${count.index}"
    pool         = "terraform"
    format       = "qcow2"
    count        = 2
}

resource "libvirt_domain" "terraform_test" {
  name   = "varkoly-terraform-test-${count.index}"
  count  = 2
  vcpu   = 4
  memory = 2048
  disk {
    volume_id = "${element(libvirt_volume.volume.*.id, count.index)}"
  }
  network_interface {
    network_name   = ""
    bridge         = "br0"
    wait_for_lease = true
    mac            = "${element(var.macs, count.index)}"
  }
  network_interface {
    network_name = "varkoly-int"
    wait_for_lease = true
    addresses = "${list(element(var.host_ips, count.index))}"
  }
  provisioner "file" {
    source      = ".ssh/id_rsa"
    destination = "/root/.ssh/id_rsa"
  }
  provisioner "file" {
    source      = ".ssh/id_rsa.pub"
    destination = "/root/.ssh/id_rsa.pub"
  }
  provisioner "file" {
    source      = ".ssh/authorized_keys"
    destination = "/root/.ssh/authorized_keys"
  }
  provisioner "file" {
    source      = "conf/corosync.conf"
    destination = "/etc/corosync/corosync.conf"
  }
}

resource "null_resource" "register" {
  count = "${length(libvirt_domain.terraform_test)}"
  connection {
    host     = "${element(libvirt_domain.terraform_test.*.network_interface.0.addresses.0, count.index)}"
    user     = "root"
    password = "linux"
  }
  provisioner "remote-exec" {
    inline = [
      "SUSEConnect -r XXXXX",
      "zypper -n install lsb-release corosync pacemaker apache2 wget",
      "corosync-keygen -l"
    ]
  }
}
