<?php
// =============================================================================
// ENDPOINT: POST /api/matricula/timeout.php
// RF-09: Cancelación y liberación de cupos por temporizador de 5 minutos expirado
// =============================================================================

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth_middleware.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error("Método no permitido. Utilice POST.", 405);
}

$estudiante = verificar_token();
$pdo = Database::getConnection();

// Invocar el procedimiento almacenado que libera todas las reservas temporales
$stmt = $pdo->prepare("CALL sp_cancelar_reserva_timeout(:id_est, @codigo, @mensaje)");
$stmt->execute([':id_est' => $estudiante['id_estudiante']]);
$stmt->closeCursor();

$res = $pdo->query("SELECT @codigo AS codigo, @mensaje AS mensaje")->fetch();

json_response([
    'expirado' => true,
    'mensaje'  => $res['mensaje'] ?? 'Sesión finalizada por inactividad. Vacantes restituidas.',
    'redirect' => '/cola-virtual'
]);
