-- Carga Base de Usuários e Salas
INSERT INTO usuario (nome, email, tipo)
SELECT 
    'Usuario ' || i,
    'usuario' || i || '@instituicao.edu.br',
    (ARRAY['ALUNO', 'PROFESSOR', 'ADMIN'])[floor(random() * 3 + 1)]
FROM generate_series(1, 1000) s(i);

INSERT INTO sala (nome, capacidade, localizacao)
SELECT 
    'Sala ' || i,
    floor(random() * 50 + 10)::int,
    'Bloco ' || (ARRAY['A', 'B', 'C', 'D'])[floor(random() * 4 + 1)]
FROM generate_series(1, 50) s(i);

INSERT INTO recurso (nome, descricao) VALUES
('Projetor 4K', 'Projetor de alta definição'),
('Computadores i7', '20 computadores de alto desempenho'),
('Ar Condicionado', 'Climatização central');

-- Carga Massiva (+10.000 Reservas sem sobreposição)
INSERT INTO reserva (sala_id, usuario_id, periodo, status)
SELECT 
    (i % 50) + 1 AS sala_id,
    (i % 1000) + 1 AS usuario_id,
    tstzrange(
        '2025-01-01 08:00:00+00'::timestamptz + (i || ' hours')::interval,
        '2025-01-01 08:50:00+00'::timestamptz + (i || ' hours')::interval,
        '[)'
    ),
    'ATIVA'
FROM generate_series(1, 12000) s(i);