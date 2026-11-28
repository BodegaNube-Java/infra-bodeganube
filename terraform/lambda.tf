data "aws_iam_role" "lab" {
  name = var.lab_role_name
}

resource "aws_lambda_function" "webhook" {
  function_name    = "lambda-bodeganube-webhook"
  role             = data.aws_iam_role.lab.arn
  runtime          = "java21"
  handler          = "cl.duoc.lambda_webhook.WebhookProcesarHandler::handleRequest"
  filename         = var.lambda_jar_path
  source_code_hash = filebase64sha256(var.lambda_jar_path)
  memory_size      = 512
  timeout          = var.lambda_timeout_segundos

  environment {
    variables = {
      MS_INVENTARIO_URL = var.ms_inventario_url
      MS_ORDENES_URL    = var.ms_ordenes_url
    }
  }
}

# Trigger SQS -> Lambda. ReportBatchItemFailures permite reintentar solo los mensajes con fallo técnico.
resource "aws_lambda_event_source_mapping" "avisos_venta" {
  event_source_arn        = aws_sqs_queue.avisos_venta.arn
  function_name           = aws_lambda_function.webhook.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
}
