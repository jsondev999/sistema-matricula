<?php
// =============================================================================
// ENDPOINT: GET /api/matricula/catalogo.php
// Consulta asignaturas, secciones Grupo A / B, docentes, vacantes y horarios
// =============================================================================

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth_middleware.php';

$estudiante = verificar_token();
$pdo = Database::getConnection();

// 1. Consultar todos los cursos de la oferta activa
$stmtCursos = $pdo->query("
    SELECT c.id_curso, c.codigo, c.nombre, c.ciclo, c.creditos, c.horas_teoria, c.horas_practica
    FROM curso c
    ORDER BY c.ciclo ASC, c.codigo ASC
");
$cursos = $stmtCursos->fetchAll();

// 2. Para cada curso, consultar sus secciones (Grupo A y Grupo B) con sus horarios
$stmtSecciones = $pdo->prepare("
    SELECT s.id_seccion, s.id_curso, s.grupo, s.turno, s.vacantes_totales, s.vacantes_disponibles, s.estado,
           d.id_docente, CONCAT(d.apellidos, ', ', d.nombres) AS docente_nombre, d.correo_institucional AS docente_correo
    FROM seccion s
    INNER JOIN docente d ON s.id_docente = d.id_docente
    INNER JOIN periodo_academico p ON s.id_periodo = p.id_periodo
    WHERE s.id_curso = :id_curso AND p.estado = 'ACTIVO'
    ORDER BY s.grupo ASC
");

$stmtHorarios = $pdo->prepare("
    SELECT id_horario, dia_semana, TIME_FORMAT(hora_inicio, '%H:%i') AS hora_inicio, 
           TIME_FORMAT(hora_fin, '%H:%i') AS hora_fin, aula
    FROM horario_seccion
    WHERE id_seccion = :id_seccion
    ORDER BY FIELD(dia_semana, 'LUNES', 'MARTES', 'MIÉRCOLES', 'JUEVES', 'VIERNES', 'SÁBADO'), hora_inicio ASC
");

$catalogo = [];

foreach ($cursos as $c) {
    $stmtSecciones->execute([':id_curso' => $c['id_curso']]);
    $secciones = $stmtSecciones->fetchAll();

    $seccionesConHorario = [];
    foreach ($secciones as $sec) {
        $stmtHorarios->execute([':id_seccion' => $sec['id_seccion']]);
        $sec['horarios'] = $stmtHorarios->fetchAll();
        $seccionesConHorario[] = $sec;
    }

    $c['secciones'] = $seccionesConHorario;
    $catalogo[] = $c;
}

json_response($catalogo);
