# Rutas de Amazon API Gateway

| Método | Ruta | Destino | Autorización |
|---|---|---|---|
| POST | `/webhook/ventas` | Amazon SQS (`bodeganube-avisos-venta`) | Ninguna (validación de firma del canal externo) |
| POST | `/auth/login` | `ms-auth` | Ninguna |
| GET | `/ordenes` | `ms-ordenes` | JWT (rol `COMERCIO`) |
| GET | `/ordenes/{id}` | `ms-ordenes` | JWT (rol `COMERCIO`) |
| GET | `/inventario/productos` | `ms-inventario` | JWT (rol `OPERARIO`, `COMERCIO`) |
| GET | `/picking/ordenes` | `ms-picking-service` | JWT (rol `OPERARIO`) |
| POST | `/picking/ordenes/{id}/despacho` | `ms-picking-service` | JWT (rol `OPERARIO`) |
