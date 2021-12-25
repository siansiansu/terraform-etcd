# DD-team address block
data "google_compute_address" "etcd_asia_east1_external_ip" {
  count   = var.replica
  project = var.project
  region  = var.region
  name    = "${var.external_ip_name}-${count.index + 1}"
}

data "google_compute_address" "etcd_asia_east1_internal_ip" {
  count   = var.replica
  project = var.project
  region  = var.region
  name    = "${var.internal_ip_name}-${count.index + 1}"
}

resource "google_compute_instance" "etcd-cluster" {
  count                   = var.replica
  project                 = var.project
  name                    = "${var.etcd_name}-${count.index + 1}"
  machine_type            = var.machine_type
  zone                    = var.zones[count.index]
  min_cpu_platform        = ""
  metadata_startup_script = file("startup.sh")

  boot_disk {
    initialize_params {
      image = var.initialize_params_image
      size  = var.initialize_params_size
      type  = var.initialize_params_type
    }
  }

  network_interface {
    network    = var.network
    network_ip = element(data.google_compute_address.etcd_asia_east1_internal_ip.*.address, count.index)

    access_config {
      # resource is created at /addresses/compute_address.tf
      nat_ip = element(data.google_compute_address.etcd_asia_east1_external_ip.*.address, count.index)
    }
  }

  # labels are used to searching etcd nodes in startup.sh
  labels = var.labels

  service_account {
    # resource is created at /iam/iam_binding.tf
    email  = var.etcd_svc_account
    scopes = var.scopes
  }

  tags = var.tags
}
