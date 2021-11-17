variable "hcloud_token" {
  type = string
}

variable "ssh_keys" {
  type = string
}

locals {
  snapshotbuildtime = formatdate("YYYY-MM-DD-hhmm", timestamp())
  # Also here I believe naming this variable `buildtime` could lead to 
  # confusion mainly because this is evaluated a 'parsing-time'.
  hcloud-servertype = "cx11"
  arch-release = "{{ isotime `2006-01` }}-01"
  system-keymap = "us"
  system-locale = "en_US.UTF-8"
  system-timezone = "UTC"
  extra-packages = ""
}

source "hcloud" "debian-11" {
  image        = "debian-11"
  location     = "hel1"
  server_type  = "cx11"
  ssh_username = "root"
  token        = "${var.hcloud_token}"
  rescue       = "linux64"
  ssh_keys     = ["${var.ssh_keys}"]
  ssh_agent_auth = true
  server_name = "debian-11-${ local.snapshotbuildtime }"
  snapshot_name = "debian-11-${ local.snapshotbuildtime }"
  snapshot_labels = {
    "packer.io/version" = "${packer.version}",
    "packer.io/build.time" = "${ local.snapshotbuildtime }",
    "os-flavor" = "debian-11",
    "image_type" = "debian-11"
  }
}

build {
  sources = ["source.hcloud.debian-11"]

  provisioner "shell" {
    inline = ["echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections"]
  }

  provisioner "shell" {
    inline = ["/usr/bin/apt-get update"]
  }

  provisioner "shell" {
    inline = ["/usr/bin/apt-get -y upgrade"]
  }

  provisioner "shell" {
    inline = ["/usr/bin/apt-get -y install python3 python3-pip python3-setuptools python3-wheel"]
  }

  provisioner "shell" {
    inline = ["/usr/bin/apt-get -y install ssl-cert"]
  }

  provisioner "shell" {
    inline = ["make-ssl-cert generate-default-snakeoil --force-overwrite"]
  }
}
