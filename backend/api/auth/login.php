<?php
// =============================================================================
// ENDPOINT: POST /api/auth/login.php
// RF-01: Validar código y contraseña
// RF-04: Validar fecha/hora de acceso con fn_validar_cronograma
// =============================================================================

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth_middleware.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error("Método no permitido. Utilice POST.", 405);
}

$input = get_json_input();
$codigo   = trim($input['codigo'] ?? '');
$password = trim($input['password'] ?? '');

if (empty($codigo) || empty($password)) {
    json_error("Debe ingresar su código universitario y contraseña.", 400);
}

$pdo = Database::getConnection();

// 1. Buscar estudiante por código
$stmt = $pdo->prepare("
    SELECT e.id_estudiante, e.codigo, e.dni, e.nombres, e.apellidos, e.password_hash,
           e.id_escuela, ep.nombre AS escuela_nombre, e.id_sede, s.nombre AS sede_nombre,
           e.es_ingresante, e.condicion_academica, e.promedio_ponderado, e.creditos_permitidos, e.estado
    FROM estudiante e
    INNER JOIN escuela_profesional ep ON e.id_escuela = ep.id_escuela
    INNER JOIN sede s ON e.id_sede = s.id_sede
    WHERE e.codigo = :codigo
");
$stmt->execute([':codigo' => $codigo]);
$estudiante = $stmt->fetch();

if (!$estudiante) {
    json_error("El código universitario no se encuentra registrado.", 401);
}

if ($estudiante['estado'] !== 'ACTIVO') {
    json_error("El estudiante no se encuentra en estado ACTIVO en este periodo.", 403);
}

// 2. Validar contraseña (soporta Bcrypt o clave de prueba '123456')
$passwordValido = password_verify($password, $estudiante['password_hash']) || ($password === '123456');
if (!$passwordValido) {
    json_error("Contraseña incorrecta. Intente nuevamente.", 401);
}

// 3. Evaluar cronograma con la función determinística en MySQL
$stmtCrono = $pdo->prepare("SELECT fn_validar_cronograma(:escuela, :ingresante) AS dentro_cronograma");
$stmtCrono->execute([
    ':escuela'    => $estudiante['id_escuela'],
    ':ingresante' => $estudiante['es_ingresante'] ? 1 : 0
]);
$cronoRes = $stmtCrono->fetch();
$dentroCronograma = (bool)($cronoRes['dentro_cronograma'] ?? false);

if (!$dentroCronograma) {
    // Consultar el horario asignado para mostrarlo en el mensaje
    $stmtH = $pdo->prepare("
        SELECT fecha_inicio, fecha_fin 
        FROM cronograma_matricula 
        WHERE id_escuela = :escuela 
          AND (condicion_estudiante = :condicion OR condicion_estudiante = 'TODOS')
          AND estado = 'ACTIVO'
        ORDER BY fecha_inicio ASC LIMIT 1
    ");
    $stmtH->execute([
        ':escuela'   => $estudiante['id_escuela'],
        ':condicion' => $estudiante['es_ingresante'] ? 'INGRESANTE' : 'REGULAR'
    ]);
    $horario = $stmtH->fetch();

    $msjTurno = $horario 
        ? "Su turno según cronograma es del {$horario['fecha_inicio']} al {$horario['fecha_fin']}." 
        : "No tiene un cronograma de matrícula activo asignado.";

    json_error("Acceso no permitido por cronograma. " . $msjTurno, 403, [
        'dentro_cronograma' => false,
        'horario'           => $horario
    ]);
}

// 4. Generar Token de sesión
$token = generar_token($estudiante['id_estudiante'], $estudiante['codigo']);

// Eliminar el hash de la respuesta
unset($estudiante['password_hash']);

// Determinar redirección inicial
$rutaRedirect = $estudiante['es_ingresante'] ? '/portafolio' : '/cola-virtual';

json_response([
    'mensaje'      => "Inicio de sesión exitoso. Bienvenido, {$estudiante['nombres']}.",
    'token'        => $token,
    'estudiante'   => $estudiante,
    'es_ingresante'=> (bool)$estudiante['es_ingresante'],
    'redirect'     => $rutaRedirect
]);
