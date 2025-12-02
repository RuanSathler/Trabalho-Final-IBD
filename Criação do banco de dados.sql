-- ==========================================================
-- SCRIPT DE CRIAÇÃO (DDL) - STREAMING
-- ==========================================================

-- 1. Cria o Banco Limpo
DROP DATABASE IF EXISTS stream_db;
CREATE DATABASE stream_db;
USE stream_db;

-- 2. Tabelas Independentes
CREATE TABLE Regiao (
    id_regiao INT AUTO_INCREMENT PRIMARY KEY,
    nome_pais VARCHAR(100) NOT NULL,
    nome_regiao VARCHAR(100) NOT NULL
);

CREATE TABLE Genero (
    id_genero INT AUTO_INCREMENT PRIMARY KEY,
    nome_genero VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Plano (
    id_plano INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    valor_mensal DECIMAL(10, 2) NOT NULL,
    max_dispositivos INT NOT NULL,
    qualidade_padrao VARCHAR(20) NOT NULL
);

-- 3. Entidades Principais
CREATE TABLE Filme (
    id_filme INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    ano_lancamento INT NOT NULL,
    duracao_minutos INT NOT NULL,
    classificacao_ind VARCHAR(10),
    estudio VARCHAR(100),
    sinopse TEXT,
    id_genero INT,
    CONSTRAINT fk_filme_genero FOREIGN KEY (id_genero) REFERENCES Genero(id_genero)
);

CREATE TABLE Cliente (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome_completo VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    data_nascimento DATE NOT NULL,
    data_cadastro DATE NOT NULL,
    id_regiao INT,
    CONSTRAINT fk_cliente_regiao FOREIGN KEY (id_regiao) REFERENCES Regiao(id_regiao)
);

-- 4. Tabelas de Relacionamento
CREATE TABLE Assinatura (
    id_assinatura INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_plano INT NOT NULL,
    data_inicio DATETIME NOT NULL,
    data_fim DATETIME NULL,
    CONSTRAINT fk_assinatura_cliente FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente),
    CONSTRAINT fk_assinatura_plano FOREIGN KEY (id_plano) REFERENCES Plano(id_plano)
);

CREATE TABLE Disponibilidade_Filme (
    id_filme INT NOT NULL,
    id_regiao INT NOT NULL,
    PRIMARY KEY (id_filme, id_regiao),
    CONSTRAINT fk_disp_filme FOREIGN KEY (id_filme) REFERENCES Filme(id_filme),
    CONSTRAINT fk_disp_regiao FOREIGN KEY (id_regiao) REFERENCES Regiao(id_regiao)
);

CREATE TABLE Sessao (
    id_sessao INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_filme INT NOT NULL,
    data_hora_inicio DATETIME NOT NULL,
    duracao_assistida INT NOT NULL,
    dispositivo VARCHAR(50),
    qualidade_reproducao VARCHAR(10),
    CONSTRAINT fk_sessao_cliente FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente),
    CONSTRAINT fk_sessao_filme FOREIGN KEY (id_filme) REFERENCES Filme(id_filme)
);

CREATE TABLE Avaliacao (
    id_cliente INT NOT NULL,
    id_filme INT NOT NULL,
    nota INT NOT NULL,
    comentario TEXT,
    data_avaliacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_cliente, id_filme),
    CONSTRAINT chk_nota CHECK (nota >= 1 AND nota <= 5),
    CONSTRAINT fk_aval_cliente FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente),
    CONSTRAINT fk_aval_filme FOREIGN KEY (id_filme) REFERENCES Filme(id_filme)
);

CREATE TABLE Favorito (
    id_cliente INT NOT NULL,
    id_filme INT NOT NULL,
    data_favoritado DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_cliente, id_filme),
    CONSTRAINT fk_fav_cliente FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente),
    CONSTRAINT fk_fav_filme FOREIGN KEY (id_filme) REFERENCES Filme(id_filme)
);