-- ==========================================================
-- CONSULTAS OBRIGATÓRIAS (Queries de Análise)
-- ==========================================================

-- 1. Listar os títulos dos filmes disponíveis na região “Brasil”.
SELECT f.titulo, r.nome_pais
FROM Filme f
JOIN Disponibilidade_Filme df ON f.id_filme = df.id_filme
JOIN Regiao r ON df.id_regiao = r.id_regiao
WHERE r.nome_pais = 'Brasil';

-- 2. Listar os filmes “favoritos” de um cliente específico (ex: id 1)
-- Ordenado por data de favoritamento (mais recente primeiro)
SELECT c.nome_completo, f.titulo, fav.data_favoritado
FROM Favorito fav
JOIN Cliente c ON fav.id_cliente = c.id_cliente
JOIN Filme f ON fav.id_filme = f.id_filme
WHERE c.id_cliente = 1 -- Troque pelo ID ou Nome de um cliente gerado
ORDER BY fav.data_favoritado DESC;

-- 3. Listar filmes do gênero “Comédia” com média de avaliação >= 4
SELECT f.titulo, g.nome_genero, AVG(a.nota) as media_nota
FROM Filme f
JOIN Genero g ON f.id_genero = g.id_genero
JOIN Avaliacao a ON f.id_filme = a.id_filme
WHERE g.nome_genero = 'Comédia'
GROUP BY f.id_filme
HAVING media_nota >= 4;

-- 4. Listar filmes que NÃO tiveram nenhuma visualização (Sessão) em um período
-- (Ex: Filmes "encalhados" em 2024)
SELECT f.titulo
FROM Filme f
WHERE f.id_filme NOT IN (
    SELECT DISTINCT s.id_filme 
    FROM Sessao s 
    WHERE s.data_hora_inicio BETWEEN '2024-01-01' AND '2024-12-31'
);

-- 5. Total de visualizações e minutos assistidos por filme no Brasil num mês específico
SELECT f.titulo, COUNT(s.id_sessao) as total_views, SUM(s.duracao_assistida) as total_minutos
FROM Sessao s
JOIN Filme f ON s.id_filme = f.id_filme
JOIN Cliente c ON s.id_cliente = c.id_cliente
JOIN Regiao r ON c.id_regiao = r.id_regiao
WHERE r.nome_pais = 'Brasil' 
  AND MONTH(s.data_hora_inicio) = 10 -- Exemplo: Outubro
  AND YEAR(s.data_hora_inicio) = 2024 -- Ajuste conforme os dados gerados
GROUP BY f.id_filme;

-- 6. Total de horas assistidas pelo cliente "X" agrupado por gênero
SELECT c.nome_completo, g.nome_genero, 
       ROUND(SUM(s.duracao_assistida) / 60, 2) as horas_assistidas
FROM Sessao s
JOIN Cliente c ON s.id_cliente = c.id_cliente
JOIN Filme f ON s.id_filme = f.id_filme
JOIN Genero g ON f.id_genero = g.id_genero
WHERE c.id_cliente = 1 -- Altere para testar outros clientes
GROUP BY g.nome_genero;

-- 7. Quantidade de clientes ativos por plano e média de dispositivos
-- (Assumimos 'Ativo' quem tem data_fim NULL na tabela Assinatura)
SELECT p.nome, COUNT(a.id_assinatura) as clientes_ativos, p.max_dispositivos
FROM Plano p
JOIN Assinatura a ON p.id_plano = a.id_plano
WHERE a.data_fim IS NULL
GROUP BY p.id_plano;

-- 8. Top 5 filmes mais assistidos na região “Estados Unidos” (por minutos)
SELECT f.titulo, SUM(s.duracao_assistida) as total_minutos, COUNT(s.id_sessao) as num_sessoes
FROM Sessao s
JOIN Filme f ON s.id_filme = f.id_filme
JOIN Cliente c ON s.id_cliente = c.id_cliente
JOIN Regiao r ON c.id_regiao = r.id_regiao
WHERE r.nome_pais = 'Estados Unidos'
GROUP BY f.id_filme
ORDER BY total_minutos DESC
LIMIT 5;

-- 9. Distribuição de qualidade de reprodução (SD/HD/4K) do cliente "X"
SELECT s.qualidade_reproducao, 
       COUNT(*) as qtd_sessoes, 
       (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Sessao WHERE id_cliente = 1)) as percentual
FROM Sessao s
WHERE s.id_cliente = 1
GROUP BY s.qualidade_reproducao;

-- 10. Clientes que mudaram de plano (Histórico)
-- Busca quem tem mais de uma assinatura registrada
SELECT c.nome_completo, p.nome as plano_nome, a.data_inicio, a.data_fim
FROM Assinatura a
JOIN Cliente c ON a.id_cliente = c.id_cliente
JOIN Plano p ON a.id_plano = p.id_plano
WHERE c.id_cliente IN (
    SELECT id_cliente FROM Assinatura GROUP BY id_cliente HAVING COUNT(*) > 1
)
ORDER BY c.nome_completo, a.data_inicio;