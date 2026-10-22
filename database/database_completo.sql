-- =============================================================================
-- SISTEMA WEB DE MATRÍCULA UNIVERSITARIA - UNJBG
-- SCRIPT DDL: CREACIÓN DE ESTRUCTURA DE BASE DE DATOS (18 TABLAS EN 3FN)
-- Motor: MySQL 8.0+ | Motor de Almacenamiento: InnoDB | Charset: utf8mb4
-- =============================================================================

DROP DATABASE IF EXISTS sistema_matricula;
CREATE DATABASE sistema_matricula CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sistema_matricula;

-- -----------------------------------------------------------------------------
-- 1. TABLA: facultad
-- -----------------------------------------------------------------------------
CREATE TABLE facultad (
    id_facultad INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(120) NOT NULL,
    estado ENUM('ACTIVO', 'INACTIVO') NOT NULL DEFAULT 'ACTIVO',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 2. TABLA: escuela_profesional
-- -----------------------------------------------------------------------------
CREATE TABLE escuela_profesional (
    id_escuela INT AUTO_INCREMENT PRIMARY KEY,
    id_facultad INT NOT NULL,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(120) NOT NULL,
    estado ENUM('ACTIVO', 'INACTIVO') NOT NULL DEFAULT 'ACTIVO',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_escuela_facultad FOREIGN KEY (id_facultad) 
        REFERENCES facultad(id_facultad) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 3. TABLA: sede
-- -----------------------------------------------------------------------------
CREATE TABLE sede (
    id_sede INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    direccion VARCHAR(200) NOT NULL,
    ciudad VARCHAR(50) NOT NULL DEFAULT 'Tacna',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 4. TABLA: periodo_academico
-- -----------------------------------------------------------------------------
CREATE TABLE periodo_academico (
    id_periodo INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE, -- Ej: '2026-II'
    nombre VARCHAR(50) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado ENUM('PLANIFICACION', 'ACTIVO', 'CERRADO') NOT NULL DEFAULT 'PLANIFICACION',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 5. TABLA: cronograma_matricula
-- -----------------------------------------------------------------------------
CREATE TABLE cronograma_matricula (
    id_cronograma INT AUTO_INCREMENT PRIMARY KEY,
    id_periodo INT NOT NULL,
    id_escuela INT NOT NULL,
    condicion_estudiante ENUM('INGRESANTE', 'REGULAR', 'TODOS') NOT NULL DEFAULT 'TODOS',
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME NOT NULL,
    estado ENUM('ACTIVO', 'INACTIVO') NOT NULL DEFAULT 'ACTIVO',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cronograma_periodo FOREIGN KEY (id_periodo) 
        REFERENCES periodo_academico(id_periodo) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_cronograma_escuela FOREIGN KEY (id_escuela) 
        REFERENCES escuela_profesional(id_escuela) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_cronograma_rango (id_escuela, condicion_estudiante, fecha_inicio, fecha_fin)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 6. TABLA: tipo_documento_requisito (Portafolio de Admisión)
-- -----------------------------------------------------------------------------
CREATE TABLE tipo_documento_requisito (
    id_tipo_documento INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL UNIQUE, -- 'CONSTANCIA_INGRESO', 'DNI', 'FOTO_CARNE', 'EXAMEN_SALUD'
    nombre VARCHAR(100) NOT NULL,
    es_obligatorio BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 7. TABLA: estudiante
-- -----------------------------------------------------------------------------
CREATE TABLE estudiante (
    id_estudiante INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE, -- Ej: '2026-119001'
    dni CHAR(8) NOT NULL UNIQUE,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    correo_institucional VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    id_escuela INT NOT NULL,
    id_sede INT NOT NULL,
    es_ingresante BOOLEAN NOT NULL DEFAULT FALSE,
    condicion_academica ENUM('ESPECIAL', 'REGULAR', 'DESTACADO') NOT NULL DEFAULT 'REGULAR',
    promedio_ponderado DECIMAL(4,2) NOT NULL DEFAULT 0.00,
    creditos_permitidos INT NOT NULL DEFAULT 23,
    estado ENUM('ACTIVO', 'INACTIVO', 'EGRESADO') NOT NULL DEFAULT 'ACTIVO',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_estudiante_escuela FOREIGN KEY (id_escuela) 
        REFERENCES escuela_profesional(id_escuela) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_estudiante_sede FOREIGN KEY (id_sede) 
        REFERENCES sede(id_sede) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_estudiante_login (codigo, estado)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 8. TABLA: portafolio_documento
-- -----------------------------------------------------------------------------
CREATE TABLE portafolio_documento (
    id_documento INT AUTO_INCREMENT PRIMARY KEY,
    id_estudiante INT NOT NULL,
    id_tipo_documento INT NOT NULL,
    ruta_archivo VARCHAR(255) NOT NULL,
    formato VARCHAR(10) NOT NULL, -- 'JPG', 'PNG'
    peso_kb INT NOT NULL,
    estado ENUM('PENDIENTE', 'ENTREGADO', 'OBSERVADO', 'VALIDADO') NOT NULL DEFAULT 'ENTREGADO',
    fecha_subida DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_portafolio_estudiante FOREIGN KEY (id_estudiante) 
        REFERENCES estudiante(id_estudiante) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_portafolio_tipo FOREIGN KEY (id_tipo_documento) 
        REFERENCES tipo_documento_requisito(id_tipo_documento) ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY uk_estudiante_documento (id_estudiante, id_tipo_documento)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 9. TABLA: cola_virtual (Control de Concurrencia y Sala de Espera)
-- -----------------------------------------------------------------------------
CREATE TABLE cola_virtual (
    id_cola INT AUTO_INCREMENT PRIMARY KEY,
    id_estudiante INT NOT NULL UNIQUE,
    posicion INT NOT NULL,
    estado_turno ENUM('EN_ESPERA', 'TURNO_HABILITADO', 'EN_MATRICULA', 'EXPIRADO', 'FINALIZADO') NOT NULL DEFAULT 'EN_ESPERA',
    fecha_ingreso_cola DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_inicio_turno DATETIME NULL,
    fecha_expiracion DATETIME NULL, -- fecha_inicio_turno + 300 segundos
    CONSTRAINT fk_cola_estudiante FOREIGN KEY (id_estudiante) 
        REFERENCES estudiante(id_estudiante) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_cola_posicion (posicion, estado_turno)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 10. TABLA: plan_estudios
-- -----------------------------------------------------------------------------
CREATE TABLE plan_estudios (
    id_plan INT AUTO_INCREMENT PRIMARY KEY,
    id_escuela INT NOT NULL,
    codigo VARCHAR(10) NOT NULL, -- Ej: 'PLAN-2020'
    anio INT NOT NULL,
    estado ENUM('VIGENTE', 'OBSOLETO') NOT NULL DEFAULT 'VIGENTE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_plan_escuela FOREIGN KEY (id_escuela) 
        REFERENCES escuela_profesional(id_escuela) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 11. TABLA: curso
-- -----------------------------------------------------------------------------
CREATE TABLE curso (
    id_curso INT AUTO_INCREMENT PRIMARY KEY,
    id_plan INT NOT NULL,
    codigo VARCHAR(15) NOT NULL UNIQUE,
    nombre VARCHAR(120) NOT NULL,
    ciclo INT NOT NULL, -- Ciclo 1 al 10
    creditos INT NOT NULL,
    horas_teoria INT NOT NULL DEFAULT 2,
    horas_practica INT NOT NULL DEFAULT 2,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_curso_plan FOREIGN KEY (id_plan) 
        REFERENCES plan_estudios(id_plan) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_curso_ciclo (ciclo)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 12. TABLA: prerrequisito_curso (Relación Reflexiva)
-- -----------------------------------------------------------------------------
CREATE TABLE prerrequisito_curso (
    id_prerrequisito INT AUTO_INCREMENT PRIMARY KEY,
    id_curso INT NOT NULL,
    id_curso_requisito INT NOT NULL,
    CONSTRAINT fk_prerreq_curso FOREIGN KEY (id_curso) 
        REFERENCES curso(id_curso) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_prerreq_requisito FOREIGN KEY (id_curso_requisito) 
        REFERENCES curso(id_curso) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY uk_curso_prerrequisito (id_curso, id_curso_requisito)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 13. TABLA: docente
-- -----------------------------------------------------------------------------
CREATE TABLE docente (
    id_docente INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(15) NOT NULL UNIQUE,
    dni CHAR(8) NOT NULL UNIQUE,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    correo_institucional VARCHAR(150) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 14. TABLA: seccion (Control de Cupos y Bloqueo Pesimista)
-- -----------------------------------------------------------------------------
CREATE TABLE seccion (
    id_seccion INT AUTO_INCREMENT PRIMARY KEY,
    id_curso INT NOT NULL,
    id_periodo INT NOT NULL,
    id_docente INT NOT NULL,
    grupo ENUM('A', 'B') NOT NULL, -- 'A': Mañana, 'B': Tarde
    turno ENUM('MAÑANA', 'TARDE') NOT NULL DEFAULT 'MAÑANA',
    vacantes_totales INT NOT NULL DEFAULT 40,
    vacantes_disponibles INT NOT NULL DEFAULT 40, -- SOBRE ESTE CAMPO SE HACE FOR UPDATE
    estado ENUM('ABIERTA', 'CERRADA') NOT NULL DEFAULT 'ABIERTA',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_seccion_curso FOREIGN KEY (id_curso) 
        REFERENCES curso(id_curso) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_seccion_periodo FOREIGN KEY (id_periodo) 
        REFERENCES periodo_academico(id_periodo) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_seccion_docente FOREIGN KEY (id_docente) 
        REFERENCES docente(id_docente) ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY uk_curso_periodo_grupo (id_curso, id_periodo, grupo)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 15. TABLA: horario_seccion (Bloques de Día y Hora para Detección de Cruces)
-- -----------------------------------------------------------------------------
CREATE TABLE horario_seccion (
    id_horario INT AUTO_INCREMENT PRIMARY KEY,
    id_seccion INT NOT NULL,
    dia_semana ENUM('LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO') NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    aula VARCHAR(30) NOT NULL DEFAULT 'Aula Virtual / Lab',
    CONSTRAINT fk_horario_seccion FOREIGN KEY (id_seccion) 
        REFERENCES seccion(id_seccion) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_horario_dia_horas (dia_semana, hora_inicio, hora_fin)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 16. TABLA: pago_matricula
-- -----------------------------------------------------------------------------
CREATE TABLE pago_matricula (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_estudiante INT NOT NULL,
    id_periodo INT NOT NULL,
    nro_operacion VARCHAR(50) NOT NULL UNIQUE,
    monto DECIMAL(8,2) NOT NULL DEFAULT 120.00,
    fecha_pago DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('PENDIENTE', 'PAGADO', 'EXONERADO', 'RECHAZADO') NOT NULL DEFAULT 'PAGADO',
    CONSTRAINT fk_pago_estudiante FOREIGN KEY (id_estudiante) 
        REFERENCES estudiante(id_estudiante) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pago_periodo FOREIGN KEY (id_periodo) 
        REFERENCES periodo_academico(id_periodo) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 17. TABLA: matricula (Cabecera Transaccional)
-- -----------------------------------------------------------------------------
CREATE TABLE matricula (
    id_matricula INT AUTO_INCREMENT PRIMARY KEY,
    id_estudiante INT NOT NULL,
    id_periodo INT NOT NULL,
    id_pago INT NULL,
    total_creditos INT NOT NULL DEFAULT 0,
    monto_total DECIMAL(8,2) NOT NULL DEFAULT 120.00,
    estado ENUM('PROFORMA', 'CONFIRMADA', 'CANCELADA', 'ANULADA') NOT NULL DEFAULT 'PROFORMA',
    es_editable BOOLEAN NOT NULL DEFAULT TRUE, -- FALSE cuando pasa a CONFIRMADA
    fecha_creacion_proforma DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_confirmacion DATETIME NULL,
    codigo_verificacion VARCHAR(64) NULL UNIQUE, -- SHA-256 para validación de Ficha PDF
    CONSTRAINT fk_matricula_estudiante FOREIGN KEY (id_estudiante) 
        REFERENCES estudiante(id_estudiante) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_matricula_periodo FOREIGN KEY (id_periodo) 
        REFERENCES periodo_academico(id_periodo) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_matricula_pago FOREIGN KEY (id_pago) 
        REFERENCES pago_matricula(id_pago) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE KEY uk_estudiante_periodo (id_estudiante, id_periodo)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 18. TABLA: detalle_matricula (Detalle de Cursos y Reservas de Vacante)
-- -----------------------------------------------------------------------------
CREATE TABLE detalle_matricula (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_matricula INT NOT NULL,
    id_seccion INT NOT NULL,
    creditos INT NOT NULL,
    fecha_reserva DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('RESERVADO_TEMPORAL', 'CONFIRMADO', 'LIBERADO') NOT NULL DEFAULT 'RESERVADO_TEMPORAL',
    CONSTRAINT fk_detalle_matricula FOREIGN KEY (id_matricula) 
        REFERENCES matricula(id_matricula) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_detalle_seccion FOREIGN KEY (id_seccion) 
        REFERENCES seccion(id_seccion) ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY uk_matricula_seccion (id_matricula, id_seccion)
) ENGINE=InnoDB;
-- =============================================================================
-- SISTEMA WEB DE MATRÍCULA UNIVERSITARIA - UNJBG
-- SCRIPT DE PROCEDIMIENTOS ALMACENADOS (STORED PROCEDURES EN MYSQL)
-- Incluye control de concurrencia con BLOQUEO PESIMISTA (FOR UPDATE)
-- =============================================================================

USE sistema_matricula;

DELIMITER $$

-- -----------------------------------------------------------------------------
-- 1. SP: sp_determinar_limite_creditos
-- Clasifica al estudiante y establece los topes mínimo y máximo de créditos
-- según el Reglamento Académico (Especial, Regular, Destacado >= 14.0).
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_determinar_limite_creditos$$
CREATE PROCEDURE sp_determinar_limite_creditos(
    IN p_id_estudiante INT,
    OUT p_condicion VARCHAR(20),
    OUT p_limite_min INT,
    OUT p_limite_max INT,
    OUT p_puede_adelantar BOOLEAN
)
BEGIN
    DECLARE v_promedio DECIMAL(4,2);
    DECLARE v_es_ingresante BOOLEAN;

    SELECT promedio_ponderado, es_ingresante 
    INTO v_promedio, v_es_ingresante
    FROM estudiante 
    WHERE id_estudiante = p_id_estudiante;

    -- Los ingresantes ingresan como Regulares con créditos preestablecidos
    IF v_es_ingresante = TRUE THEN
        SET p_condicion = 'REGULAR';
        SET p_limite_min = 12;
        SET p_limite_max = 23;
        SET p_puede_adelantar = FALSE;
    ELSEIF v_promedio >= 14.00 THEN
        SET p_condicion = 'DESTACADO';
        SET p_limite_min = 12;
        SET p_limite_max = 28;
        SET p_puede_adelantar = TRUE;
    ELSEIF v_promedio < 11.00 THEN
        SET p_condicion = 'ESPECIAL';
        SET p_limite_min = 1;
        SET p_limite_max = 11;
        SET p_puede_adelantar = FALSE;
    ELSE
        SET p_condicion = 'REGULAR';
        SET p_limite_min = 12;
        SET p_limite_max = 23;
        SET p_puede_adelantar = FALSE;
    END IF;

    -- Actualizar la condición y tope en la tabla estudiante
    UPDATE estudiante 
    SET condicion_academica = p_condicion,
        creditos_permitidos = p_limite_max
    WHERE id_estudiante = p_id_estudiante;
END$$

-- -----------------------------------------------------------------------------
-- 2. SP: sp_matricular_curso (JOYAL TÉCNICA CON BLOQUEO PESIMISTA)
-- Reserva cupo en tiempo real evitando sobrecupos con SELECT ... FOR UPDATE.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_matricular_curso$$
CREATE PROCEDURE sp_matricular_curso(
    IN p_id_matricula INT,
    IN p_id_seccion INT,
    OUT p_codigo_error INT,
    OUT p_mensaje VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_id_estudiante INT;
    DECLARE v_estado_matricula VARCHAR(20);
    DECLARE v_es_editable BOOLEAN;
    DECLARE v_total_creditos INT;
    DECLARE v_creditos_permitidos INT;
    
    DECLARE v_id_curso INT;
    DECLARE v_creditos_curso INT;
    DECLARE v_vacantes_disponibles INT;
    DECLARE v_estado_seccion VARCHAR(20);
    DECLARE v_existe_curso_en_proforma INT;

    -- Manejo de excepciones SQL
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_codigo_error = 500;
        SET p_mensaje = 'Error interno en la base de datos al intentar reservar el cupo.';
    END;

    -- Validar existencia y estado de la matrícula
    SELECT id_estudiante, estado, es_editable, total_creditos
    INTO v_id_estudiante, v_estado_matricula, v_es_editable, v_total_creditos
    FROM matricula
    WHERE id_matricula = p_id_matricula;

    IF v_id_estudiante IS NULL THEN
        SET p_codigo_error = 404;
        SET p_mensaje = 'La proforma de matrícula especificada no existe.';
        LEAVE proc_label;
    END IF;

    IF v_estado_matricula <> 'PROFORMA' OR v_es_editable = FALSE THEN
        SET p_codigo_error = 403;
        SET p_mensaje = 'La matrícula ya está confirmada o cerrada. No se admiten modificaciones.';
        LEAVE proc_label;
    END IF;

    -- Obtener tope de créditos del estudiante
    SELECT creditos_permitidos INTO v_creditos_permitidos
    FROM estudiante WHERE id_estudiante = v_id_estudiante;

    -- =========================================================================
    -- INICIO DE TRANSACCIÓN ATÓMICA CON BLOQUEO PESIMISTA
    -- =========================================================================
    START TRANSACTION;

    -- Bloqueo pesimista a nivel de fila sobre la sección solicitada
    SELECT s.id_curso, s.vacantes_disponibles, s.estado, c.creditos
    INTO v_id_curso, v_vacantes_disponibles, v_estado_seccion, v_creditos_curso
    FROM seccion s
    INNER JOIN curso c ON s.id_curso = c.id_curso
    WHERE s.id_seccion = p_id_seccion
    FOR UPDATE;

    -- Validar que la sección exista
    IF v_id_curso IS NULL THEN
        ROLLBACK;
        SET p_codigo_error = 404;
        SET p_mensaje = 'La sección solicitada no existe.';
        LEAVE proc_label;
    END IF;

    -- Validar que haya cupo disponible
    IF v_vacantes_disponibles <= 0 OR v_estado_seccion = 'CERRADA' THEN
        ROLLBACK;
        SET p_codigo_error = 409;
        SET p_mensaje = 'Vacantes agotadas para la sección seleccionada.';
        LEAVE proc_label;
    END IF;

    -- Validar que el estudiante no tenga ya matriculado este curso (en otra sección)
    SELECT COUNT(*) INTO v_existe_curso_en_proforma
    FROM detalle_matricula dm
    INNER JOIN seccion sec ON dm.id_seccion = sec.id_seccion
    WHERE dm.id_matricula = p_id_matricula AND sec.id_curso = v_id_curso;

    IF v_existe_curso_en_proforma > 0 THEN
        ROLLBACK;
        SET p_codigo_error = 400;
        SET p_mensaje = 'Ya tiene una sección seleccionada para esta asignatura en su proforma.';
        LEAVE proc_label;
    END IF;

    -- Validar que no se exceda el límite de créditos permitido
    IF (v_total_creditos + v_creditos_curso) > v_creditos_permitidos THEN
        ROLLBACK;
        SET p_codigo_error = 400;
        SET p_mensaje = CONCAT('Supera su límite de créditos permitido. Máximo: ', v_creditos_permitidos, ' créditos.');
        LEAVE proc_label;
    END IF;

    -- 1. Insertar en detalle de matrícula
    INSERT INTO detalle_matricula (id_matricula, id_seccion, creditos, estado)
    VALUES (p_id_matricula, p_id_seccion, v_creditos_curso, 'RESERVADO_TEMPORAL');

    -- 2. Descontar la vacante y actualizar estado si se agota
    UPDATE seccion 
    SET vacantes_disponibles = vacantes_disponibles - 1,
        estado = IF(vacantes_disponibles - 1 = 0, 'CERRADA', 'ABIERTA')
    WHERE id_seccion = p_id_seccion;

    -- 3. Actualizar créditos acumulados en cabecera
    UPDATE matricula 
    SET total_creditos = total_creditos + v_creditos_curso
    WHERE id_matricula = p_id_matricula;

    COMMIT;

    SET p_codigo_error = 200;
    SET p_mensaje = 'Asignatura y sección agregadas exitosamente con cupo reservado.';
END$$

-- -----------------------------------------------------------------------------
-- 3. SP: sp_desmatricular_curso
-- Retira una asignatura de la proforma y restituye inmediatamente la vacante.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_desmatricular_curso$$
CREATE PROCEDURE sp_desmatricular_curso(
    IN p_id_matricula INT,
    IN p_id_seccion INT,
    OUT p_codigo_error INT,
    OUT p_mensaje VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_es_editable BOOLEAN;
    DECLARE v_creditos_curso INT;
    DECLARE v_existe INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_codigo_error = 500;
        SET p_mensaje = 'Error interno al intentar retirar la asignatura de la proforma.';
    END;

    -- Validar que la matrícula sea editable
    SELECT es_editable INTO v_es_editable FROM matricula WHERE id_matricula = p_id_matricula;
    IF v_es_editable IS NULL OR v_es_editable = FALSE THEN
        SET p_codigo_error = 403;
        SET p_mensaje = 'No se puede modificar una matrícula confirmada o inexistente.';
        LEAVE proc_label;
    END IF;

    -- Verificar que la sección esté en la proforma
    SELECT creditos INTO v_creditos_curso
    FROM detalle_matricula 
    WHERE id_matricula = p_id_matricula AND id_seccion = p_id_seccion;

    IF v_creditos_curso IS NULL THEN
        SET p_codigo_error = 404;
        SET p_mensaje = 'La sección indicada no figura en la proforma del estudiante.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    -- 1. Eliminar de detalle_matricula
    DELETE FROM detalle_matricula 
    WHERE id_matricula = p_id_matricula AND id_seccion = p_id_seccion;

    -- 2. Restituir vacante a la sección con bloqueo pesimista
    UPDATE seccion 
    SET vacantes_disponibles = vacantes_disponibles + 1,
        estado = 'ABIERTA'
    WHERE id_seccion = p_id_seccion;

    -- 3. Restar créditos en cabecera
    UPDATE matricula 
    SET total_creditos = total_creditos - v_creditos_curso
    WHERE id_matricula = p_id_matricula;

    COMMIT;

    SET p_codigo_error = 200;
    SET p_mensaje = 'Asignatura retirada de la proforma y vacante liberada satisfactoriamente.';
END$$

-- -----------------------------------------------------------------------------
-- 4. SP: sp_confirmar_matricula
-- Cierre transaccional definitivo: pasa de PROFORMA a CONFIRMADA, valida pago
-- e inscribe inmutabilidad bloqueando futuras modificaciones.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_confirmar_matricula$$
CREATE PROCEDURE sp_confirmar_matricula(
    IN p_id_matricula INT,
    OUT p_codigo_error INT,
    OUT p_mensaje VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_id_estudiante INT;
    DECLARE v_total_creditos INT;
    DECLARE v_condicion VARCHAR(20);
    DECLARE v_cruces_detectados BOOLEAN;
    DECLARE v_id_pago INT;
    DECLARE v_hash_pdf VARCHAR(64);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_codigo_error = 500;
        SET p_mensaje = 'Error transaccional al confirmar la matrícula.';
    END;

    -- Validar proforma
    SELECT m.id_estudiante, m.total_creditos, e.condicion_academica, m.id_pago
    INTO v_id_estudiante, v_total_creditos, v_condicion, v_id_pago
    FROM matricula m
    INNER JOIN estudiante e ON m.id_estudiante = e.id_estudiante
    WHERE m.id_matricula = p_id_matricula AND m.estado = 'PROFORMA';

    IF v_id_estudiante IS NULL THEN
        SET p_codigo_error = 404;
        SET p_mensaje = 'Proforma no encontrada o ya confirmada previamente.';
        LEAVE proc_label;
    END IF;

    -- Validar que tenga cursos seleccionados
    IF v_total_creditos <= 0 THEN
        SET p_codigo_error = 400;
        SET p_mensaje = 'Debe seleccionar al menos una asignatura antes de confirmar.';
        LEAVE proc_label;
    END IF;

    -- Validar mínimo de créditos para condición Regular / Destacado
    IF v_condicion IN ('REGULAR', 'DESTACADO') AND v_total_creditos < 12 THEN
        SET p_codigo_error = 400;
        SET p_mensaje = 'No cumple con el mínimo de 12 créditos exigidos para su condición.';
        LEAVE proc_label;
    END IF;

    -- Validar que no existan cruces de horario
    SELECT fn_validar_cruces_horario(p_id_matricula) INTO v_cruces_detectados;
    IF v_cruces_detectados = TRUE THEN
        SET p_codigo_error = 400;
        SET p_mensaje = 'Tiene asignaturas con cruce de horario. Resuelva los conflictos antes de confirmar.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    -- Generar código hash único para validación de la Ficha en PDF
    SET v_hash_pdf = SHA2(CONCAT(p_id_matricula, v_id_estudiante, NOW()), 256);

    -- 1. Actualizar cabecera a CONFIRMADA e inmutable
    UPDATE matricula 
    SET estado = 'CONFIRMADA',
        es_editable = FALSE,
        fecha_confirmacion = NOW(),
        codigo_verificacion = v_hash_pdf
    WHERE id_matricula = p_id_matricula;

    -- 2. Consolidar el detalle de la matrícula a CONFIRMADO
    UPDATE detalle_matricula 
    SET estado = 'CONFIRMADO' 
    WHERE id_matricula = p_id_matricula;

    -- 3. Marcar turno como finalizado en la cola virtual
    UPDATE cola_virtual 
    SET estado_turno = 'FINALIZADO' 
    WHERE id_estudiante = v_id_estudiante;

    COMMIT;

    SET p_codigo_error = 200;
    SET p_mensaje = 'Matrícula confirmada exitosamente. Ficha oficial disponible para descarga.';
END$$

-- -----------------------------------------------------------------------------
-- 5. SP: sp_cancelar_reserva_timeout
-- Cancela la proforma y restituye todas las vacantes si expiran los 5 minutos.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_cancelar_reserva_timeout$$
CREATE PROCEDURE sp_cancelar_reserva_timeout(
    IN p_id_estudiante INT,
    OUT p_codigo_error INT,
    OUT p_mensaje VARCHAR(255)
)
BEGIN
    DECLARE v_id_matricula INT;

    SELECT id_matricula INTO v_id_matricula 
    FROM matricula 
    WHERE id_estudiante = p_id_estudiante AND estado = 'PROFORMA';

    IF v_id_matricula IS NOT NULL THEN
        START TRANSACTION;

        -- Restituir vacantes de todos los cursos que estaban reservados
        UPDATE seccion s
        INNER JOIN detalle_matricula dm ON s.id_seccion = dm.id_seccion
        SET s.vacantes_disponibles = s.vacantes_disponibles + 1,
            s.estado = 'ABIERTA'
        WHERE dm.id_matricula = v_id_matricula AND dm.estado = 'RESERVADO_TEMPORAL';

        -- Marcar estado de detalle como LIBERADO
        UPDATE detalle_matricula 
        SET estado = 'LIBERADO' 
        WHERE id_matricula = v_id_matricula;

        -- Cancelar la proforma
        UPDATE matricula 
        SET estado = 'CANCELADA',
            es_editable = FALSE,
            total_creditos = 0
        WHERE id_matricula = v_id_matricula;

        -- Marcar turno expirado en cola
        UPDATE cola_virtual 
        SET estado_turno = 'EXPIRADO' 
        WHERE id_estudiante = p_id_estudiante;

        COMMIT;
        SET p_codigo_error = 200;
        SET p_mensaje = 'Tiempo de 5 minutos expirado. Reservas temporales liberadas.';
    ELSE
        SET p_codigo_error = 404;
        SET p_mensaje = 'No hay proforma activa pendiente para el estudiante.';
    END IF;
END$$

DELIMITER ;
-- =============================================================================
-- SISTEMA WEB DE MATRÍCULA UNIVERSITARIA - UNJBG
-- SCRIPT DE FUNCIONES DETERMINÍSTICAS (FUNCTIONS EN MYSQL)
-- =============================================================================

USE sistema_matricula;

DELIMITER $$

-- -----------------------------------------------------------------------------
-- 1. FUNCIÓN: fn_validar_cronograma
-- Retorna TRUE si la fecha y hora actual (NOW()) se encuentra dentro del rango
-- autorizado para la escuela y condición del estudiante; FALSE en caso contrario.
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_validar_cronograma$$
CREATE FUNCTION fn_validar_cronograma(
    p_id_escuela INT,
    p_es_ingresante BOOLEAN
) 
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_permitido INT DEFAULT 0;
    DECLARE v_condicion_busqueda VARCHAR(20);

    IF p_es_ingresante = TRUE THEN
        SET v_condicion_busqueda = 'INGRESANTE';
    ELSE
        SET v_condicion_busqueda = 'REGULAR';
    END IF;

    SELECT COUNT(*) INTO v_permitido
    FROM cronograma_matricula
    WHERE id_escuela = p_id_escuela
      AND (condicion_estudiante = v_condicion_busqueda OR condicion_estudiante = 'TODOS')
      AND estado = 'ACTIVO'
      AND NOW() BETWEEN fecha_inicio AND fecha_fin;

    IF v_permitido > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- 2. FUNCIÓN: fn_validar_cruces_horario
-- Retorna TRUE si existe solapamiento en día y horas entre las secciones
-- agregadas en la proforma de matrícula; FALSE si el horario está libre de cruces.
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_validar_cruces_horario$$
CREATE FUNCTION fn_validar_cruces_horario(
    p_id_matricula INT
) 
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_cantidad_cruces INT DEFAULT 0;

    -- Compara pares de bloques de horario de las secciones seleccionadas
    SELECT COUNT(*) INTO v_cantidad_cruces
    FROM detalle_matricula dm1
    INNER JOIN horario_seccion h1 ON dm1.id_seccion = h1.id_seccion
    INNER JOIN detalle_matricula dm2 ON dm1.id_matricula = dm2.id_matricula
    INNER JOIN horario_seccion h2 ON dm2.id_seccion = h2.id_seccion
    WHERE dm1.id_matricula = p_id_matricula
      AND dm1.id_seccion < dm2.id_seccion -- Evita comparar una sección consigo misma o duplicar pares
      AND h1.dia_semana = h2.dia_semana   -- Mismo día de la semana
      -- Condición de solapamiento de intervalos de tiempo: [Inicio1, Fin1) cruza con [Inicio2, Fin2)
      AND (h1.hora_inicio < h2.hora_fin AND h1.hora_fin > h2.hora_inicio);

    IF v_cantidad_cruces > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- 3. FUNCIÓN: fn_validar_requisitos_completos
-- Verifica si un estudiante ingresante ha subido los 4 documentos obligatorios
-- exigidos en el módulo de Portafolio de Admisión.
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_validar_requisitos_completos$$
CREATE FUNCTION fn_validar_requisitos_completos(
    p_id_estudiante INT
) 
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total_obligatorios INT DEFAULT 0;
    DECLARE v_total_entregados INT DEFAULT 0;

    -- Conteo total de requisitos obligatorios configurados
    SELECT COUNT(*) INTO v_total_obligatorios
    FROM tipo_documento_requisito
    WHERE es_obligatorio = TRUE;

    -- Conteo de requisitos entregados válidos por el alumno
    SELECT COUNT(DISTINCT pd.id_tipo_documento) INTO v_total_entregados
    FROM portafolio_documento pd
    INNER JOIN tipo_documento_requisito tdr ON pd.id_tipo_documento = tdr.id_tipo_documento
    WHERE pd.id_estudiante = p_id_estudiante
      AND tdr.es_obligatorio = TRUE
      AND pd.estado IN ('ENTREGADO', 'VALIDADO');

    IF v_total_entregados >= v_total_obligatorios AND v_total_obligatorios > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END$$

DELIMITER ;
-- =============================================================================
-- SISTEMA WEB DE MATRÍCULA UNIVERSITARIA - UNJBG
-- SCRIPT DE VISTAS CONSOLIDADAS (VIEWS EN MYSQL)
-- =============================================================================

USE sistema_matricula;

-- -----------------------------------------------------------------------------
-- 1. VISTA: vw_ficha_matricula
-- Consolida toda la información académica y de asignaturas para generar
-- la Ficha Oficial de Matrícula en PDF (DomPDF / FPDF).
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_ficha_matricula;
CREATE VIEW vw_ficha_matricula AS
SELECT 
    m.id_matricula,
    m.id_estudiante,
    m.estado AS estado_matricula,
    m.total_creditos,
    m.monto_total,
    m.fecha_confirmacion,
    m.codigo_verificacion,
    
    e.codigo AS codigo_estudiante,
    e.dni AS dni_estudiante,
    CONCAT(e.apellidos, ', ', e.nombres) AS nombre_completo_estudiante,
    e.correo_institucional,
    e.condicion_academica,
    e.promedio_ponderado,
    
    f.nombre AS nombre_facultad,
    ep.nombre AS nombre_escuela,
    s.nombre AS nombre_sede,
    p.codigo AS codigo_periodo,
    
    c.codigo AS codigo_curso,
    c.nombre AS nombre_curso,
    c.ciclo AS ciclo_curso,
    dm.creditos AS creditos_curso,
    sec.grupo,
    sec.turno,
    CONCAT(d.apellidos, ', ', d.nombres) AS docente_asignado,
    
    -- Agrupación consolidada de los bloques horarios de la sección
    (SELECT GROUP_CONCAT(CONCAT(hs.dia_semana, ' ', TIME_FORMAT(hs.hora_inicio, '%H:%i'), '-', TIME_FORMAT(hs.hora_fin, '%H:%i'), ' (', hs.aula, ')') SEPARATOR ' | ')
     FROM horario_seccion hs 
     WHERE hs.id_seccion = sec.id_seccion) AS horario_completo
FROM matricula m
INNER JOIN estudiante e ON m.id_estudiante = e.id_estudiante
INNER JOIN escuela_profesional ep ON e.id_escuela = ep.id_escuela
INNER JOIN facultad f ON ep.id_facultad = f.id_facultad
INNER JOIN sede s ON e.id_sede = s.id_sede
INNER JOIN periodo_academico p ON m.id_periodo = p.id_periodo
INNER JOIN detalle_matricula dm ON m.id_matricula = dm.id_matricula
INNER JOIN seccion sec ON dm.id_seccion = sec.id_seccion
INNER JOIN curso c ON sec.id_curso = c.id_curso
INNER JOIN docente d ON sec.id_docente = d.id_docente;

-- -----------------------------------------------------------------------------
-- 2. VISTA: vw_catalogo_oferta_academica
-- Expone los cursos activos con sus secciones disponibles, docentes y cupos
-- para la interfaz de selección del estudiante.
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_catalogo_oferta_academica;
CREATE VIEW vw_catalogo_oferta_academica AS
SELECT 
    sec.id_seccion,
    sec.id_periodo,
    p.codigo AS codigo_periodo,
    c.id_curso,
    c.codigo AS codigo_curso,
    c.nombre AS nombre_curso,
    c.ciclo,
    c.creditos,
    c.horas_teoria,
    c.horas_practica,
    sec.grupo, -- 'A' o 'B'
    sec.turno, -- 'MAÑANA' o 'TARDE'
    sec.vacantes_totales,
    sec.vacantes_disponibles,
    sec.estado AS estado_seccion,
    CONCAT(d.apellidos, ', ', d.nombres) AS docente_nombre,
    (SELECT GROUP_CONCAT(CONCAT(hs.dia_semana, ' ', TIME_FORMAT(hs.hora_inicio, '%H:%i'), '-', TIME_FORMAT(hs.hora_fin, '%H:%i')) SEPARATOR ', ')
     FROM horario_seccion hs 
     WHERE hs.id_seccion = sec.id_seccion) AS horarios_resumen
FROM seccion sec
INNER JOIN curso c ON sec.id_curso = c.id_curso
INNER JOIN periodo_academico p ON sec.id_periodo = p.id_periodo
INNER JOIN docente d ON sec.id_docente = d.id_docente
WHERE p.estado = 'ACTIVO';
-- =============================================================================
-- SISTEMA WEB DE MATRÍCULA UNIVERSITARIA - UNJBG
-- SCRIPT DE DATOS INICIALES DE PRUEBA (SEEDS EN MYSQL)
-- =============================================================================

USE sistema_matricula;

-- 1. FACULTAD
INSERT INTO facultad (id_facultad, codigo, nombre, estado) VALUES
(1, 'FAING', 'Facultad de Ingeniería', 'ACTIVO');

-- 2. ESCUELA PROFESIONAL
INSERT INTO escuela_profesional (id_escuela, id_facultad, codigo, nombre, estado) VALUES
(1, 1, 'ESIS', 'Ingeniería en Informática y Sistemas', 'ACTIVO');

-- 3. SEDE
INSERT INTO sede (id_sede, nombre, direccion, ciudad) VALUES
(1, 'Sede Central Capanique', 'Av. Miraflores S/N - Campus Capanique', 'Tacna');

-- 4. PERIODO ACADÉMICO
INSERT INTO periodo_academico (id_periodo, codigo, nombre, fecha_inicio, fecha_fin, estado) VALUES
(1, '2026-II', 'Semestre Académico 2026-II', '2026-08-01', '2026-12-31', 'ACTIVO');

-- 5. CRONOGRAMA DE MATRÍCULA (Vigente durante todo el año 2026 para pruebas)
INSERT INTO cronograma_matricula (id_periodo, id_escuela, condicion_estudiante, fecha_inicio, fecha_fin, estado) VALUES
(1, 1, 'INGRESANTE', '2026-01-01 00:00:00', '2026-12-31 23:59:59', 'ACTIVO'),
(1, 1, 'REGULAR',    '2026-01-01 00:00:00', '2026-12-31 23:59:59', 'ACTIVO'),
(1, 1, 'TODOS',      '2026-01-01 00:00:00', '2026-12-31 23:59:59', 'ACTIVO');

-- 6. TIPOS DE DOCUMENTO (Portafolio de Admisión)
INSERT INTO tipo_documento_requisito (id_tipo_documento, codigo, nombre, es_obligatorio) VALUES
(1, 'CONSTANCIA_INGRESO', 'Constancia Oficial de Ingreso', TRUE),
(2, 'DNI', 'Documento Nacional de Identidad (DNI)', TRUE),
(3, 'FOTO_CARNE', 'Fotografía para Carné Universitario', TRUE),
(4, 'EXAMEN_SALUD', 'Constancia de Examen de Salud', TRUE);

-- 7. PLAN DE ESTUDIOS
INSERT INTO plan_estudios (id_plan, id_escuela, codigo, anio, estado) VALUES
(1, 1, 'PLAN-2020', 2020, 'VIGENTE');

-- 8. ASIGNATURAS (CURSOS)
INSERT INTO curso (id_curso, id_plan, codigo, nombre, ciclo, creditos, horas_teoria, horas_practica) VALUES
(1, 1, 'IS-501', 'Base de Datos II', 5, 4, 2, 2),
(2, 1, 'IS-502', 'Ingeniería de Software I', 5, 4, 2, 2),
(3, 1, 'IS-503', 'Redes y Comunicaciones', 5, 4, 2, 2),
(4, 1, 'IS-504', 'Sistemas Operativos', 5, 4, 2, 2),
(5, 1, 'IS-505', 'Estadística y Probabilidades', 5, 4, 2, 2),
(6, 1, 'IS-601', 'Inteligencia Artificial', 6, 4, 2, 2); -- Curso superior (Para adelanto de Destacados)

-- 9. PRERREQUISITOS DE ASIGNATURAS
INSERT INTO prerrequisito_curso (id_curso, id_curso_requisito) VALUES
(6, 1); -- Inteligencia Artificial exige Base de Datos II

-- 10. DOCENTES
INSERT INTO docente (id_docente, codigo, dni, nombres, apellidos, correo_institucional) VALUES
(1, 'DOC-101', '10203040', 'Carlos Alberto', 'Flores Mamani', 'cfloresm@unjbg.edu.pe'),
(2, 'DOC-102', '20304050', 'Rosa Elena', 'Vargas Quispe', 'rvargasq@unjbg.edu.pe'),
(3, 'DOC-103', '30405060', 'Manuel Jesús', 'Paredes Choque', 'mparedesc@unjbg.edu.pe'),
(4, 'DOC-104', '40506070', 'Jorge Luis', 'Medina Ticona', 'jmedinat@unjbg.edu.pe');

-- 11. SECCIONES (Grupo A Mañana / Grupo B Tarde)
INSERT INTO seccion (id_seccion, id_curso, id_periodo, id_docente, grupo, turno, vacantes_totales, vacantes_disponibles, estado) VALUES
-- IS-501: Base de Datos II
(1, 1, 1, 1, 'A', 'MAÑANA', 35, 35, 'ABIERTA'),
(2, 1, 1, 1, 'B', 'TARDE',  35, 35, 'ABIERTA'),
-- IS-502: Ingeniería de Software I
(3, 2, 1, 2, 'A', 'MAÑANA', 35, 35, 'ABIERTA'),
(4, 2, 1, 2, 'B', 'TARDE',  35, 35, 'ABIERTA'),
-- IS-503: Redes y Comunicaciones
(5, 3, 1, 3, 'A', 'MAÑANA', 35, 35, 'ABIERTA'),
(6, 3, 1, 3, 'B', 'TARDE',  35, 35, 'ABIERTA'),
-- IS-504: Sistemas Operativos
(7, 4, 1, 4, 'A', 'MAÑANA', 35, 35, 'ABIERTA'),
(8, 4, 1, 4, 'B', 'TARDE',  35, 35, 'ABIERTA'),
-- IS-505: Estadística y Probabilidades
(9, 5, 1, 2, 'A', 'MAÑANA', 35, 35, 'ABIERTA'),
(10, 5, 1, 2, 'B', 'TARDE', 35, 35, 'ABIERTA'),
-- IS-601: Inteligencia Artificial (Adelanto) - SECCIÓN CON 1 VACANTE (Para probar que se agota!)
(11, 6, 1, 1, 'A', 'MAÑANA', 1, 1, 'ABIERTA');

-- 12. HORARIOS DE LAS SECCIONES
-- Grupo A: Lunes a Viernes por la Mañana (08:00 a 12:00)
INSERT INTO horario_seccion (id_seccion, dia_semana, hora_inicio, hora_fin, aula) VALUES
-- BD II Grupo A
(1, 'LUNES',     '08:00:00', '10:00:00', 'Lab-Sistemas 1'),
(1, 'MIERCOLES', '08:00:00', '10:00:00', 'Lab-Sistemas 1'),
-- Ing. Software I Grupo A
(3, 'MARTES',    '08:00:00', '10:00:00', 'Aula 201'),
(3, 'JUEVES',    '08:00:00', '10:00:00', 'Aula 201'),
-- Redes Grupo A
(5, 'LUNES',     '10:00:00', '12:00:00', 'Lab-Redes'),
(5, 'MIERCOLES', '10:00:00', '12:00:00', 'Lab-Redes'),
-- Sistemas Operativos Grupo A
(7, 'MARTES',    '10:00:00', '12:00:00', 'Lab-Sistemas 2'),
(7, 'JUEVES',    '10:00:00', '12:00:00', 'Lab-Sistemas 2'),
-- Estadística Grupo A
(9, 'VIERNES',   '08:00:00', '12:00:00', 'Aula 202'),

-- Grupo B: Lunes a Viernes por la Tarde (14:00 a 18:00)
-- BD II Grupo B
(2, 'LUNES',     '14:00:00', '16:00:00', 'Lab-Sistemas 1'),
(2, 'MIERCOLES', '14:00:00', '16:00:00', 'Lab-Sistemas 1'),
-- Ing. Software I Grupo B
(4, 'MARTES',    '14:00:00', '16:00:00', 'Aula 201'),
(4, 'JUEVES',    '14:00:00', '16:00:00', 'Aula 201'),
-- Redes Grupo B
(6, 'LUNES',     '16:00:00', '18:00:00', 'Lab-Redes'),
(6, 'MIERCOLES', '16:00:00', '18:00:00', 'Lab-Redes'),
-- Sistemas Operativos Grupo B
(8, 'MARTES',    '16:00:00', '18:00:00', 'Lab-Sistemas 2'),
(8, 'JUEVES',    '16:00:00', '18:00:00', 'Lab-Sistemas 2'),
-- Estadística Grupo B
(10, 'VIERNES',  '14:00:00', '18:00:00', 'Aula 202'),

-- Inteligencia Artificial Grupo A (Sección 11 - Cruzará con BD II Grupo A los Lunes de 08:00 a 10:00 para probar la alerta de cruce!)
(11, 'LUNES',    '08:00:00', '10:00:00', 'Lab-Sistemas 3'),
(11, 'VIERNES',  '16:00:00', '18:00:00', 'Lab-Sistemas 3');

-- 13. ESTUDIANTES DE PRUEBA
-- Password para todos: '123456' (Hash Bcrypt estándar)
-- Hash: '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2' (o string simple en pruebas)
INSERT INTO estudiante (id_estudiante, codigo, dni, nombres, apellidos, correo_institucional, password_hash, id_escuela, id_sede, es_ingresante, condicion_academica, promedio_ponderado, creditos_permitidos, estado) VALUES
-- Estudiante 1: Ingresante SIN portafolio (Para probar bloqueo por documentos pendientes)
(1, '2026-119001', '71000001', 'Juan Carlos', 'Pérez Condori', 'jperezc@unjbg.edu.pe', '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2', 1, 1, TRUE, 'REGULAR', 0.00, 23, 'ACTIVO'),

-- Estudiante 2: Ingresante CON portafolio completo (Para probar que pasa a la cola)
(2, '2026-119002', '71000002', 'María Fernanda', 'Gómez Quispe', 'mgomezq@unjbg.edu.pe', '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2', 1, 1, TRUE, 'REGULAR', 0.00, 23, 'ACTIVO'),

-- Estudiante 3: Regular (Promedio 13.50, límite 23 créditos)
(3, '2023-119010', '71000003', 'Kevin Arnold', 'Mamani Ticona', 'kmamanit@unjbg.edu.pe', '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2', 1, 1, FALSE, 'REGULAR', 13.50, 23, 'ACTIVO'),

-- Estudiante 4: Destacado (Promedio 16.80, límite 28 créditos, opción de adelantar curso)
(4, '2022-119005', '71000004', 'Andrea Sofía', 'López Ramos', 'alopezr@unjbg.edu.pe', '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2', 1, 1, FALSE, 'DESTACADO', 16.80, 28, 'ACTIVO'),

-- Estudiante 5: Especial (Promedio 10.20, límite 11 créditos)
(5, '2021-119099', '71000005', 'Christian David', 'Huanca Calizaya', 'chuancac@unjbg.edu.pe', '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2', 1, 1, FALSE, 'ESPECIAL', 10.20, 11, 'ACTIVO');

-- 14. DOCUMENTOS DE PORTAFOLIO (Para Estudiante 2 que ya tiene sus 4 requisitos)
INSERT INTO portafolio_documento (id_estudiante, id_tipo_documento, ruta_archivo, formato, peso_kb, estado) VALUES
(2, 1, '/uploads/portafolio/constancia_2026119002.png', 'PNG', 450, 'ENTREGADO'),
(2, 2, '/uploads/portafolio/dni_2026119002.jpg', 'JPG', 380, 'ENTREGADO'),
(2, 3, '/uploads/portafolio/foto_2026119002.jpg', 'JPG', 220, 'ENTREGADO'),
(2, 4, '/uploads/portafolio/salud_2026119002.png', 'PNG', 510, 'ENTREGADO');

-- 15. REGISTRO DE COLA VIRTUAL INICIAL
INSERT INTO cola_virtual (id_estudiante, posicion, estado_turno, fecha_ingreso_cola, fecha_inicio_turno, fecha_expiracion) VALUES
(3, 1, 'TURNO_HABILITADO', NOW(), NOW(), DATE_ADD(NOW(), INTERVAL 300 SECOND)), -- Turno activo (5 min)
(4, 2, 'EN_ESPERA', NOW(), NULL, NULL);

-- 16. REGISTRO DE PROFORMA INICIAL PARA ESTUDIANTE 3 (REGULAR)
INSERT INTO matricula (id_matricula, id_estudiante, id_periodo, id_pago, total_creditos, monto_total, estado, es_editable) VALUES
(1, 3, 1, NULL, 0, 120.00, 'PROFORMA', TRUE);

-- 17. PAGOS REGISTRADOS
INSERT INTO pago_matricula (id_pago, id_estudiante, id_periodo, nro_operacion, monto, estado) VALUES
(1, 3, 1, 'BN-2026-981245', 120.00, 'PAGADO'),
(2, 4, 1, 'BN-2026-981246', 120.00, 'PAGADO');
