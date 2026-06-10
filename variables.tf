variable "environment" {
  type        = string
  description = "The target deployment lifecycle environment (dev, staging, prod)."[cite: 1]
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)[cite: 1]
    error_message = "The environment variable must be one of: dev, staging, prod."[cite: 1]
  }
}

variable "client_name" {
  type        = string
  description = "The unique short identifier of the client being deployed (e.g., 'acmecorp')."
}

variable "deployment_timestamp" {
  type        = string
  description = "UTC tracking signature injected by CI/CD workflows to prevent perpetual state plan diffs."
  default     = "Manual-Run"
}

variable "connectivity_subscription_id" {
  type        = string
  description = "The target Azure Subscription UUID assigned for core Hub/Network topologies."
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.connectivity_subscription_id))[cite: 1]
    error_message = "The connectivity_subscription_id must match a valid UUID/GUID pattern."[cite: 1]
  }
}

variable "management_subscription_id" {
  type        = string
  description = "The target Azure Subscription UUID assigned for operations logging and SIEM metrics."[cite: 1, 4]
}

variable "workload_subscription_id" {
  type        = string
  description = "The target Azure Subscription UUID hosting client-specific workload Spoke VNets."[cite: 1, 4]
}
