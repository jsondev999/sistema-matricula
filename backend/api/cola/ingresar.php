<?php
// =============================================================================
// ENDPOINT: POST /api/cola/ingresar.php
// RF-06: Bloquear acceso a cola si el ingresante no tiene 4 documentos
// RF-07: Inscribir estudiante en la sala de espera virtual
// =============================================================================

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth_middleware.php';

$estudiante = verificar_token();
$pdo = Database::getConnection();

// 1. Si es ingresante, validar que tenga los 4 documentos completados
if ($estudiante['es_ingresante']) {
    $stmtReq = $pdo->prepare("SELECT fn_validar_requisitos_completos(:id) AS completos");
    $stmtReq->execute([':id' => $estudiante['id_estudiante']]);
    $resReq = $stmtReq->fetch();
    
    if (!($resReq['completos'] ?? false)) {
        json_error("No puede ingresar a la cola virtual: tiene documentos pendientes en su portafolio.", 403, [
            'redirect' => '/portafolio'
        ]);
    }
}

// 2. Verificar si ya tiene un registro en la cola virtual
$stmtCola = $pdo->prepare("
    SELECT id_cola, posicion, estado_turno, fecha_inicio_turno, fecha_expiracion
    FROM cola_virtual 
    WHERE id_estudiante = ?
");
$stmtCola->execute([$estudiante['id_estudiante']]);
$cola = $stmtCola->fetch();

if (!$cola) {
    // Calcular siguiente posición correlativa en la cola
    $stmtMax = $pdo->query("SELECT IFNULL(MAX(posicion), 0) + 1 AS siguiente FROM cola_virtual WHERE estado_turno IN ('EN_ESPERA', 'TURNO_HABILITADO')");
    $siguiente = (int)$stmtMax->fetch()['siguiente'];

    // Si es el primero, habilitar el turno de inmediato con 5 minutos (300 segundos)
    if ($siguiente === 1) {
        $stmtInsert = $pdo->prepare("
            INSERT INTO cola_virtual (id_estudiante, posicion, estado_turno, fecha_ingreso_cola, fecha_inicio_turno, fecha_expiracion)
            VALUES (?, 1, 'TURNO_HABILITADO', NOW(), NOW(), DATE_ADD(NOW(), INTERVAL 300 SECOND))
        ");
        $stmtInsert->execute([$estudiante['id_estudiante']]);
        $cola = [
            'posicion'     => 1,
            'estado_turno' => 'TURNO_HABILITADO',
            'expira_en'    => 300
        ];
    } else {
        $stmtInsert = $pdo->prepare("
            INSERT INTO cola_virtual (id_estudiante, posicion, estado_turno, fecha_ingreso_cola)
            VALUES (?, ?, 'EN_ESPERA', NOW())
        ");
        $stmtInsert->execute([$estudiante['id_estudiante'], $siguiente]);
        $cola = [
            'posicion'     => $siguiente,
            'estado_turno' => 'EN_ESPERA',
            'expira_en'    => null
        ];
    }
}

// 3. Crear o asegurar existencia de registro de proforma inicial para este periodo
$stmtPeriodo = $pdo->query("SELECT id_periodo FROM periodo_academico WHERE estado = 'ACTIVO' LIMIT 1");
$id_periodo = $stmtPeriodo->fetch()['id_periodo'] ?? 1;

$stmtProforma = $pdo->prepare("
    INSERT IGNORE INTO matricula (id_estudiante, id_periodo, total_creditos, monto_total, estado, es_editable, fecha_creacion_proforma)
    VALUES (?, ?, 0, 120.00, 'PROFORMA', TRUE, NOW())
");
$stmtProforma->execute([$estudiante['id_estudiante'], $id_periodo]);

json_response([
    'mensaje'      => 'Registrado en sala de espera.',
    'posicion'     => (int)$cola['posicion'],
    'estado_turno' => $cola['estado_turno'],
    'turno_activo' => ($cola['posicion'] == 1 && $cola['estado_turno'] === 'TURNO_HABILITADO')
]);
