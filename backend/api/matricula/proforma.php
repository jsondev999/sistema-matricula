<?php
// =============================================================================
// ENDPOINT: GET /api/matricula/proforma.php
// Visualizar horario tentativo
// Detección y alerta de cruces de horario mediante función MySQL
// Costo y estado de pago
// =============================================================================

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth_middleware.php';

$estudiante = verificar_token();
$pdo = Database::getConnection();

// 1. Obtener la matrícula activa
$stmtM = $pdo->prepare("
    SELECT m.id_matricula, m.total_creditos, m.monto_total, m.estado, m.es_editable,
           p.id_periodo, p.codigo AS periodo_codigo,
           IFNULL(pm.estado, 'PENDIENTE') AS estado_pago,
           pm.nro_operacion
    FROM matricula m
    INNER JOIN periodo_academico p ON m.id_periodo = p.id_periodo
    LEFT JOIN pago_matricula pm ON m.id_pago = pm.id_pago
    WHERE m.id_estudiante = ? AND p.estado = 'ACTIVO'
");
$stmtM->execute([$estudiante['id_estudiante']]);
$matricula = $stmtM->fetch();

if (!$matricula) {
    json_error("No se encontró una proforma activa para el estudiante.", 404);
}

$id_matricula = $matricula['id_matricula'];

// 2. Obtener lista de cursos y secciones en la proforma
$stmtDetalle = $pdo->prepare("
    SELECT dm.id_detalle, dm.id_seccion, dm.creditos, dm.estado AS estado_detalle,
           c.id_curso, c.codigo AS curso_codigo, c.nombre AS curso_nombre, c.ciclo,
           s.grupo, s.turno,
           CONCAT(d.apellidos, ', ', d.nombres) AS docente_nombre
    FROM detalle_matricula dm
    INNER JOIN seccion s ON dm.id_seccion = s.id_seccion
    INNER JOIN curso c ON s.id_curso = c.id_curso
    INNER JOIN docente d ON s.id_docente = d.id_docente
    WHERE dm.id_matricula = ?
    ORDER BY c.ciclo ASC, c.codigo ASC
");
$stmtDetalle->execute([$id_matricula]);
$items = $stmtDetalle->fetchAll();

// 3. Consultar los horarios de cada sección en la proforma
$stmtHorarios = $pdo->prepare("
    SELECT id_horario, dia_semana, TIME_FORMAT(hora_inicio, '%H:%i') AS hora_inicio, 
           TIME_FORMAT(hora_fin, '%H:%i') AS hora_fin, aula
    FROM horario_seccion
    WHERE id_seccion = :id_seccion
");

$itemsConHorarios = [];
$todosLosBloques = [];

foreach ($items as $item) {
    $item['turno'] = ($item['turno'] === 'MANANA') ? 'MAÑANA' : $item['turno'];
    $stmtHorarios->execute([':id_seccion' => $item['id_seccion']]);
    $horarios = $stmtHorarios->fetchAll();
    $item['horarios'] = $horarios;
    $itemsConHorarios[] = $item;

    foreach ($horarios as $h) {
        $todosLosBloques[] = [
            'id_seccion'   => $item['id_seccion'],
            'curso_codigo' => $item['curso_codigo'],
            'curso_nombre' => $item['curso_nombre'],
            'grupo'        => $item['grupo'],
            'dia_semana'   => $h['dia_semana'],
            'hora_inicio'  => $h['hora_inicio'],
            'hora_fin'     => $h['hora_fin'],
            'aula'         => $h['aula']
        ];
    }
}

// 4. Evaluar si existen cruces mediante la función MySQL fn_validar_cruces_horario
$stmtCruce = $pdo->prepare("SELECT fn_validar_cruces_horario(:id_mat) AS tiene_cruces");
$stmtCruce->execute([':id_mat' => $id_matricula]);
$tieneCruces = (bool)($stmtCruce->fetch()['tiene_cruces'] ?? false);

// 5. Identificar pares en conflicto para pintarlos de rojo en la grilla
$crucesDetallados = [];
if ($tieneCruces) {
    $totalBloques = count($todosLosBloques);
    for ($i = 0; $i < $totalBloques; $i++) {
        for ($j = $i + 1; $j < $totalBloques; $j++) {
            $b1 = $todosLosBloques[$i];
            $b2 = $todosLosBloques[$j];

            if ($b1['id_seccion'] !== $b2['id_seccion'] && $b1['dia_semana'] === $b2['dia_semana']) {
                if ($b1['hora_inicio'] < $b2['hora_fin'] && $b1['hora_fin'] > $b2['hora_inicio']) {
                    $crucesDetallados[] = [
                        'curso_1' => "{$b1['curso_nombre']} ({$b1['grupo']})",
                        'curso_2' => "{$b2['curso_nombre']} ({$b2['grupo']})",
                        'dia'     => $b1['dia_semana'],
                        'rango'   => "{$b1['hora_inicio']}-{$b1['hora_fin']} / {$b2['hora_inicio']}-{$b2['hora_fin']}",
                        'seccion_1' => $b1['id_seccion'],
                        'seccion_2' => $b2['id_seccion']
                    ];
                }
            }
        }
    }
}

json_response([
    'matricula'        => $matricula,
    'total_creditos'   => (int)$matricula['total_creditos'],
    'monto_total'      => (float)$matricula['monto_total'],
    'estado_pago'      => $matricula['estado_pago'],
    'tiene_cruces'     => $tieneCruces,
    'cruces'           => $crucesDetallados,
    'cursos'           => $itemsConHorarios,
    'bloques_horario'  => $todosLosBloques
]);
