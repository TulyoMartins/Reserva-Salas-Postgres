-- Análise de busca por usuário sem índice
EXPLAIN ANALYZE 
SELECT * FROM reserva WHERE usuario_id = 450;

-- Criar Índices B-Tree
CREATE INDEX idx_reserva_usuario ON reserva(usuario_id);
CREATE INDEX idx_reserva_sala ON reserva(sala_id);

-- Análise após criação do índice
EXPLAIN ANALYZE 
SELECT * FROM reserva WHERE usuario_id = 450;