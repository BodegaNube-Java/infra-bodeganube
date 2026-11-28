output "avisos_venta_queue_url" {
  description = "URL de la cola principal. El API Gateway la usa como destino del webhook."
  value       = aws_sqs_queue.avisos_venta.url
}

output "avisos_venta_dlq_url" {
  description = "URL de la DLQ, para revisar mensajes con fallo técnico."
  value       = aws_sqs_queue.avisos_venta_dlq.url
}

output "lambda_name" {
  value = aws_lambda_function.webhook.function_name
}
