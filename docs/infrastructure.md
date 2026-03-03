# 🌍 Infrastructure Layer

## ☁️ Terraform (GCP)

Terraform provisions:

- 3 Compute Engine VMs
  - 1 Control Plane
  - 2 Worker Nodes
- Static External IP
- Firewall Rules:
  - 80 / 443 (Ingress)
  - Kafka NodePort
- VPC + networking configuration

Characteristics:

- Reproducible infrastructure
- Infrastructure as Code
- Versioned provisioning
- Minimal manual setup

---

## ⚙️ Ansible (Cluster Bootstrap)

Ansible configures:

- Container runtime (containerd)
- Kubernetes packages
- kubeadm init (control plane)
- Worker node join
- CNI installation (Cilium)
- Ingress controller
- Cert-manager
- StorageClass (Local Path Provisioner)

Cluster can be recreated using:
