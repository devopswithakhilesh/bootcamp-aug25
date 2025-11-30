locals {
  
  lambda_info = [
{
    name    = "cloud-report"
    handler = "main.handler" # filename.lambda_trigger_function
    path = "../functions/cloud_report"
    runtime = "python3.12"
},
{
    name    = "pandas-usecase"
    handler = "main.handler" # filename.lambda_trigger_function
    path = "../functions/panda_usecase"
    runtime = "python3.12"
},
{
    name    = "new-lambda"
    handler = "main.lambda_handler" # filename.lambda_trigger_function
    path = "../functions/new_lambda"
    runtime = "python3.12"
}

  ]

  lambda_info_map = {
    for lambda in local.lambda_info : lambda.name => lambda
  }




}

# output "lambda_tst" {
#   value = local.lambda_info_map
  
# }


