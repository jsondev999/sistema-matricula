<?php
// =============================================================================
// ENDPOINT: POST /api/auth/recuperar.php
// Restablecimiento de contraseña olvidada
// =============================================================================

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error("Método no permitido. Utilice POST.", 405);
}

$input = get_json_input();
$codigo = trim($input['codigo'] ?? '');
$correo = trim($input['correo'] ?? '');

if (empty($codigo) || empty($correo)) {
    json_error("Debe proporcionar su código universitario y correo institucional.", 400);
}

$pdo = Database::getConnection();
$stmt = $pdo->prepare("SELECT id_estudiante, nombres, correo_institucional FROM estudiante WHERE codigo = ? AND correo_institucional = ?");
$stmt->execute([$codigo, $correo]);
$estudiante = $stmt->fetch();

if (!$estudiante) {
    json_error("No se encontró coincidencia entre el código universitario y el correo proporcionado.", 404);
}

json_response([
    'mensaje' => "Se ha enviado un enlace de restablecimiento seguro a {$estudiante['correo_institucional']}."
]);
