-- View 1: Agenda do Dia
CREATE OR REPLACE VIEW v_agenda_dia AS
SELECT 
    r.id AS reserva_id,
    s.id AS sala_id,
    s.nome AS sala_nome,
    u.nome AS usuario_nome,
    lower(r.periodo) AS hora_inicio,
    upper(r.periodo) AS hora_fim,
    DATE(lower(r.periodo)) AS data_reserva
FROM reserva r
JOIN sala s ON r.sala_id = s.id
JOIN usuario u ON r.usuario_id = u.id
WHERE r.status = 'ATIVA';

-- View 2: Reservas por Usuário
CREATE OR REPLACE VIEW v_reservas_usuario AS
SELECT 
    u.id AS usuario_id,
    u.nome AS usuario_nome,
    r.id AS reserva_id,
    s.nome AS sala_nome,
    lower(r.periodo) AS inicio,
    upper(r.periodo) AS fim,
    r.status
FROM usuario u
JOIN reserva r ON u.id = r.usuario_id;

-- Materialized View: Taxa de Ocupação Mensal
CREATE MATERIALIZED VIEW mv_ocupacao_mensal AS
SELECT 
    s.id AS sala_id,
    s.nome AS sala_nome,
    TO_CHAR(lower(r.periodo), 'YYYY-MM') AS mes_ano,
    COUNT(r.id) AS total_reservas,
    ROUND(SUM(EXTRACT(EPOCH FROM (upper(r.periodo) - lower(r.periodo))) / 3600)::numeric, 2) AS horas_reservadas
FROM sala s
LEFT JOIN reserva r ON s.id = r.sala_id AND r.status = 'ATIVA'
GROUP BY s.id, s.nome, TO_CHAR(lower(r.periodo), 'YYYY-MM');

CREATE UNIQUE INDEX idx_mv_ocupacao ON mv_ocupacao_mensal (sala_id, mes_ano);