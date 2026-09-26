# Rutas de Amazon API Gateway

| Método | Ruta | Destino | Tipo | Autorización |
|---|---|---|---|---|
| POST | `/webhook/ventas` | Amazon SQS (`bodeganube-avisos-venta`) | Asíncrono | Ninguna (validación de firma del canal externo) |
| POST | `/auth/login` | `ms-auth` | Síncrono | Ninguna |
| GET | `/ordenes` | `ms-ordenes` | Síncrono | JWT (rol `COMERCIO`) |
| GET | `/ordenes/{id}` | `ms-ordenes` | Síncrono | JWT (rol `COMERCIO`) |
| GET | `/inventario/productos` | `ms-inventario` | Síncrono | JWT (rol `OPERARIO`, `COMERCIO`) |
| GET | `/picking/ordenes` | `ms-picking-service` | Síncrono | JWT (rol `OPERARIO`) |
| POST | `/picking/ordenes/{id}/despacho` | `ms-picking-service` | Síncrono | JWT (rol `OPERARIO`) |

## Cola muerta (DLQ)

Los mensajes de `bodeganube-avisos-venta` que agotan sus reintentos se redirigen a `bodeganube-avisos-venta-dlq` para revisión manual, en vez de perderse.
