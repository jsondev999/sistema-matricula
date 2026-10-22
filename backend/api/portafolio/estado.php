<?php
// =============================================================================
// ENDPOINT: GET /api/portafolio/estado.php
// RF-05 y RF-06: Consulta estado de los 4 documentos del portafolio
// =============================================================================

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth_middleware.php';

$estudiante = verificar_token();
$pdo = Database::getConnection();

// 1. Obtener lista de tipos de documentos requeridos con el estado de subida del alumno
$stmt = $pdo->prepare("
    SELECT tdr.id_tipo_documento, tdr.codigo, tdr.nombre, tdr.es_obligatorio,
           pd.id_documento, pd.ruta_archivo, pd.formato, pd.peso_kb, pd.fecha_subida,
           IFNULL(pd.estado, 'PENDIENTE') AS estado_documento
    FROM tipo_documento_requisito tdr
    LEFT JOIN portafolio_documento pd 
           ON tdr.id_tipo_documento = pd.id_tipo_documento 
          AND pd.id_estudiante = :id_estudiante
    ORDER BY tdr.id_tipo_documento ASC
");
$stmt->execute([':id_estudiante' => $estudiante['id_estudiante']]);
$documentos = $stmt->fetchAll();

// 2. Evaluar mediante la función MySQL si los requisitos obligatorios están completos
$stmtCheck = $pdo->prepare("SELECT fn_validar_requisitos_completos(:id_estudiante) AS completos");
$stmtCheck->execute([':id_estudiante' => $estudiante['id_estudiante']]);
$resCheck = $stmtCheck->fetch();
$completos = (bool)($resCheck['completos'] ?? false);

json_response([
    'estudiante_id'  => $estudiante['id_estudiante'],
    'es_ingresante'  => (bool)$estudiante['es_ingresante'],
    'completos'      => $completos,
    'puede_continuar'=> $completos,
    'documentos'     => $documentos
]);
