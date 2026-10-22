# Especificación de Requerimientos del Sistema Web de Matrícula

## 1. Información General del Proyecto
* **Sistema:** Sistema Web de Matrícula Universitaria
* **Perfil de Usuario Principal:** Estudiante (Ingresante y Regular)
* **Base de Datos:** MySQL
* **Mecanismos Clave:** Control de Concurrencia (Bloqueo Pesimista `FOR UPDATE`), Sala de Espera / Cola Virtual, Transición de Estados (`PROFORMA` a `CONFIRMADA`).

---

## 2. Requerimientos Funcionales (RF)

### Módulo 1: Autenticación y Control de Acceso
* **RF-01: Inicio de Sesión de Estudiante**
  * **Descripción:** Permite el ingreso del estudiante al sistema validando su código universitario y contraseña institucional.
  * **Regla de Negocio:** Valida que el estudiante exista y se encuentre en estado activo en el periodo lectivo vigente.

* **RF-02: Cierre de Sesión**
  * **Descripción:** Permite al estudiante cerrar su sesión en cualquier momento, invalidando el token de autenticación y liberando recursos de sesión.

* **RF-03: Restablecimiento de Contraseña**
  * **Descripción:** Permite al estudiante que haya olvidado su contraseña solicitar un enlace o código temporal de recuperación a través de su correo institucional registrado.

* **RF-04: Validación de Cronograma de Acceso**
  * **Descripción:** Valida la fecha y hora de acceso del estudiante antes de permitirle continuar en el flujo de matrícula.
  * **Regla de Negocio:** El acceso se restringe según el cronograma oficial configurado por facultad, escuela profesional y condición del estudiante (ingresante o regular). Si se encuentra fuera de horario, se muestra un mensaje informativo con la fecha/hora asignada.

---

### Módulo 2: Portafolio de Admisión (Exclusivo Ingresantes)
* **RF-05: Carga de Documentación de Admisión**
  * **Descripción:** Redirige al estudiante ingresante al módulo de portafolio para adjuntar en formato JPG o PNG los siguientes 4 documentos obligatorios:
    1. Constancia de Ingreso.
    2. Documento Nacional de Identidad (DNI).
    3. Fotografía para Carné Universitario.
    4. Constancia de Examen de Salud.
  * **Regla de Negocio:** El sistema valida la extensión permitida (JPG/PNG) y un peso máximo por archivo (ej. 2 MB).

* **RF-06: Bloqueo de Acceso por Documentación Incompleta**
  * **Descripción:** Impide el paso del estudiante ingresante hacia la cola virtual y el proceso de matrícula mientras no tenga los 4 documentos debidamente registrados y validados.

---

### Módulo 3: Cola Virtual y Control de Concurrencia
* **RF-07: Gestión de Sala de Espera (Cola Virtual)**
  * **Descripción:** Implementa una cola virtual para regular el flujo de estudiantes concurrentes hacia el módulo de selección de cursos, protegiendo al servidor de caídas por alta demanda.

* **RF-08: Visualización de Turno y Posición en Cola**
  * **Descripción:** Permite al estudiante visualizar en tiempo real su número de turno, su posición en la cola y un tiempo estimado de espera para ingresar.

* **RF-09: Temporizador de Sesión de Matrícula (5 Minutos)**
  * **Descripción:** Asigna una ventana estricta de 5 minutos (300 segundos) a partir del momento en que el estudiante ingresa al panel de selección de cursos.
  * **Regla de Negocio:** Si el temporizador expira sin que el estudiante haya confirmado su matrícula, la reserva temporal de asignaturas se cancela automáticamente y las vacantes son restituidas de inmediato.

---

### Módulo 4: Datos Académicos y Límite de Créditos
* **RF-10: Visualización de Perfil Académico**
  * **Descripción:** Muestra en pantalla los datos de cabecera del estudiante: nombre completo, código universitario, carrera (escuela profesional), sede académica y periodo actual (ejemplo: 2026-II).

* **RF-11: Clasificación de Condición Académica**
  * **Descripción:** Clasifica al estudiante según su rendimiento académico previo en: Especial, Regular o Destacado.

* **RF-12: Determinación de Límites de Créditos mediante Procedimiento Almacenado**
  * **Descripción:** Ejecuta un procedimiento almacenado en MySQL para calcular y mostrar el tope de créditos permitidos para la matrícula del ciclo:
    * **Especial:** Matrícula permitida en menos de 12 créditos.
    * **Regular:** Matrícula permitida con un mínimo de 12 créditos y hasta un máximo de 23 créditos.
    * **Destacado (Promedio ponderado $\ge 14.0$):** Hasta un máximo de 28 créditos, habilitando además la opción de adelantar cursos de ciclos superiores.

---

### Módulo 5: Selección de Cursos, Horarios y Control de Vacantes
* **RF-13: Consulta de Asignaturas, Horarios y Docentes**
  * **Descripción:** Permite visualizar el catálogo de cursos disponibles para el estudiante, mostrando para cada uno:
    * Secciones y horarios propuestos: Grupo A (Mañana) o Grupo B (Tarde).
    * Docentes asignados a cada sección.
    * Cantidad de créditos de la asignatura.
    * Vacantes totales y vacantes disponibles en tiempo real.

* **RF-14: Reserva Pesimista de Vacante al Seleccionar Curso**
  * **Descripción:** Al agregar un curso/sección a la proforma, el sistema ejecuta un procedimiento almacenado en MySQL con bloqueo pesimista (`SELECT ... FOR UPDATE`) para verificar que existan vacantes disponibles, descontar provisionalmente el cupo y asociarlo a la proforma del estudiante.

* **RF-15: Retiro de Curso de Proforma y Liberación de Cupo**
  * **Descripción:** Permite al estudiante desmarcar o retirar una asignatura de su proforma tentativa antes de confirmar, restituyendo inmediatamente la vacante a la sección correspondiente.

* **RF-16: Visualización de Horario Tentativo**
  * **Descripción:** Permite visualizar dinámicamente una grilla horaria semanal con los cursos y bloques horarios seleccionados hasta el momento.

* **RF-17: Validación y Alerta de Cruce de Horarios**
  * **Descripción:** Valida que no exista solapamiento de día y hora entre las secciones elegidas. En caso de conflicto, muestra una alerta inmediata en la interfaz y bloquea la confirmación de la matrícula hasta resolver el cruce.

---

### Módulo 6: Pagos, Confirmación y Emisión de Ficha
* **RF-18: Consulta de Costos y Estado de Pago**
  * **Descripción:** Permite al estudiante visualizar el monto asignado por concepto de matrícula y el estado de su pago (ej. PAGADO / PENDIENTE).

* **RF-19: Confirmación Transaccional de Matrícula**
  * **Descripción:** Al presionar "Confirmar Matrícula", el sistema ejecuta una transacción que valida el cumplimiento de las reglas (créditos mínimos/máximos, sin cruces, cupos válidos) y actualiza automáticamente el estado de la matrícula de `PROFORMA` a `CONFIRMADA`.

* **RF-20: Bloqueo de Modificaciones Post-Confirmación**
  * **Descripción:** Una vez confirmada la matrícula, el sistema bloquea cualquier edición, retiro o adición de asignaturas, garantizando la inmutabilidad del registro.

* **RF-21: Generación y Descarga de Ficha de Matrícula (PDF)**
  * **Descripción:** Permite al estudiante generar y descargar su documento oficial de Ficha de Matrícula en formato `.pdf`, detallando cursos matriculados, créditos, horarios, docentes y código de verificación.

---

## 3. Matriz de Trazabilidad: Requerimientos vs. Diagramas del Proyecto

| Requerimientos | Módulo / Paquete | Diagrama de Casos de Uso (`casos-de-uso/`) | Diagrama de Secuencia (`secuencia/`) |
| :--- | :--- | :--- | :--- |
| **RF-01 a RF-04** | Autenticación y Cronograma | `autenticacion.puml` | `autenticacion.puml` |
| **RF-05, RF-06** | Portafolio de Requisitos | `portafolio.puml` | `portafolio.puml` |
| **RF-07 a RF-09** | Cola Virtual y Timeout | `colavirtual.puml` | `colavirtual.puml` |
| **RF-10 a RF-12** | Créditos y Categorización | `cursoscreditos.puml` | `colavirtual.puml` / Transaccional |
| **RF-13 a RF-17** | Cursos, Cupos y Horario | `matricula.puml` | `colavirtual.puml` / SP |
| **RF-18 a RF-21** | Confirmación y Ficha PDF | `confirmacion.puml` | `validacion.puml` |

---

## 4. Requerimientos Técnicos y de Base de Datos (Para Sustentación)
1. **Procedimientos Almacenados (MySQL):**
   * `sp_determinar_limite_creditos`: Clasifica la condición del estudiante y retorna el rango min/max de créditos.
   * `sp_matricular_curso`: Aplica `SELECT ... FOR UPDATE` sobre la tabla `seccion` para garantizar que dos alumnos concurrentes no tomen la última vacante simultáneamente.
   * `sp_confirmar_matricula`: Ejecuta la transacción atómica que pasa el estado de `PROFORMA` a `CONFIRMADA`.
2. **Funciones Determinísticas:**
   * `fn_validar_cronograma(id_escuela, es_ingresante)`: Retorna un booleano indicando si la fecha/hora actual se encuentra dentro del rango permitido.
   * `fn_validar_cruces_horario(p_id_proforma)`: Detecta solapamiento en minutos entre los bloques horarios de los cursos seleccionados.
