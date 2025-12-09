-- Módulo Básico e Modelagem (Integridade e CRUD)

-- 1 Modelagem DDL

-- Criar banco de dados
DROP DATABASE IF EXISTS gestaoeventos_db;
CREATE DATABASE gestaoeventos_db;
USE gestaoeventos_db;

-- ==========================
-- Tabela de Eventos
-- ==========================
CREATE TABLE Eventos (
    id_evento INT AUTO_INCREMENT PRIMARY KEY,
    nome_evento VARCHAR(255) NOT NULL,
    local VARCHAR(255) NOT NULL,
    data_evento DATE NOT NULL,
    UNIQUE (nome_evento, data_evento)
);

-- ==========================
-- Tabela de Participantes
-- ==========================
CREATE TABLE Participantes (
    id_participante INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    cpf VARCHAR(14) NOT NULL UNIQUE,
    celular VARCHAR(20),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================
-- Tabela de Palestras
-- ==========================
CREATE TABLE Palestras (
    id_palestra INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    palestrante VARCHAR(255) NOT NULL,
    id_evento INT NOT NULL,
    FOREIGN KEY (id_evento) REFERENCES Eventos(id_evento)
);

-- ==========================
-- Tabela auxiliar numinscritos
-- ==========================
CREATE TABLE numinscritos (
    id_numinscrito INT AUTO_INCREMENT PRIMARY KEY,
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================
-- Tabela de Inscricoes
-- ==========================
CREATE TABLE Inscricoes (
    id_inscricao INT AUTO_INCREMENT PRIMARY KEY,
    id_evento INT NOT NULL,
    id_participante INT NOT NULL,
    id_numinscrito INT NOT NULL,
    data_inscricao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_evento) REFERENCES Eventos(id_evento),
    FOREIGN KEY (id_participante) REFERENCES Participantes(id_participante),
    FOREIGN KEY (id_numinscrito) REFERENCES numinscritos(id_numinscrito),
    UNIQUE (id_evento, id_participante)
);

-- 2 - DML Simulação da Volumetria

-- ==========================
-- Tabela auxiliar numeros (para melhor popular)
-- ==========================
CREATE TABLE numeros (
    n INT PRIMARY KEY    
);

-- Popular numeros de 0 a 9999
INSERT INTO numeros (n)
SELECT t1.n + t10.n*10 + t100.n*100 + t1000.n*1000
FROM (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1
CROSS JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t10
CROSS JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t100
CROSS JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1000
WHERE t1.n + t10.n*10 + t100.n*100 + t1000.n*1000 <= 9999;

-- ==========================
-- Popular numinscritos com 10.000 registros
-- ==========================
INSERT INTO numinscritos (data_registro)
SELECT CURRENT_TIMESTAMP
FROM numeros
WHERE n < 10000;

-- ==========================
-- Popular Participantes com 10.000 registros
-- ==========================
INSERT INTO Participantes (nome, email, cpf)
SELECT CONCAT('Participante_', n),
       CONCAT('user', n, '@teste.com'),
       LPAD(n, 11, '0')
FROM numeros
WHERE n < 10000;

-- ==========================
-- Criar alguns eventos
-- ==========================
INSERT INTO Eventos (nome_evento, local, data_evento)
VALUES ('Congresso TI','Centro de Convenções','2025-12-15'),
       ('Hackathon','Campus Universitário','2025-12-20'),
       ('Bootcamp Dev','Online','2025-12-30');


-- ==========================
-- Popular Inscricoes com 10.000 registros
-- Distribui os participantes entre 3 eventos
-- ==========================
INSERT INTO Inscricoes (id_evento, id_participante, id_numinscrito)
SELECT (n % 3) + 1, n+1, n+1
FROM numeros
WHERE n < 10000;

-- ==========================
-- Índices para Alta Performance
-- ==========================
-- Índices em Inscricoes
CREATE INDEX idx_inscricoes_evento ON Inscricoes(id_evento);
CREATE INDEX idx_inscricoes_participante ON Inscricoes(id_participante);
CREATE INDEX idx_inscricoes_numinscrito ON Inscricoes(id_numinscrito);
CREATE INDEX idx_evento_participante ON Inscricoes(id_evento, id_participante);
CREATE INDEX idx_inscricoes_evento_data ON Inscricoes(id_evento, data_inscricao);

-- Índices em Participantes
CREATE INDEX idx_participantes_nome ON Participantes(nome);
CREATE INDEX idx_participantes_email ON Participantes(email);
-- Otimização 1: Índice único (ou garantia de índice) na coluna de e-mail
CREATE UNIQUE INDEX idx_participantes_email ON Participantes (email);

-- Índices em Palestras
CREATE INDEX idx_palestras_evento ON Palestras(id_evento);

-- Índices de Eventos
CREATE INDEX idx_eventos_data ON Eventos (data_evento);

    -- Inserir Eventos
INSERT INTO Eventos (nome_evento, local, data_evento) VALUES
('Tech Summit 2025', 'Online', '2025-05-10'),     -- id_evento = 1
('Workshop de Design', 'Auditório Central', '2025-06-15'); -- id_evento = 2

-- Inserir Palestras
INSERT INTO Palestras (titulo, palestrante, id_evento) VALUES
('Futuro da IA', 'Dr. Alan Turing Jr.', 1),
('Introdução ao UX', 'Maria Silva', 2),
('Segurança em Nuvem', 'Carlos Oliveira', 1),
('Tipografia Moderna', 'Maria Silva', 2);

-- Inserir Participantes (Necessário para o UNION ALL)
INSERT INTO Participantes (nome, email, cpf) VALUES
('João Souza', 'joao.souza@email.com', '111.111.111-11'),
('Ana Costa', 'ana.costa@email.com', '222.222.222-22');

-- 3 - Consultas Básicas: 

Exemplo e consulta:

SELECT
    P.nome,
    P.email,
    E.nome_evento
FROM
    Participantes P
JOIN
    Inscricoes I ON P.id_participante = I.id_participante
JOIN
    Eventos E ON I.id_evento = E.id_evento
WHERE
    I.id_evento = 10  -- Filtra pelo Evento específico
    AND (             -- Usa parênteses para agrupar as condições OR
        P.nome LIKE 'Maria%' -- Condição 1 (Nome começa com Maria)
        OR
        P.email LIKE '%@empresa.com' -- Condição 2 (Email termina com @empresa.com)
    );


   -- Listar os Primeiros 50 Inscritos em Ordem Alfabética


mysql> SELECT P.nome, P.email, I.data_inscricao FROM Participantes P JOIN Inscricoes I
     ON P.id_participante = I.id_participante ORDER BY P.nome ASC LIMIT 50;
+-------------------+--------------------+---------------------+
| nome              | email              | data_inscricao      |
+-------------------+--------------------+---------------------+
| Participante_0    | user0@teste.com    | 2025-11-30 17:42:25 |
| Participante_1    | user1@teste.com    | 2025-11-30 17:42:25 |
| Participante_10   | user10@teste.com   | 2025-11-30 17:42:25 |
| Participante_100  | user100@teste.com  | 2025-11-30 17:42:25 |
| Participante_1000 | user1000@teste.com | 2025-11-30 17:42:25 |
| Participante_1001 | user1001@teste.com | 2025-11-30 17:42:25 |
| Participante_1002 | user1002@teste.com | 2025-11-30 17:42:25 |
| Participante_1003 | user1003@teste.com | 2025-11-30 17:42:25 |
| Participante_1004 | user1004@teste.com | 2025-11-30 17:42:25 |
| Participante_1005 | user1005@teste.com | 2025-11-30 17:42:25 |
| Participante_1006 | user1006@teste.com | 2025-11-30 17:42:25 |
| Participante_1007 | user1007@teste.com | 2025-11-30 17:42:25 |
| Participante_1008 | user1008@teste.com | 2025-11-30 17:42:25 |
| Participante_1009 | user1009@teste.com | 2025-11-30 17:42:25 |
| Participante_101  | user101@teste.com  | 2025-11-30 17:42:25 |
| Participante_1010 | user1010@teste.com | 2025-11-30 17:42:25 |
| Participante_1011 | user1011@teste.com | 2025-11-30 17:42:25 |
| Participante_1012 | user1012@teste.com | 2025-11-30 17:42:25 |
| Participante_1013 | user1013@teste.com | 2025-11-30 17:42:25 |
| Participante_1014 | user1014@teste.com | 2025-11-30 17:42:25 |
| Participante_1015 | user1015@teste.com | 2025-11-30 17:42:25 |
| Participante_1016 | user1016@teste.com | 2025-11-30 17:42:25 |
| Participante_1017 | user1017@teste.com | 2025-11-30 17:42:25 |
| Participante_1018 | user1018@teste.com | 2025-11-30 17:42:25 |
| Participante_1019 | user1019@teste.com | 2025-11-30 17:42:25 |
| Participante_102  | user102@teste.com  | 2025-11-30 17:42:25 |
| Participante_1020 | user1020@teste.com | 2025-11-30 17:42:25 |
| Participante_1021 | user1021@teste.com | 2025-11-30 17:42:25 |
| Participante_1022 | user1022@teste.com | 2025-11-30 17:42:25 |
| Participante_1023 | user1023@teste.com | 2025-11-30 17:42:25 |
| Participante_1024 | user1024@teste.com | 2025-11-30 17:42:25 |
| Participante_1025 | user1025@teste.com | 2025-11-30 17:42:25 |
| Participante_1026 | user1026@teste.com | 2025-11-30 17:42:25 |
| Participante_1027 | user1027@teste.com | 2025-11-30 17:42:25 |
| Participante_1028 | user1028@teste.com | 2025-11-30 17:42:25 |
| Participante_1029 | user1029@teste.com | 2025-11-30 17:42:25 |
| Participante_103  | user103@teste.com  | 2025-11-30 17:42:25 |
| Participante_1030 | user1030@teste.com | 2025-11-30 17:42:25 |
| Participante_1031 | user1031@teste.com | 2025-11-30 17:42:25 |
| Participante_1032 | user1032@teste.com | 2025-11-30 17:42:25 |
| Participante_1033 | user1033@teste.com | 2025-11-30 17:42:25 |
| Participante_1034 | user1034@teste.com | 2025-11-30 17:42:25 |
| Participante_1035 | user1035@teste.com | 2025-11-30 17:42:25 |
| Participante_1036 | user1036@teste.com | 2025-11-30 17:42:25 |
| Participante_1037 | user1037@teste.com | 2025-11-30 17:42:25 |
| Participante_1038 | user1038@teste.com | 2025-11-30 17:42:25 |
| Participante_1039 | user1039@teste.com | 2025-11-30 17:42:25 |
| Participante_104  | user104@teste.com  | 2025-11-30 17:42:25 |
| Participante_1040 | user1040@teste.com | 2025-11-30 17:42:25 |
| Participante_1041 | user1041@teste.com | 2025-11-30 17:42:25 |
+-------------------+--------------------+---------------------+
50 rows in set (0,00 sec)


-- Módulo Intermediário (Análise e Estrutura)

-- 4 - JOINs e UNION: Utilizar INNER JOIN e LEFT JOIN para 
     -- listar todas as palestras, mostrando o nome do evento
     -- e do palestrante. Usar UNION ALL para combinar a lista de todos os palestrantes e participantes em uma única coluna.

-- Consulta 1: Palestras e Eventos (INNER JOIN)

mysql> SELECT P.titulo AS Nome_da_Palestra, E.nome_evento AS Nome_do_Evento, P.palestrante AS Nome_do_Palestrante
       FROM Palestras P INNER JOIN Eventos E ON P.id_evento = E.id_event o ORDER BY E.nome_evento, P.titulo;

+---------------------+----------------+---------------------+
| Nome_da_Palestra    | Nome_do_Evento | Nome_do_Palestrante |
+---------------------+----------------+---------------------+
| Futuro da IA        | Congresso TI   | Dr. Alan Turing Jr. |
| Segurança em Nuvem  | Congresso TI   | Carlos Oliveira     |
| Introdução ao UX    | Hackathon      | Maria Silva         |
| Tipografia Moderna  | Hackathon      | Maria Silva         |
+---------------------+----------------+---------------------+
4 rows in set (0,00 sec)

-- Consulta 2: Combinar Palestrantes e Participantes (UNION ALL) customisando
-- para apenas exibir o total de cadastrados para o evento e não listar, a tabela contém
-- um total muito elevado.

SELECT COUNT(*) AS Total_de_Pessoas FROM (SELECT P.palestrante AS
Nome, 'Palestrante' AS Tipo FROM Palestras P UNION ALL SELECT PA.nome AS
Nome, 'Participante' AS Tipo FROM Participantes PA) AS TotalPessoas;
+------------------+
| Total_de_Pessoas |
+------------------+
|            10006 |
+------------------+
1 row in set (0,03 sec)


-- 5 - Agregação e Having,
     -- Número de palestrantes por evento

     mysql> SELECT E.nome_evento AS Nome_do_Evento, COUNT(DISTINCT P.palestrante) AS Total_Palestrantes FROM Palestras P INNER JOIN Eventos E ON P.id_evento = E.id_evento GROUP BY E.nome_evento ORDER BY Total_Palestrantes DESC, E.nome_evento;
+----------------+--------------------+
| Nome_do_Evento | Total_Palestrantes |
+----------------+--------------------+
| Congresso TI   |                  2 |
| Hackathon      |                  1 |
+----------------+--------------------+
2 rows in set (0,00 sec)


-- 6 - Subqueries e Views: Criar uma VIEW para simplificar relatórios de eventos com 
     -- alta lotação. Utilizar SUBQUERY para identificar o evento com a palestra de maior duração (MAX(duracao_minutos)).


mysql> select * from Palestras;
+-------------+---------------------+---------------------+-----------+-----------------+
| id_palestra | titulo              | palestrante         | id_evento | duracao_minutos |
+-------------+---------------------+---------------------+-----------+-----------------+
|           1 | Futuro da IA        | Dr. Alan Turing Jr. |         1 |              60 |
|           2 | Introdução ao UX    | Maria Silva         |         2 |              90 |
|           3 | Segurança em Nuvem  | Carlos Oliveira     |         1 |              45 |
|           4 | Tipografia Moderna  | Maria Silva         |         2 |              90 |
+-------------+---------------------+---------------------+-----------+-----------------+
4 rows in set (0,00 sec)


mysql> SELECT E.nome_evento, P.titulo AS Palestra_Mais_Longa, P.duracao_minutos FROM Palestras P INNER JOIN  Eventos E ON P.id_evento = E.id_evento WHERE  P.duracao_minutos = (
       SELECT MAX(duracao_minutos) FROM Palestras);
+-------------+---------------------+-----------------+
| nome_evento | Palestra_Mais_Longa | duracao_minutos |
+-------------+---------------------+-----------------+
| Hackathon   | Introdução ao UX    |              90 |
| Hackathon   | Tipografia Moderna  |              90 |
+-------------+---------------------+-----------------+
2 rows in set (0,01 sec)



-- 7 - Funções e Normalização: Aplicar funções de Data para listar eventos do próximo fim de semana. 
     -- Assegurar que as tabelas estejam, no mínimo, na 3ª Forma Normal.


mysql> SELECT CURDATE() AS Hoje, WEEKDAY(CURDATE()) AS Dia_Semana_0_a_6
, DATE_ADD(CURDATE(), INTERVAL (7 - WEEKDAY(CURDATE())) % 7 DAY) AS Pro
ximo_Sabado, DATE_ADD(CURDATE(), INTERVAL (7 - WEEKDAY(CURDATE())) % 7
+ 1 DAY) AS Proximo_Domingo;
+------------+------------------+----------------+-----------------+
| Hoje       | Dia_Semana_0_a_6 | Proximo_Sabado | Proximo_Domingo |
+------------+------------------+----------------+-----------------+
| 2025-12-02 |                1 | 2025-12-08     | 2025-12-09      |
+------------+------------------+----------------+-----------------+
1 row in set (0,00 sec)


-- Módulo Avançado (Programação e Controle Transacional)

-- 8 - Otimização: Adicionar um INDEX na coluna de e-mail da tabela Participantes e na coluna de data do evento para acelerar consultas.

-- Otimização 1: Índice único na coluna de e-mail para buscas rápidas
CREATE UNIQUE INDEX idx_participantes_email ON Participantes (email);

-- Otimização 2: Índice na coluna de data para consultas de intervalo e ordenação
CREATE INDEX idx_eventos_data ON Eventos (data_evento);

-- 9 - Stored Procedure: Criar uma STORED PROCEDURE que insere uma nova inscrição, atualizando o contador de vagas_disponiveis na tabela Eventos.

DELIMITER //

CREATE PROCEDURE sp_inserir_inscricao (
    IN p_id_evento INT,
    IN p_id_participante INT,
    OUT p_mensagem VARCHAR(255)
)
BEGIN
    DECLARE v_vagas_atuais INT;
    DECLARE v_num_inscrito_id INT;
    DECLARE v_inscricao_existente INT;

    -- 1. Verificar se a inscrição já existe
    SELECT COUNT(*)
    INTO v_inscricao_existente
    FROM Inscricoes
    WHERE id_evento = p_id_evento AND id_participante = p_id_participante;

    IF v_inscricao_existente > 0 THEN
        SET p_mensagem = 'ERRO: Participante já está inscrito neste evento.';
    ELSE
        -- 2. Verificar vagas disponíveis
        SELECT vagas_disponiveis
        INTO v_vagas_atuais
        FROM Eventos
        WHERE id_evento = p_id_evento;

        IF v_vagas_atuais > 0 THEN
            -- 3. Inserir na tabela numinscritos (para obter o ID serial)
            INSERT INTO numinscritos (data_registro) VALUES (CURRENT_TIMESTAMP());
            SET v_num_inscrito_id = LAST_INSERT_ID();

            -- 4. Inserir a nova inscrição na tabela Inscricoes
            INSERT INTO Inscricoes (id_evento, id_participante, id_numinscrito)
            VALUES (p_id_evento, p_id_participante, v_num_inscrito_id);

            -- 5. Atualizar (decrementar) o contador de vagas
            UPDATE Eventos
            SET vagas_disponiveis = vagas_disponiveis - 1
            WHERE id_evento = p_id_evento;

            SET p_mensagem = 'SUCESSO: Inscrição registrada e vagas atualizadas.';
        ELSE
            SET p_mensagem = 'ERRO: Vagas esgotadas para este evento.';
        END IF;
    END IF;
END //

DELIMITER ;

-- Resultado esperado SUCESSO ou
mysql> SELECT @mensagem_status AS Status_Inscricao;
+------------------------------------------------------+
| Status_Inscricao                                     |
+------------------------------------------------------+
| SUCESSO: Inscrição registrada e vagas atualizadas.   |
+------------------------------------------------------+
1 row in set (0,00 sec)

 select * from Eventos;
+-----------+---------------------------+------------------------+-------------+-------------------+
| id_evento | nome_evento               | local                  | data_evento | vagas_disponiveis |
+-----------+---------------------------+------------------------+-------------+-------------------+
|         1 | Congresso TI              | Centro de Convenções   | 2025-12-15  |                50 |
|         2 | Hackathon                 | Campus Universitário   | 2025-12-20  |                50 |
|         3 | Bootcamp Dev              | Online                 | 2025-12-30  |                50 |
|         4 | Tech Summit 2025          | Online                 | 2025-05-10  |                50 |
|         5 | Workshop de Design        | Auditório Central      | 2025-06-15  |                 2 |
|         6 | Fórum de Cibersegurança   | Centro de Convenções   | 2025-12-06  |                50 |
+-----------+---------------------------+------------------------+-------------+-------------------+
6 rows in set (0,00 sec)

mysql> SELECT vagas_disponiveis FROM Eventos WHERE id_evento = 1;
+-------------------+
| vagas_disponiveis |
+-------------------+
|                50 |
+-------------------+
1 row in set (0,00 sec)
 


-- 10 - Triggers: Implementar um TRIGGER que é acionado automaticamente quando uma inscrição é deletada (DELETE), para garantir que as vagas_disponiveis sejam restauradas na tabela Eventos.

mysql> SELECT vagas_disponiveis FROM Eventos WHERE id_evento = 1;

+-------------------+
| vagas_disponiveis |
+-------------------+
|                50 |
+-------------------+
1 row in set (0,00 sec)

Query OK, 0 rows affected (0,00 sec)

mysql> DELETE FROM Inscricoes WHERE id_inscricao = 1;
Query OK, 0 rows affected (0,01 sec)


mysql> SELECT nome_evento, vagas_disponiveis FROM Eventos WHERE id_evento = 1;
+--------------+-------------------+
| nome_evento  | vagas_disponiveis |
+--------------+-------------------+
| Congresso TI |                51 |
+--------------+-------------------+
1 row in set (0,00 sec)


-- 11 - Transações Programáticas: Na STORED PROCEDURE de inscrição, implementar a lógica para verificar a disponibilidade de vagas. Se a vaga for zero, forçar o ROLLBACK da transação e usar o Gerenciamento de Erro para retornar uma mensagem de "Evento Lotado".

-- 12 - Transações (ACID): Encapsular a lógica da inscrição na procedure dentro de uma única Transação com COMMIT ou ROLLBACK explícitos para garantir a atomicidade da operação.