locals {
  control_plane = google_compute_instance.k8s["k8s-cp-01"]

  workers = [
    google_compute_instance.k8s["k8s-worker-01"],
    google_compute_instance.k8s["k8s-worker-02"]
  ]
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"

  content = <<-EOT
[kube_control_plane]
k8s-cp-01 ansible_host=${local.control_plane.network_interface[0].access_config[0].nat_ip} private_ip=${local.control_plane.network_interface[0].network_ip}

[kube_workers]
k8s-worker-01 ansible_host=${local.workers[0].network_interface[0].access_config[0].nat_ip} private_ip=${local.workers[0].network_interface[0].network_ip}
k8s-worker-02 ansible_host=${local.workers[1].network_interface[0].access_config[0].nat_ip} private_ip=${local.workers[1].network_interface[0].network_ip}

[all:vars]
ansible_user=ubuntu
ansible_become=true
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOT
}
