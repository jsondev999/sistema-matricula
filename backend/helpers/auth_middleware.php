<?php
// =============================================================================
// MIDDLEWARE DE AUTENTICACIÓN Y MANEJO DE TOKENS EN PHP PURO
// =============================================================================

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/response.php';

const SECRET_KEY = 'UNJBG_ESIS_SISTEMA_MATRICULA_2026_SECRET_KEY';

function generar_token(int $id_estudiante, string $codigo): string {
    $payload = [
        'id'        => $id_estudiante,
        'codigo'    => $codigo,
        'timestamp' => time()
    ];
    $json = json_encode($payload);
    $b64 = base64_encode($json);
    $firma = hash_hmac('sha256', $b64, SECRET_KEY);
    return $b64 . '.' . $firma;
}

function verificar_token(): array {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

    if (empty($authHeader) || !preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        json_error("Token de autorización no proporcionado o inválido.", 401);
    }

    $token = $matches[1];
    $partes = explode('.', $token);

    if (count($partes) !== 2) {
        json_error("Formato de token inválido.", 401);
    }

    list($b64, $firma) = $partes;
    $firmaEsperada = hash_hmac('sha256', $b64, SECRET_KEY);

    if (!hash_equals($firmaEsperada, $firma)) {
        json_error("Firma de autenticación no válida.", 401);
    }

    $payload = json_decode(base64_decode($b64), true);
    if (!isset($payload['id'])) {
        json_error("Contenido de sesión corrupto.", 401);
    }

    // Verificar en BD que el estudiante siga activo
    $pdo = Database::getConnection();
    $stmt = $pdo->prepare("SELECT id_estudiante, codigo, nombres, apellidos, id_escuela, es_ingresante, condicion_academica, promedio_ponderado, creditos_permitidos, estado FROM estudiante WHERE id_estudiante = ? AND estado = 'ACTIVO'");
    $stmt->execute([$payload['id']]);
    $estudiante = $stmt->fetch();

    if (!$estudiante) {
        json_error("Usuario no encontrado o inactivo.", 401);
    }

    return $estudiante;
}
