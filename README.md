# Sistema de Reserva de Salas e Laboratórios (PostgreSQL)

Aplicação CLI em Python desenvolvida para a disciplina de Banco de Dados II. Toda a integridade declarativa e as regras de negócio estão encapsuladas diretamente no PostgreSQL através de PL/pgSQL, Triggers e Constraints avançadas.

##  Tecnologias

- **PostgreSQL 15+**

- **PL/pgSQL**

- **Python 3.10+** (psycopg 3 sem ORM)

##  Destaques do Projeto

- **Normalização**: Modelo em Terceira Forma Normal (3FN).

- **Sem Conflito de Horário**: Utilização de `EXCLUDE USING gist (sala_id WITH =, periodo WITH &&)` para evitar reservas sobrepostas via motor do banco.

- **Triggers**: Auditoria automática e restrição do limite de reservas por usuário.

- **Segurança RBAC**: Permissões gerenciadas via Role `app_reservas` sem acesso direto às tabelas base.

##  Como Executar

1. **Rodar Scripts no PostgreSQL** (na ordem):

   ```bash

   psql -U postgres -f database/01_schema.sql

   psql -U postgres -f database/02_functions_triggers.sql

   psql -U postgres -f database/03_views.sql

   psql -U postgres -f database/04_seed_data.sql

   psql -U postgres -f database/05_analytics.sql

   psql -U postgres -f database/06_security.sql