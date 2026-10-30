provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure

  # Authentication can be provided via variables or environment variables:
  # PROXMOX_VE_API_TOKEN or PROXMOX_VE_USERNAME + PROXMOX_VE_PASSWORD
  api_token = var.proxmox_api_token
}
