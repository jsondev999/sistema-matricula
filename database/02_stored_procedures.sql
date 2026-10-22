-- =============================================================================
-- SISTEMA WEB DE MATRÍCULA UNIVERSITARIA - UNJBG
-- SCRIPT DE PROCEDIMIENTOS ALMACENADOS (STORED PROCEDURES EN MYSQL)
-- Incluye control de concurrencia con BLOQUEO PESIMISTA (FOR UPDATE)
-- =============================================================================

USE sistema_matricula;

DELIMITER $$

-- -----------------------------------------------------------------------------
-- 1. SP: sp_determinar_limite_creditos
-- Clasifica al estudiante y establece los topes mínimo y máximo de créditos
-- según el Reglamento Académico (Especial, Regular, Destacado >= 14.0).
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_determinar_limite_creditos$$
CREATE PROCEDURE sp_determinar_limite_creditos(
    IN p_id_estudiante INT,
    OUT p_condicion VARCHAR(20),
    OUT p_limite_min INT,
    OUT p_limite_max INT,
    OUT p_puede_adelantar BOOLEAN
)
BEGIN
    DECLARE v_promedio DECIMAL(4,2);
    DECLARE v_es_ingresante BOOLEAN;

    SELECT promedio_ponderado, es_ingresante 
    INTO v_promedio, v_es_ingresante
    FROM estudiante 
    WHERE id_estudiante = p_id_estudiante;

    -- Los ingresantes ingresan como Regulares con créditos preestablecidos
    IF v_es_ingresante = TRUE THEN
        SET p_condicion = 'REGULAR';
        SET p_limite_min = 12;
        SET p_limite_max = 23;
        SET p_puede_adelantar = FALSE;
    ELSEIF v_promedio >= 14.00 THEN
        SET p_condicion = 'DESTACADO';
        SET p_limite_min = 12;
        SET p_limite_max = 28;
        SET p_puede_adelantar = TRUE;
    ELSEIF v_promedio < 11.00 THEN
        SET p_condicion = 'ESPECIAL';
        SET p_limite_min = 1;
        SET p_limite_max = 11;
        SET p_puede_adelantar = FALSE;
    ELSE
        SET p_condicion = 'REGULAR';
        SET p_limite_min = 12;
        SET p_limite_max = 23;
        SET p_puede_adelantar = FALSE;
    END IF;

    -- Actualizar la condición y tope en la tabla estudiante
    UPDATE estudiante 
    SET condicion_academica = p_condicion,
        creditos_permitidos = p_limite_max
    WHERE id_estudiante = p_id_estudiante;
END$$

-- -----------------------------------------------------------------------------
-- 2. SP: sp_matricular_curso (JOYAL TÉCNICA CON BLOQUEO PESIMISTA)
-- Reserva cupo en tiempo real evitando sobrecupos con SELECT ... FOR UPDATE.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_matricular_curso$$
CREATE PROCEDURE sp_matricular_curso(
    IN p_id_matricula INT,
    IN p_id_seccion INT,
    OUT p_codigo_error INT,
    OUT p_mensaje VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_id_estudiante INT;
    DECLARE v_estado_matricula VARCHAR(20);
    DECLARE v_es_editable BOOLEAN;
    DECLARE v_total_creditos INT;
    DECLARE v_creditos_permitidos INT;
    
    DECLARE v_id_curso INT;
    DECLARE v_creditos_curso INT;
    DECLARE v_vacantes_disponibles INT;
    DECLARE v_estado_seccion VARCHAR(20);
    DECLARE v_existe_curso_en_proforma INT;

    -- Manejo de excepciones SQL
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_codigo_error = 500;
        SET p_mensaje = 'Error interno en la base de datos al intentar reservar el cupo.';
    END;

    -- Validar existencia y estado de la matrícula
    SELECT id_estudiante, estado, es_editable, total_creditos
    INTO v_id_estudiante, v_estado_matricula, v_es_editable, v_total_creditos
    FROM matricula
    WHERE id_matricula = p_id_matricula;

    IF v_id_estudiante IS NULL THEN
        SET p_codigo_error = 404;
        SET p_mensaje = 'La proforma de matrícula especificada no existe.';
        LEAVE proc_label;
    END IF;

    IF v_estado_matricula <> 'PROFORMA' OR v_es_editable = FALSE THEN
        SET p_codigo_error = 403;
        SET p_mensaje = 'La matrícula ya está confirmada o cerrada. No se admiten modificaciones.';
        LEAVE proc_label;
    END IF;

    -- Obtener tope de créditos del estudiante
    SELECT creditos_permitidos INTO v_creditos_permitidos
    FROM estudiante WHERE id_estudiante = v_id_estudiante;

    -- =========================================================================
    -- INICIO DE TRANSACCIÓN ATÓMICA CON BLOQUEO PESIMISTA
    -- =========================================================================
    START TRANSACTION;

    -- Bloqueo pesimista a nivel de fila sobre la sección solicitada
    SELECT s.id_curso, s.vacantes_disponibles, s.estado, c.creditos
    INTO v_id_curso, v_vacantes_disponibles, v_estado_seccion, v_creditos_curso
    FROM seccion s
    INNER JOIN curso c ON s.id_curso = c.id_curso
    WHERE s.id_seccion = p_id_seccion
    FOR UPDATE;

    -- Validar que la sección exista
    IF v_id_curso IS NULL THEN
        ROLLBACK;
        SET p_codigo_error = 404;
        SET p_mensaje = 'La sección solicitada no existe.';
        LEAVE proc_label;
    END IF;

    -- Validar que haya cupo disponible
    IF v_vacantes_disponibles <= 0 OR v_estado_seccion = 'CERRADA' THEN
        ROLLBACK;
        SET p_codigo_error = 409;
        SET p_mensaje = 'Vacantes agotadas para la sección seleccionada.';
        LEAVE proc_label;
    END IF;

    -- Validar que el estudiante no tenga ya matriculado este curso (en otra sección)
    SELECT COUNT(*) INTO v_existe_curso_en_proforma
    FROM detalle_matricula dm
    INNER JOIN seccion sec ON dm.id_seccion = sec.id_seccion
    WHERE dm.id_matricula = p_id_matricula AND sec.id_curso = v_id_curso;

    IF v_existe_curso_en_proforma > 0 THEN
        ROLLBACK;
        SET p_codigo_error = 400;
        SET p_mensaje = 'Ya tiene una sección seleccionada para esta asignatura en su proforma.';
        LEAVE proc_label;
    END IF;

    -- Validar que no se exceda el límite de créditos permitido
    IF (v_total_creditos + v_creditos_curso) > v_creditos_permitidos THEN
        ROLLBACK;
        SET p_codigo_error = 400;
        SET p_mensaje = CONCAT('Supera su límite de créditos permitido. Máximo: ', v_creditos_permitidos, ' créditos.');
        LEAVE proc_label;
    END IF;

    -- 1. Insertar en detalle de matrícula
    INSERT INTO detalle_matricula (id_matricula, id_seccion, creditos, estado)
    VALUES (p_id_matricula, p_id_seccion, v_creditos_curso, 'RESERVADO_TEMPORAL');

    -- 2. Descontar la vacante y actualizar estado si se agota
    UPDATE seccion 
    SET vacantes_disponibles = vacantes_disponibles - 1,
        estado = IF(vacantes_disponibles - 1 = 0, 'CERRADA', 'ABIERTA')
    WHERE id_seccion = p_id_seccion;

    -- 3. Actualizar créditos acumulados en cabecera
    UPDATE matricula 
    SET total_creditos = total_creditos + v_creditos_curso
    WHERE id_matricula = p_id_matricula;

    COMMIT;

    SET p_codigo_error = 200;
    SET p_mensaje = 'Asignatura y sección agregadas exitosamente con cupo reservado.';
END$$

-- -----------------------------------------------------------------------------
-- 3. SP: sp_desmatricular_curso
-- Retira una asignatura de la proforma y restituye inmediatamente la vacante.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_desmatricular_curso$$
CREATE PROCEDURE sp_desmatricular_curso(
    IN p_id_matricula INT,
    IN p_id_seccion INT,
    OUT p_codigo_error INT,
    OUT p_mensaje VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_es_editable BOOLEAN;
    DECLARE v_creditos_curso INT;
    DECLARE v_existe INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_codigo_error = 500;
        SET p_mensaje = 'Error interno al intentar retirar la asignatura de la proforma.';
    END;

    -- Validar que la matrícula sea editable
    SELECT es_editable INTO v_es_editable FROM matricula WHERE id_matricula = p_id_matricula;
    IF v_es_editable IS NULL OR v_es_editable = FALSE THEN
        SET p_codigo_error = 403;
        SET p_mensaje = 'No se puede modificar una matrícula confirmada o inexistente.';
        LEAVE proc_label;
    END IF;

    -- Verificar que la sección esté en la proforma
    SELECT creditos INTO v_creditos_curso
    FROM detalle_matricula 
    WHERE id_matricula = p_id_matricula AND id_seccion = p_id_seccion;

    IF v_creditos_curso IS NULL THEN
        SET p_codigo_error = 404;
        SET p_mensaje = 'La sección indicada no figura en la proforma del estudiante.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    -- 1. Eliminar de detalle_matricula
    DELETE FROM detalle_matricula 
    WHERE id_matricula = p_id_matricula AND id_seccion = p_id_seccion;

    -- 2. Restituir vacante a la sección con bloqueo pesimista
    UPDATE seccion 
    SET vacantes_disponibles = vacantes_disponibles + 1,
        estado = 'ABIERTA'
    WHERE id_seccion = p_id_seccion;

    -- 3. Restar créditos en cabecera
    UPDATE matricula 
    SET total_creditos = total_creditos - v_creditos_curso
    WHERE id_matricula = p_id_matricula;

    COMMIT;

    SET p_codigo_error = 200;
    SET p_mensaje = 'Asignatura retirada de la proforma y vacante liberada satisfactoriamente.';
END$$

-- -----------------------------------------------------------------------------
-- 4. SP: sp_confirmar_matricula
-- Cierre transaccional definitivo: pasa de PROFORMA a CONFIRMADA, valida pago
-- e inscribe inmutabilidad bloqueando futuras modificaciones.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_confirmar_matricula$$
CREATE PROCEDURE sp_confirmar_matricula(
    IN p_id_matricula INT,
    OUT p_codigo_error INT,
    OUT p_mensaje VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_id_estudiante INT;
    DECLARE v_total_creditos INT;
    DECLARE v_condicion VARCHAR(20);
    DECLARE v_cruces_detectados BOOLEAN;
    DECLARE v_id_pago INT;
    DECLARE v_hash_pdf VARCHAR(64);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_codigo_error = 500;
        SET p_mensaje = 'Error transaccional al confirmar la matrícula.';
    END;

    -- Validar proforma
    SELECT m.id_estudiante, m.total_creditos, e.condicion_academica, m.id_pago
    INTO v_id_estudiante, v_total_creditos, v_condicion, v_id_pago
    FROM matricula m
    INNER JOIN estudiante e ON m.id_estudiante = e.id_estudiante
    WHERE m.id_matricula = p_id_matricula AND m.estado = 'PROFORMA';

    IF v_id_estudiante IS NULL THEN
        SET p_codigo_error = 404;
        SET p_mensaje = 'Proforma no encontrada o ya confirmada previamente.';
        LEAVE proc_label;
    END IF;

    -- Validar que tenga cursos seleccionados
    IF v_total_creditos <= 0 THEN
        SET p_codigo_error = 400;
        SET p_mensaje = 'Debe seleccionar al menos una asignatura antes de confirmar.';
        LEAVE proc_label;
    END IF;

    -- Validar mínimo de créditos para condición Regular / Destacado
    IF v_condicion IN ('REGULAR', 'DESTACADO') AND v_total_creditos < 12 THEN
        SET p_codigo_error = 400;
        SET p_mensaje = 'No cumple con el mínimo de 12 créditos exigidos para su condición.';
        LEAVE proc_label;
    END IF;

    -- Validar que no existan cruces de horario
    SELECT fn_validar_cruces_horario(p_id_matricula) INTO v_cruces_detectados;
    IF v_cruces_detectados = TRUE THEN
        SET p_codigo_error = 400;
        SET p_mensaje = 'Tiene asignaturas con cruce de horario. Resuelva los conflictos antes de confirmar.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    -- Generar código hash único para validación de la Ficha en PDF
    SET v_hash_pdf = SHA2(CONCAT(p_id_matricula, v_id_estudiante, NOW()), 256);

    -- 1. Actualizar cabecera a CONFIRMADA e inmutable
    UPDATE matricula 
    SET estado = 'CONFIRMADA',
        es_editable = FALSE,
        fecha_confirmacion = NOW(),
        codigo_verificacion = v_hash_pdf
    WHERE id_matricula = p_id_matricula;

    -- 2. Consolidar el detalle de la matrícula a CONFIRMADO
    UPDATE detalle_matricula 
    SET estado = 'CONFIRMADO' 
    WHERE id_matricula = p_id_matricula;

    -- 3. Marcar turno como finalizado en la cola virtual
    UPDATE cola_virtual 
    SET estado_turno = 'FINALIZADO' 
    WHERE id_estudiante = v_id_estudiante;

    COMMIT;

    SET p_codigo_error = 200;
    SET p_mensaje = 'Matrícula confirmada exitosamente. Ficha oficial disponible para descarga.';
END$$

-- -----------------------------------------------------------------------------
-- 5. SP: sp_cancelar_reserva_timeout
-- Cancela la proforma y restituye todas las vacantes si expiran los 5 minutos.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_cancelar_reserva_timeout$$
CREATE PROCEDURE sp_cancelar_reserva_timeout(
    IN p_id_estudiante INT,
    OUT p_codigo_error INT,
    OUT p_mensaje VARCHAR(255)
)
BEGIN
    DECLARE v_id_matricula INT;

    SELECT id_matricula INTO v_id_matricula 
    FROM matricula 
    WHERE id_estudiante = p_id_estudiante AND estado = 'PROFORMA';

    IF v_id_matricula IS NOT NULL THEN
        START TRANSACTION;

        -- Restituir vacantes de todos los cursos que estaban reservados
        UPDATE seccion s
        INNER JOIN detalle_matricula dm ON s.id_seccion = dm.id_seccion
        SET s.vacantes_disponibles = s.vacantes_disponibles + 1,
            s.estado = 'ABIERTA'
        WHERE dm.id_matricula = v_id_matricula AND dm.estado = 'RESERVADO_TEMPORAL';

        -- Marcar estado de detalle como LIBERADO
        UPDATE detalle_matricula 
        SET estado = 'LIBERADO' 
        WHERE id_matricula = v_id_matricula;

        -- Cancelar la proforma
        UPDATE matricula 
        SET estado = 'CANCELADA',
            es_editable = FALSE,
            total_creditos = 0
        WHERE id_matricula = v_id_matricula;

        -- Marcar turno expirado en cola
        UPDATE cola_virtual 
        SET estado_turno = 'EXPIRADO' 
        WHERE id_estudiante = p_id_estudiante;

        COMMIT;
        SET p_codigo_error = 200;
        SET p_mensaje = 'Tiempo de 5 minutos expirado. Reservas temporales liberadas.';
    ELSE
        SET p_codigo_error = 404;
        SET p_mensaje = 'No hay proforma activa pendiente para el estudiante.';
    END IF;
END$$

DELIMITER ;
