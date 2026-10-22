<?php
// =============================================================================
// ENDPOINT: POST /api/matricula/confirmar.php
// RF-19: Confirmación transaccional de PROFORMA a CONFIRMADA
// RF-20: Bloqueo de ediciones (es_editable = FALSE)
// =============================================================================

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth_middleware.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error("Método no permitido. Utilice POST.", 405);
}

$estudiante = verificar_token();
$input = get_json_input();

$id_proforma = isset($input['id_proforma']) ? (int)$input['id_proforma'] : 0;
if ($id_proforma <= 0) {
    json_error("Debe proporcionar el id_proforma a confirmar.", 400);
}

$pdo = Database::getConnection();

// Verificar pertenencia y estado
$stmtVerif = $pdo->prepare("SELECT id_matricula, estado, es_editable FROM matricula WHERE id_matricula = ? AND id_estudiante = ?");
$stmtVerif->execute([$id_proforma, $estudiante['id_estudiante']]);
$proforma = $stmtVerif->fetch();

if (!$proforma) {
    json_error("La proforma no pertenece al estudiante autenticado o no existe.", 403);
}

if ($proforma['estado'] === 'CONFIRMADA') {
    json_error("La matrícula ya se encuentra confirmada.", 400);
}

// Asegurar que tenga un registro de pago asociado para la confirmación
$stmtPago = $pdo->prepare("
    SELECT id_pago FROM pago_matricula 
    WHERE id_estudiante = ? AND estado = 'PAGADO' 
    ORDER BY id_pago DESC LIMIT 1
");
$stmtPago->execute([$estudiante['id_estudiante']]);
$pago = $stmtPago->fetch();

if ($pago) {
    $stmtSetPago = $pdo->prepare("UPDATE matricula SET id_pago = ? WHERE id_matricula = ?");
    $stmtSetPago->execute([$pago['id_pago'], $id_proforma]);
}

// Invocar el procedimiento almacenado transaccional en MySQL
$stmt = $pdo->prepare("CALL sp_confirmar_matricula(:proforma, @codigo, @mensaje)");
$stmt->execute([':proforma' => $id_proforma]);
$stmt->closeCursor();

$res = $pdo->query("SELECT @codigo AS codigo, @mensaje AS mensaje")->fetch();
$codigoRes = (int)($res['codigo'] ?? 500);
$mensajeRes = $res['mensaje'] ?? 'Error desconocido al confirmar matrícula.';

if ($codigoRes === 200) {
    // Consultar matrícula actualizada
    $stmtMat = $pdo->prepare("SELECT id_matricula, estado, es_editable, fecha_confirmacion, codigo_verificacion FROM matricula WHERE id_matricula = ?");
    $stmtMat->execute([$id_proforma]);
    $matConfirmada = $stmtMat->fetch();

    json_response([
        'mensaje'             => $mensajeRes,
        'estado'              => 'CONFIRMADA',
        'fecha_confirmacion'  => $matConfirmada['fecha_confirmacion'],
        'codigo_verificacion' => $matConfirmada['codigo_verificacion'],
        'url_pdf'             => "/api/reportes/generar_ficha.php?id={$id_proforma}"
    ], 200);
} else {
    json_error($mensajeRes, $codigoRes);
}
