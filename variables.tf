variable "project" {
  type        = string
  description = "project name"
  default     = ""
}

variable "region" {
  type        = string
  description = "region name"
  default     = ""
}

variable "network" {
  type        = string
  description = "network name"
  default     = ""
}

variable "scopes" {
  type        = list(string)
  description = "scopes for etcd instances"

  default = [
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/trace.append",
    "https://www.googleapis.com/auth/compute",
  ]
}

variable "tags" {
  type        = list(string)
  description = ""

  default = [
    "etcd",
  ]
}

variable "labels" {
  type        = map(string)
  description = "label list"
  default = {
    service = "etcd-cluster"
    env     = "stage"
    for     = "gp"
  }
}

variable "etcd_name" {
  type        = string
  description = ""
  default     = ""
}

variable "machine_type" {
  type        = string
  description = ""
  default     = "n1-standard-4"
}

variable "etcd_svc_account" {
  type        = string
  description = "service account"
  default     = "etcd-cluster@<service_account>.iam.gserviceaccount.com"
}

variable "initialize_params_image" {
  type        = string
  description = "initialize_params image name"
  default     = "ubuntu-os-cloud/ubuntu-1804-lts"
}

variable "initialize_params_size" {
  type        = number
  description = "initialize_params size"
  default     = 100
}

variable "initialize_params_type" {
  type        = string
  description = "initialize_params type name"
  default     = "pd-ssd"
}

variable "external_ip_name" {
  type        = string
  description = "external IP resource name"
  default     = ""
}

variable "internal_ip_name" {
  type        = string
  description = "internal IP resource name"
  default     = ""
}

variable "replica" {
  type        = number
  description = "number of replica"
  default     = 1
}

variable "zones" {
  type        = list(string)
  description = "zone list"
  default     = []
}

