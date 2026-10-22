# ARQUITECTURA DEL SISTEMA Y DISTRIBUCIÓN DEL CÓDIGO
## SISTEMA WEB DE MATRÍCULA UNIVERSITARIA - UNJBG

**Documentos de Referencia:**
* Requerimientos del Sistema: [REQUERIMIENTOS.md](REQUERIMIENTOS.md)
* Documentación Técnica de BD: [DOCUMENTACION_BD.md](DOCUMENTACION_BD.md)
* Casos de Uso: [diagramas/casos-de-uso/ESPECIFICACION_CASOS_DE_USO.md](diagramas/casos-de-uso/ESPECIFICACION_CASOS_DE_USO.md)

---

## 1. VISIÓN GENERAL DE LA ARQUITECTURA

El sistema implementa una **Arquitectura Cliente-Servidor Desacoplada (Decoupled SPA / REST API)**:

```
[ Cliente Web (Navegador) ]
          │
          ▼
   React SPA (Vite)  ──(HTTP / JSON Fetch con CORS)──►  Backend PHP 8 Puro (Apache / XAMPP)
                                                                 │
                                                       (Conexión PDO / SQL)
                                                                 ▼
                                                        MySQL 8.0 (InnoDB)
                                                    (Tablas 3FN + Stored Procedures)
```

### Principios de Diseño:
1. **Frontend (React + Vite):** Interfaz Single Page Application (SPA) modular, rápida y responsiva, encargada del temporizador de 5 minutos, la sala de espera asíncrona y la grilla de horarios interactiva.
2. **Backend (PHP 8 Puro con PDO):** **Cero frameworks** (sin Laravel, sin Symfony). Consiste en micro-controladores/endpoints REST atómicos que procesan peticiones, manejan sesiones y delegan la lógica crítica a los Stored Procedures de MySQL.
3. **Capa de Persistencia (MySQL 8.0 InnoDB):** Base de datos normalizada en 3FN que garantiza consistencia ACID, bloqueos pesimistas a nivel de fila (`SELECT ... FOR UPDATE`) para evitar sobrecupos y transacciones atómicas.

---

## 2. ÁRBOL COMPLETO DE DIRECTORIOS DEL PROYECTO

```text
sistema-matricula/
│
├── database/                          # [15 PUNTOS] Scripts SQL para entrega al docente
│   ├── 01_schema.sql                  # Estructura DDL de las 18 tablas (InnoDB, 3FN)
│   ├── 02_stored_procedures.sql       # Procedimientos almacenados (bloqueo pesimista, matrícula)
│   ├── 03_functions.sql               # Funciones determinísticas (cronograma, cruces)
│   ├── 04_views.sql                   # Vistas consolidadas (vw_ficha_matricula)
│   ├── 05_seeds.sql                   # Datos iniciales de prueba (carreras, cursos, alumnos)
│   ├── database_completo.sql          # Script consolidado todo-en-uno exportado de MySQL
│   └── pruebas_mysql.txt              # [EXIGIDO POR DOCENTE] Comandos TXT para probar en MySQL
│
├── backend/                           # Backend en PHP 8 Puro (Cero frameworks)
│   ├── config/
│   │   ├── database.php               # Conexión PDO Singleton a MySQL
│   │   └── cors.php                   # Cabeceras CORS (Allow-Origin) y Content-Type JSON
│   ├── helpers/
│   │   ├── response.php               # Funciones json_response(), json_error()
│   │   ├── auth_middleware.php        # Verificación de token/sesión en peticiones protegidas
│   │   └── validator.php              # Sanitización y validación de tipos y formatos
│   ├── api/                           # Endpoints RESTful (Controladores de acción única)
│   │   ├── auth/
│   │   │   ├── login.php              # RF-01 y RF-04: Autenticación y cronograma
│   │   │   ├── logout.php             # RF-02: Cierre de sesión e invalidación de token
│   │   │   └── recuperar.php          # RF-03: Restablecimiento de contraseña
│   │   ├── portafolio/
│   │   │   ├── subir.php              # RF-05: Carga física de JPG/PNG y registro en BD
│   │   │   └── estado.php             # RF-06: Verificación de los 4 documentos
│   │   ├── cola/
│   │   │   ├── ingresar.php           # RF-07: Asignación de ticket secuencial en cola
│   │   │   └── posicion.php           # RF-08 y RF-09: Polling de turno y cuenta regresiva
│   │   ├── matricula/
│   │   │   ├── perfil.php             # RF-10: Datos académicos y sede del alumno
│   │   │   ├── creditos.php           # RF-11 y RF-12: SP para clasificar y tope de créditos
│   │   │   ├── catalogo.php           # RF-13: Listado de asignaturas, grupos A/B y docentes
│   │   │   ├── agregar_curso.php      # RF-14: SP con SELECT ... FOR UPDATE (Bloqueo pesimista)
│   │   │   ├── retirar_curso.php      # RF-15: Retiro de proforma y restitución de vacante
│   │   │   ├── proforma.php           # RF-16 y RF-17: Grilla tentativa y validación de cruces
│   │   │   ├── pago_estado.php        # RF-18: Verificación de estado de pago de matrícula
│   │   │   └── confirmar.php          # RF-19 y RF-20: Transacción PROFORMA -> CONFIRMADA
│   │   └── reportes/
│   │       └── generar_ficha.php      # RF-21: Emisión y descarga de Ficha Oficial en PDF
│   └── uploads/                       # Directorio de almacenamiento de archivos subidos
│       └── portafolio/                # Imágenes de DNI, Foto, Salud y Constancia (.jpg, .png)
│
├── frontend/                          # Frontend SPA en React 18 / Vite
│   ├── public/
│   │   └── favicon.ico                # Ícono institucional UNJBG
│   ├── src/
│   │   ├── assets/                    # Imágenes estáticas, logos institucionales
│   │   ├── components/                # Componentes reutilizables de UI
│   │   │   ├── Navbar.jsx             # Barra superior con datos del estudiante y logout
│   │   │   ├── CountdownTimer.jsx     # Temporizador regresivo de 5 minutos
│   │   │   ├── QueueCard.jsx          # Tarjeta visual con número de turno en sala de espera
│   │   │   ├── ScheduleGrid.jsx       # Grilla semanal interactiva de horarios
│   │   │   ├── CourseCard.jsx         # Tarjeta de curso con botón Grupo A y Grupo B
│   │   │   ├── ProformaTable.jsx      # Tabla resumen de asignaturas seleccionadas
│   │   │   └── ConflictAlert.jsx      # Alerta modal y visual de cruce de horarios
│   │   ├── pages/                     # Vistas principales del flujo de matrícula
│   │   │   ├── LoginPage.jsx          # Pantalla de inicio de sesión
│   │   │   ├── PortafolioPage.jsx     # Formulario de carga de 4 documentos para ingresantes
│   │   │   ├── WaitingRoomPage.jsx    # Sala de espera / Cola virtual interactiva
│   │   │   ├── MatriculaPage.jsx      # Panel maestro: Selección de asignaturas y grilla
│   │   │   └── ConfirmacionPage.jsx   # Vista de éxito y botón de descarga de Ficha PDF
│   │   ├── services/
│   │   │   └── api.js                 # Cliente Axios / Fetch unificado con base URL
│   │   ├── context/
│   │   │   └── AuthContext.jsx        # Estado global de usuario, token y temporizador
│   │   ├── App.jsx                    # Enrutador principal (React Router DOM)
│   │   ├── main.jsx                   # Punto de entrada de React
│   │   └── index.css                  # Estilos globales y paleta de colores institucional
│   ├── index.html
│   ├── package.json
│   └── vite.config.js
│
├── diagramas/                         # Modelado del sistema entregado
│   ├── casos-de-uso/                  # PUML, especificación e imágenes de Casos de Uso
│   │   ├── ESPECIFICACION_CASOS_DE_USO.md
│   │   ├── *.puml
│   │   └── imagenes/*.png
│   └── secuencia/                     # PUML e imágenes de Diagramas de Secuencia
│       ├── *.puml
│       └── imagenes/*.png
│
├── REQUERIMIENTOS.md                  # Especificación funcional formal
├── DOCUMENTACION_BD.md                # Diccionario de datos y diagrama ER (3FN)
└── ARQUITECTURA_Y_ESTRUCTURA.md       # Este documento
```

---

## 3. DETALLE DE RESPONSABILIDADES: BACKEND (PHP PURO + PDO)

Cada archivo en `backend/api/` sigue el principio de **Responsabilidad Única (SRP)**:

### 3.1. `backend/config/database.php`
* Implementa una clase `Database` con patrón **Singleton**.
* Instancia un único objeto `PDO` hacia MySQL con las banderas:
  * `PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION` (Manejo de errores por excepciones).
  * `PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC` (Retorno de arreglos asociativos).
  * `PDO::ATTR_EMULATE_PREPARES => false` (Prepared statements nativos en el motor MySQL).

### 3.2. `backend/config/cors.php`
* Incluido al inicio de todos los endpoints.
* Configura los encabezados HTTP para permitir la comunicación cruzada desde `http://localhost:5173` (React Vite) hacia `http://localhost/sistema-matricula/backend/`:
  ```php
  header("Access-Control-Allow-Origin: *");
  header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
  header("Access-Control-Allow-Headers: Content-Type, Authorization");
  header("Content-Type: application/json; charset=UTF-8");
  if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit(0); }
  ```

### 3.3. `backend/api/matricula/agregar_curso.php` (Punto Clave: Bloqueo Pesimista)
* Recibe vía POST `{ id_proforma, id_seccion }`.
* Llama al Stored Procedure:
  ```php
  $stmt = $pdo->prepare("CALL sp_matricular_curso(:proforma, :seccion, @cod, @msj)");
  $stmt->execute([':proforma' => $id_proforma, ':seccion' => $id_seccion]);
  $stmt->closeCursor();
  $res = $pdo->query("SELECT @cod AS codigo, @msj AS mensaje")->fetch();
  ```
* En caso de éxito (`codigo = 200`), responde con JSON de éxito; en caso de falta de vacantes o límite de créditos, devuelve HTTP 400 con el mensaje descriptivo.

### 3.4. `backend/api/matricula/confirmar.php` (Transacción Atómica)
* Llama a `sp_confirmar_matricula(p_id_proforma)`.
* Valida en la base de datos:
  1. Que no existan cruces (`fn_validar_cruces_horario == FALSE`).
  2. Que los créditos cumplan con el mínimo y máximo según la categoría.
  3. Que el pago esté en estado `'PAGADO'`.
* Ejecuta el cambio de estado de `'PROFORMA'` a `'CONFIRMADA'` y bloquea la edición (`es_editable = FALSE`).

---

## 4. DETALLE DE RESPONSABILIDADES: FRONTEND (REACT + VITE)

### 4.1. Servicios de Comunicación (`src/services/api.js`)
Centraliza las llamadas `fetch` con el backend:
```javascript
const BASE_URL = "http://localhost/sistema-matricula/backend/api";

export const api = {
  login: (data) => fetch(`${BASE_URL}/auth/login.php`, { method: "POST", body: JSON.stringify(data) }).then(r => r.json()),
  consultarCola: (token) => fetch(`${BASE_URL}/cola/posicion.php`, { headers: { Authorization: `Bearer ${token}` } }).then(r => r.json()),
  getCatalogo: (token) => fetch(`${BASE_URL}/matricula/catalogo.php`, { headers: { Authorization: `Bearer ${token}` } }).then(r => r.json()),
  agregarCurso: (idSeccion, idProforma) => fetch(`${BASE_URL}/matricula/agregar_curso.php`, { method: "POST", body: JSON.stringify({ id_seccion: idSeccion, id_proforma: idProforma }) }).then(r => r.json()),
  retirarCurso: (idSeccion, idProforma) => fetch(`${BASE_URL}/matricula/retirar_curso.php`, { method: "POST", body: JSON.stringify({ id_seccion: idSeccion, id_proforma: idProforma }) }).then(r => r.json()),
  confirmarMatricula: (idProforma) => fetch(`${BASE_URL}/matricula/confirmar.php`, { method: "POST", body: JSON.stringify({ id_proforma: idProforma }) }).then(r => r.json()),
};
```

### 4.2. Componentes Clave:
* **`CountdownTimer.jsx`:** Componente que inicia una cuenta regresiva de 300 a 0 segundos al obtener el turno activo. Al llegar a cero, invoca automáticamente el endpoint de cancelación por inactividad y expulsa al usuario al login.
* **`ScheduleGrid.jsx`:** Matriz de 6 columnas (Lunes a Sábado) y filas por horas (07:00 a 20:00). Dibuja los bloques de las materias agregadas. Si dos materias coinciden en el mismo día y bloque horario, les asigna la clase CSS `conflict-block` (fondo rojo parpadeante) y desactiva el botón de confirmación.

---

## 5. CAPA DE BASE DE DATOS Y ENTREGABLES PARA EL DOCENTE (`database/`)

El docente exige una carpeta comprimida con scripts ejecutables y ejemplos en `.txt`:

1. **`01_schema.sql`:**
   * Creación de las 18 tablas con `ENGINE = InnoDB` y `DEFAULT CHARSET = utf8mb4`.
   * Integridad referencial (`FOREIGN KEY`) y restricciones de unicidad (`UNIQUE`).
2. **`02_stored_procedures.sql`:**
   * `sp_determinar_limite_creditos`: Reglas de Especial (<12), Regular (12-23) y Destacado (28).
   * `sp_matricular_curso`: Bloqueo pesimista con `SELECT ... FOR UPDATE` sobre la fila de la tabla `seccion`.
   * `sp_desmatricular_curso`: Retiro de asignatura e incremento seguro de vacantes.
   * `sp_confirmar_matricula`: Transacción de cierre definitivo e inmutabilidad.
3. **`03_functions.sql`:**
   * `fn_validar_cronograma`: Retorna booleano evaluando `NOW()` contra la tabla `cronograma_matricula`.
   * `fn_validar_cruces_horario`: Algoritmo que detecta solapamientos temporales en minutos.
   * `fn_validar_requisitos_completos`: Retorna booleano tras verificar los 4 documentos entregados.
4. **`pruebas_mysql.txt` (Punto 2 de la Rúbrica):**
   * Archivo de texto plano con ejemplos listos para copiar, pegar y ejecutar directamente en MySQL Workbench o phpMyAdmin demostrando cada procedimiento y función.

---

## 6. GUÍA RÁPIDA DE PUESTA EN MARCHA LOCAL

### Requisitos Previos:
* XAMPP con **PHP 8.1+** y **MySQL 8.0+** instalado.
* Node.js v18+ y npm instalados.

### Paso 1: Configurar la Base de Datos
1. Inicia **Apache** y **MySQL** desde el panel de control de XAMPP.
2. Abre phpMyAdmin (`http://localhost/phpmyadmin`) o MySQL Workbench.
3. Crea la base de datos:
   ```sql
   CREATE DATABASE sistema_matricula CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   USE sistema_matricula;
   ```
4. Importa el archivo consolidado `database/database_completo.sql`.

### Paso 2: Configurar el Backend (PHP Puro)
1. Coloca la carpeta del proyecto en `C:\xampp\htdocs\sistema-matricula\`.
2. Verifica que `backend/config/database.php` apunte a `localhost`, usuario `root`, contraseña vacía `""` y base de datos `sistema_matricula`.
3. Prueba la conexión abriendo en el navegador:
   `http://localhost/sistema-matricula/backend/api/auth/login.php` (deberá responder un JSON indicando método no permitido o datos requeridos).

### Paso 3: Iniciar el Frontend (React + Vite)
1. Abre una terminal en la carpeta `frontend/`:
   ```bash
   cd frontend
   npm install
   npm run dev
   ```
2. Abre la URL local generada (normalmente `http://localhost:5173`).
3. El frontend consumirá directamente la API local de PHP en el puerto 80 sin problemas de CORS ni conexión a internet.
