# terraform veuson with aws version
terraform {
  required_version = "= 1.8.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    # version = "6.0.0" # exact version
    #   version = ">= 6.22.0" # will patch the version to latest 6.x.x 
    # version = "~> 6.22.0" # Patch version updates allowed, so any 6.0.x version
    version = "> 6.22.0"
    }
  }
}


# ">= 6.0.0 -> 6.1.0, 6.2.0, 6.3.0 ... but not 7.0.0
# "~= 6.0.0" -> 6.0.1, 6.0.2, 6.0.3. but not hgher than 6.1