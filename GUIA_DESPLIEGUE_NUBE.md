# GUÍA DE DESPLIEGUE EN LA NUBE: RAILWAY + VERCEL
## SISTEMA WEB DE MATRÍCULA UNIVERSITARIA - UNJBG

Esta guía detalla los pasos para poner el sistema en producción para que cualquier estudiante, compañero o docente pueda acceder desde cualquier dispositivo por internet.

---

### ARQUITECTURA DE DESPLIEGUE

```text
[ Vercel (Frontend React) ] ──> [ Railway (Backend PHP 8) ] ──> [ Railway (MySQL 8.0 InnoDB) ]
```

---

## FASE 1: SUBIR EL PROYECTO A GITHUB

Si aún no lo has subido o tienes cambios pendientes:

```bash
git add .
git commit -m "feat: configuracion para despliegue en Railway y Vercel"
git push origin main
```

---

## FASE 2: DESPLEGAR EN RAILWAY (BASE DE DATOS Y BACKEND)

### Paso 1: Crear la Base de Datos MySQL en Railway
1. Ingresa a [railway.app](https://railway.app) e inicia sesión con tu cuenta de GitHub.
2. Haz clic en **"New Project"** -> Selecciona **"Provision MySQL"**.
3. Espera 15 segundos a que el contenedor de MySQL se inicialice.

### Paso 2: Importar la Base de Datos con MySQL Workbench
1. Haz clic sobre la tarjeta de **MySQL** en Railway.
2. Ve a la pestaña **"Connect"** (o **"Variables"**).
3. En la sección **"Public Networking"**, copia los datos de conexión externa:
   * **Host:** (Ej. `roundhouse.proxy.rlwy.net`)
   * **Port:** (Ej. `45678`)
   * **Username:** `root`
   * **Password:** (Tu contraseña generada por Railway)
4. Abre **MySQL Workbench** en tu computadora:
   * Crea una nueva conexión con ese Host, Puerto, Usuario y Contraseña.
   * Conéctate.
   * Abre el archivo `database/database_completo.sql`.
   * Presiona el ícono del **Rayo (⚡ Execute)**.
   * *(Esto creará la base de datos `sistema_matricula` con todas las 18 tablas, Stored Procedures, Funciones y datos iniciales).*

### Paso 3: Desplegar el Backend PHP en Railway
1. En el mismo proyecto de Railway, haz clic en **"+ New"** -> **"GitHub Repo"**.
2. Selecciona tu repositorio del sistema de matrícula.
3. Una vez creado el servicio, haz clic sobre él y ve a **"Settings"**:
   * En **"Root Directory"**, escribe: `/backend`
   * *(Railway detectará automáticamente el archivo `Dockerfile` optimizado con PHP 8 y Apache).*
4. En **"Networking"**:
   * Haz clic en **"Generate Domain"** (Te dará una URL pública como `https://backend-production-xxxx.up.railway.app`).
5. En **"Variables"**:
   * Haz clic en **"New Variable"** -> **"Add Reference"** y selecciona las variables de tu MySQL (`MYSQLHOST`, `MYSQLPORT`, `MYSQLUSER`, `MYSQLPASSWORD`, `MYSQLDATABASE`).
   * Agrega además la variable:
     * `MYSQLDATABASE` = `sistema_matricula`
6. Railway compilará el contenedor y en 1 minuto tu Backend estará activo y conectado a MySQL.

> **Prueba de verificación:** Abre en tu navegador `https://tu-backend.up.railway.app/api/matricula/catalogo.php`. Deberás ver el JSON con los cursos.

---

## FASE 3: DESPLEGAR EL FRONTEND EN VERCEL

1. Ingresa a [vercel.com](https://vercel.com) e inicia sesión con GitHub.
2. Haz clic en **"Add New..."** -> **"Project"**.
3. Busca tu repositorio `sistema-matricula` e impórtalo.
4. En la pantalla de configuración:
   * **Project Name:** `sistema-matricula-unjbg` (o el que gustes).
   * **Framework Preset:** `Vite` (se detecta solo).
   * **Root Directory:** Haz clic en *Edit* y selecciona la carpeta `frontend`.
5. En la sección **"Environment Variables"**:
   * **Name:** `VITE_API_URL`
   * **Value:** `https://tu-backend.up.railway.app/api` *(La URL que te generó Railway + `/api` al final)*.
6. Haz clic en **"Deploy"**.
7. En menos de 45 segundos, Vercel te entregará la URL final:  
   `https://sistema-matricula-unjbg.vercel.app`

---

## ¡LISTO!
Cualquier persona desde cualquier celular o computadora con acceso a internet podrá:
1. Iniciar sesión con los usuarios de prueba (`2023-119010` / `123456`).
2. Pasar por la cola virtual en tiempo real.
3. Reservar vacantes con bloqueo pesimista en MySQL InnoDB.
4. Generar y descargar su Ficha Oficial de Matrícula en PDF.
