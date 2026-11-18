variable "farm_id" {
  description = "Farm identifier for identity attributes and governance tags."
  type        = string
  validation {
    condition     = can(regex("^[A-Z]{3}-F[0-9]{3,6}$", var.farm_id))
    error_message = "Use a farm ID such as CAU-F001."
  }
}

variable "thing_name" {
  description = "Root-built IoT thing name and MQTT ClientId."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,128}$", var.thing_name))
    error_message = "Use a valid exact IoT thing name."
  }
}

variable "policy_name" {
  description = "Existing farm-scoped policy from the ingest module."
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{1,128}$", var.policy_name))
    error_message = "Use a specific IoT policy name."
  }
}

variable "certificate_csr" {
  description = "Public CSR generated on the device; private key never enters Terraform."
  type        = string
  validation {
    condition     = can(regex("(?s)^-----BEGIN CERTIFICATE REQUEST-----\n[A-Za-z0-9+/=\r\n]+\n-----END CERTIFICATE REQUEST-----\\s*$", trimspace(var.certificate_csr)))
    error_message = "Supply a PEM CSR, never a private key or an empty request."
  }
}

variable "certificate_active" {
  description = "Set false to deactivate the certificate while retaining its attachments."
  type        = bool
  default     = false
  validation {
    condition     = var.certificate_active != null
    error_message = "Specify true or false."
  }
}

variable "additional_tags" {
  description = "Additional tags; identity and Name tags are owned by the module."
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for k, v in var.additional_tags : length(k) > 0 && length(v) > 0])
    error_message = "Tag keys and values must not be empty."
  }
}
