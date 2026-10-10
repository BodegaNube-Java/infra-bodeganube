# BodegaNube — Guía para levantar el proyecto completo

BodegaNube es una plataforma de gestión de pedidos para bodegas, construida con 4 microservicios Spring Boot. Cada uno vive en su propio repositorio y tiene su propia base de datos.

Esta guía explica cómo levantar **todo el ecosistema en local** desde cero: clonar los repositorios, levantar las bases de datos, arrancar los microservicios en el orden correcto y probar el flujo completo.

> Si solo necesitas un microservicio, revisa el README de ese repositorio.

---

## Índice

1. [Mapa del ecosistema](#1-mapa-del-ecosistema)
2. [Requisitos previos](#2-requisitos-previos)
3. [Clonar los repositorios](#3-clonar-los-repositorios)
4. [Configurar variables de entorno](#4-configurar-variables-de-entorno)
5. [Levantar las bases de datos](#5-levantar-las-bases-de-datos)
6. [Levantar los microservicios](#6-levantar-los-microservicios)
7. [Verificar que todo está arriba](#7-verificar-que-todo-está-arriba)
8. [Probar el flujo completo](#8-probar-el-flujo-completo)
9. [Detener el proyecto](#9-detener-el-proyecto)
10. [Problemas frecuentes](#10-problemas-frecuentes)
11. [Limitaciones conocidas](#11-limitaciones-conocidas)
12. [Arquitectura en la nube (diseño)](#12-arquitectura-en-la-nube-diseño)

---

## 1. Mapa del ecosistema

| Microservicio | Repositorio | Puerto app | Base de datos | Puerto BD | Contenedor BD |
|---|---|---|---|---|---|
| Autenticación | [`ms-auth`](https://github.com/BodegaNube-Java/ms-auth) | **8081** | PostgreSQL `auth_db` | **5434** | `auth-db` |
| Órdenes | [`ms-ordenes`](https://github.com/BodegaNube-Java/ms-ordenes) | **8082** | PostgreSQL `ordenes_db` | **5432** | `bodeganube-postgres` |
| Inventario | [`ms-inventario`](https://github.com/BodegaNube-Java/ms-inventario) | **8083** | PostgreSQL `inventario_db` | **5435** | `inventario-db` |
| Picking y despacho | [`ms-picking-service`](https://github.com/BodegaNube-Java/ms-picking-service) | **8084** | MongoDB | **27017** | `picking-db` |

Comunicación entre servicios (lo que existe hoy en el código):

```
ms-ordenes ──POST /inventario/reservar──► ms-inventario
```

El resto de los servicios funciona de forma independiente.

Todos los servicios usan **Java 21**, **Spring Boot 4.1.1** y **Maven** (con el wrapper `mvnw` incluido).

---

## 2. Requisitos previos

| Herramienta | Versión | Para qué | Cómo comprobarla |
|---|---|---|---|
| Git | cualquiera reciente | Clonar los repositorios | `git --version` |
| JDK | **21** | Compilar y ejecutar los servicios | `java -version` |
| Docker Desktop | con Docker Compose v2 | Levantar las bases de datos | `docker compose version` |
| Postman o curl | — | Probar los endpoints | `curl --version` |

- No necesitas instalar Maven: cada repositorio trae `mvnw` (Linux/macOS/Git Bash) y `mvnw.cmd` (Windows).
- Docker Desktop debe estar **abierto** antes de seguir.
- Los puertos **8081–8084**, **5432**, **5434**, **5435** y **27017** deben estar libres. Si tienes un PostgreSQL instalado localmente usando el 5432, detenlo primero.

---

## 3. Clonar los repositorios

Clona todos los repositorios dentro de una misma carpeta:

```bash
mkdir bodeganube && cd bodeganube

git clone https://github.com/BodegaNube-Java/ms-auth.git
git clone https://github.com/BodegaNube-Java/ms-ordenes.git
git clone https://github.com/BodegaNube-Java/ms-inventario.git
git clone https://github.com/BodegaNube-Java/ms-picking-service.git
git clone https://github.com/BodegaNube-Java/infra-bodeganube.git
git clone https://github.com/BodegaNube-Java/docs.git
```

Estructura resultante:

```
bodeganube/
├── ms-auth/
├── ms-ordenes/
├── ms-inventario/
├── ms-picking-service/
├── infra-bodeganube/
└── docs/
```

---

## 4. Configurar variables de entorno

Los archivos `docker-compose.yml` de cada microservicio leen las credenciales de PostgreSQL desde un archivo `.env` ubicado en la raíz del repositorio. **Ese archivo no se sube a Git**: cada integrante lo crea en su máquina.

### 4.1 Crear los `.env`

Crea un archivo `.env` en **ms-auth**, **ms-inventario** y **ms-ordenes** con este contenido:

```env
DB_USER=postgres
DB_PASSWORD=tu_password
```

En **ms-auth** agrega además la clave para firmar los JWT (mínimo 32 caracteres):

```env
JWT_SECRET=una_clave_larga_de_al_menos_32_caracteres
```

### 4.2 Pasar las mismas credenciales a las aplicaciones

Spring Boot **no lee el archivo `.env`**: solo lo usa Docker Compose. Las aplicaciones toman `DB_USER`, `DB_PASSWORD` y `JWT_SECRET` desde las variables de entorno de la terminal y, si no existen, usan un valor por defecto definido en `application.properties`.

Por eso, **la contraseña del `.env` y la que recibe la aplicación deben ser la misma**. Tienes dos opciones:

- **Opción A (recomendada):** usa en el `.env` los mismos valores por defecto que trae `application.properties` (pídelos al equipo). Así no tienes que exportar nada.
- **Opción B:** exporta las variables en cada terminal antes de arrancar el servicio (paso 6).

```bash
# Git Bash / Linux / macOS
export DB_USER=postgres
export DB_PASSWORD=tu_password
```

```powershell
# PowerShell
$env:DB_USER = "postgres"
$env:DB_PASSWORD = "tu_password"
```

> **Importante:** si cambias la contraseña en el `.env` después de haber levantado la BD por primera vez, PostgreSQL seguirá usando la anterior, porque se guarda en el volumen. Ver [Problemas frecuentes](#10-problemas-frecuentes).

---

## 5. Levantar las bases de datos

Cada microservicio levanta su propia base de datos en un contenedor separado.

### 5.1 PostgreSQL de ms-auth (puerto 5434)

```bash
cd ms-auth
docker compose up -d
cd ..
```

### 5.2 PostgreSQL de ms-inventario (puerto 5435)

```bash
cd ms-inventario
docker compose up -d
cd ..
```

### 5.3 PostgreSQL de ms-ordenes (puerto 5432)

```bash
cd ms-ordenes
docker compose up -d
cd ..
```

Este contenedor ejecuta `init-db.sql` en el primer arranque y crea la base `ordenes_db`.

### 5.4 MongoDB de ms-picking-service (puerto 27017)

ms-picking-service no trae `docker-compose.yml`, así que su BD se levanta con un solo comando:

```bash
docker run -d --name picking-db -p 27017:27017 -v picking-mongodata:/data/db mongo:7
```

### 5.5 Comprobar

```bash
docker ps
```

Deberías ver 4 contenedores en estado `Up`: `auth-db`, `inventario-db`, `bodeganube-postgres` y `picking-db`. Los de PostgreSQL deben aparecer como `(healthy)` a los pocos segundos.

---

## 6. Levantar los microservicios

Abre **una terminal por microservicio** y respeta este orden. ms-ordenes depende de ms-inventario, por eso inventario va antes.

| Orden | Servicio | Por qué en este orden |
|---|---|---|
| 1 | ms-auth | Independiente |
| 2 | ms-inventario | ms-ordenes lo llama para reservar stock |
| 3 | ms-ordenes | Necesita que ms-inventario esté arriba |
| 4 | ms-picking-service | Independiente |

Si elegiste la **opción B** del paso 4.2, exporta `DB_USER` y `DB_PASSWORD` (y `JWT_SECRET` en ms-auth) en cada terminal antes de arrancar.

### Terminal 1: ms-auth

```bash
cd ms-auth
./mvnw spring-boot:run          # Windows: .\mvnw.cmd spring-boot:run
```

### Terminal 2: ms-inventario

```bash
cd ms-inventario
./mvnw spring-boot:run          # Windows: .\mvnw.cmd spring-boot:run
```

### Terminal 3: ms-ordenes

```bash
cd ms-ordenes
./mvnw spring-boot:run          # Windows: .\mvnw.cmd spring-boot:run
```

### Terminal 4: ms-picking-service

Este servicio **necesita** la variable `MONGODB_URI`:

```bash
# Git Bash / Linux / macOS
cd ms-picking-service
export MONGODB_URI=mongodb://localhost:27017/picking_db
./mvnw spring-boot:run
```

```powershell
# PowerShell
cd ms-picking-service
$env:MONGODB_URI = "mongodb://localhost:27017/picking_db"
.\mvnw.cmd spring-boot:run
```

Cada servicio está listo cuando la consola muestra `Started ...Application in X seconds`. La primera ejecución tarda más porque Maven descarga las dependencias.

### Alternativa: ejecutar el `.jar`

```bash
./mvnw clean package -DskipTests
java -jar target/<artifactId>-0.0.1-SNAPSHOT.jar
```

Por ejemplo: `target/ms-auth-0.0.1-SNAPSHOT.jar`. Se usa `-DskipTests` porque el test `contextLoads` necesita la base de datos levantada.

---

## 7. Verificar que todo está arriba

```bash
curl http://localhost:8081/actuator/health   # ms-auth
curl http://localhost:8082/actuator/health   # ms-ordenes
curl http://localhost:8083/actuator/health   # ms-inventario
curl http://localhost:8084/actuator/health   # ms-picking-service
```

Cada uno debe responder `{"status":"UP"}`.

> En **PowerShell** usa `curl.exe` en lugar de `curl`, porque `curl` es un alias de `Invoke-WebRequest`. Para los pasos con JSON del punto 8 es más cómodo usar **Git Bash** o **Postman**.

---

## 8. Probar el flujo completo

Este recorrido usa los 4 servicios en el orden de un pedido real. Guarda los valores que se indican (`TOKEN`, `PRODUCTO_ID`, `ORDEN_ID`, `COMERCIO_ID`), porque los pasos siguientes los usan.

### 8.1 Registrar un usuario (ms-auth)

```bash
curl -X POST http://localhost:8081/auth/registro \
  -H "Content-Type: application/json" \
  -d '{"email":"comercio@bodeganube.cl","password":"Password123"}'
```

Respuesta `201` con el `id`, el rol `COMERCIO` y el `comercioId`. **Guarda el `comercioId`.**

### 8.2 Iniciar sesión (ms-auth)

```bash
curl -X POST http://localhost:8081/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"comercio@bodeganube.cl","password":"Password123"}'
```

Respuesta `200` con el `token`. **Guárdalo como `TOKEN`.**

```bash
curl http://localhost:8081/auth/me -H "Authorization: Bearer TOKEN"
```

### 8.3 Crear un producto con stock (ms-inventario)

```bash
curl -X POST http://localhost:8083/catalogo/productos \
  -H "Content-Type: application/json" \
  -d '{"sku":"SKU-001","nombre":"Polera negra M","descripcion":"Algodon","precio":9990,"cantidadInicial":10}'
```

Respuesta `201` con el `id` del producto. **Guárdalo como `PRODUCTO_ID`.**

```bash
curl http://localhost:8083/catalogo            # lista productos activos
```

### 8.4 Crear una orden (ms-ordenes → ms-inventario)

```bash
curl -X POST http://localhost:8082/ordenes \
  -H "Content-Type: application/json" \
  -d '{"codigoPedido":"PED-1001","comercioId":"COMERCIO_ID","items":[{"productoId":"PRODUCTO_ID","cantidad":2}]}'
```

ms-ordenes guarda la orden y llama a `POST /inventario/reservar`:
- **Con stock:** responde `201` y la orden queda en `LISTA_PARA_PICKING`.
- **Sin stock:** responde `201` y la orden queda en `PENDIENTE_STOCK`.

**Guarda el `id` de la orden como `ORDEN_ID`.**

Comprueba que el stock quedó reservado (`cantidadDisponible` 8 y `cantidadReservada` 2):

```bash
curl http://localhost:8083/inventario/PRODUCTO_ID
curl http://localhost:8082/ordenes/disponibles
```

### 8.5 Registrar la orden en picking (ms-picking-service)

ms-ordenes **todavía no avisa** a picking, así que este paso se hace a mano:

```bash
curl -X POST http://localhost:8084/picking/ordenes \
  -H "Content-Type: application/json" \
  -d '{"ordenId":"ORDEN_ID","comercioId":"COMERCIO_ID"}'

curl http://localhost:8084/picking/ordenes     # la orden aparece como DISPONIBLE
```

### 8.6 Despachar y descontar stock

```bash
# Registra el despacho y genera el número de seguimiento (BN-XXXXXXXX)
curl -X POST http://localhost:8084/picking/ordenes/ORDEN_ID/despacho

# Confirma el descuento definitivo del stock reservado
curl -X PATCH http://localhost:8083/inventario/PRODUCTO_ID/descuento \
  -H "Content-Type: application/json" \
  -d '{"ordenId":"ORDEN_ID"}'
```

### 8.7 Otros endpoints útiles

| Servicio | Método y ruta | Uso |
|---|---|---|
| ms-inventario | `PUT /catalogo/productos/{id}` | Actualizar nombre, descripción y precio |
| ms-inventario | `DELETE /catalogo/productos/{id}` | Desactivar un producto (borrado lógico) |
| ms-inventario | `DELETE /inventario/reservas/{ordenId}` | Liberar el stock reservado de una orden |

---

## 9. Detener el proyecto

1. Detén cada microservicio con `Ctrl + C` en su terminal.
2. Detén las bases de datos:

```bash
cd ms-auth && docker compose down && cd ..
cd ms-inventario && docker compose down && cd ..
cd ms-ordenes && docker compose down && cd ..
docker stop picking-db
```

Para **borrar también los datos**, usa `docker compose down -v` y `docker rm -v picking-db && docker volume rm picking-mongodata`.

Para volver a levantar MongoDB más tarde, usa `docker start picking-db`.

---

## 10. Problemas frecuentes

| Síntoma | Causa probable | Solución |
|---|---|---|
| `password authentication failed for user "postgres"` | La contraseña del `.env` no coincide con la que usa la aplicación, o el volumen se creó con otra contraseña | Revisa el paso 4.2. Si cambiaste la contraseña, recrea la BD con `docker compose down -v` y `docker compose up -d` |
| `Connection refused` al puerto 5432, 5434 o 5435 | La BD no está levantada o sigue iniciando | `docker ps` y espera a que aparezca `(healthy)` |
| `port is already allocated` al levantar una BD | Otro contenedor o un PostgreSQL local ocupa ese puerto | `docker ps` para ver quién lo usa y detenlo. Si un PostgreSQL instalado en Windows ocupa el 5432, detén su servicio |
| `Port 808X was already in use` | Ese microservicio ya está corriendo en otra terminal | Ciérralo o mata el proceso que usa el puerto |
| ms-ordenes responde un error de comunicación con inventario | ms-inventario no está arriba, o el `productoId` no existe o no es un UUID | Levanta ms-inventario primero y usa un `PRODUCTO_ID` real |
| ms-picking-service no conecta a MongoDB | Falta `MONGODB_URI` o el contenedor `picking-db` está detenido | Exporta la variable (paso 6) y ejecuta `docker start picking-db` |
| Los datos de picking no aparecen en `picking_db` | Spring Boot 4 puede ignorar la propiedad antigua `spring.data.mongodb.uri` y conectarse a la base por defecto `test` | Revisa la base `test` en MongoDB. Si es el caso, ms-picking debe usar `spring.mongodb.uri` |
| Las órdenes desaparecen al reiniciar ms-ordenes | ms-ordenes usa `ddl-auto=create-drop` | Es el comportamiento actual (ver la sección 11) |
| `mvnw: Permission denied` (Linux/macOS) | El archivo no tiene permiso de ejecución | `chmod +x mvnw` |
| `release version 21 not supported` | Maven está usando un JDK distinto de 21 | Configura `JAVA_HOME` con el JDK 21 |

---

## 11. Limitaciones conocidas

Estado actual del código; conviene tenerlo presente durante la demo:

- **ms-ordenes no notifica a ms-picking-service.** Las órdenes con stock deben registrarse en picking a mano (paso 8.5).
- **ms-ordenes usa `ddl-auto=create-drop`.** Sus tablas se borran cada vez que se reinicia el servicio.
- **Solo ms-auth tiene Spring Security.** Los demás servicios no validan el JWT; en el diseño, esa validación la hará el API Gateway.
- **El `compose.yml` de este repositorio aún no sirve para levantar todo junto.** No pasa variables de entorno a los servicios, y ms-auth y ms-inventario apuntan a `127.0.0.1`, una dirección que no funciona dentro de un contenedor. Mientras no se ajuste, usa el procedimiento de esta guía.

---

## 12. Arquitectura en la nube (diseño)

> Esta capa está diseñada pero **todavía no implementada**. No es necesaria para levantar el proyecto en local.

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

- **API Gateway:** HTTP API con JWT Authorizer. Detalle de rutas en [`apigateway/routes.md`](./apigateway/routes.md).
- **Amazon SQS:**
  - `bodeganube-avisos-venta` recibe los avisos de venta del webhook.
  - `bodeganube-avisos-venta-dlq` recibe solo los mensajes que agotaron sus reintentos por un fallo técnico. La falta de stock es un resultado de negocio y no usa la DLQ.
- **AWS Lambda:** [`lambda-bodeganube-webhook`](https://github.com/BodegaNube-Java/lambda-bodeganube-webhook) orquesta la reserva de stock y la creación de la orden.

### Documentación relacionada

- Diagrama de arquitectura: [`docs/diagrama/BodegaNube_Arquitectura.puml`](https://github.com/BodegaNube-Java/docs/blob/main/diagrama/BodegaNube_Arquitectura.puml)
- README y `openapi.yaml` de cada microservicio, en sus repositorios.
