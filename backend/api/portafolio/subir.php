<?php
// =============================================================================
// ENDPOINT: POST /api/portafolio/subir.php
// RF-05: Carga de archivo JPG/PNG (máx 2MB) y guardado en portafolio_documento
// =============================================================================

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth_middleware.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error("Método no permitido. Utilice POST con multipart/form-data.", 405);
}

$estudiante = verificar_token();

$id_tipo_documento = isset($_POST['id_tipo_documento']) ? (int)$_POST['id_tipo_documento'] : 0;
if ($id_tipo_documento <= 0) {
    json_error("Debe especificar el id_tipo_documento a adjuntar.", 400);
}

if (!isset($_FILES['archivo']) || $_FILES['archivo']['error'] !== UPLOAD_ERR_OK) {
    json_error("No se ha enviado ningún archivo o hubo un error en la carga.", 400);
}

$file = $_FILES['archivo'];

// 1. Validar tamaño (máximo 2 MB = 2 * 1024 * 1024 bytes)
$maxBytes = 2 * 1024 * 1024;
if ($file['size'] > $maxBytes) {
    json_error("El archivo excede el tamaño máximo permitido de 2 MB.", 422);
}

// 2. Validar formato (solo JPG, JPEG o PNG)
$extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
if (!in_array($extension, ['jpg', 'jpeg', 'png'])) {
    json_error("Formato no permitido. Solo se aceptan archivos en formato JPG o PNG.", 422);
}

// 3. Crear directorio de destino si no existe
$uploadDir = __DIR__ . '/../../uploads/portafolio';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

// 4. Nombre seguro para el archivo en disco
$nuevoNombre = "doc_{$estudiante['id_estudiante']}_tipo_{$id_tipo_documento}_" . time() . ".{$extension}";
$rutaFisica = $uploadDir . '/' . $nuevoNombre;
$rutaRelativa = '/uploads/portafolio/' . $nuevoNombre;

if (!move_uploaded_file($file['tmp_name'], $rutaFisica)) {
    json_error("Error al guardar el archivo en el servidor de almacenamiento.", 500);
}

$formato = strtoupper($extension === 'jpeg' ? 'jpg' : $extension);
$pesoKb = (int)round($file['size'] / 1024);

// 5. Insertar o actualizar registro en portafolio_documento
$pdo = Database::getConnection();
$stmt = $pdo->prepare("
    INSERT INTO portafolio_documento (id_estudiante, id_tipo_documento, ruta_archivo, formato, peso_kb, estado, fecha_subida)
    VALUES (:id_estudiante, :id_tipo, :ruta, :formato, :peso, 'ENTREGADO', NOW())
    ON DUPLICATE KEY UPDATE 
        ruta_archivo = VALUES(ruta_archivo),
        formato      = VALUES(formato),
        peso_kb      = VALUES(peso_kb),
        estado       = 'ENTREGADO',
        fecha_subida = NOW()
");
$stmt->execute([
    ':id_estudiante' => $estudiante['id_estudiante'],
    ':id_tipo'       => $id_tipo_documento,
    ':ruta'          => $rutaRelativa,
    ':formato'       => $formato,
    ':peso'          => $pesoKb
]);

// 6. Verificar si con este archivo ya completó los 4 requisitos obligatorios
$stmtCheck = $pdo->prepare("SELECT fn_validar_requisitos_completos(:id_estudiante) AS completos");
$stmtCheck->execute([':id_estudiante' => $estudiante['id_estudiante']]);
$resCheck = $stmtCheck->fetch();
$completos = (bool)($resCheck['completos'] ?? false);

json_response([
    'mensaje'          => "Documento adjuntado satisfactoriamente.",
    'ruta_archivo'     => $rutaRelativa,
    'requisitos_listos'=> $completos,
    'redirect'         => $completos ? '/cola-virtual' : null
]);
