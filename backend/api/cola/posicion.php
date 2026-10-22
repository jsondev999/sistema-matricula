<?php
// =============================================================================
// ENDPOINT: GET /api/cola/posicion.php
// Visualizar en qué posición de la cola se encuentra (polling 5s)
// Control del temporizador de 5 minutos y expiración automática
// =============================================================================

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth_middleware.php';

$estudiante = verificar_token();
$pdo = Database::getConnection();

// 0. Limpiar automáticamente turnos expirados que ya no hacen polling
//    (usuarios que cerraron la página sin confirmar ni esperar el timeout)
$stmtLimpiar = $pdo->prepare("
    UPDATE cola_virtual 
    SET estado_turno = 'EXPIRADO'
    WHERE estado_turno = 'TURNO_HABILITADO' 
      AND fecha_expiracion IS NOT NULL 
      AND fecha_expiracion < NOW()
");
$stmtLimpiar->execute();

// 1. Consultar estado en cola
$stmt = $pdo->prepare("
    SELECT id_cola, posicion, estado_turno, fecha_inicio_turno, fecha_expiracion,
           TIMESTAMPDIFF(SECOND, NOW(), fecha_expiracion) AS segundos_restantes
    FROM cola_virtual 
    WHERE id_estudiante = ?
");
$stmt->execute([$estudiante['id_estudiante']]);
$cola = $stmt->fetch();

if (!$cola) {
    json_error("No se encuentra registrado en la cola virtual.", 404, ['redirect' => '/cola-virtual']);
}

// 2a. Estados terminales — redirigir apropiadamente
if ($cola['estado_turno'] === 'EXPIRADO' || $cola['estado_turno'] === 'CANCELADA') {
    json_error("Su turno expiró o fue cancelado. Puede reingresar a la cola.", 410, [
        'expirado'  => true,
        'redirect'  => '/cola-virtual'
    ]);
}

if ($cola['estado_turno'] === 'FINALIZADO') {
    json_response([
        'posicion'      => 0,
        'estado_turno'  => 'FINALIZADO',
        'turno_activo'  => false,
        'espera_estimada' => 'Matrícula completada',
        'redirect'      => '/confirmacion'
    ]);
}

// 2b. Si el turno ya estaba habilitado, verificar si el tiempo de 5 minutos expiró
if ($cola['estado_turno'] === 'TURNO_HABILITADO' || $cola['estado_turno'] === 'EN_MATRICULA') {
    $segundosRestantes = (int)($cola['segundos_restantes'] ?? 0);

    if ($segundosRestantes <= 0) {
        // Ejecutar procedimiento almacenado de cancelación automática por timeout
        $stmtCancel = $pdo->prepare("CALL sp_cancelar_reserva_timeout(:id_est, @cod, @msj)");
        $stmtCancel->execute([':id_est' => $estudiante['id_estudiante']]);
        
        json_error("Su tiempo de sesión de 5 minutos ha expirado. Sus reservas temporales han sido liberadas.", 408, [
            'expirado' => true,
            'redirect' => '/cola-virtual'
        ]);
    }

    json_response([
        'posicion'           => 1,
        'estado_turno'       => $cola['estado_turno'],
        'turno_activo'       => true,
        'segundos_restantes' => $segundosRestantes,
        'espera_estimada'    => '¡Es tu turno!'
    ]);
}


// 3. Si aún está en espera, calcular avance si los que estaban antes ya salieron
$posicion = (int)$cola['posicion'];

// Si no es el número 1, recomputar cuántos estudiantes activos hay antes que él
$stmtCount = $pdo->prepare("
    SELECT COUNT(*) AS delante 
    FROM cola_virtual 
    WHERE estado_turno IN ('EN_ESPERA', 'TURNO_HABILITADO') 
      AND id_cola < ?
");
$stmtCount->execute([$cola['id_cola']]);
$delante = (int)$stmtCount->fetch()['delante'];
$posicionActual = $delante + 1;

if ($posicionActual !== $posicion) {
    $stmtUpd = $pdo->prepare("UPDATE cola_virtual SET posicion = ? WHERE id_cola = ?");
    $stmtUpd->execute([$posicionActual, $cola['id_cola']]);
    $posicion = $posicionActual;
}

// Si llegó al puesto #1, activar el turno inmediatamente
if ($posicion === 1 && $cola['estado_turno'] === 'EN_ESPERA') {
    $stmtActivar = $pdo->prepare("
        UPDATE cola_virtual 
        SET estado_turno = 'TURNO_HABILITADO',
            fecha_inicio_turno = NOW(),
            fecha_expiracion = DATE_ADD(NOW(), INTERVAL 300 SECOND)
        WHERE id_cola = ?
    ");
    $stmtActivar->execute([$cola['id_cola']]);

    json_response([
        'posicion'           => 1,
        'estado_turno'       => 'TURNO_HABILITADO',
        'turno_activo'       => true,
        'segundos_restantes' => 300,
        'espera_estimada'    => '¡Es tu turno!'
    ]);
}

// Tiempo estimado aproximado (2 minutos por cada persona delante)
$esperaMinutos = ($posicion - 1) * 2;
$esperaEstimada = $esperaMinutos <= 0 ? "Menos de 1 min" : "Aprox. {$esperaMinutos} min";

json_response([
    'posicion'           => $posicion,
    'estado_turno'       => 'EN_ESPERA',
    'turno_activo'       => false,
    'segundos_restantes' => null,
    'espera_estimada'    => $esperaEstimada
]);
