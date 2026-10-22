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
    turno ENUM('MANANA', 'TARDE') NOT NULL,
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
