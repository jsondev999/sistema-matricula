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
    sec.turno, -- 'MANANA' o 'TARDE'
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
