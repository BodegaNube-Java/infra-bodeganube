# DLQ: solo llegan mensajes que agotaron reintentos por fallo técnico.
# La falta de stock es un resultado de negocio y no pasa por aquí.
resource "aws_sqs_queue" "avisos_venta_dlq" {
  name                      = "bodeganube-avisos-venta-dlq"
  message_retention_seconds = 1209600 # 14 días, máximo permitido
}

resource "aws_sqs_queue" "avisos_venta" {
  name                       = "bodeganube-avisos-venta"
  visibility_timeout_seconds = 6 * var.lambda_timeout_segundos
  receive_wait_time_seconds  = 20 # long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.avisos_venta_dlq.arn
    maxReceiveCount     = var.max_reintentos_sqs
  })
}
