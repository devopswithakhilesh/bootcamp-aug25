locals {

 lambda_info = [
    {
        name = "lambda1",
        path = "../lambdas/lambda1",
        handler = "main.lambda_handler",
        runtime = "python3.13"

        environments_variables = {
            DB_NAME     = "prod_db"
            LAMBDA_USER = "lambda_user"
            LOG_LEVEL   = "info"
        }
        # layers = "layer2"
         layers = ["layer1", "layer2"]
    },
    {
        name = "lambda2",
        path = "../lambdas/lambda2",
        handler = "main.lambda_handler",
        runtime = "python3.13"
        environments_variables = {
            DB_NAME     = "prod_db"
            LAMBDA_USER = "lambda_user"
            LOG_LEVEL   = "info"
        }
        # layers = "layer3"
        layers = ["layer1", "layer2"]
    },
    {
        name = "lambda3",
        path = "../lambdas/lambda3",
        handler = "main.lambda_handler",
        runtime = "python3.13"
        environments_variables = {
            DB_NAME     = "prod_db"
            LAMBDA_USER = "lambda_user"
            LOG_LEVEL   = "info"
        }
        # layers = "layer1"
         layers = ["layer2", "layer3"]
    }
 ]

  layers = [
    {
      name                = "layer1",
      path              = "../layers/layer1",
      compatible_runtimes = ["python3.13", "python3.12"]
    },
    {
      name                = "layer2",
      path              = "../layers/layer2",
      compatible_runtimes = ["python3.13", "python3.11", "python3.12"]
    },

    {
      name                = "layer3",
      path              = "../layers/layer3",
      compatible_runtimes = ["python3.13", "python3.11", "python3.12"]
    }
  ]

  lambda_layers = { for layer in local.layers : layer.name => layer }
  lambda_info_map = { for lambda in local.lambda_info : lambda.name => lambda }
}