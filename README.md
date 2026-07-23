# Aromas Store

Sistema web academico para una empresa ficticia de venta de perfumes y productos aromaticos.

## Estructura del proyecto

```txt
aromas-store/
  backend/          API REST con Node.js, Express, Prisma y PostgreSQL
  frontend/         Aplicacion Flutter Web
  docs/             Bitacora, documentacion API, pruebas y criterios UX/IHC
  docker-compose.yml
```

## Stack tecnico

- Frontend: Flutter Web + Dart
- Backend: Node.js + Express
- Base de datos: PostgreSQL
- ORM: Prisma
- Autenticacion: JWT
- Seguridad: bcrypt para contrasenas
- Documentacion API: Swagger
- Contenedores: Docker Compose

## Requisitos previos

- Docker Desktop
- Node.js
- Flutter SDK
- Git

## Levantar base de datos

Desde la raiz del proyecto:

```powershell
docker compose up -d
```

PostgreSQL queda disponible en:

```txt
localhost:5433
Base: aromas_store
Usuario: aromas_user
Password: aromas_pass
```

## Configurar backend

Entrar al backend:

```powershell
cd backend
copy .env.example .env
npm install
npm run prisma:migrate
npm run seed
npm run dev
```

API local:

```txt
http://localhost:3000/api
```

Swagger:

```txt
http://localhost:3000/api/docs
```

Credenciales de prueba:

```txt
Correo: admin@aromasstore.com
Contrasena: Admin12345
Rol: Administrador
```

## Levantar frontend

Entrar al frontend:

```powershell
cd frontend
C:\javilar\flutter\bin\flutter.bat pub get
C:\javilar\flutter\bin\flutter.bat run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Frontend local:

```txt
http://127.0.0.1:8080
```

## Documentacion principal

- `docs/proyecto/BITACORA_PROYECTO.md`
- `docs/backend/API_DOCUMENTACION.md`
- `docs/backend/PRUEBAS_BACKEND.md`
- `docs/ux-ui/GUIA_DISENO_IHC_UX_UI.md`
- `docs/frontend/MEJORAS_DISENO_FRONTEND_AS040.md`

## Estado actual

- Backend modular implementado.
- Base de datos PostgreSQL con Prisma.
- Endpoints principales documentados en Swagger.
- Frontend Flutter Web conectado al catalogo publico.
- Bitacora de avances organizada por RF y RNF.
