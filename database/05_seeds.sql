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
(1, 1, 1, 1, 'A', 'MANANA', 35, 35, 'ABIERTA'),
(2, 1, 1, 1, 'B', 'TARDE',  35, 35, 'ABIERTA'),
-- IS-502: Ingeniería de Software I
(3, 2, 1, 2, 'A', 'MANANA', 35, 35, 'ABIERTA'),
(4, 2, 1, 2, 'B', 'TARDE',  35, 35, 'ABIERTA'),
-- IS-503: Redes y Comunicaciones
(5, 3, 1, 3, 'A', 'MANANA', 35, 35, 'ABIERTA'),
(6, 3, 1, 3, 'B', 'TARDE',  35, 35, 'ABIERTA'),
-- IS-504: Sistemas Operativos
(7, 4, 1, 4, 'A', 'MANANA', 35, 35, 'ABIERTA'),
(8, 4, 1, 4, 'B', 'TARDE',  35, 35, 'ABIERTA'),
-- IS-505: Estadística y Probabilidades
(9, 5, 1, 2, 'A', 'MANANA', 35, 35, 'ABIERTA'),
(10, 5, 1, 2, 'B', 'TARDE', 35, 35, 'ABIERTA'),
-- IS-601: Inteligencia Artificial (Adelanto) - SECCIÓN CON 1 VACANTE (Para probar que se agota!)
(11, 6, 1, 1, 'A', 'MANANA', 1, 1, 'ABIERTA');

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
-- Estudiante 1: Ingresante SIN portafolio (Para probar bloqueo de RF-06)
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
