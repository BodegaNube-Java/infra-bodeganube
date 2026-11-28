variable "region" {
  description = "Región de AWS (Academy opera en us-east-1)."
  type        = string
  default     = "us-east-1"
}

variable "lab_role_name" {
  description = "Rol existente en AWS Academy. No se pueden crear roles IAM, así que se reutiliza LabRole."
  type        = string
  default     = "LabRole"
}

variable "lambda_jar_path" {
  description = "Ruta al JAR generado por `mvn clean package` en el repo de la Lambda."
  type        = string
  default     = "../../lambda-bodeganube-webhook/target/lambda-bodeganube-webhook.jar"
}

variable "ms_inventario_url" {
  description = "URL base de ms-inventario accesible desde la Lambda."
  type        = string
}

variable "ms_ordenes_url" {
  description = "URL base de ms-ordenes accesible desde la Lambda."
  type        = string
}

variable "lambda_timeout_segundos" {
  description = "Timeout de la Lambda. La visibilidad de SQS debe ser al menos 6 veces este valor."
  type        = number
  default     = 30
}

variable "max_reintentos_sqs" {
  description = "Intentos antes de enviar el mensaje a la DLQ por fallo técnico."
  type        = number
  default     = 3
}
