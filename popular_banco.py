import mysql.connector
from faker import Faker
import random
from datetime import datetime, timedelta

# ==============================================================================
# CONFIGURAÇÃO DO BANCO DE DADOS
# ==============================================================================
# Edite aqui com as suas credenciais
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',       
    'password': '12345678',  # <--- COLOQUE SUA SENHA DO MYSQL AQUI
    'database': 'stream_db'
}

# Configuração do Gerador de Dados
faker = Faker('pt_BR')  # Gera nomes e dados em Português do Brasil
NUM_FILMES = 50         # Quantos filmes criar
NUM_CLIENTES = 100      # Quantos clientes criar
NUM_SESSOES = 500       # Quantas sessões de visualização criar

def get_connection():
    try:
        return mysql.connector.connect(**DB_CONFIG)
    except mysql.connector.Error as err:
        print(f"Erro ao conectar: {err}")
        exit(1)

def popular_banco():
    conn = get_connection()
    cursor = conn.cursor()
    print("🚀 Iniciando a população do banco de dados...")

    # 1. POPULAR REGIÕES (Dados Fixos para consistência)
    regioes = [
        ('Brasil', 'América Latina'), 
        ('Estados Unidos', 'América do Norte'), 
        ('França', 'Europa'),
        ('Japão', 'Ásia')
    ]
    cursor.executemany("INSERT INTO Regiao (nome_pais, nome_regiao) VALUES (%s, %s)", regioes)
    print(f"✅ {len(regioes)} Regiões inseridas.")

    # 2. POPULAR GÊNEROS
    generos_lista = ['Ação', 'Comédia', 'Drama', 'Terror', 'Ficção Científica', 'Documentário', 'Romance', 'Animação']
    for g in generos_lista:
        cursor.execute("INSERT INTO Genero (nome_genero) VALUES (%s)", (g,))
    print(f"✅ {len(generos_lista)} Gêneros inseridos.")

    # 3. POPULAR PLANOS
    planos = [
        ('Básico com Anúncios', 19.90, 1, 'HD'),
        ('Padrão', 39.90, 2, 'FHD'),
        ('Premium', 55.90, 4, '4K')
    ]
    cursor.executemany("INSERT INTO Plano (nome, valor_mensal, max_dispositivos, qualidade_padrao) VALUES (%s, %s, %s, %s)", planos)
    print(f"✅ {len(planos)} Planos inseridos.")
    conn.commit()

    # Recuperar IDs gerados para usar nas chaves estrangeiras
    cursor.execute("SELECT id_regiao FROM Regiao")
    ids_regioes = [r[0] for r in cursor.fetchall()]

    cursor.execute("SELECT id_genero FROM Genero")
    ids_generos = [g[0] for g in cursor.fetchall()]

    cursor.execute("SELECT id_plano FROM Plano")
    ids_planos = [p[0] for p in cursor.fetchall()]

    # 4. POPULAR FILMES
    filmes_data = []
    classificacoes = ['Livre', '10', '12', '14', '16', '18']
    estudios = ['Universal', 'Warner', 'Disney', 'Paramount', 'Sony', 'Independente']
    
    for _ in range(NUM_FILMES):
        titulo = faker.catch_phrase().title()  # Gera um título aleatório
        filmes_data.append((
            titulo,
            random.randint(1990, 2024),          # Ano
            random.randint(80, 180),             # Duração
            random.choice(classificacoes),
            random.choice(estudios),
            faker.text(max_nb_chars=200),        # Sinopse
            random.choice(ids_generos)
        ))
    cursor.executemany("""
        INSERT INTO Filme (titulo, ano_lancamento, duracao_minutos, classificacao_ind, estudio, sinopse, id_genero)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, filmes_data)
    print(f"✅ {NUM_FILMES} Filmes inseridos.")
    conn.commit()

    # Recuperar IDs de filmes
    cursor.execute("SELECT id_filme FROM Filme")
    ids_filmes = [f[0] for f in cursor.fetchall()]

    # 5. DISPONIBILIDADE (Ligar filmes a regiões)
    disp_data = []
    for f_id in ids_filmes:
        # Cada filme está disponível em 1 a 3 regiões aleatórias
        for r_id in random.sample(ids_regioes, k=random.randint(1, 3)):
            disp_data.append((f_id, r_id))
    cursor.executemany("INSERT INTO Disponibilidade_Filme (id_filme, id_regiao) VALUES (%s, %s)", disp_data)
    print("✅ Disponibilidade Regional configurada.")

    # 6. POPULAR CLIENTES
    clientes_data = []
    for _ in range(NUM_CLIENTES):
        clientes_data.append((
            faker.name(),
            faker.email(),
            faker.date_of_birth(minimum_age=18, maximum_age=80),
            faker.date_between(start_date='-5y', end_date='today'), # Data cadastro
            random.choice(ids_regioes)
        ))
    # ... (código anterior igual) ...

    cursor.executemany("""
        INSERT IGNORE INTO Cliente (nome_completo, email, data_nascimento, data_cadastro, id_regiao)
        VALUES (%s, %s, %s, %s, %s)
    """, clientes_data)
    
    # ... (resto do código igual) ...
    print(f"✅ {NUM_CLIENTES} Clientes inseridos.")
    conn.commit()

    # Recuperar IDs de clientes
    cursor.execute("SELECT id_cliente, data_cadastro FROM Cliente")
    clientes_info = cursor.fetchall() # Lista de tuplas (id, data_cadastro)

    # 7. POPULAR ASSINATURAS (Histórico)
    assinaturas_data = []
    for client_id, data_cad in clientes_info:
        # Cria uma assinatura inicial na data de cadastro
        plano_id = random.choice(ids_planos)
        
        # 80% de chance de ter mudado de plano ou cancelado
        if random.random() > 0.2:
            # Assinatura antiga
            data_fim = data_cad + timedelta(days=random.randint(30, 300))
            assinaturas_data.append((client_id, plano_id, data_cad, data_fim))
            
            # Assinatura atual (nova)
            novo_plano = random.choice(ids_planos)
            assinaturas_data.append((client_id, novo_plano, data_fim, None)) # None = Ativa
        else:
            # Apenas uma assinatura ativa desde o cadastro
            assinaturas_data.append((client_id, plano_id, data_cad, None))

    cursor.executemany("INSERT INTO Assinatura (id_cliente, id_plano, data_inicio, data_fim) VALUES (%s, %s, %s, %s)", assinaturas_data)
    print("✅ Histórico de Assinaturas gerado.")

    # 8. POPULAR SESSÕES (Visualizações)
    sessoes_data = []
    qualidades = ['SD', 'HD', 'FHD', '4K']
    dispositivos = ['Smart TV', 'Smartphone', 'Tablet', 'Web Browser']

    for _ in range(NUM_SESSOES):
        cli = random.choice(clientes_info) # (id, data_cadastro)
        filme_id = random.choice(ids_filmes)
        
        # A sessão deve ser DEPOIS do cadastro do cliente
        data_inicio = faker.date_time_between(start_date=cli[1], end_date='now')
        
        sessoes_data.append((
            cli[0], # id_cliente
            filme_id,
            data_inicio,
            random.randint(5, 180), # min assistidos
            random.choice(dispositivos),
            random.choice(qualidades)
        ))
    cursor.executemany("""
        INSERT INTO Sessao (id_cliente, id_filme, data_hora_inicio, duracao_assistida, dispositivo, qualidade_reproducao)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, sessoes_data)
    print(f"✅ {NUM_SESSOES} Sessões de visualização registradas.")

    # 9. AVALIAÇÕES E FAVORITOS
    avaliacoes_data = []
    favoritos_data = []
    
    for cli in clientes_info:
        # Cada cliente avalia/favorita alguns filmes aleatórios
        filmes_interagidos = random.sample(ids_filmes, k=random.randint(1, 10))
        
        for f_id in filmes_interagidos:
            # Gera Avaliação
            if random.random() > 0.5:
                avaliacoes_data.append((
                    cli[0], f_id, random.randint(1, 5), faker.sentence(), datetime.now()
                ))
            
            # Gera Favorito
            if random.random() > 0.7:
                favoritos_data.append((
                    cli[0], f_id, datetime.now()
                ))

    # Inserir ignorando duplicatas (caso o random gere par repetido, embora o sample evite isso para o mesmo cliente)
    cursor.executemany("INSERT IGNORE INTO Avaliacao (id_cliente, id_filme, nota, comentario, data_avaliacao) VALUES (%s, %s, %s, %s, %s)", avaliacoes_data)
    cursor.executemany("INSERT IGNORE INTO Favorito (id_cliente, id_filme, data_favoritado) VALUES (%s, %s, %s)", favoritos_data)
    print("✅ Avaliações e Favoritos inseridos.")

    conn.commit()
    cursor.close()
    conn.close()
    print("\n🎉 SUCESSO! O banco de dados foi populado com dados sintéticos.")

if __name__ == "__main__":
    popular_banco()