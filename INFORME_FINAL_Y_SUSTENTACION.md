# INFORME TÉCNICO FINAL Y GUÍA DE SUSTENTACIÓN
## SISTEMA WEB DE MATRÍCULA UNIVERSITARIA - UNJBG (ESIS)

> **Institución:** Universidad Nacional Jorge Basadre Grohmann (UNJBG)  
> **Escuela Profesional:** Ingeniería en Informática y Sistemas (ESIS)  
> **Semestre Académico:** 2026-II  
> **Arquitectura:** Desacoplada (Frontend React SPA + Backend PHP 8 con PDO + Base de Datos MySQL 8.0 InnoDB)  
> **Estado del Proyecto:** 100% Operativo y Validado

---

## 1. CUMPLIMIENTO RIGUROSO DE LA RÚBRICA DE EVALUACIÓN

El proyecto ha sido estructurado para satisfacer al 100% cada uno de los criterios exigidos en la rúbrica docente:

| Criterio / Ítem de Rúbrica | Puntuación | Estado | Evidencia y Justificación Técnica en el Repositorio |
| :--- | :---: | :---: | :--- |
| **Punto 1: Base de Datos Relacional en 3FN** | **15 pts** | **Cumplido** | [database/01_schema.sql](database/01_schema.sql) y [database/database_completo.sql](database/database_completo.sql).<br>• 18 tablas estrictamente normalizadas en Tercera Forma Normal (3FN).<br>• Motor `InnoDB` con integridad referencial (`FOREIGN KEY ON DELETE RESTRICT`).<br>• Juego de caracteres `utf8mb4` e índices optimizados en campos de búsqueda. |
| **Manejo de Concurrencia y Bloqueo Pesimista** | *(Incluido en BD)* | **Cumplido** | [database/02_stored_procedures.sql](database/02_stored_procedures.sql) (`sp_matricular_curso`).<br>• Implementación de `SELECT vacantes_disponibles FROM seccion WHERE id_seccion = ? FOR UPDATE` dentro de una transacción ACID (`START TRANSACTION ... COMMIT / ROLLBACK`), garantizando que dos alumnos jamás tomen el último cupo simultáneamente. |
| **Procedimientos Almacenados y Funciones** | *(Incluido en BD)* | **Cumplido** | • **5 Stored Procedures:** `sp_determinar_limite_creditos`, `sp_matricular_curso`, `sp_desmatricular_curso`, `sp_confirmar_matricula` y `sp_cancelar_reserva_timeout`.<br>• **3 Funciones deterministas:** `fn_validar_cronograma`, `fn_validar_cruces_horario` (detección de solapes) y `fn_validar_requisitos_completos` ([database/03_functions.sql](database/03_functions.sql)). |
| **Vistas Consolidadas** | *(Incluido en BD)* | **Cumplido** | [database/04_views.sql](database/04_views.sql).<br>• `vw_ficha_matricula`: Consolida datos del alumno, escuela, asignaturas, horarios y código de verificación.<br>• `vw_catalogo_oferta_academica`: Catálogo de cursos con vacantes en tiempo real. |
| **Punto 2: Archivo de Pruebas en Texto Plano (.txt)** | **Requisito Obligatorio** | **Cumplido** | [database/pruebas_mysql.txt](database/pruebas_mysql.txt).<br>• Archivo de texto plano con **9 casos de prueba ejecutables paso a paso**, que demuestran validaciones de cronograma, cruce de horarios, cálculo de créditos, concurrencia y confirmación inmutable. |
| **Diccionario de Datos y Modelo E-R** | **Requisito Técnico** | **Cumplido** | [DOCUMENTACION_BD.md](DOCUMENTACION_BD.md).<br>• 18 tablas detalladas en formato: *Nombre del Atributo*, *Tipo de Dato*, *Claves*, *Nulabilidad* y *Descripción/Propósito*.<br>• Matriz de 23 relaciones foráneas.<br>• Diagrama Entidad-Relación completo en Mermaid bajo estándar 3FN. |
| **Restricción Tecnológica (Sin Frameworks en Backend)** | **Requisito Obligatorio** | **Cumplido** | Backend desarrollado en **PHP 8 estructurado con PDO** (Cero Laravel, Cero Symfony, Cero ORMs pesados). Patrón Singleton de conexión en [backend/config/database.php](backend/config/database.php) y micro-controladores atómicos REST. |
| **Diagramas de Casos de Uso y Secuencia** | **Documentación UML** | **Cumplido** | Carpetas [diagramas/casos-de-uso/](diagramas/casos-de-uso/) y [diagramas/secuencia/](diagramas/secuencia/) con archivos fuente PlantUML (`.puml`) e imágenes `.png` renderizadas en alta resolución. |

---

## 2. LA APLICACIÓN WEB: QUÉ TIENE Y QUÉ PUEDE HACER

La solución es una plataforma web completa tipo **SPA (Single Page Application)** construida con **React + Vite** en el frontend y **PHP 8 + PDO** en el backend.

### 2.1. Módulos y Capacidades del Sistema:

1. **Módulo de Autenticación y Control de Acceso ([api/auth/login.php](backend/api/auth/login.php)):**
   * Validación segura de credenciales contra contraseñas encriptadas mediante `password_verify()`.
   * Validación automática de **cronograma universitario** mediante la función MySQL `fn_validar_cronograma`. Si el estudiante intenta acceder antes o después de su rango de fecha/hora, el sistema le deniega el ingreso.
   * Emisión de un **Token de Sesión firmado con HMAC-SHA256** para autorizar las peticiones subsecuentes.
   * Opción de recuperación de contraseña simulada mediante verificación de código y correo institucional.

2. **Módulo de Portafolio de Requisitos de Admisión ([api/portafolio/](backend/api/portafolio/)):**
   * **Detección inteligente de condición:** Si el alumno autenticado es *ingresante*, el sistema lo desvía obligatoriamente a la pantalla de portafolio.
   * **Carga de 4 documentos obligatorios:**
     1. Constancia Oficial de Ingreso
     2. Documento Nacional de Identidad (DNI)
     3. Fotografía para Carné Universitario
     4. Constancia de Examen de Salud Preventivo
   * **Validación de archivos:** Filtra extensiones permitidas (**JPG, JPEG, PNG**) y restringe el tamaño a un máximo de **2 MB** por documento.
   * **Bloqueo estricto:** El botón para continuar a la sala de espera permanece deshabilitado hasta que los 4 documentos hayan sido entregados.

3. **Módulo de Sala de Espera Virtual (Cola Concurrente) ([api/cola/](backend/api/cola/)):**
   * Regula el tráfico simultáneo de estudiantes para evitar sobrecargas del servidor universitario.
   * Asignación de posición correlativa en fila.
   * **Mecanismo de Polling:** El cliente consulta automáticamente el estado cada 5 segundos.
   * **Habilitación de turno y temporizador de 5 minutos (300 segundos):** Cuando el turno se activa, el estudiante visualiza una tarjeta verde interactiva y al ingresar a la selección de asignaturas se activa un temporizador regresivo visible en el encabezado.
   * **Cancelación por Timeout:** Si transcurren los 5 minutos sin confirmar, el endpoint `api/matricula/timeout.php` libera automáticamente cualquier cupo reservado provisionalmente.

4. **Módulo de Asignaturas y Cálculo Dinámico de Créditos ([api/matricula/](backend/api/matricula/)):**
   * Ejecuta el procedimiento almacenado `sp_determinar_limite_creditos`, clasificando al alumno en:
     * **Alumno Observado/Especial (PPA < 12.0):** Restringido a un tope de **11 créditos**.
     * **Alumno Regular (12.0 $\le$ PPA < 14.0):** Bolsa estándar de 12 a **23 créditos**.
     * **Alumno Destacado (PPA $\ge$ 14.0):** Bolsa ampliada de hasta **28 créditos** con autorización para adelantar materias de semestres superiores.
   * Catálogo de asignaturas con desglose por secciones: **Grupo A (Turno MAÑANA)** y **Grupo B (Turno TARDE)**.
   * Monitoreo en tiempo real de vacantes disponibles.

5. **Módulo de Reserva Concurrente con Bloqueo Pesimista ([api/matricula/agregar_curso.php](backend/api/matricula/agregar_curso.php)):**
   * Al hacer clic en *"Matricular"* en una sección, el backend invoca el SP `sp_matricular_curso`.
   * El SP bloquea la fila de la sección con `SELECT ... FOR UPDATE`, descuenta la vacante de forma atómica y registra el detalle de matrícula.
   * **Retiro voluntario:** El alumno puede retirar cualquier curso de su proforma; el SP `sp_desmatricular_curso` restituye la vacante inmediatamente al stock general.

6. **Módulo de Horario Semanal y Detección de Cruces ([src/components/ScheduleGrid.jsx](frontend/src/components/ScheduleGrid.jsx)):**
   * Matriz visual de Lunes a Sábado (de 08:00 a 19:00 horas).
   * Colorea cada curso seleccionado de forma diferenciada.
   * **Alerta en Rojo de Cruce de Horario:** La función de base de datos `fn_validar_cruces_horario` detecta si dos asignaturas solapan sus horas en el mismo día; en caso de cruce, las celdas afectadas parpadean en rojo y se bloquea la confirmación.

7. **Módulo de Liquidación, Confirmación e Inmutabilidad ([api/matricula/confirmar.php](backend/api/matricula/confirmar.php)):**
   * Valida que el estudiante cumpla el mínimo de créditos, no exceda su límite máximo, no tenga cruces de horario y registre el comprobante de pago por derecho de matrícula.
   * Transiciona la matrícula de estado `PROFORMA` a **`CONFIRMADA`**.
   * **Candado de Inmutabilidad:** Establece `es_editable = FALSE`, imposibilitando cualquier alteración posterior de los cursos matriculados.

8. **Módulo de Ficha Oficial de Matrícula en PDF ([api/reportes/generar_ficha.php](backend/api/reportes/generar_ficha.php)):**
   * Genera el documento oficial universitario con membrete institucional de la UNJBG, datos del alumno, código de verificación hash único, tabla de asignaturas inscritas con grupos y horarios, créditos totales y firmas de registro.
   * Dispone de impresión directa y descarga en PDF mediante la API nativa de impresión del navegador.

---

## 3. GUÍA PASO A PASO PARA LA DEMOSTRACIÓN (SUSTENTACIÓN ANTE EL DOCENTE)

Sigue esta secuencia para demostrar el 100% de los requerimientos en menos de 4 minutos:

```
[ PASO 1: Ingresante Bloqueado ] ➔ [ PASO 2: Sala de Espera y Regular ] ➔ [ PASO 3: Cruce de Horarios ] ➔ [ PASO 4: Destacado (28 cr.) ] ➔ [ PASO 5: Confirmación e Impresión PDF ]
```

### Escenario 1: Demostrar control de ingresantes y portafolio
1. En la pantalla de Login, haz clic en el botón de acceso rápido **Carlos Mendoza** (`2026-119001` / contraseña `123456`).
2. Presiona **"Ingresar a Matrícula"**.
3. **Explicación al docente:**  
   *«Profesor, el sistema detectó que es un alumno ingresante (`es_ingresante = TRUE`). En lugar de permitirle matricularse, lo desvía obligatoriamente al Portafolio de Admisión. El botón inferior dice 'Acceso Bloqueado' porque aún tiene 0 de 4 documentos entregados».*
4. Adjunta cualquier imagen JPG/PNG en los 4 casilleros (Constancia de Ingreso, DNI, Foto y Examen de Salud).
5. Observa cómo el contador cambia a `4 de 4 entregados` y el botón se transforma en color verde: **"Continuar a Cola Virtual ➔"**.

### Escenario 2: Demostrar la Sala de Espera Virtual y Alumno Regular
1. Cierra sesión e ingresa con **Kevin Arnold** (`2023-119010` / contraseña `123456`).
2. Al ingresar, se observa la **Sala de Espera Virtual** regulando el acceso correlativo mediante sondeo automático cada 5 segundos.
3. Se habilita el turno con la tarjeta verde: **"¡ES TU TURNO DE MATRÍCULA! - TURNO ACTIVO #01"**.
4. Haz clic en **"Ingresar a Selección de Cursos ➔"**.
5. **Explicación al docente:**  
   *«Se ha activado el temporizador regresivo de 5 minutos en el Navbar superior. Este estudiante tiene condición REGULAR (PPA 13.50), por lo que el SP en MySQL le asignó un tope de 23 créditos».*

### Escenario 3: Demostrar concurrencia y detección de cruces de horario
1. En el catálogo de asignaturas, matricula **Cálculo I (Grupo A - MAÑANA)**. Observa cómo disminuye en 1 la vacante disponible y se dibuja el bloque azul en el horario semanal.
2. Luego intenta matricular otra asignatura que coincida en el mismo horario (por ejemplo, **Física General** en el mismo día y hora).
3. **Explicación al docente:**  
   *«La función determinista `fn_validar_cruces_horario` detectó un solapamiento de rangos de horas. La grilla resalta el bloque en rojo con la alerta '¡Cruce de horarios detectado!' y el botón inferior de Confirmar Matrícula queda deshabilitado para proteger la consistencia académica».*
4. Retira el curso en conflicto haciendo clic en el ícono del tacho rojo; la vacante se reintegra al instante.

### Escenario 4: Demostrar Alumno Destacado (Bolsa de 28 créditos)
1. Cierra sesión e inicia sesión con **Andrea Sofía** (`2022-119005` / contraseña `123456`).
2. **Explicación al docente:**  
   *«Andrea tiene condición DESTACADO gracias a su promedio ponderado de 16.80 ($\ge 14.0$). El procedimiento almacenado `sp_determinar_limite_creditos` le otorgó automáticamente una bolsa ampliada de 28 créditos y le permite adelantar cursos».*

### Escenario 5: Confirmación Atómica y Descarga de Ficha en PDF
1. Con los cursos seleccionados, haz clic en **"Confirmar Matrícula Definitiva"**.
2. Acepta el modal de confirmación.
3. El sistema ejecuta el SP `sp_confirmar_matricula`:
   * Cambia el estado a **`CONFIRMADA`**.
   * Activa el flag de inmutabilidad: **`Edición de Cursos: BLOQUEADA`**.
   * Genera un código de verificación alfanumérico irrepetible.
4. Haz clic en el botón azul **"Descargar Ficha Oficial en PDF"**. Se abrirá la Ficha Oficial de Matrícula lista para imprimir o guardar como documento PDF con el sello y firmas de la UNJBG.

---

## 4. ACLARACIÓN: SUBIDA DE CONSTANCIAS Y DOCUMENTOS

> **Pregunta frecuente:** *¿Se pueden subir las constancias en el sistema?*

### ✅ **SÍ, se pueden subir perfectamente.**
El módulo de Portafolio ([api/portafolio/subir.php](backend/api/portafolio/subir.php)) implementa la carga real de los siguientes 4 recaudos:
1. **Constancia Oficial de Ingreso** (Emitida por la Dirección de Admisión).
2. **Documento Nacional de Identidad (DNI)**.
3. **Fotografía tamaño carné digitalizada**.
4. **Constancia de Examen de Salud Preventivo**.

**Cómo opera internamente:**
* El usuario selecciona el archivo desde su computadora.
* El backend valida en el servidor que el peso no sobrepase los **2 MB** y que el formato sea estrictamente **JPG, JPEG o PNG**.
* Guarda el archivo físicamente en la carpeta del servidor: `backend/uploads/portafolio/doc_{id_estudiante}_tipo_{id_tipo}_{timestamp}.jpg`.
* Registra en la tabla `portafolio_documento` la ruta física, el peso en KB, el formato y marca el estado como `ENTREGADO`.

---

## 5. LIMITACIONES DEL SISTEMA Y ALCANCE REAL

Para responder con total honestidad profesional ante el jurado o docente, es importante tener claros los **límites del alcance del proyecto**:

### ❌ Lo que el sistema NO hace (Limitaciones de alcance):

1. **No admite documentos en formato PDF multipágina en el Portafolio:**
   * *Motivo:* El requerimiento original del sistema solicita imágenes escaneadas digitalizadas (JPG/PNG). Si el usuario intenta subir un `.pdf` o `.docx`, el validador lo rechazará por seguridad y control de peso.
2. **No cuenta con Pasarela de Pago Bancaria en Vivo (Niubiz / Banco de la Nación):**
   * *Motivo:* Por tratarse de un prototipo académico local sin convenios bancarios ni certificados SSL de producción, la verificación de pago se realiza contra la tabla relacional `pago_matricula` mediante un número de operación universitario precargado, pero no debita dinero real de tarjetas de crédito/débito.
3. **No incluye Panel Administrativo para Autoridades Universitarias:**
   * *Motivo:* El alcance del proyecto fue asignado exclusivamente al **Portal Web del Estudiante**. La creación de nuevos planes de estudio, apertura de nuevas secciones docentes o modificación de fechas de cronograma se realiza directamente a nivel de base de datos relacional mediante sentencias SQL (o phpMyAdmin/Workbench).
4. **No gestiona Citas Médicas Clínicas:**
   * *Motivo:* La programación de consultas médicas presenciales corresponde al subsistema de Bienestar Universitario / Centro Médico, el cual es un sistema independiente de la matrícula curricular.
5. **Autenticación Institucional Local (Sin Google OAuth / LDAP Central):**
   * *Motivo:* Las credenciales residen en la tabla `estudiante` con hash Bcrypt estándar, sin conexión con el directorio activo (LDAP) o correo institucional de Google Workspace de la universidad.

---

## 6. SÍNTESIS DE ARCHIVOS CLAVE PARA LA EVALUACIÓN

```text
sistema-matricula/
├── database/
│   ├── database_completo.sql     <-- [IMPORTAR ESTE EN MYSQL WORKBENCH] 47 KB todo incluido
│   ├── pruebas_mysql.txt         <-- [EXIGIDO POR RÚBRICA] 9 pruebas paso a paso en consola
│   ├── 01_schema.sql             <-- Estructura DDL 18 tablas en 3FN
│   ├── 02_stored_procedures.sql  <-- Bloqueo pesimista con SELECT ... FOR UPDATE
│   ├── 03_functions.sql          <-- Funciones deterministas (cruces, cronograma)
│   └── 04_views.sql              <-- Vistas consolidadas para ficha y catálogo
├── backend/                      <-- PHP 8 sin frameworks con PDO Singleton
│   ├── api/auth/                 <-- Login, logout, recuperación
│   ├── api/portafolio/           <-- Subida y estado de documentos
│   ├── api/cola/                 <-- Sala de espera virtual y temporizador
│   ├── api/matricula/            <-- Catálogo, selección concurrente y confirmación
│   └── api/reportes/             <-- Generador de Ficha Oficial en PDF
├── frontend/                     <-- React + Vite SPA
│   ├── src/pages/                <-- Vistas interactivas
│   └── src/components/           <-- Grilla semanal, temporizador y navbar
├── DOCUMENTACION_BD.md           <-- Diccionario de datos y diagrama ER Mermaid
├── REQUERIMIENTOS.md             <-- 21 requerimientos funcionales formales
├── ARQUITECTURA_Y_ESTRUCTURA.md  <-- Especificación técnica de arquitectura
└── README.md                     <-- Guía de instalación y credenciales de prueba
```
