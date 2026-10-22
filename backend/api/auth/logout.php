<?php
// =============================================================================
// ENDPOINT: POST /api/auth/logout.php
// RF-02: Cierre de sesión del estudiante
// =============================================================================

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../helpers/response.php';

json_response([
    'mensaje' => 'Sesión cerrada satisfactoriamente.'
]);
