# infra-bodeganube

Infraestructura general de BodegaNube para desarrollo local y despliegue.

## Tecnologías

- Amazon API Gateway
- Amazon SQS
- AWS Lambda
- PostgreSQL
- Docker / Docker Compose

## Arquitectura de seguridad

```
Cliente/Operario/Comercio → API Gateway (JWT Authorizer) → Microservicio de dominio
Canal externo (webhook)   → API Gateway → Amazon SQS → AWS Lambda → ms-ordenes / ms-inventario
```

## Servicios locales (docker-compose)

- `ms-auth` (8081)
- `ms-ordenes` (8082)
- `ms-inventario` (8083)
- `ms-picking-service` (8084)
- `postgres` (5432)

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

## Base de datos

PostgreSQL, una base de datos por microservicio (`ms_auth`, `ms_ordenes`, `ms_inventario`, `ms_picking`).

## Ejecución local

```bash
docker compose up -d
```
