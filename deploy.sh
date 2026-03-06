#!/usr/bin/env bash
set -euo pipefail

TERRAFORM_DIR="$(cd "$(dirname "$0")/terraform" && pwd)"
ANSIBLE_DIR="$(cd "$(dirname "$0")/ansible" && pwd)"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo "[$(date +%H:%M:%S)] $*"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

check_deps() {
  local missing=()
  for cmd in terraform ansible-playbook gcloud; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done
  [[ ${#missing[@]} -eq 0 ]] || die "Missing required tools: ${missing[*]}"
}

# ---------------------------------------------------------------------------
# Phases
# ---------------------------------------------------------------------------
phase_terraform() {
  log "=== Terraform: provisioning GCP infrastructure ==="
  cd "$TERRAFORM_DIR"

  terraform init -input=false
  terraform validate

  log "Planning..."
  terraform plan -input=false -out=tfplan

  log "Applying..."
  terraform apply -input=false tfplan
  rm -f tfplan

  log "Terraform complete. Inventory written to ansible/inventory.ini"
}

phase_wait_ssh() {
  log "=== Waiting for VMs to become reachable via SSH ==="
  local inventory="$ANSIBLE_DIR/inventory.ini"

  [[ -f "$inventory" ]] || die "Ansible inventory not found: $inventory"

  local hosts
  hosts=$(grep -oP 'ansible_host=\K[^\s]+' "$inventory")

  local timeout=120
  local interval=5
  local elapsed=0

  for host in $hosts; do
    log "Waiting for $host..."
    while ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@"$host" true 2>/dev/null; do
      sleep "$interval"
      elapsed=$((elapsed + interval))
      [[ $elapsed -lt $timeout ]] || die "Timed out waiting for $host"
    done
    log "$host is reachable."
    elapsed=0
  done
}

phase_ansible() {
  log "=== Ansible: bootstrapping Kubernetes cluster and platform ==="
  cd "$ANSIBLE_DIR"

  ansible-playbook site.yml
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $(basename "$0") [PHASE]

Phases (run in order by default):
  terraform   Provision GCP VMs with Terraform
  ansible     Bootstrap the cluster and deploy platform services
  all         Run all phases (default)

Options:
  -h, --help  Show this help
EOF
}

PHASE="${1:-all}"

case "$PHASE" in
  -h|--help) usage; exit 0 ;;
  terraform|ansible|all) ;;
  *) die "Unknown phase: $PHASE. Run with --help for usage." ;;
esac

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
check_deps

case "$PHASE" in
  terraform)
    phase_terraform
    ;;
  ansible)
    phase_ansible
    ;;
  all)
    phase_terraform
    phase_wait_ssh
    phase_ansible
    ;;
esac

log "=== Deployment complete ==="
