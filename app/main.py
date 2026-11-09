import psycopg
from psycopg import errors
import sys

# Ajuste com a porta e senha do seu PostgreSQL local se for diferente
DB_URI = "postgresql://postgres:postgres@localhost:5432/postgres"

def get_connection():
    try:
        return psycopg.connect(DB_URI)
    except Exception as e:
        print(f"Erro ao conectar ao Banco de Dados: {e}")
        sys.exit(1)

def listar_agenda_dia():
    data = input("Digite a data (AAAA-MM-DD): ")
    sala_id = input("ID da Sala: ")
    query = """
        SELECT reserva_id, sala_nome, usuario_nome, hora_inicio, hora_fim 
        FROM v_agenda_dia 
        WHERE sala_id = %s AND data_reserva = %s;
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, (sala_id, data))
            rows = cur.fetchall()
            print(f"\n--- AGENDA DA SALA {sala_id} EM {data} ---")
            if not rows:
                print("Nenhuma reserva encontrada para este dia.")
            for r in rows:
                print(f"Reserva #{r[0]} | Usuario: {r[2]} | {r[3].strftime('%H:%M')} ate {r[4].strftime('%H:%M')}")

def criar_reserva():
    print("\n--- CRIAR RESERVA ---")
    sala_id = int(input("ID da Sala: "))
    usuario_id = int(input("Seu ID de Usuario: "))
    inicio = input("Inicio (AAAA-MM-DD HH:MM:SS): ")
    fim = input("Fim (AAAA-MM-DD HH:MM:SS): ")

    with get_connection() as conn:
        with conn.cursor() as cur:
            try:
                cur.execute("CALL pr_criar_reserva(%s, %s, %s::timestamptz, %s::timestamptz);", 
                            (sala_id, usuario_id, inicio, fim))
                conn.commit()
                print("Sucesso: Reserva criada com sucesso!")
            except errors.ExclusionViolation:
                print("ERRO DO BANCO: Conflito de horario! A sala ja esta reservada nesse periodo.")
            except errors.RaiseException as e:
                print(f"ERRO DE REGRA DE NEGOCIO (PostgreSQL): {e.diag.message_primary}")
            except Exception as e:
                print(f"Erro inesperado: {e}")

def cancelar_reserva():
    print("\n--- CANCELAR RESERVA ---")
    reserva_id = int(input("ID da Reserva: "))
    usuario_id = int(input("Seu ID de Usuario: "))

    with get_connection() as conn:
        with conn.cursor() as cur:
            try:
                cur.execute("CALL pr_cancelar_reserva(%s, %s);", (reserva_id, usuario_id))
                conn.commit()
                print("Sucesso: Reserva cancelada!")
            except errors.RaiseException as e:
                print(f"ERRO DO BANCO: {e.diag.message_primary}")

def relatorio_ocupacao():
    query = "SELECT sala_nome, mes_ano, total_reservas, horas_reservadas FROM mv_ocupacao_mensal LIMIT 20;"
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query)
            rows = cur.fetchall()
            print("\n--- RELATORIO DE OCUPACAO MENSAL ---")
            for r in rows:
                print(f"Sala: {r[0]} | Mes: {r[1]} | Reservas: {r[2]} | Total Horas: {r[3]}h")

def menu():
    while True:
        print("\n==================================")
        print(" SISTEMA DE RESERVA DE SALAS (BD2)")
        print("==================================")
        print("1. Listar agenda de uma sala no dia")
        print("2. Criar reserva")
        print("3. Cancelar reserva")
        print("4. Relatorio de ocupacao mensal")
        print("5. Sair")
        opcao = input("Escolha uma opcao: ")

        if opcao == '1': listar_agenda_dia()
        elif opcao == '2': criar_reserva()
        elif opcao == '3': cancelar_reserva()
        elif opcao == '4': relatorio_ocupacao()
        elif opcao == '5': break
        else: print("Opcao invalida.")

if __name__ == "__main__":
    menu()