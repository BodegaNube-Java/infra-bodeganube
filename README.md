# infra-bodeganube

Infraestructura general de BodegaNube para desarrollo local y despliegue.

## Tecnologías

- Amazon API Gateway
- Amazon SQS (+ DLQ)
- AWS Lambda
- PostgreSQL
- MongoDB
- Docker / Docker Compose

## Arquitectura de seguridad y flujo

```
Comercio / Operario ──► API Gateway (JWT Authorizer) ──► ms-auth / ms-ordenes / ms-picking-service   (síncrono)
Canal externo (webhook) ──► API Gateway ──► Amazon SQS ──► AWS Lambda
                                                 │
                                                 ├─ 1. reserva stock ──► ms-inventario
                                                 │      (sin stock → confirma mensaje, no reintenta)
                                                 └─ 2. crea orden/dedup ──► ms-ordenes (solo si hubo stock)
                                                 │
                                                 ▼ (solo fallos técnicos)
                                                DLQ
```

## Servicios locales (docker-compose)

- `ms-auth` (8081)
- `ms-ordenes` (8082)
- `ms-inventario` (8083)
- `ms-picking-service` (8084)
- `postgres` (5432) — DB de `ms-auth`, `ms-ordenes`, `ms-inventario`
- `mongo` (27017) — DB de `ms-picking-service`

## API Gateway (configuración)

- Tipo: `HTTP API`
- Autorización: JWT Authorizer
- Rutas:
  - `POST /webhook/ventas` → integración con Amazon SQS
  - `/auth/*` → `ms-auth`
  - `/ordenes/*` → `ms-ordenes`
  - `/inventario/*` → `ms-inventario`
  - `/picking/*` → `ms-picking-service`

Ver [`apigateway/routes.md`](./apigateway/routes.md) para el detalle de rutas.

## Colas (Amazon SQS)

- `bodeganube-avisos-venta` — recibe los avisos de venta del webhook antes de ser procesados por la Lambda.
- `bodeganube-avisos-venta-dlq` — Dead Letter Queue, solo para mensajes que agotaron reintentos por un fallo **técnico** (no por falta de stock, que es un resultado de negocio que la Lambda confirma sin reintentar).

## Base de datos

- PostgreSQL: una base por microservicio (`ms_auth`, `ms_ordenes`, `ms_inventario`).
- MongoDB: base de `ms_picking`.

## Ejecución local

```bash
docker compose up -d
```
