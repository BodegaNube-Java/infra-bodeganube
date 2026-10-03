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

## Orquestación asíncrona (Lambda)

1. `AWS Lambda` reserva stock en `ms-inventario`.
2. Si hay stock, `AWS Lambda` crea la orden en `ms-ordenes` (evitando duplicados).
3. Si no hay stock, la Lambda confirma el mensaje SQS como procesado (resultado de negocio, no reintenta).

## Cola muerta (DLQ)

Los mensajes de `bodeganube-avisos-venta` que agotan sus reintentos por un **fallo técnico** (timeout, servicio caído, etc.) se redirigen a `bodeganube-avisos-venta-dlq` para revisión manual. La falta de stock **no** genera reintentos ni usa la DLQ: es un resultado de negocio normal.
