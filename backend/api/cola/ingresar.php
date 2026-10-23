<?php
// =============================================================================
// ENDPOINT: POST /api/cola/ingresar.php
// Bloquear acceso a cola si el ingresante no tiene 4 documentos
// Inscribir estudiante en la sala de espera virtual
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

// Si ya existe pero está en estado terminal, eliminar para permitir reingreso
if ($cola && in_array($cola['estado_turno'], ['EXPIRADO', 'CANCELADA'])) {
    $pdo->prepare("DELETE FROM cola_virtual WHERE id_cola = ?")->execute([$cola['id_cola']]);
    $cola = null;
}

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

// Verificar si ya existe una matrícula para este estudiante y periodo
$stmtExistente = $pdo->prepare("
    SELECT id_matricula, estado, es_editable
    FROM matricula
    WHERE id_estudiante = ? AND id_periodo = ?
    LIMIT 1
");
$stmtExistente->execute([$estudiante['id_estudiante'], $id_periodo]);
$matriculaExistente = $stmtExistente->fetch();

if ($matriculaExistente) {
    // Si existe pero está CANCELADA (turno expirado anterior), reactivarla como PROFORMA editable
    if (in_array($matriculaExistente['estado'], ['CANCELADA', 'EXPIRADA'])) {
        $stmtReactivar = $pdo->prepare("
            UPDATE matricula
            SET estado = 'PROFORMA',
                es_editable = TRUE,
                total_creditos = 0,
                id_pago = NULL,
                fecha_confirmacion = NULL,
                codigo_verificacion = NULL,
                fecha_creacion_proforma = NOW()
            WHERE id_matricula = ?
        ");
        $stmtReactivar->execute([$matriculaExistente['id_matricula']]);

        // También limpiar detalles anteriores de esa matrícula para empezar limpio
        $stmtLimpiar = $pdo->prepare("DELETE FROM detalle_matricula WHERE id_matricula = ?");
        $stmtLimpiar->execute([$matriculaExistente['id_matricula']]);
    }
    // Si ya está CONFIRMADA, no tocar (protección)
} else {
    // No existe ningún registro: crear uno nuevo
    $stmtProforma = $pdo->prepare("
        INSERT INTO matricula (id_estudiante, id_periodo, total_creditos, monto_total, estado, es_editable, fecha_creacion_proforma)
        VALUES (?, ?, 0, 120.00, 'PROFORMA', TRUE, NOW())
    ");
    $stmtProforma->execute([$estudiante['id_estudiante'], $id_periodo]);
}

// Obtener segundos restantes reales si el turno ya está habilitado
$segundosRestantes = null;
if ($cola['estado_turno'] === 'TURNO_HABILITADO' && isset($cola['expira_en'])) {
    $segundosRestantes = (int)$cola['expira_en'];
} elseif ($cola['estado_turno'] === 'TURNO_HABILITADO' && isset($cola['fecha_expiracion'])) {
    $stmtSeg = $pdo->prepare("SELECT GREATEST(0, TIMESTAMPDIFF(SECOND, NOW(), ?)) AS seg");
    $stmtSeg->execute([$cola['fecha_expiracion']]);
    $segundosRestantes = (int)($stmtSeg->fetch()['seg'] ?? 300);
}

json_response([
    'mensaje'           => 'Registrado en sala de espera.',
    'posicion'          => (int)$cola['posicion'],
    'estado_turno'      => $cola['estado_turno'],
    'turno_activo'      => ($cola['posicion'] == 1 && $cola['estado_turno'] === 'TURNO_HABILITADO'),
    'segundos_restantes'=> $segundosRestantes
]);
