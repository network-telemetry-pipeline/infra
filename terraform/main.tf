locals {
  nodes = [
    { name = "k8s-cp-01",     ip = "10.50.0.21", role = "control-plane" },
    { name = "k8s-worker-01", ip = "10.50.0.22", role = "worker" },
    { name = "k8s-worker-02", ip = "10.50.0.23", role = "worker" },
  ]

  ssh_pub_key = trimspace(file(var.ssh_public_key_path))
}

data "google_compute_address" "w01_static_ip" {
  name   = "ml-lab-w01-ip"
  region = var.region
}

resource "google_compute_network" "vpc" {
  name                    = "net-tel-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "net-tel-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Firewall: allow SSH only from admin CIDR
resource "google_compute_firewall" "ssh" {
  name    = "net-tel-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.admin_cidr]
  target_tags   = ["net-tel"]
}

# Firewall: internal cluster traffic within subnet
resource "google_compute_firewall" "internal" {
  name    = "net-tel-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["net-tel"]
}

# Allow NodePort range internally
resource "google_compute_firewall" "nodeport_internal" {
  name    = "net-tel-nodeport-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["net-tel"]
}

resource "google_compute_firewall" "allow_web_80_443" {
  name    = "net-tel-allow-web-80-443"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["net-tel"]
}

resource "google_compute_firewall" "nodeport_kafka" {
  name    = "net-tel-nodeport-kafka"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["30994", "30995"]
  }

  source_ranges = [var.admin_cidr]

  target_tags = ["net-tel"]
}

resource "google_compute_firewall" "nodeport_minio" {
  name    = "net-tel-nodeport-minio"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["31000", "31001"]
  }

  source_ranges = [var.admin_cidr]

  target_tags = ["net-tel"]
}

resource "google_compute_instance" "k8s" {
  for_each     = { for n in local.nodes : n.name => n }
  name         = each.value.name
  machine_type = each.value.role == "worker" ? "e2-standard-4" : "e2-medium"
  zone         = var.zone
  tags         = ["net-tel", each.value.role]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 40
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    network_ip = each.value.ip

    access_config {
        nat_ip = each.key == "k8s-worker-01" ? data.google_compute_address.w01_static_ip.address : null
    }
  }

  metadata = {
    # This sets the login user + public key
    ssh-keys = "${var.ssh_user}:${local.ssh_pub_key}"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    apt-get update
    apt-get install -y qemu-guest-agent || true
  EOT
}
