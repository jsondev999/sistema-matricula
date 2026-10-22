# Sistema Web de Matrícula Universitaria - UNJBG (ESIS)

> Sistema web transaccional desarrollado bajo arquitectura desacoplada para la Escuela Profesional de Ingeniería en Informática y Sistemas (**ESIS**) de la **Universidad Nacional Jorge Basadre Grohmann (UNJBG)**.

---

## 🚀 Arquitectura y Tecnologías

| Capa | Tecnología | Justificación y Cumplimiento de Rúbrica |
| :--- | :--- | :--- |
| **Frontend** | React 19 + Vite + Lucide Icons | Interfaz moderna tipo Single Page Application (SPA), cuadrícula semanal de horarios interactiva, temporizador animado de 5 minutos y sala de espera virtual con sondeo en tiempo real. |
| **Backend** | PHP 8.2 + PDO | Arquitectura modular basada en micro-controladores REST atómicos, patrón Singleton para PDO, validación de sesiones con tokens HMAC y respuestas JSON normalizadas. |
| **Base de Datos** | MySQL 8.0+ (Motor InnoDB) | Normalización en Tercera Forma Normal (**3FN**), integridad referencial estricta, bloqueo pesimista de vacantes con `SELECT ... FOR UPDATE` en transacciones ACID, procedimientos almacenados, funciones y vistas. |

---

## 📁 Estructura del Repositorio

```text
sistema-matricula/
├── backend/                         # Backend en PHP 8 (Micro-controladores REST)
│   ├── api/
│   │   ├── auth/                    # login.php, logout.php, recuperar.php
│   │   ├── portafolio/              # estado.php, subir.php (JPG/PNG máx 2MB)
│   │   ├── cola/                    # ingresar.php, posicion.php (polling cada 5s)
│   │   ├── matricula/               # perfil.php, creditos.php, catalogo.php, proforma.php,
│   │   │                            # agregar_curso.php, retirar_curso.php, confirmar.php, timeout.php
│   │   └── reportes/                # generar_ficha.php (Ficha Oficial con impresión PDF)
│   ├── config/                      # database.php (PDO Singleton), cors.php
│   ├── helpers/                     # response.php, auth_middleware.php (HMAC)
│   └── uploads/portafolio/          # Almacenamiento seguro de documentos de ingresantes
│
├── database/                        # Scripts SQL y Pruebas según Rúbrica
│   ├── 01_schema.sql                # 18 tablas normalizadas en 3FN (InnoDB)
│   ├── 02_stored_procedures.sql     # sp_matricular_curso (FOR UPDATE), confirmar, etc.
│   ├── 03_functions.sql             # fn_validar_cronograma, fn_validar_cruces_horario, etc.
│   ├── 04_views.sql                 # vw_ficha_matricula, vw_catalogo_oferta_academica
│   ├── 05_seeds.sql                 # Datos de prueba (cursos, horarios, estudiantes)
│   ├── database_completo.sql        # Script unificado listo para importar en MySQL (47 KB)
│   └── pruebas_mysql.txt            # 9 casos de prueba documentados (Punto 2 de la Rúbrica)
│
├── diagramas/                       # Diagramas de Casos de Uso y Secuencia
│   ├── casos-de-uso/                # CU-01 al CU-06 en PlantUML y PNGs de alta resolución
│   │   └── ESPECIFICACION_CASOS_DE_USO.md
│   └── secuencia/                   # Autenticación, Portafolio, Cola Virtual, Matrícula
│
├── frontend/                        # SPA en React + Vite
│   ├── src/
│   │   ├── components/              # Navbar, CountdownTimer, ScheduleGrid
│   │   ├── context/                 # AuthContext.jsx (Estado global y vistas)
│   │   ├── pages/                   # LoginPage, PortafolioPage, ColaVirtualPage,
│   │   │                            # MatriculaPage, ConfirmacionPage
│   │   └── services/                # api.js (Cliente HTTP REST)
│
├── DOCUMENTACION_BD.md              # Diccionario de datos, relaciones y diagrama ER Mermaid
├── REQUERIMIENTOS.md                # 21 requerimientos funcionales y matriz de trazabilidad
└── ARQUITECTURA_Y_ESTRUCTURA.md     # Especificación de arquitectura y protocolos
```

---

## ⚡ Guía de Instalación y Ejecución Local

### 1. Base de Datos (MySQL en XAMPP)
1. Inicie el módulo **MySQL** desde el Panel de Control de XAMPP.
2. Abra su cliente de base de datos preferido (phpMyAdmin o MySQL CLI) e importe el archivo unificado:
   ```bash
   mysql -u root -p < database/database_completo.sql
   ```
   *Esto creará la base de datos `sistema_matricula_unjbg` con todas las 18 tablas, procedimientos, funciones, vistas y datos iniciales de prueba.*

### 2. Backend (PHP 8)
Puede ejecutarse de dos maneras:
- **Opción A (Recomendada con servidor embebido de PHP)**:
  ```bash
  cd backend
  C:\xampp\php\php.exe -S localhost:8000
  ```
  *(En este caso, configure `VITE_API_URL=http://localhost:8000/api` en el frontend).*
- **Opción B (Vía Apache de XAMPP)**:
  Copie o enlace simbólicamente la carpeta del proyecto a `C:\xampp\htdocs\sistema-matricula`.
  La API responderá por defecto en `http://localhost/sistema-matricula/backend/api`.

### 3. Frontend (React + Vite)
1. Abra una terminal en la carpeta `frontend`:
   ```bash
   cd frontend
   npm install
   npm run dev
   ```
2. Abra su navegador en `http://localhost:5173`.

---

## 👥 Cuentas de Prueba Pre-cargadas

Para facilitar la evaluación del docente y las pruebas, la pantalla de Login incluye botones de acceso directo para los siguientes escenarios:

| Estudiante | Código | Contraseña | Condición | Escenario que Demuestra |
| :--- | :--- | :--- | :--- | :--- |
| **Carlos Mendoza** | `2026-119001` | `password123` | REGULAR (Ingresante) | **Ingresante sin portafolio**: Bloqueado hasta subir los 4 documentos requeridos (DNI, Certificado, Examen Médico, Foto). |
| **Lucía Paredes** | `2026-119002` | `password123` | REGULAR (Ingresante) | **Ingresante con portafolio completo**: Pasa directo a la Sala de Espera Virtual. |
| **Ana Sofía Quispe** | `2022-119015` | `password123` | DESTACADO | **Alumno Destacado (PPA $\ge$ 14.0)**: Límite ampliado hasta **28 créditos** y habilitación de asignaturas de semestres superiores. |
| **Diego Huamán** | `2021-119030` | `password123` | ESPECIAL | **Alumno Observado/Especial**: Límite restringido a **11 créditos** con advertencias preventivas. |
| **Juan Pérez** | `2023-119001` | `password123` | REGULAR | **Alumno Regular**: Límite estándar de 12 a 23 créditos. |

---

## 📋 Cumplimiento de la Rúbrica de Evaluación

- **Punto 1 (15 puntos de BD)**:
  - Base de datos en 3FN con motor InnoDB (`database/01_schema.sql`).
  - Procedimientos almacenados para concurrencia con `SELECT ... FOR UPDATE` (`database/02_stored_procedures.sql`).
  - Funciones para validación de cronograma, cruce de horarios y requisitos (`database/03_functions.sql`).
  - Vistas para proforma y catálogo (`database/04_views.sql`).
  - Script SQL unificado (`database/database_completo.sql`).
- **Punto 2 (Pruebas en archivo de texto plano)**:
  - Documentado detalladamente con 9 casos de prueba en `database/pruebas_mysql.txt`.
- **Diccionario de Datos y Diagrama ER**:
  - En `DOCUMENTACION_BD.md` con tablas formateadas con Atributo, Tipo de Dato, Claves, Nulabilidad y Propósito, más el diagrama Mermaid de 18 entidades.
- **Diagramas de Casos de Uso y Secuencia**:
  - Casos de uso CU-01 a CU-06 con especificación completa e imágenes renderizadas en `diagramas/casos-de-uso/`.
  - Diagramas de secuencia en `diagramas/secuencia/` actualizados a React + PHP 8 + MySQL InnoDB.
