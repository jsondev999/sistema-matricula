<?php
// =============================================================================
// FUNCIONES AUXILIARES PARA RESPUESTAS JSON Y PARSEO DE ENTRADAS
// =============================================================================

function json_response(mixed $data, int $status = 200): void {
    http_response_code($status);
    echo json_encode([
        'status' => 'success',
        'data'   => $data
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit(0);
}

function json_error(string $message, int $status = 400, array $extra = []): void {
    http_response_code($status);
    $payload = array_merge([
        'status'  => 'error',
        'mensaje' => $message
    ], $extra);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit(0);
}

function get_json_input(): array {
    $raw = file_get_contents("php://input");
    if (empty($raw)) {
        return $_POST; // Fallback si viene como form-data
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}
