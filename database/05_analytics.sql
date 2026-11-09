-- 1. Window Function: Ranking dos usuários que mais reservaram salas
SELECT 
    u.nome,
    COUNT(r.id) AS total_reservas,
    DENSE_RANK() OVER (ORDER BY COUNT(r.id) DESC) AS ranking
FROM usuario u
JOIN reserva r ON u.id = r.usuario_id
GROUP BY u.id, u.nome
LIMIT 10;

-- 2. CTE: Salas com ocupação acima da média geral
WITH horas_por_sala AS (
    SELECT sala_id, SUM(EXTRACT(EPOCH FROM (upper(periodo) - lower(periodo)))/3600) AS total_horas
    FROM reserva WHERE status = 'ATIVA' GROUP BY sala_id
),
media_geral AS (
    SELECT AVG(total_horas) AS media FROM horas_por_sala
)
SELECT s.nome, h.total_horas
FROM horas_por_sala h
JOIN sala s ON s.id = h.sala_id
WHERE h.total_horas > (SELECT media FROM media_geral);

-- 3. Subconsulta no HAVING: Usuários que reservaram no Bloco A
SELECT u.nome, COUNT(r.id) AS qtd
FROM usuario u
JOIN reserva r ON u.id = r.usuario_id
WHERE r.sala_id IN (SELECT id FROM sala WHERE localizacao LIKE 'Bloco A%')
GROUP BY u.id, u.nome
HAVING COUNT(r.id) > 5;

-- 4. GROUP BY + ROLLUP: Totalizador por tipo de usuário e status
SELECT u.tipo, r.status, COUNT(r.id) AS total
FROM reserva r
JOIN usuario u ON r.usuario_id = u.id
GROUP BY ROLLUP(u.tipo, r.status);

-- 5. Subconsulta Correlacionada: Última reserva realizada por usuário
SELECT u.nome, 
       (SELECT lower(r.periodo) 
        FROM reserva r 
        WHERE r.usuario_id = u.id 
        ORDER BY r.criado_em DESC LIMIT 1) AS ultima_reserva
FROM usuario u;