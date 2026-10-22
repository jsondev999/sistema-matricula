<?php
// =============================================================================
// ENDPOINT: GET /api/reportes/generar_ficha.php?id={id_matricula}&format={html|json}
// Generación y descarga de la Ficha Oficial de Matrícula
// =============================================================================

require_once __DIR__ . '/../../config/database.php';

$id_matricula = isset($_GET['id']) ? (int)$_GET['id'] : 0;
$format       = isset($_GET['format']) ? strtolower($_GET['format']) : 'html';

if ($id_matricula <= 0) {
    http_response_code(400);
    echo "Debe especificar un id de matrícula válido.";
    exit();
}

$pdo = Database::getConnection();

// Consultar la vista consolidada vw_ficha_matricula
$stmt = $pdo->prepare("SELECT * FROM vw_ficha_matricula WHERE id_matricula = ?");
$stmt->execute([$id_matricula]);
$registros = $stmt->fetchAll();

if (empty($registros)) {
    http_response_code(404);
    echo "No se encontraron registros de matrícula confirmada para el ID especificado.";
    exit();
}

$cabecera = $registros[0];

if ($format === 'json') {
    header("Content-Type: application/json; charset=UTF-8");
    header("Access-Control-Allow-Origin: *");
    echo json_encode([
        'status' => 'success',
        'data'   => [
            'cabecera'   => $cabecera,
            'cursos'     => $registros
        ]
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit();
}

// =============================================================================
// RENDERIZADO OFICIAL HTML/CSS CON DISPARADOR DE IMPRESIÓN DIRECTA A PDF
// =============================================================================
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Ficha_Matricula_<?= htmlspecialchars($cabecera['codigo_estudiante']) ?>.pdf</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 30px;
            color: #1a1a1a;
            background: #f8fafc;
        }
        .container {
            max-width: 850px;
            margin: 0 auto;
            background: #ffffff;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            border-bottom: 3px double #1e3a8a;
            padding-bottom: 15px;
            margin-bottom: 25px;
        }
        .header h1 {
            margin: 0;
            font-size: 18px;
            color: #1e3a8a;
            letter-spacing: 0.5px;
        }
        .header h2 {
            margin: 5px 0;
            font-size: 15px;
            color: #334155;
        }
        .header h3 {
            margin: 5px 0;
            font-size: 14px;
            color: #475569;
            font-weight: 500;
        }
        .title-badge {
            display: inline-block;
            background: #1e3a8a;
            color: #ffffff;
            padding: 6px 20px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: bold;
            margin-top: 10px;
            text-transform: uppercase;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 12px;
            background: #f1f5f9;
            padding: 16px;
            border-radius: 6px;
            margin-bottom: 25px;
            font-size: 13px;
        }
        .info-item strong {
            color: #1e3a8a;
            display: inline-block;
            width: 140px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 25px;
            font-size: 12px;
        }
        th {
            background: #1e3a8a;
            color: #ffffff;
            text-align: left;
            padding: 10px 8px;
            font-weight: 600;
        }
        td {
            padding: 9px 8px;
            border-bottom: 1px solid #e2e8f0;
        }
        tr:nth-child(even) {
            background: #f8fafc;
        }
        .text-center { text-align: center; }
        .text-right { text-align: right; }
        .total-box {
            display: flex;
            justify-content: flex-end;
            margin-top: 10px;
            margin-bottom: 30px;
        }
        .total-table {
            width: 250px;
            font-size: 13px;
        }
        .total-table td {
            padding: 6px 12px;
        }
        .total-table tr.total-row {
            background: #e2e8f0;
            font-weight: bold;
        }
        .footer {
            margin-top: 40px;
            border-top: 1px dashed #cbd5e1;
            padding-top: 20px;
            font-size: 11px;
            color: #64748b;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .qr-placeholder {
            border: 2px solid #cbd5e1;
            padding: 8px;
            border-radius: 4px;
            background: #ffffff;
            font-family: monospace;
            font-size: 10px;
        }
        .no-print {
            text-align: center;
            margin-bottom: 20px;
        }
        .btn-print {
            background: #2563eb;
            color: #ffffff;
            border: none;
            padding: 10px 24px;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
        }
        .btn-print:hover { background: #1d4ed8; }

        @media print {
            body { background: #ffffff; padding: 0; }
            .container { box-shadow: none; padding: 0; }
            .no-print { display: none; }
        }
    </style>
</head>
<body>

<div class="no-print">
    <button class="btn-print" onclick="window.print()">🖨️ Imprimir / Guardar en PDF</button>
</div>

<div class="container">
    <div class="header">
        <h1>UNIVERSIDAD NACIONAL JORGE BASADRE GROHMANN</h1>
        <h2><?= htmlspecialchars($cabecera['nombre_facultad']) ?></h2>
        <h3><?= htmlspecialchars($cabecera['nombre_escuela']) ?></h3>
        <div class="title-badge">FICHA OFICIAL DE MATRÍCULA - <?= htmlspecialchars($cabecera['codigo_periodo']) ?></div>
    </div>

    <div class="info-grid">
        <div class="info-item"><strong>CÓDIGO:</strong> <?= htmlspecialchars($cabecera['codigo_estudiante']) ?></div>
        <div class="info-item"><strong>DNI:</strong> <?= htmlspecialchars($cabecera['dni_estudiante']) ?></div>
        <div class="info-item"><strong>ESTUDIANTE:</strong> <?= htmlspecialchars($cabecera['nombre_completo_estudiante']) ?></div>
        <div class="info-item"><strong>CONDICIÓN:</strong> <?= htmlspecialchars($cabecera['condicion_academica']) ?></div>
        <div class="info-item"><strong>SEDE:</strong> <?= htmlspecialchars($cabecera['nombre_sede']) ?></div>
        <div class="info-item"><strong>ESTADO MATRÍCULA:</strong> <span style="color:#16a34a; font-weight:bold;"><?= htmlspecialchars($cabecera['estado_matricula']) ?></span></div>
        <div class="info-item"><strong>FECHA CONFIRMACIÓN:</strong> <?= htmlspecialchars($cabecera['fecha_confirmacion'] ?? 'No registrada') ?></div>
        <div class="info-item"><strong>PROMEDIO PONDERADO:</strong> <?= htmlspecialchars($cabecera['promedio_ponderado']) ?></div>
    </div>

    <table>
        <thead>
            <tr>
                <th style="width: 70px;">CÓDIGO</th>
                <th>ASIGNATURA</th>
                <th class="text-center" style="width: 40px;">CICLO</th>
                <th class="text-center" style="width: 40px;">CRÉD</th>
                <th class="text-center" style="width: 50px;">GRUPO</th>
                <th>DOCENTE</th>
                <th>HORARIO Y AULA</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($registros as $row): ?>
            <tr>
                <td style="font-weight: 600;"><?= htmlspecialchars($row['codigo_curso']) ?></td>
                <td><?= htmlspecialchars($row['nombre_curso']) ?></td>
                <td class="text-center"><?= htmlspecialchars($row['ciclo_curso']) ?></td>
                <td class="text-center" style="font-weight: 600;"><?= htmlspecialchars($row['creditos_curso']) ?></td>
                <td class="text-center"><?= htmlspecialchars($row['grupo']) ?> (<?= htmlspecialchars($row['turno']) ?>)</td>
                <td><?= htmlspecialchars($row['docente_asignado']) ?></td>
                <td style="font-size: 11px;"><?= htmlspecialchars($row['horario_completo']) ?></td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <div class="total-box">
        <table class="total-table">
            <tr>
                <td>Total Asignaturas:</td>
                <td class="text-right"><strong><?= count($registros) ?></strong></td>
            </tr>
            <tr class="total-row">
                <td>Total Créditos:</td>
                <td class="text-right"><strong><?= htmlspecialchars($cabecera['total_creditos']) ?></strong></td>
            </tr>
            <tr>
                <td>Derecho de Matrícula:</td>
                <td class="text-right">S/. <?= number_format($cabecera['monto_total'], 2) ?></td>
            </tr>
        </table>
    </div>

    <div class="footer">
        <div>
            <div><strong>SISTEMA WEB DE MATRÍCULA - UNJBG</strong></div>
            <div>Documento generado electrónicamente con valor oficial.</div>
            <div style="font-size: 9px; margin-top: 4px;">Hash: <?= htmlspecialchars($cabecera['codigo_verificacion']) ?></div>
        </div>
        <div class="qr-placeholder text-center">
            [ CÓDIGO QR DE VERIFICACIÓN ]<br>
            UNJBG-VERIFIED-2026
        </div>
    </div>
</div>

</body>
</html>
