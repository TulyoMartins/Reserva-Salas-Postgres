-- Trigger (a): Auditoria automática
CREATE OR REPLACE FUNCTION fn_trg_auditoria_reserva()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO log_reserva(reserva_id, operacao, dados_novos)
        VALUES (NEW.id, 'INSERT', to_jsonb(NEW));
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO log_reserva(reserva_id, operacao, dados_antigos, dados_novos)
        VALUES (NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO log_reserva(reserva_id, operacao, dados_antigos)
        VALUES (OLD.id, 'DELETE', to_jsonb(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auditoria_reserva
AFTER INSERT OR UPDATE OR DELETE ON reserva
FOR EACH ROW EXECUTE FUNCTION fn_trg_auditoria_reserva();

-- Trigger (b): Validação de limite de 3 reservas ativas futuras
CREATE OR REPLACE FUNCTION fn_trg_validar_limite_reservas()
RETURNS TRIGGER AS $$
DECLARE
    v_qtd INT;
BEGIN
    IF NEW.status = 'ATIVA' THEN
        SELECT COUNT(*) INTO v_qtd
        FROM reserva
        WHERE usuario_id = NEW.usuario_id
          AND status = 'ATIVA'
          AND lower(periodo) > CURRENT_TIMESTAMP;

        IF v_qtd >= 3 THEN
            RAISE EXCEPTION 'Limite atingido: O usuário ID % já possui 3 ou mais reservas ativas futuras.', NEW.usuario_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_limite_reservas
BEFORE INSERT ON reserva
FOR EACH ROW EXECUTE FUNCTION fn_trg_validar_limite_reservas();

-- Procedure: Criar Reserva (Com Transação Explícita e Validações)
CREATE OR REPLACE PROCEDURE pr_criar_reserva(
    p_sala_id INT,
    p_usuario_id INT,
    p_inicio TIMESTAMPTZ,
    p_fim TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_inicio >= p_fim THEN
        RAISE EXCEPTION 'A data/hora final deve ser maior que a data/hora inicial.';
    END IF;

    IF p_inicio < CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'Não é permitido criar reservas no passado.';
    END IF;

    INSERT INTO reserva (sala_id, usuario_id, periodo, status)
    VALUES (p_sala_id, p_usuario_id, tstzrange(p_inicio, p_fim, '[)'), 'ATIVA');
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
$$;

-- Procedure: Cancelar Reserva
CREATE OR REPLACE PROCEDURE pr_cancelar_reserva(
    p_reserva_id INT,
    p_usuario_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status enum_status_reserva;
    v_donodareserva INT;
BEGIN
    SELECT status, usuario_id INTO v_status, v_donodareserva
    FROM reserva WHERE id = p_reserva_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Reserva ID % não encontrada.', p_reserva_id;
    END IF;

    IF v_donodareserva <> p_usuario_id THEN
        RAISE EXCEPTION 'Usuário não tem permissão para cancelar esta reserva.';
    END IF;

    IF v_status = 'CANCELADA' THEN
        RAISE EXCEPTION 'Reserva ID % já está cancelada.', p_reserva_id;
    END IF;

    UPDATE reserva SET status = 'CANCELADA' WHERE id = p_reserva_id;
    COMMIT;
END;
$$;
