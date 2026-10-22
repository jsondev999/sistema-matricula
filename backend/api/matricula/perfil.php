<?php
// =============================================================================
// ENDPOINT: GET /api/matricula/perfil.php
// RF-10 y RF-14: Consulta datos académicos del estudiante, periodo y proforma activa
// =============================================================================

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth_middleware.php';

$estudiante = verificar_token();
$pdo = Database::getConnection();

// 1. Consultar periodo activo
$stmtP = $pdo->query("SELECT id_periodo, codigo, nombre FROM periodo_academico WHERE estado = 'ACTIVO' LIMIT 1");
$periodo = $stmtP->fetch() ?: ['id_periodo' => 1, 'codigo' => '2026-II', 'nombre' => 'Semestre 2026-II'];

// 2. Obtener o crear cabecera de matrícula (proforma)
$stmtM = $pdo->prepare("
    SELECT id_matricula, total_creditos, monto_total, estado, es_editable, fecha_confirmacion, codigo_verificacion
    FROM matricula
    WHERE id_estudiante = ? AND id_periodo = ?
");
$stmtM->execute([$estudiante['id_estudiante'], $periodo['id_periodo']]);
$matricula = $stmtM->fetch();

if (!$matricula) {
    $stmtIns = $pdo->prepare("
        INSERT INTO matricula (id_estudiante, id_periodo, total_creditos, monto_total, estado, es_editable)
        VALUES (?, ?, 0, 120.00, 'PROFORMA', TRUE)
    ");
    $stmtIns->execute([$estudiante['id_estudiante'], $periodo['id_periodo']]);
    $idMatricula = (int)$pdo->lastInsertId();
    $matricula = [
        'id_matricula'        => $idMatricula,
        'total_creditos'      => 0,
        'monto_total'         => 120.00,
        'estado'              => 'PROFORMA',
        'es_editable'         => true,
        'fecha_confirmacion'  => null,
        'codigo_verificacion' => null
    ];
}

// 3. Consultar datos institucionales completos
$stmtD = $pdo->prepare("
    SELECT e.id_estudiante, e.codigo, e.dni, e.nombres, e.apellidos, e.correo_institucional,
           e.condicion_academica, e.promedio_ponderado, e.creditos_permitidos, e.es_ingresante,
           ep.nombre AS escuela_profesional, f.nombre AS facultad, s.nombre AS sede
    FROM estudiante e
    INNER JOIN escuela_profesional ep ON e.id_escuela = ep.id_escuela
    INNER JOIN facultad f ON ep.id_facultad = f.id_facultad
    INNER JOIN sede s ON e.id_sede = s.id_sede
    WHERE e.id_estudiante = ?
");
$stmtD->execute([$estudiante['id_estudiante']]);
$perfil = $stmtD->fetch();

json_response([
    'estudiante' => $perfil,
    'periodo'    => $periodo,
    'matricula'  => $matricula
]);
