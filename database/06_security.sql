-- Criar role sem login direto de superusuário
CREATE ROLE app_reservas WITH LOGIN PASSWORD 'SenhaSegura123!';

-- Conceder permissões
GRANT CONNECT ON DATABASE postgres TO app_reservas;
GRANT USAGE ON SCHEMA public TO app_reservas;

-- Revogar acesso direto às tabelas
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM app_reservas;

-- Permissão apenas em Views e Procedures
GRANT SELECT ON v_agenda_dia TO app_reservas;
GRANT SELECT ON v_reservas_usuario TO app_reservas;
GRANT SELECT ON mv_ocupacao_mensal TO app_reservas;

GRANT EXECUTE ON PROCEDURE pr_criar_reserva(INT, INT, TIMESTAMPTZ, TIMESTAMPTZ) TO app_reservas;
GRANT EXECUTE ON PROCEDURE pr_cancelar_reserva(INT, INT) TO app_reservas;