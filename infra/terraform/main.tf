locals {
  nodes = [
    { name = "k8s-cp-01",     ip = "10.50.0.21", role = "control-plane" },
    { name = "k8s-worker-01", ip = "10.50.0.22", role = "worker" },
    { name = "k8s-worker-02", ip = "10.50.0.23", role = "worker" },
  ]

  ssh_pub_key = trimspace(file(var.ssh_public_key_path))
}

resource "google_compute_network" "vpc" {
  name                    = "ml-lab-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "ml-lab-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Firewall: allow SSH only from admin CIDR
resource "google_compute_firewall" "ssh" {
  name    = "ml-lab-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.admin_cidr]
  target_tags   = ["ml-lab"]
}

# Firewall: internal cluster traffic within subnet
resource "google_compute_firewall" "internal" {
  name    = "ml-lab-allow-internal"
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
  target_tags   = ["ml-lab"]
}

# Optional: allow NodePort range internally only
resource "google_compute_firewall" "nodeport_internal" {
  name    = "ml-lab-nodeport-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["ml-lab"]
}

resource "google_compute_firewall" "ingress_nodeports" {
  name    = "ml-lab-allow-ingress-nodeports"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["30080", "30443"]
  }

  # Restrict to your current public IP/CIDR (recommended)
  source_ranges = [var.admin_cidr]

  # Must match your instances' tags
  target_tags = ["ml-lab"]
}

resource "google_compute_instance" "k8s" {
  for_each     = { for n in local.nodes : n.name => n }
  name         = each.value.name
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["ml-lab", each.value.role]

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

    # If you want public IPs for SSH directly, uncomment this:
    access_config {}
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
