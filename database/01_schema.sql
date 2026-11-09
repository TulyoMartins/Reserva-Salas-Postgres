CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Domain e Enum
CREATE DOMAIN dm_email AS VARCHAR(255) 
  CHECK (VALUE ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$');

CREATE TYPE enum_status_reserva AS ENUM ('ATIVA', 'CANCELADA');
CREATE TYPE enum_tipo_usuario AS ENUM ('ALUNO', 'PROFESSOR', 'ADMIN');

-- 1. Tabela USUARIO
CREATE TABLE usuario (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email dm_email NOT NULL UNIQUE,
    tipo enum_tipo_usuario NOT NULL DEFAULT 'ALUNO',
    criado_em TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabela SALA
CREATE TABLE sala (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    capacidade INT NOT NULL CHECK (capacidade > 0),
    localizacao VARCHAR(100) NOT NULL
);

-- 3. Tabela RECURSO
CREATE TABLE recurso (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    descricao TEXT
);

-- 4. Tabela SALA_RECURSO (N:N)
CREATE TABLE sala_recurso (
    sala_id INT NOT NULL REFERENCES sala(id) ON DELETE CASCADE,
    recurso_id INT NOT NULL REFERENCES recurso(id) ON DELETE RESTRICT,
    quantidade INT NOT NULL DEFAULT 1 CHECK (quantidade > 0),
    PRIMARY KEY (sala_id, recurso_id)
);

-- 5. Tabela RESERVA
CREATE TABLE reserva (
    id SERIAL PRIMARY KEY,
    sala_id INT NOT NULL REFERENCES sala(id) ON DELETE RESTRICT,
    usuario_id INT NOT NULL REFERENCES usuario(id) ON DELETE RESTRICT,
    periodo TSTZRANGE NOT NULL,
    status enum_status_reserva NOT NULL DEFAULT 'ATIVA',
    criado_em TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_duracao_minima CHECK (upper(periodo) - lower(periodo) >= INTERVAL '30 minutes'),
    CONSTRAINT sem_conflito_horario EXCLUDE USING gist (
        sala_id WITH =, 
        periodo WITH &&
    ) WHERE (status = 'ATIVA')
);

-- 6. Tabela LOG_RESERVA (Auditoria)
CREATE TABLE log_reserva (
    id SERIAL PRIMARY KEY,
    reserva_id INT,
    operacao VARCHAR(10) NOT NULL,
    usuario_bd VARCHAR(50) NOT NULL DEFAULT CURRENT_USER,
    data_operacao TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    dados_antigos JSONB,
    dados_novos JSONB
);