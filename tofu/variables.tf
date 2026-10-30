variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint URL (e.g. https://10.10.11.53:8006/)"
  type        = string
  default     = "https://10.10.11.53:8006/"
}

variable "proxmox_insecure" {
  description = "Disable TLS verification for self-signed Proxmox certificates"
  type        = bool
  default     = true
}

variable "proxmox_api_token" {
  description = "Proxmox API token (format: USER@REALM!TOKENID=UUID). Defaults to PROXMOX_VE_API_TOKEN environment variable if null."
  type        = string
  default     = null
  sensitive   = true
}

variable "pve_target_node" {
  description = "Target Proxmox node for Synology DSM VM"
  type        = string
  default     = "pve-rog"
}

variable "synology_vm_id" {
  description = "VM ID for Synology DSM"
  type        = number
  default     = 210
}
