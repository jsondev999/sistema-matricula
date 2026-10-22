<?php
// =============================================================================
// ENDPOINT: POST /api/matricula/retirar_curso.php
// RF-15: Retiro de asignatura de la proforma y restitución inmediata de vacante
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
$id_seccion  = isset($input['id_seccion']) ? (int)$input['id_seccion'] : 0;

if ($id_proforma <= 0 || $id_seccion <= 0) {
    json_error("Debe proporcionar id_proforma y id_seccion a retirar.", 400);
}

$pdo = Database::getConnection();

// Verificar que la proforma pertenezca al estudiante
$stmtVerif = $pdo->prepare("SELECT id_matricula, estado, es_editable FROM matricula WHERE id_matricula = ? AND id_estudiante = ?");
$stmtVerif->execute([$id_proforma, $estudiante['id_estudiante']]);
$proforma = $stmtVerif->fetch();

if (!$proforma || $proforma['estado'] !== 'PROFORMA' || !$proforma['es_editable']) {
    json_error("La proforma no es editable o no pertenece al estudiante.", 403);
}

// Invocar el procedimiento almacenado que libera el cupo
$stmt = $pdo->prepare("CALL sp_desmatricular_curso(:proforma, :seccion, @codigo, @mensaje)");
$stmt->execute([
    ':proforma' => $id_proforma,
    ':seccion'  => $id_seccion
]);
$stmt->closeCursor();

$res = $pdo->query("SELECT @codigo AS codigo, @mensaje AS mensaje")->fetch();
$codigoRes = (int)($res['codigo'] ?? 500);
$mensajeRes = $res['mensaje'] ?? 'Error desconocido al retirar curso.';

if ($codigoRes === 200) {
    $stmtTot = $pdo->prepare("SELECT total_creditos FROM matricula WHERE id_matricula = ?");
    $stmtTot->execute([$id_proforma]);
    $totalCreditos = (int)$stmtTot->fetch()['total_creditos'];

    json_response([
        'mensaje'        => $mensajeRes,
        'id_seccion'     => $id_seccion,
        'total_creditos' => $totalCreditos
    ], 200);
} else {
    json_error($mensajeRes, $codigoRes);
}
