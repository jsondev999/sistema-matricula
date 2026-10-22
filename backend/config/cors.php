<?php
// =============================================================================
// CONFIGURACIÓN DE CABECERAS CORS Y TIPO DE CONTENIDO JSON
// Permite peticiones asíncronas desde el frontend React (http://localhost:5173)
// =============================================================================

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

// Si el navegador envía una solicitud previa OPTIONS (Pre-flight request), responder 200 OK
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}
