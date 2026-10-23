<?php
// =============================================================================
// CONEXIÓN A BASE DE DATOS (MYSQL CON PDO EN PHP 8)
// Patrón Singleton para optimizar el pool de conexiones en el servidor
// =============================================================================

class Database {
    private static ?PDO $instance = null;

    public static function getConnection(): PDO {
        if (self::$instance === null) {
            // 1. Detectar si viene una URL de conexión completa (MYSQL_URL o DATABASE_URL de Railway)
            $dbUrl = getenv('MYSQL_URL') ?: getenv('DATABASE_URL') ?: ($_ENV['MYSQL_URL'] ?? ($_ENV['DATABASE_URL'] ?? ''));

            $host = '127.0.0.1';
            $port = '3306';
            $db   = 'sistema_matricula';
            $user = 'root';
            $pass = '';
            $charset = 'utf8mb4';

            if (!empty($dbUrl)) {
                $parsed = parse_url($dbUrl);
                if ($parsed) {
                    $host = $parsed['host'] ?? $host;
                    $port = (string)($parsed['port'] ?? $port);
                    $user = $parsed['user'] ?? $user;
                    $pass = $parsed['pass'] ?? $pass;
                    $db   = ltrim($parsed['path'] ?? '', '/') ?: $db;
                }
            } else {
                // 2. Detectar variables individuales inyectadas por Railway o .env
                $host = getenv('MYSQLHOST') ?: getenv('DB_HOST') ?: ($_ENV['MYSQLHOST'] ?? ($_ENV['DB_HOST'] ?? $host));
                $port = (string)(getenv('MYSQLPORT') ?: getenv('DB_PORT') ?: ($_ENV['MYSQLPORT'] ?? ($_ENV['DB_PORT'] ?? $port)));
                $db   = getenv('MYSQLDATABASE') ?: getenv('DB_NAME') ?: ($_ENV['MYSQLDATABASE'] ?? ($_ENV['DB_NAME'] ?? $db));
                $user = getenv('MYSQLUSER') ?: getenv('DB_USER') ?: ($_ENV['MYSQLUSER'] ?? ($_ENV['DB_USER'] ?? $user));
                
                $envPass = getenv('MYSQLPASSWORD');
                if ($envPass === false) {
                    $envPass = getenv('DB_PASS');
                }
                if ($envPass === false && isset($_ENV['MYSQLPASSWORD'])) {
                    $envPass = $_ENV['MYSQLPASSWORD'];
                }
                if ($envPass === false && isset($_ENV['DB_PASS'])) {
                    $envPass = $_ENV['DB_PASS'];
                }
                if ($envPass !== false) {
                    $pass = $envPass;
                }
            }

            $dsn = "mysql:host={$host};port={$port};dbname={$db};charset={$charset}";
            
            $options = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION, // Lanza excepciones en errores SQL
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,       // Retorna arreglos asociativos
                PDO::ATTR_EMULATE_PREPARES   => false,                  // Prepared statements nativos en MySQL
                PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
            ];

            try {
                self::$instance = new PDO($dsn, $user, $pass, $options);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode([
                    "status" => "error",
                    "mensaje" => "Error de conexión a la Base de Datos: " . $e->getMessage()
                ], JSON_UNESCAPED_UNICODE);
                exit(1);
            }
        }
        return self::$instance;
    }
}
