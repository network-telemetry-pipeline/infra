output "vm_internal_ips" {
  value = {
    for name, inst in google_compute_instance.k8s :
    name => inst.network_interface[0].network_ip
  }
}

output "vm_external_ips" {
  value = {
    for name, inst in google_compute_instance.k8s :
    name => try(inst.network_interface[0].access_config[0].nat_ip, null)
  }
}