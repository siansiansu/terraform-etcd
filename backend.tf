terraform {
  backend "gcs" {
    bucket = "stage-tfstate"
    prefix = "etcd-"
  }
}
