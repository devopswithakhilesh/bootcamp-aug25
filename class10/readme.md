# Dev

terraform init -backend-config=vars/dev.tfbackend

terraform plan -var-file=vars/dev.tfvars

terraform apply -var-file=vars/dev.tfvars

## destroy
terraform destroy -var-file=vars/dev.tfvars

On prod
terraform init -backend-config=vars/prod.tfbackend

terraform plan -var-file=vars/prod.tfvars

terraform apply -var-file=vars/prod.tfvars




docker run --rm williamyeh/hey \
  -n 10000 \    # Total requests
  -c 200 \      # Concurrent workers
  https://your-ecs-app-url.com/


  docker run --rm williamyeh/hey \
  -n 1000 \    
  -c 200 \      
  https://dev.studentportal.akhileshmishra.tech/login


  <!-- docker run fjudith/load-test -h [host] -c [number of clients] -r [number of requests] -->


  docker run fjudith/load-test \
   -h https://dev.studentportal.akhileshmishra.tech/login \
   -c 10 \
   -r 1000