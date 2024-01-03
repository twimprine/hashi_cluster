packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

locals {
  timestamp = formatdate("YYYYMMDD-HHmmss", timestamp())
  admin_users = [
    "thomas",
    "ansible"
  ]
  tags = {
    project = "hashi_cluster_demo"
    contact = "thomas"
  }
}

source "amazon-ebs" "cluster_image_x64" {
  ami_name      = "hashi_cluster_image_x64-${local.timestamp}"
  instance_type = "t2.micro"
  region        = "us-west-2"
  ssh_username  = "admin"
  source_ami_filter {
    filters = {
      name                = "debian-12-amd64-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["136693071363"]
  }
  tags = local.tags
}

source "amazon-ebs" "cluster_image_arm64" {
  ami_name      = "hashi_cluster_image_arm64-${local.timestamp}"
  instance_type = "t4g.small"
  region        = "us-west-2"
  ssh_username  = "admin"
  source_ami_filter {
    filters = {
      name                = "debian-12-arm64-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["136693071363"]
  }
  tags = local.tags
}

build {
  name = "cluster_image"
  sources = [
    "source.amazon-ebs.cluster_image_x64",
    "source.amazon-ebs.cluster_image_arm64"
  ]

  provisioner "shell" {
    inline = [
      "sudo ls -al /",
      "sudo ls -alh /root",
      "sudo ls -alh /home",
      "sudo mkdir -p /home/admin/.ssh/",
      "sudo apt update",
      "sudo apt install -y gpg",
    ]
  }

  provisioner "file" {
    source      = "/home/thomas/.ssh/id_rsa.pub"
    destination = "/home/admin/.ssh/authorized_keys"
  }

  provisioner "shell" {
    inline = [
      "wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "echo 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bookworm main' | sudo tee /etc/apt/sources.list.d/hashicorp.list",
      "sudo apt update",
      "sudo apt install vault -y"
    ]
  }

}
