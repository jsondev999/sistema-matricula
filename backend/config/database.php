<?php
// =============================================================================
// CONEXIÓN A BASE DE DATOS (MYSQL CON PDO EN PHP 8)
// Patrón Singleton para optimizar el pool de conexiones en el servidor
// =============================================================================

class Database {
    private static ?PDO $instance = null;

    private static string $host = '127.0.0.1';
    private static string $port = '3306';
    private static string $db   = 'sistema_matricula';
    private static string $user = 'root';
    private static string $pass = ''; // Por defecto en XAMPP es vacío
    private static string $charset = 'utf8mb4';

    public static function getConnection(): PDO {
        if (self::$instance === null) {
            $dsn = "mysql:host=" . self::$host . ";port=" . self::$port . ";dbname=" . self::$db . ";charset=" . self::$charset;
            
            $options = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION, // Lanza excepciones en errores SQL
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,       // Retorna arreglos asociativos
                PDO::ATTR_EMULATE_PREPARES   => false,                  // Prepared statements nativos en MySQL
                PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
            ];

            try {
                self::$instance = new PDO($dsn, self::$user, self::$pass, $options);
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
