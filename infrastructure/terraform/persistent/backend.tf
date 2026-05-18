terraform {
  backend "s3" {
    bucket       = "devops-project-tfstate-486336528116"
    key          = "persistent/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
