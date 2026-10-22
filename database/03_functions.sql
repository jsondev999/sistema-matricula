-- =============================================================================
-- SISTEMA WEB DE MATRÍCULA UNIVERSITARIA - UNJBG
-- SCRIPT DE FUNCIONES DETERMINÍSTICAS (FUNCTIONS EN MYSQL)
-- =============================================================================

USE sistema_matricula;

DELIMITER $$

-- -----------------------------------------------------------------------------
-- 1. FUNCIÓN: fn_validar_cronograma
-- Retorna TRUE si la fecha y hora actual (NOW()) se encuentra dentro del rango
-- autorizado para la escuela y condición del estudiante; FALSE en caso contrario.
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_validar_cronograma$$
CREATE FUNCTION fn_validar_cronograma(
    p_id_escuela INT,
    p_es_ingresante BOOLEAN
) 
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_permitido INT DEFAULT 0;
    DECLARE v_condicion_busqueda VARCHAR(20);

    IF p_es_ingresante = TRUE THEN
        SET v_condicion_busqueda = 'INGRESANTE';
    ELSE
        SET v_condicion_busqueda = 'REGULAR';
    END IF;

    SELECT COUNT(*) INTO v_permitido
    FROM cronograma_matricula
    WHERE id_escuela = p_id_escuela
      AND (condicion_estudiante = v_condicion_busqueda OR condicion_estudiante = 'TODOS')
      AND estado = 'ACTIVO'
      AND NOW() BETWEEN fecha_inicio AND fecha_fin;

    IF v_permitido > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- 2. FUNCIÓN: fn_validar_cruces_horario
-- Retorna TRUE si existe solapamiento en día y horas entre las secciones
-- agregadas en la proforma de matrícula; FALSE si el horario está libre de cruces.
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_validar_cruces_horario$$
CREATE FUNCTION fn_validar_cruces_horario(
    p_id_matricula INT
) 
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_cantidad_cruces INT DEFAULT 0;

    -- Compara pares de bloques de horario de las secciones seleccionadas
    SELECT COUNT(*) INTO v_cantidad_cruces
    FROM detalle_matricula dm1
    INNER JOIN horario_seccion h1 ON dm1.id_seccion = h1.id_seccion
    INNER JOIN detalle_matricula dm2 ON dm1.id_matricula = dm2.id_matricula
    INNER JOIN horario_seccion h2 ON dm2.id_seccion = h2.id_seccion
    WHERE dm1.id_matricula = p_id_matricula
      AND dm1.id_seccion < dm2.id_seccion -- Evita comparar una sección consigo misma o duplicar pares
      AND h1.dia_semana = h2.dia_semana   -- Mismo día de la semana
      -- Condición de solapamiento de intervalos de tiempo: [Inicio1, Fin1) cruza con [Inicio2, Fin2)
      AND (h1.hora_inicio < h2.hora_fin AND h1.hora_fin > h2.hora_inicio);

    IF v_cantidad_cruces > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- 3. FUNCIÓN: fn_validar_requisitos_completos
-- Verifica si un estudiante ingresante ha subido los 4 documentos obligatorios
-- exigidos en el módulo de Portafolio de Admisión.
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_validar_requisitos_completos$$
CREATE FUNCTION fn_validar_requisitos_completos(
    p_id_estudiante INT
) 
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total_obligatorios INT DEFAULT 0;
    DECLARE v_total_entregados INT DEFAULT 0;

    -- Conteo total de requisitos obligatorios configurados
    SELECT COUNT(*) INTO v_total_obligatorios
    FROM tipo_documento_requisito
    WHERE es_obligatorio = TRUE;

    -- Conteo de requisitos entregados válidos por el alumno
    SELECT COUNT(DISTINCT pd.id_tipo_documento) INTO v_total_entregados
    FROM portafolio_documento pd
    INNER JOIN tipo_documento_requisito tdr ON pd.id_tipo_documento = tdr.id_tipo_documento
    WHERE pd.id_estudiante = p_id_estudiante
      AND tdr.es_obligatorio = TRUE
      AND pd.estado IN ('ENTREGADO', 'VALIDADO');

    IF v_total_entregados >= v_total_obligatorios AND v_total_obligatorios > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END$$

DELIMITER ;
