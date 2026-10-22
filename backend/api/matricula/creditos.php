<?php
// =============================================================================
// ENDPOINT: GET /api/matricula/creditos.php
// Clasifica al estudiante y calcula límite de créditos mediante SP
// =============================================================================

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth_middleware.php';

$estudiante = verificar_token();
$pdo = Database::getConnection();

// Invocar el procedimiento almacenado en MySQL
$stmt = $pdo->prepare("CALL sp_determinar_limite_creditos(:id_est, @condicion, @limite_min, @limite_max, @adelanto)");
$stmt->execute([':id_est' => $estudiante['id_estudiante']]);
$stmt->closeCursor();

// Obtener parámetros OUT
$res = $pdo->query("SELECT @condicion AS condicion, @limite_min AS limite_min, @limite_max AS limite_max, @adelanto AS puede_adelantar")->fetch();

json_response([
    'id_estudiante'   => $estudiante['id_estudiante'],
    'promedio'        => (float)$estudiante['promedio_ponderado'],
    'condicion'       => $res['condicion'],
    'limite_min'      => (int)$res['limite_min'],
    'limite_max'      => (int)$res['limite_max'],
    'puede_adelantar' => (bool)$res['puede_adelantar']
]);
