-----------------------------------------------------------------------------------------------------------------------------------------------
-- Módulo Básico e Modelagem (Integridade e CRUD)
-----------------------------------------------------------------------------------------------------------------------------------------------

-- Cria o esquema/banco de dados
-- DROP database SistemaBancario;
CREATE DATABASE IF NOT EXISTS SistemaBancario;
USE SistemaBancario;

-- -----------------------------------------------------------
-- Tabela Log_Auditoria: Estrutura para o registro de alterações
-- É recomendável que a tabela de Log não tenha muitas chaves estrangeiras, 
-- para garantir alta performance nas operações de INSERT (via TRIGER).
-- -----------------------------------------------------------
CREATE TABLE Log_Auditoria (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    nome_tabela VARCHAR(50) NOT NULL,
    id_registro BIGINT, -- ID da linha alterada na tabela de origem
    tipo_operacao ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    dados_antigos JSON,
    dados_novos JSON,
    data_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario VARCHAR(100) -- REMOVIDO: DEFAULT USER()
);

-- Índice para otimizar a busca por ID do registro e data
CREATE INDEX idx_log_registro_data ON Log_Auditoria (id_registro, data_hora);-- ÍNDICE DE ALTO DESEMPENHO: Otimiza a busca por ID do registro e data (para relatórios de auditoria)
-- -----------------------------------------------------------
-- Tabela Clientes
-- -----------------------------------------------------------
CREATE TABLE Clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    data_cadastro DATE DEFAULT (CURRENT_DATE)
);
-- ÍNDICE DE ALTO DESEMPENHO: Otimiza a busca por nome e email (frequentes em consultas)
CREATE INDEX idx_cliente_nome ON Clientes (nome);
CREATE INDEX idx_cliente_email ON Clientes (email);


-- -----------------------------------------------------------
-- Tabela Contas
-- Requisitos: UNIQUE para numero_conta e NOT NULL para saldo.
-- -----------------------------------------------------------
CREATE TABLE Contas (
    id_conta INT AUTO_INCREMENT PRIMARY KEY,
    numero_conta VARCHAR(20) UNIQUE NOT NULL, -- UNIQUE e NOT NULL (requisito)
    id_cliente INT NOT NULL,
    saldo DECIMAL(15, 2) NOT NULL DEFAULT 0.00, -- NOT NULL (requisito)
    data_abertura DATE DEFAULT (CURRENT_DATE),
    
    FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente)
);
-- ÍNDICE DE ALTO DESEMPENHO: Otimiza a busca e ordenação por saldo, e o JOIN com clientes
CREATE INDEX idx_conta_saldo ON Contas (saldo DESC);
CREATE INDEX idx_conta_cliente ON Contas (id_cliente);


-- -----------------------------------------------------------
-- Tabela Transacoes
-- -----------------------------------------------------------
CREATE TABLE Transacoes (
    id_transacao BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_conta_origem INT NOT NULL,
    id_conta_destino INT, -- Pode ser NULL para depósitos ou saques
    tipo ENUM('DEPOSITO', 'SAQUE', 'TRANSFERENCIA') NOT NULL,
    valor DECIMAL(15, 2) NOT NULL,
    data_transacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (id_conta_origem) REFERENCES Contas(id_conta),
    FOREIGN KEY (id_conta_destino) REFERENCES Contas(id_conta)
);
-- ÍNDICE DE ALTO DESEMPENHO: Índice composto para otimizar buscas por conta e período
CREATE INDEX idx_transacao_conta_data ON Transacoes (id_conta_origem, data_transacao DESC);


DELIMITER //

CREATE TRIGGER tr_contas_after_update
AFTER UPDATE ON Contas
FOR EACH ROW
BEGIN
    INSERT INTO Log_Auditoria (
        nome_tabela, 
        id_registro, 
        tipo_operacao, 
        dados_antigos, 
        dados_novos,
        usuario -- ADICIONADO
    )
    VALUES (
        'Contas', 
        NEW.id_conta, 
        'UPDATE', 
        JSON_OBJECT(
            'numero_conta', OLD.numero_conta,
            'saldo', OLD.saldo,
            'id_cliente', OLD.id_cliente
        ),
        JSON_OBJECT(
            'numero_conta', NEW.numero_conta,
            'saldo', NEW.saldo,
            'id_cliente', NEW.id_cliente
        ),
        USER() -- USADO AQUI DENTRO DO INSERT
    );
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE RealizarTransferencia (
    IN p_numero_origem VARCHAR(20),
    IN p_numero_destino VARCHAR(20),
    IN p_valor DECIMAL(15, 2)
)
BEGIN
    DECLARE v_id_origem INT;
    DECLARE v_id_destino INT;
    DECLARE v_saldo_origem DECIMAL(15, 2);
    
    -- Inicia a transação para garantir atomicidade
    START TRANSACTION;

    -- 1. Verifica se as contas existem e pega os IDs
    SELECT id_conta, saldo INTO v_id_origem, v_saldo_origem
    FROM Contas 
    WHERE numero_conta = p_numero_origem
    FOR UPDATE; -- Bloqueia a linha da conta origem para evitar condições de corrida
    
    SELECT id_conta INTO v_id_destino
    FROM Contas 
    WHERE numero_conta = p_numero_destino
    FOR UPDATE; -- Bloqueia a linha da conta destino

    -- Validação: Conta origem ou destino não encontrada
    IF v_id_origem IS NULL OR v_id_destino IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Conta de origem ou destino não encontrada.';
        ROLLBACK;
    
    -- Validação: Saldo insuficiente
    ELSEIF v_saldo_origem < p_valor THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo insuficiente para a transferência.';
        ROLLBACK;
        
    ELSE
        -- 2. Débito na conta origem
        UPDATE Contas SET saldo = saldo - p_valor WHERE id_conta = v_id_origem;
        
        -- 3. Crédito na conta destino
        UPDATE Contas SET saldo = saldo + p_valor WHERE id_conta = v_id_destino;
        
        -- 4. Registro da transação
        INSERT INTO Transacoes (id_conta_origem, id_conta_destino, tipo, valor)
        VALUES (v_id_origem, v_id_destino, 'TRANSFERENCIA', p_valor);
        
        -- 5. Confirma a transação
        COMMIT;
    END IF;
    
END //

DELIMITER ;

-- Para simular as transações (DML de INSERT)
-- 1. Inserir Clientes
INSERT INTO Clientes (nome, cpf, email) VALUES
('Alice Silva', '111.111.111-11', 'alice@exemplo.com'),
('Bruno Costa', '222.222.222-22', 'bruno@exemplo.com'),
('Carla Souza', '333.333.333-33', 'carla@exemplo.com'),
('Daniel Lins', '444.444.444-44', 'daniel@exemplo.com');

-- 2. Inserir Contas
-- Saldo inicial para simular transações
INSERT INTO Contas (numero_conta, id_cliente, saldo) VALUES
('1000-1', 1, 15000.00), -- Alice
('2000-2', 2, 8000.00),  -- Bruno
('3000-3', 3, 500.00),   -- Carla
('4000-4', 4, 2500.00);  -- Daniel

-- ----------------------------------------------------------------------------------------
-- 500 transações de forma eficiente, simulando saques, depósitos e transferências entre 
-- as quatro contas criadas.
-- ----------------------------------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE SimularTransacoes(IN num_transacoes INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE origem_id INT;
    DECLARE destino_id INT;
    DECLARE tipo_operacao ENUM('DEPOSITO', 'SAQUE', 'TRANSFERENCIA');
    DECLARE valor_transacao DECIMAL(15, 2);
    
    -- IDs das contas existentes para referência aleatória
    DECLARE conta_ids CURSOR FOR SELECT id_conta FROM Contas;
    
    OPEN conta_ids;
    
    WHILE i < num_transacoes DO
        -- Seleciona IDs de contas aleatoriamente entre 1 e 4 (os IDs inseridos)
        SET origem_id = FLOOR(1 + (RAND() * 4)); 
        SET destino_id = FLOOR(1 + (RAND() * 4));
        
        -- Garante que destino e origem são diferentes para transferências
        IF origem_id = destino_id THEN
            SET destino_id = IF(origem_id = 4, 1, origem_id + 1);
        END IF;

        -- Define o tipo de operação aleatoriamente
        SET tipo_operacao = ELT(FLOOR(1 + (RAND() * 3)), 'DEPOSITO', 'SAQUE', 'TRANSFERENCIA');
        
        -- Define um valor de transação entre 10 e 1000
        SET valor_transacao = ROUND(10 + (RAND() * 990), 2);
        
        -- Simulação do INSERT na tabela Transacoes
        IF tipo_operacao = 'TRANSFERENCIA' THEN
            -- Inserir o registro de transferência
            INSERT INTO Transacoes (id_conta_origem, id_conta_destino, tipo, valor)
            VALUES (origem_id, destino_id, tipo_operacao, valor_transacao);
            
            -- ATUALIZA SALDOS (Simulação básica - ignorando saldo negativo para este loop DML)
            UPDATE Contas SET saldo = saldo - valor_transacao WHERE id_conta = origem_id;
            UPDATE Contas SET saldo = saldo + valor_transacao WHERE id_conta = destino_id;
            
        ELSEIF tipo_operacao = 'DEPOSITO' THEN
            -- Inserir o registro de depósito (id_conta_destino é NULL)
            INSERT INTO Transacoes (id_conta_origem, tipo, valor)
            VALUES (origem_id, tipo_operacao, valor_transacao);

            -- ATUALIZA SALDO
            UPDATE Contas SET saldo = saldo + valor_transacao WHERE id_conta = origem_id;
            
        ELSE -- SAQUE
             -- Inserir o registro de saque (id_conta_destino é NULL)
            INSERT INTO Transacoes (id_conta_origem, tipo, valor)
            VALUES (origem_id, tipo_operacao, valor_transacao);

            -- ATUALIZA SALDO
            UPDATE Contas SET saldo = saldo - valor_transacao WHERE id_conta = origem_id;
            
        END IF;

        SET i = i + 1;
    END WHILE;
    
    CLOSE conta_ids;
END //

DELIMITER ;

-- Executa o procedimento para inserir 500 transações
-- A cada execução soma-se mais 500 transações para esta
-- PROCEDURE
CALL SimularTransacoes(500);

-- Verifica a volumetria
-- A cada execução soma-se mais 500 transações, Para 3 execuções
SELECT COUNT(*) AS TotalTransacoes FROM Transacoes;
+-----------------+
| TotalTransacoes |
+-----------------+
|            1500 |
+-----------------+
1 row in set (0,01 sec)

-----------------------------------------------------------------------------------------------------------------------------------------------
-- Módulo Intermediário (Análise e Estrutura)
-----------------------------------------------------------------------------------------------------------------------------------------------

-- 2. Praticar UPDATE (Modificar Status de uma Conta)
-- Para praticar o UPDATE, vamos simular a inclusão de uma nova coluna de status na tabela 
-- 2.1. Adicionar Coluna de Status (DDL Adicional)
-- Adiciona uma coluna 'status_conta' à tabela Contas
ALTER TABLE Contas
ADD COLUMN status_conta ENUM('ATIVA', 'BLOQUEADA', 'ENCERRADA') NOT NULL DEFAULT 'ATIVA';

-- 2.2. Executar o UPDATE
-- Vamos modificar a conta de ID 3 (Carla Souza) para o status 'BLOQUEADA'.

UPDATE Contas
SET status_conta = 'BLOQUEADA'
WHERE id_conta = 3;

-- Verifica o Log de Auditoria (o Trigger deve ter registrado esta alteração!)
SELECT 
    id_log, 
    tipo_operacao, 
    JSON_UNQUOTE(JSON_EXTRACT(dados_antigos, '$.saldo')) AS SaldoAnterior, 
    JSON_UNQUOTE(JSON_EXTRACT(dados_novos, '$.saldo')) AS SaldoNovo
FROM Log_Auditoria 
WHERE nome_tabela = 'Contas' AND id_registro = 3 
ORDER BY data_hora DESC LIMIT 1;

+--------+---------------+---------------+-----------+
| id_log | tipo_operacao | SaldoAnterior | SaldoNovo |
+--------+---------------+---------------+-----------+
|   1997 | UPDATE        | 13802.07      | 13802.07  |
+--------+---------------+---------------+-----------+
1 row in set (0,00 sec)

-- continuação 2
-- DELETE de um registro de transação (com restrições).

-- Encontrando o ID da transação a ser deletada (Ex: o primeiro registro inserido)
mysql> SET @id_deletar = (SELECT MIN(id_transacao) FROM Transacoes);
Query OK, 0 rows affected (0,01 sec)

-- Executa o DELETE
mysql> DELETE FROM Transacoes
    -> WHERE id_transacao = @id_deletar;
Query OK, 1 row affected (0,01 sec)

-- Confirmação
mysql> SELECT CONCAT('Transação ', @id_deletar, ' foi removida.') AS Status;
+-----------------------------+
| Status                      |
+-----------------------------+
| Transação 1 foi removida.   |
+-----------------------------+
1 row in set (0,00 sec)

-- 3. Consultas Básicas: Filtrar transações entre dois valores (BETWEEN) e transações de um tipo específico 
-- (WHERE) usando ORDER BY E LIMIT para listar as transações mais recentes.
--  Exemplo: Listar transações com valor entre R$ 500,00 e R$ 800,00.

mysql> SELECT
        t.id_transacao,
        c_origem.numero_conta AS ContaOrigem,
        t.tipo,
        t.valor,
        t.data_transacao
    FROM
        Transacoes t
    JOIN
        Contas c_origem ON t.id_conta_origem = c_origem.id_conta
    WHERE
        t.valor BETWEEN 500.00 AND 800.00
    ORDER BY
        t.valor DESC;

+--------------+-------------+---------------+--------+---------------------+
| id_transacao | ContaOrigem | tipo          | valor  | data_transacao      |
+--------------+-------------+---------------+--------+---------------------+
|         1120 | 3000-3      | DEPOSITO      | 799.96 | 2025-12-06 13:13:25 |
|          457 | 1000-1      | DEPOSITO      | 799.73 | 2025-12-06 13:12:50 |
|         1094 | 4000-4      | TRANSFERENCIA | 799.42 | 2025-12-06 13:13:25 |
|          865 | 3000-3      | TRANSFERENCIA | 799.39 | 2025-12-06 13:12:59 |
|          276 | 1000-1      | SAQUE         | 799.32 | 2025-12-06 13:12:48 |
|         1035 | 2000-2      | TRANSFERENCIA | 797.95 | 2025-12-06 13:13:24 |
|          574 | 4000-4      | TRANSFERENCIA | 797.41 | 2025-12-06 13:12:56 |
|         1442 | 3000-3      | SAQUE         | 797.29 | 2025-12-06 13:13:29 |
|          621 | 2000-2      | TRANSFERENCIA | 797.28 | 2025-12-06 13:12:56 |
|         1329 | 1000-1      | DEPOSITO      | 797.22 | 2025-12-06 13:13:27 |
|          532 | 3000-3      | SAQUE         | 796.10 | 2025-12-06 13:12:55 |
|          710 | 3000-3      | DEPOSITO      | 796.10 | 2025-12-06 13:12:57 |
|          550 | 1000-1      | DEPOSITO      | 795.41 | 2025-12-06 13:12:55 |
|          875 | 3000-3      | SAQUE         | 795.31 | 2025-12-06 13:12:59 |
|          963 | 2000-2      | SAQUE         | 794.46 | 2025-12-06 13:13:00 |
|         1432 | 1000-1      | SAQUE         | 793.99 | 2025-12-06 13:13:29 |
|          156 | 3000-3      | TRANSFERENCIA | 792.68 | 2025-12-06 13:12:47 |
|          188 | 2000-2      | SAQUE         | 792.26 | 2025-12-06 13:12:47 |
|         1352 | 2000-2      | SAQUE         | 791.50 | 2025-12-06 13:13:28 |
|          415 | 4000-4      | SAQUE         | 789.89 | 2025-12-06 13:12:49 |
|         1437 | 2000-2      | TRANSFERENCIA | 789.81 | 2025-12-06 13:13:29 |
|         1259 | 4000-4      | DEPOSITO      | 789.33 | 2025-12-06 13:13:27 |
|          477 | 2000-2      | SAQUE         | 788.18 | 2025-12-06 13:12:50 |
|         1216 | 2000-2      | SAQUE         | 787.95 | 2025-12-06 13:13:26 |
|         1029 | 1000-1      | SAQUE         | 786.65 | 2025-12-06 13:13:24 |
|         1365 | 3000-3      | TRANSFERENCIA | 785.98 | 2025-12-06 13:13:28 |
|         1161 | 4000-4      | DEPOSITO      | 785.34 | 2025-12-06 13:13:26 |
|          933 | 1000-1      | TRANSFERENCIA | 785.22 | 2025-12-06 13:12:59 |
|          261 | 2000-2      | TRANSFERENCIA | 784.32 | 2025-12-06 13:12:48 |
|          944 | 2000-2      | TRANSFERENCIA | 784.22 | 2025-12-06 13:13:00 |
|          723 | 3000-3      | SAQUE         | 784.02 | 2025-12-06 13:12:57 |
|          253 | 1000-1      | TRANSFERENCIA | 783.55 | 2025-12-06 13:12:48 |
|         1378 | 4000-4      | SAQUE         | 783.41 | 2025-12-06 13:13:28 |
|          351 | 4000-4      | TRANSFERENCIA | 783.32 | 2025-12-06 13:12:49 |
|         1424 | 3000-3      | SAQUE         | 783.29 | 2025-12-06 13:13:28 |
|          601 | 1000-1      | SAQUE         | 782.80 | 2025-12-06 13:12:56 |
|          130 | 1000-1      | DEPOSITO      | 781.30 | 2025-12-06 13:12:46 |
|          450 | 1000-1      | TRANSFERENCIA | 781.20 | 2025-12-06 13:12:50 |
|          106 | 2000-2      | TRANSFERENCIA | 780.25 | 2025-12-06 13:12:46 |
|          726 | 3000-3      | TRANSFERENCIA | 779.22 | 2025-12-06 13:12:57 |
|           57 | 3000-3      | DEPOSITO      | 778.87 | 2025-12-06 13:12:46 |
|          255 | 1000-1      | SAQUE         | 778.81 | 2025-12-06 13:12:48 |
|          893 | 1000-1      | SAQUE         | 778.19 | 2025-12-06 13:12:59 |
|          122 | 2000-2      | TRANSFERENCIA | 776.17 | 2025-12-06 13:12:46 |
|         1013 | 2000-2      | DEPOSITO      | 775.31 | 2025-12-06 13:13:24 |
|          815 | 1000-1      | TRANSFERENCIA | 774.46 | 2025-12-06 13:12:58 |
|          484 | 3000-3      | SAQUE         | 773.71 | 2025-12-06 13:12:50 |
|          510 | 3000-3      | DEPOSITO      | 771.96 | 2025-12-06 13:12:55 |
|          526 | 1000-1      | SAQUE         | 771.69 | 2025-12-06 13:12:55 |
|          429 | 2000-2      | TRANSFERENCIA | 771.38 | 2025-12-06 13:12:50 |
|          401 | 3000-3      | TRANSFERENCIA | 770.60 | 2025-12-06 13:12:49 |
|          222 | 4000-4      | SAQUE         | 768.79 | 2025-12-06 13:12:47 |
|         1057 | 4000-4      | TRANSFERENCIA | 768.70 | 2025-12-06 13:13:24 |
|         1040 | 4000-4      | DEPOSITO      | 768.61 | 2025-12-06 13:13:24 |
|          137 | 3000-3      | DEPOSITO      | 767.03 | 2025-12-06 13:12:46 |
|          628 | 2000-2      | DEPOSITO      | 766.26 | 2025-12-06 13:12:56 |
|         1109 | 4000-4      | DEPOSITO      | 765.11 | 2025-12-06 13:13:25 |
|          368 | 4000-4      | SAQUE         | 764.32 | 2025-12-06 13:12:49 |
|         1053 | 3000-3      | SAQUE         | 764.31 | 2025-12-06 13:13:24 |
|         1135 | 3000-3      | DEPOSITO      | 764.26 | 2025-12-06 13:13:25 |
|         1356 | 4000-4      | SAQUE         | 763.70 | 2025-12-06 13:13:28 |
|         1357 | 1000-1      | TRANSFERENCIA | 763.61 | 2025-12-06 13:13:28 |
|          848 | 2000-2      | DEPOSITO      | 761.33 | 2025-12-06 13:12:58 |
|          692 | 1000-1      | TRANSFERENCIA | 761.25 | 2025-12-06 13:12:57 |
|         1108 | 3000-3      | DEPOSITO      | 761.25 | 2025-12-06 13:13:25 |
|          458 | 2000-2      | SAQUE         | 760.34 | 2025-12-06 13:12:50 |
|         1058 | 4000-4      | SAQUE         | 759.86 | 2025-12-06 13:13:24 |
|         1471 | 1000-1      | SAQUE         | 757.20 | 2025-12-06 13:13:29 |
|          358 | 1000-1      | TRANSFERENCIA | 756.98 | 2025-12-06 13:12:49 |
|          961 | 3000-3      | DEPOSITO      | 756.57 | 2025-12-06 13:13:00 |
|          533 | 4000-4      | TRANSFERENCIA | 755.33 | 2025-12-06 13:12:55 |
|          724 | 4000-4      | DEPOSITO      | 755.09 | 2025-12-06 13:12:57 |
|         1004 | 4000-4      | TRANSFERENCIA | 754.69 | 2025-12-06 13:13:24 |
|         1232 | 3000-3      | SAQUE         | 753.02 | 2025-12-06 13:13:26 |
|          547 | 4000-4      | DEPOSITO      | 752.44 | 2025-12-06 13:12:55 |
|         1277 | 4000-4      | SAQUE         | 751.63 | 2025-12-06 13:13:27 |
|          475 | 4000-4      | SAQUE         | 751.07 | 2025-12-06 13:12:50 |
|         1162 | 1000-1      | TRANSFERENCIA | 751.04 | 2025-12-06 13:13:26 |
|          160 | 4000-4      | DEPOSITO      | 750.89 | 2025-12-06 13:12:47 |
|          197 | 4000-4      | TRANSFERENCIA | 750.52 | 2025-12-06 13:12:47 |
|           72 | 2000-2      | TRANSFERENCIA | 750.39 | 2025-12-06 13:12:46 |
|          971 | 3000-3      | SAQUE         | 750.12 | 2025-12-06 13:13:00 |
|          307 | 3000-3      | SAQUE         | 749.90 | 2025-12-06 13:12:48 |
|         1143 | 4000-4      | DEPOSITO      | 749.39 | 2025-12-06 13:13:25 |
|         1325 | 4000-4      | DEPOSITO      | 749.36 | 2025-12-06 13:13:27 |
|          299 | 4000-4      | SAQUE         | 748.15 | 2025-12-06 13:12:48 |
|          535 | 1000-1      | TRANSFERENCIA | 747.53 | 2025-12-06 13:12:55 |
|          787 | 1000-1      | DEPOSITO      | 747.07 | 2025-12-06 13:12:58 |
|          948 | 2000-2      | SAQUE         | 746.37 | 2025-12-06 13:13:00 |
|          170 | 1000-1      | TRANSFERENCIA | 746.26 | 2025-12-06 13:12:47 |
|          554 | 4000-4      | DEPOSITO      | 745.54 | 2025-12-06 13:12:55 |
|          433 | 2000-2      | TRANSFERENCIA | 743.90 | 2025-12-06 13:12:50 |
|          891 | 1000-1      | TRANSFERENCIA | 743.83 | 2025-12-06 13:12:59 |
|         1285 | 2000-2      | DEPOSITO      | 741.41 | 2025-12-06 13:13:27 |
|         1278 | 2000-2      | DEPOSITO      | 741.01 | 2025-12-06 13:13:27 |
|           76 | 4000-4      | SAQUE         | 740.88 | 2025-12-06 13:12:46 |
|         1027 | 1000-1      | TRANSFERENCIA | 739.96 | 2025-12-06 13:13:24 |
|          419 | 3000-3      | SAQUE         | 739.88 | 2025-12-06 13:12:50 |
|         1345 | 1000-1      | TRANSFERENCIA | 739.83 | 2025-12-06 13:13:28 |
|           45 | 3000-3      | DEPOSITO      | 739.49 | 2025-12-06 13:12:45 |
|           71 | 1000-1      | DEPOSITO      | 737.95 | 2025-12-06 13:12:46 |
|         1244 | 3000-3      | DEPOSITO      | 737.93 | 2025-12-06 13:13:26 |
|          686 | 3000-3      | TRANSFERENCIA | 737.78 | 2025-12-06 13:12:57 |
|         1313 | 3000-3      | TRANSFERENCIA | 736.31 | 2025-12-06 13:13:27 |
|          317 | 4000-4      | TRANSFERENCIA | 735.95 | 2025-12-06 13:12:48 |
|         1304 | 2000-2      | TRANSFERENCIA | 735.60 | 2025-12-06 13:13:27 |
|          462 | 1000-1      | DEPOSITO      | 735.32 | 2025-12-06 13:12:50 |
|           47 | 4000-4      | TRANSFERENCIA | 733.40 | 2025-12-06 13:12:45 |
|          395 | 2000-2      | DEPOSITO      | 732.32 | 2025-12-06 13:12:49 |
|          758 | 3000-3      | SAQUE         | 732.18 | 2025-12-06 13:12:58 |
|          911 | 3000-3      | TRANSFERENCIA | 732.02 | 2025-12-06 13:12:59 |
|          514 | 4000-4      | SAQUE         | 731.79 | 2025-12-06 13:12:55 |
|          790 | 1000-1      | DEPOSITO      | 731.71 | 2025-12-06 13:12:58 |
|          934 | 1000-1      | DEPOSITO      | 731.36 | 2025-12-06 13:12:59 |
|          340 | 1000-1      | TRANSFERENCIA | 731.33 | 2025-12-06 13:12:49 |
|          246 | 2000-2      | TRANSFERENCIA | 730.69 | 2025-12-06 13:12:48 |
|         1467 | 1000-1      | SAQUE         | 729.93 | 2025-12-06 13:13:29 |
|          466 | 3000-3      | DEPOSITO      | 729.78 | 2025-12-06 13:12:50 |
|          266 | 2000-2      | TRANSFERENCIA | 729.30 | 2025-12-06 13:12:48 |
|          338 | 3000-3      | TRANSFERENCIA | 728.73 | 2025-12-06 13:12:49 |
|         1059 | 3000-3      | SAQUE         | 727.93 | 2025-12-06 13:13:24 |
|          176 | 1000-1      | TRANSFERENCIA | 727.69 | 2025-12-06 13:12:47 |
|         1450 | 2000-2      | DEPOSITO      | 727.10 | 2025-12-06 13:13:29 |
|          303 | 1000-1      | SAQUE         | 727.08 | 2025-12-06 13:12:48 |
|         1090 | 3000-3      | TRANSFERENCIA | 727.00 | 2025-12-06 13:13:25 |
|          142 | 4000-4      | SAQUE         | 726.58 | 2025-12-06 13:12:46 |
|          885 | 2000-2      | TRANSFERENCIA | 725.04 | 2025-12-06 13:12:59 |
|         1349 | 4000-4      | DEPOSITO      | 724.58 | 2025-12-06 13:13:28 |
|          204 | 2000-2      | DEPOSITO      | 724.39 | 2025-12-06 13:12:47 |
|          113 | 3000-3      | DEPOSITO      | 724.23 | 2025-12-06 13:12:46 |
|         1129 | 3000-3      | SAQUE         | 724.22 | 2025-12-06 13:13:25 |
|          775 | 1000-1      | SAQUE         | 723.48 | 2025-12-06 13:12:58 |
|          360 | 3000-3      | TRANSFERENCIA | 720.87 | 2025-12-06 13:12:49 |
|          702 | 2000-2      | DEPOSITO      | 720.66 | 2025-12-06 13:12:57 |
|         1149 | 1000-1      | SAQUE         | 719.09 | 2025-12-06 13:13:25 |
|          446 | 4000-4      | SAQUE         | 719.07 | 2025-12-06 13:12:50 |
|          921 | 2000-2      | DEPOSITO      | 718.81 | 2025-12-06 13:12:59 |
|          898 | 1000-1      | SAQUE         | 717.67 | 2025-12-06 13:12:59 |
|          613 | 3000-3      | TRANSFERENCIA | 717.64 | 2025-12-06 13:12:56 |
|         1003 | 4000-4      | TRANSFERENCIA | 715.59 | 2025-12-06 13:13:24 |
|            4 | 2000-2      | TRANSFERENCIA | 714.50 | 2025-12-06 13:12:45 |
|         1039 | 1000-1      | TRANSFERENCIA | 712.42 | 2025-12-06 13:13:24 |
|          997 | 3000-3      | DEPOSITO      | 711.95 | 2025-12-06 13:13:00 |
|         1380 | 2000-2      | DEPOSITO      | 709.07 | 2025-12-06 13:13:28 |
|          631 | 4000-4      | SAQUE         | 707.12 | 2025-12-06 13:12:56 |
|          991 | 1000-1      | DEPOSITO      | 706.89 | 2025-12-06 13:13:00 |
|          995 | 4000-4      | TRANSFERENCIA | 706.58 | 2025-12-06 13:13:00 |
|          439 | 1000-1      | DEPOSITO      | 706.12 | 2025-12-06 13:12:50 |
|         1086 | 3000-3      | SAQUE         | 706.12 | 2025-12-06 13:13:25 |
|          435 | 4000-4      | SAQUE         | 706.01 | 2025-12-06 13:12:50 |
|          887 | 4000-4      | DEPOSITO      | 705.17 | 2025-12-06 13:12:59 |
|         1421 | 1000-1      | DEPOSITO      | 705.13 | 2025-12-06 13:13:28 |
|          258 | 4000-4      | SAQUE         | 704.55 | 2025-12-06 13:12:48 |
|          147 | 4000-4      | TRANSFERENCIA | 704.27 | 2025-12-06 13:12:47 |
|          638 | 1000-1      | DEPOSITO      | 703.21 | 2025-12-06 13:12:56 |
|          159 | 4000-4      | DEPOSITO      | 703.18 | 2025-12-06 13:12:47 |
|          958 | 2000-2      | TRANSFERENCIA | 702.81 | 2025-12-06 13:13:00 |
|          402 | 4000-4      | SAQUE         | 702.09 | 2025-12-06 13:12:49 |
|          842 | 4000-4      | TRANSFERENCIA | 701.42 | 2025-12-06 13:12:58 |
|          418 | 2000-2      | SAQUE         | 701.25 | 2025-12-06 13:12:50 |
|          424 | 4000-4      | TRANSFERENCIA | 700.72 | 2025-12-06 13:12:50 |
|          870 | 4000-4      | SAQUE         | 700.56 | 2025-12-06 13:12:59 |
|           11 | 4000-4      | TRANSFERENCIA | 700.50 | 2025-12-06 13:12:45 |
|         1117 | 2000-2      | SAQUE         | 700.50 | 2025-12-06 13:13:25 |
|          291 | 4000-4      | SAQUE         | 700.00 | 2025-12-06 13:12:48 |
|          387 | 4000-4      | SAQUE         | 699.99 | 2025-12-06 13:12:49 |
|          667 | 1000-1      | DEPOSITO      | 698.55 | 2025-12-06 13:12:57 |
|          813 | 1000-1      | DEPOSITO      | 698.55 | 2025-12-06 13:12:58 |
|         1049 | 2000-2      | TRANSFERENCIA | 698.12 | 2025-12-06 13:13:24 |
|          917 | 2000-2      | TRANSFERENCIA | 697.40 | 2025-12-06 13:12:59 |
|          823 | 1000-1      | DEPOSITO      | 697.27 | 2025-12-06 13:12:58 |
|         1088 | 1000-1      | DEPOSITO      | 696.76 | 2025-12-06 13:13:25 |
|          332 | 4000-4      | DEPOSITO      | 695.27 | 2025-12-06 13:12:48 |
|          907 | 2000-2      | DEPOSITO      | 694.81 | 2025-12-06 13:12:59 |
|          251 | 1000-1      | SAQUE         | 694.11 | 2025-12-06 13:12:48 |
|          918 | 2000-2      | DEPOSITO      | 693.53 | 2025-12-06 13:12:59 |
|         1174 | 1000-1      | DEPOSITO      | 692.44 | 2025-12-06 13:13:26 |
|           32 | 4000-4      | TRANSFERENCIA | 692.25 | 2025-12-06 13:12:45 |
|         1364 | 3000-3      | DEPOSITO      | 689.94 | 2025-12-06 13:13:28 |
|         1016 | 4000-4      | DEPOSITO      | 689.69 | 2025-12-06 13:13:24 |
|          349 | 1000-1      | DEPOSITO      | 687.97 | 2025-12-06 13:12:49 |
|         1080 | 1000-1      | TRANSFERENCIA | 685.73 | 2025-12-06 13:13:25 |
|          910 | 4000-4      | TRANSFERENCIA | 685.69 | 2025-12-06 13:12:59 |
|         1326 | 4000-4      | TRANSFERENCIA | 684.96 | 2025-12-06 13:13:27 |
|          483 | 4000-4      | SAQUE         | 683.97 | 2025-12-06 13:12:50 |
|          636 | 4000-4      | SAQUE         | 683.12 | 2025-12-06 13:12:56 |
|         1140 | 2000-2      | TRANSFERENCIA | 682.98 | 2025-12-06 13:13:25 |
|         1350 | 2000-2      | SAQUE         | 682.87 | 2025-12-06 13:13:28 |
|           12 | 2000-2      | SAQUE         | 682.25 | 2025-12-06 13:12:45 |
|          668 | 1000-1      | TRANSFERENCIA | 682.21 | 2025-12-06 13:12:57 |
|          345 | 1000-1      | SAQUE         | 682.07 | 2025-12-06 13:12:49 |
|          536 | 4000-4      | SAQUE         | 680.82 | 2025-12-06 13:12:55 |
|         1138 | 4000-4      | SAQUE         | 679.23 | 2025-12-06 13:13:25 |
|          599 | 2000-2      | DEPOSITO      | 678.97 | 2025-12-06 13:12:56 |
|          271 | 4000-4      | DEPOSITO      | 678.82 | 2025-12-06 13:12:48 |
|         1404 | 1000-1      | DEPOSITO      | 678.60 | 2025-12-06 13:13:28 |
|          998 | 3000-3      | SAQUE         | 677.91 | 2025-12-06 13:13:00 |
|           62 | 3000-3      | TRANSFERENCIA | 677.19 | 2025-12-06 13:12:46 |
|         1435 | 4000-4      | TRANSFERENCIA | 676.33 | 2025-12-06 13:13:29 |
|          416 | 1000-1      | TRANSFERENCIA | 676.21 | 2025-12-06 13:12:49 |
|          562 | 3000-3      | SAQUE         | 676.11 | 2025-12-06 13:12:55 |
|           31 | 4000-4      | DEPOSITO      | 675.83 | 2025-12-06 13:12:45 |
|         1124 | 3000-3      | SAQUE         | 675.64 | 2025-12-06 13:13:25 |
|          708 | 3000-3      | SAQUE         | 675.56 | 2025-12-06 13:12:57 |
|         1394 | 2000-2      | TRANSFERENCIA | 674.52 | 2025-12-06 13:13:28 |
|         1273 | 2000-2      | TRANSFERENCIA | 674.37 | 2025-12-06 13:13:27 |
|          649 | 4000-4      | TRANSFERENCIA | 673.95 | 2025-12-06 13:12:56 |
|          145 | 3000-3      | TRANSFERENCIA | 673.65 | 2025-12-06 13:12:47 |
|         1469 | 1000-1      | DEPOSITO      | 672.47 | 2025-12-06 13:13:29 |
|          737 | 2000-2      | DEPOSITO      | 672.10 | 2025-12-06 13:12:57 |
|          205 | 1000-1      | DEPOSITO      | 671.98 | 2025-12-06 13:12:47 |
|         1133 | 2000-2      | SAQUE         | 671.82 | 2025-12-06 13:13:25 |
|         1433 | 1000-1      | SAQUE         | 671.01 | 2025-12-06 13:13:29 |
|          546 | 1000-1      | TRANSFERENCIA | 669.80 | 2025-12-06 13:12:55 |
|          576 | 3000-3      | DEPOSITO      | 668.64 | 2025-12-06 13:12:56 |
|         1083 | 3000-3      | DEPOSITO      | 668.05 | 2025-12-06 13:13:25 |
|          632 | 1000-1      | TRANSFERENCIA | 667.60 | 2025-12-06 13:12:56 |
|         1230 | 2000-2      | TRANSFERENCIA | 667.28 | 2025-12-06 13:13:26 |
|          131 | 4000-4      | DEPOSITO      | 667.18 | 2025-12-06 13:12:46 |
|         1362 | 4000-4      | SAQUE         | 666.91 | 2025-12-06 13:13:28 |
|         1428 | 1000-1      | SAQUE         | 666.03 | 2025-12-06 13:13:28 |
|          886 | 2000-2      | TRANSFERENCIA | 665.78 | 2025-12-06 13:12:59 |
|          375 | 2000-2      | TRANSFERENCIA | 665.41 | 2025-12-06 13:12:49 |
|         1480 | 3000-3      | TRANSFERENCIA | 665.09 | 2025-12-06 13:13:29 |
|          611 | 2000-2      | SAQUE         | 664.84 | 2025-12-06 13:12:56 |
|         1351 | 4000-4      | SAQUE         | 664.74 | 2025-12-06 13:13:28 |
|          984 | 4000-4      | DEPOSITO      | 663.35 | 2025-12-06 13:13:00 |
|          676 | 4000-4      | TRANSFERENCIA | 662.85 | 2025-12-06 13:12:57 |
|         1206 | 1000-1      | DEPOSITO      | 662.43 | 2025-12-06 13:13:26 |
|          229 | 2000-2      | DEPOSITO      | 661.96 | 2025-12-06 13:12:47 |
|         1303 | 2000-2      | DEPOSITO      | 659.83 | 2025-12-06 13:13:27 |
|         1214 | 3000-3      | DEPOSITO      | 659.59 | 2025-12-06 13:13:26 |
|         1215 | 2000-2      | TRANSFERENCIA | 659.23 | 2025-12-06 13:13:26 |
|         1183 | 2000-2      | TRANSFERENCIA | 659.19 | 2025-12-06 13:13:26 |
|          523 | 2000-2      | DEPOSITO      | 659.04 | 2025-12-06 13:12:55 |
|          260 | 1000-1      | DEPOSITO      | 658.69 | 2025-12-06 13:12:48 |
|         1172 | 2000-2      | DEPOSITO      | 658.61 | 2025-12-06 13:13:26 |
|          614 | 3000-3      | DEPOSITO      | 656.51 | 2025-12-06 13:12:56 |
|         1486 | 2000-2      | TRANSFERENCIA | 655.36 | 2025-12-06 13:13:29 |
|         1328 | 1000-1      | TRANSFERENCIA | 653.10 | 2025-12-06 13:13:27 |
|          190 | 1000-1      | SAQUE         | 651.48 | 2025-12-06 13:12:47 |
|          306 | 4000-4      | TRANSFERENCIA | 647.02 | 2025-12-06 13:12:48 |
|           34 | 1000-1      | SAQUE         | 646.02 | 2025-12-06 13:12:45 |
|         1048 | 2000-2      | SAQUE         | 645.88 | 2025-12-06 13:13:24 |
|          324 | 2000-2      | SAQUE         | 645.72 | 2025-12-06 13:12:48 |
|          511 | 3000-3      | DEPOSITO      | 644.83 | 2025-12-06 13:12:55 |
|          804 | 4000-4      | DEPOSITO      | 644.20 | 2025-12-06 13:12:58 |
|          108 | 4000-4      | TRANSFERENCIA | 643.36 | 2025-12-06 13:12:46 |
|         1411 | 1000-1      | TRANSFERENCIA | 643.29 | 2025-12-06 13:13:28 |
|         1299 | 1000-1      | TRANSFERENCIA | 642.62 | 2025-12-06 13:13:27 |
|          981 | 4000-4      | TRANSFERENCIA | 642.52 | 2025-12-06 13:13:00 |
|          748 | 4000-4      | TRANSFERENCIA | 642.51 | 2025-12-06 13:12:57 |
|         1187 | 3000-3      | SAQUE         | 642.07 | 2025-12-06 13:13:26 |
|          821 | 4000-4      | SAQUE         | 637.84 | 2025-12-06 13:12:58 |
|          103 | 1000-1      | DEPOSITO      | 637.75 | 2025-12-06 13:12:46 |
|          373 | 4000-4      | SAQUE         | 636.88 | 2025-12-06 13:12:49 |
|         1111 | 1000-1      | TRANSFERENCIA | 636.19 | 2025-12-06 13:13:25 |
|         1314 | 3000-3      | TRANSFERENCIA | 635.92 | 2025-12-06 13:13:27 |
|          356 | 2000-2      | DEPOSITO      | 635.73 | 2025-12-06 13:12:49 |
|          695 | 1000-1      | SAQUE         | 634.91 | 2025-12-06 13:12:57 |
|         1238 | 1000-1      | SAQUE         | 633.78 | 2025-12-06 13:13:26 |
|         1131 | 3000-3      | SAQUE         | 632.61 | 2025-12-06 13:13:25 |
|          107 | 1000-1      | SAQUE         | 632.46 | 2025-12-06 13:12:46 |
|           75 | 4000-4      | DEPOSITO      | 632.26 | 2025-12-06 13:12:46 |
|          217 | 2000-2      | TRANSFERENCIA | 632.18 | 2025-12-06 13:12:47 |
|           89 | 2000-2      | SAQUE         | 632.00 | 2025-12-06 13:12:46 |
|          112 | 1000-1      | TRANSFERENCIA | 628.69 | 2025-12-06 13:12:46 |
|         1399 | 1000-1      | TRANSFERENCIA | 627.90 | 2025-12-06 13:13:28 |
|         1043 | 2000-2      | SAQUE         | 627.39 | 2025-12-06 13:13:24 |
|         1334 | 4000-4      | TRANSFERENCIA | 627.23 | 2025-12-06 13:13:27 |
|          624 | 3000-3      | TRANSFERENCIA | 627.16 | 2025-12-06 13:12:56 |
|          592 | 1000-1      | DEPOSITO      | 626.43 | 2025-12-06 13:12:56 |
|         1261 | 2000-2      | DEPOSITO      | 625.24 | 2025-12-06 13:13:27 |
|         1106 | 1000-1      | DEPOSITO      | 624.06 | 2025-12-06 13:13:25 |
|          652 | 2000-2      | TRANSFERENCIA | 623.03 | 2025-12-06 13:12:56 |
|         1332 | 4000-4      | SAQUE         | 622.84 | 2025-12-06 13:13:27 |
|          361 | 1000-1      | TRANSFERENCIA | 622.75 | 2025-12-06 13:12:49 |
|         1425 | 2000-2      | SAQUE         | 622.39 | 2025-12-06 13:13:28 |
|         1465 | 1000-1      | TRANSFERENCIA | 622.15 | 2025-12-06 13:13:29 |
|         1137 | 2000-2      | SAQUE         | 621.74 | 2025-12-06 13:13:25 |
|         1265 | 2000-2      | SAQUE         | 621.10 | 2025-12-06 13:13:27 |
|           79 | 2000-2      | DEPOSITO      | 619.70 | 2025-12-06 13:12:46 |
|          993 | 1000-1      | SAQUE         | 619.45 | 2025-12-06 13:13:00 |
|          413 | 2000-2      | TRANSFERENCIA | 618.76 | 2025-12-06 13:12:49 |
|         1473 | 3000-3      | DEPOSITO      | 618.65 | 2025-12-06 13:13:29 |
|          494 | 2000-2      | DEPOSITO      | 618.55 | 2025-12-06 13:12:50 |
|         1340 | 2000-2      | DEPOSITO      | 618.17 | 2025-12-06 13:13:28 |
|          296 | 2000-2      | DEPOSITO      | 617.61 | 2025-12-06 13:12:48 |
|          899 | 2000-2      | SAQUE         | 617.55 | 2025-12-06 13:12:59 |
|          101 | 3000-3      | DEPOSITO      | 616.27 | 2025-12-06 13:12:46 |
|         1407 | 2000-2      | SAQUE         | 616.18 | 2025-12-06 13:13:28 |
|          327 | 1000-1      | SAQUE         | 616.10 | 2025-12-06 13:12:48 |
|          860 | 3000-3      | TRANSFERENCIA | 615.20 | 2025-12-06 13:12:59 |
|          561 | 2000-2      | DEPOSITO      | 614.96 | 2025-12-06 13:12:55 |
|          499 | 4000-4      | SAQUE         | 613.96 | 2025-12-06 13:12:50 |
|         1266 | 1000-1      | DEPOSITO      | 612.84 | 2025-12-06 13:13:27 |
|          715 | 4000-4      | DEPOSITO      | 612.79 | 2025-12-06 13:12:57 |
|          189 | 1000-1      | SAQUE         | 612.23 | 2025-12-06 13:12:47 |
|           81 | 2000-2      | TRANSFERENCIA | 609.59 | 2025-12-06 13:12:46 |
|         1294 | 1000-1      | DEPOSITO      | 609.52 | 2025-12-06 13:13:27 |
|          946 | 2000-2      | DEPOSITO      | 609.35 | 2025-12-06 13:13:00 |
|         1151 | 3000-3      | SAQUE         | 608.96 | 2025-12-06 13:13:25 |
|          784 | 4000-4      | DEPOSITO      | 608.60 | 2025-12-06 13:12:58 |
|          940 | 2000-2      | SAQUE         | 608.55 | 2025-12-06 13:13:00 |
|          512 | 3000-3      | SAQUE         | 608.31 | 2025-12-06 13:12:55 |
|          236 | 2000-2      | TRANSFERENCIA | 608.16 | 2025-12-06 13:12:47 |
|         1341 | 3000-3      | DEPOSITO      | 607.51 | 2025-12-06 13:13:28 |
|          468 | 4000-4      | SAQUE         | 607.36 | 2025-12-06 13:12:50 |
|          374 | 3000-3      | DEPOSITO      | 607.33 | 2025-12-06 13:12:49 |
|          913 | 1000-1      | TRANSFERENCIA | 606.85 | 2025-12-06 13:12:59 |
|          486 | 1000-1      | DEPOSITO      | 605.19 | 2025-12-06 13:12:50 |
|         1247 | 2000-2      | TRANSFERENCIA | 604.91 | 2025-12-06 13:13:26 |
|          369 | 3000-3      | SAQUE         | 604.19 | 2025-12-06 13:12:49 |
|          350 | 4000-4      | DEPOSITO      | 602.42 | 2025-12-06 13:12:49 |
|          279 | 3000-3      | DEPOSITO      | 600.58 | 2025-12-06 13:12:48 |
|          994 | 2000-2      | TRANSFERENCIA | 600.44 | 2025-12-06 13:13:00 |
|          645 | 2000-2      | TRANSFERENCIA | 598.64 | 2025-12-06 13:12:56 |
|          900 | 1000-1      | SAQUE         | 598.40 | 2025-12-06 13:12:59 |
|          838 | 3000-3      | DEPOSITO      | 598.16 | 2025-12-06 13:12:58 |
|         1443 | 1000-1      | DEPOSITO      | 595.69 | 2025-12-06 13:13:29 |
|           94 | 4000-4      | SAQUE         | 594.72 | 2025-12-06 13:12:46 |
|         1279 | 4000-4      | SAQUE         | 593.93 | 2025-12-06 13:13:27 |
|          235 | 2000-2      | TRANSFERENCIA | 592.71 | 2025-12-06 13:12:47 |
|         1167 | 3000-3      | TRANSFERENCIA | 592.31 | 2025-12-06 13:13:26 |
|         1289 | 2000-2      | SAQUE         | 591.67 | 2025-12-06 13:13:27 |
|          281 | 3000-3      | TRANSFERENCIA | 591.12 | 2025-12-06 13:12:48 |
|          383 | 2000-2      | DEPOSITO      | 590.89 | 2025-12-06 13:12:49 |
|          179 | 1000-1      | TRANSFERENCIA | 590.32 | 2025-12-06 13:12:47 |
|         1484 | 1000-1      | TRANSFERENCIA | 590.15 | 2025-12-06 13:13:29 |
|          196 | 1000-1      | TRANSFERENCIA | 589.23 | 2025-12-06 13:12:47 |
|          720 | 2000-2      | TRANSFERENCIA | 589.21 | 2025-12-06 13:12:57 |
|         1448 | 4000-4      | TRANSFERENCIA | 588.47 | 2025-12-06 13:13:29 |
|          132 | 4000-4      | SAQUE         | 587.43 | 2025-12-06 13:12:46 |
|         1073 | 1000-1      | DEPOSITO      | 587.22 | 2025-12-06 13:13:25 |
|         1186 | 1000-1      | DEPOSITO      | 586.19 | 2025-12-06 13:13:26 |
|          895 | 2000-2      | DEPOSITO      | 586.17 | 2025-12-06 13:12:59 |
|           20 | 1000-1      | SAQUE         | 585.78 | 2025-12-06 13:12:45 |
|         1491 | 2000-2      | DEPOSITO      | 585.67 | 2025-12-06 13:13:29 |
|          966 | 1000-1      | DEPOSITO      | 584.27 | 2025-12-06 13:13:00 |
|         1128 | 4000-4      | SAQUE         | 583.97 | 2025-12-06 13:13:25 |
|         1125 | 4000-4      | DEPOSITO      | 583.51 | 2025-12-06 13:13:25 |
|          919 | 4000-4      | DEPOSITO      | 582.77 | 2025-12-06 13:12:59 |
|          795 | 1000-1      | SAQUE         | 581.15 | 2025-12-06 13:12:58 |
|         1112 | 4000-4      | DEPOSITO      | 580.29 | 2025-12-06 13:13:25 |
|          515 | 1000-1      | SAQUE         | 578.40 | 2025-12-06 13:12:55 |
|          835 | 1000-1      | DEPOSITO      | 577.90 | 2025-12-06 13:12:58 |
|         1178 | 1000-1      | DEPOSITO      | 577.80 | 2025-12-06 13:13:26 |
|          565 | 2000-2      | TRANSFERENCIA | 576.67 | 2025-12-06 13:12:55 |
|          243 | 4000-4      | TRANSFERENCIA | 575.98 | 2025-12-06 13:12:48 |
|           21 | 1000-1      | SAQUE         | 574.62 | 2025-12-06 13:12:45 |
|         1419 | 4000-4      | TRANSFERENCIA | 574.26 | 2025-12-06 13:13:28 |
|          665 | 3000-3      | TRANSFERENCIA | 573.16 | 2025-12-06 13:12:57 |
|         1449 | 3000-3      | SAQUE         | 572.98 | 2025-12-06 13:13:29 |
|          201 | 4000-4      | TRANSFERENCIA | 572.31 | 2025-12-06 13:12:47 |
|         1333 | 2000-2      | DEPOSITO      | 572.15 | 2025-12-06 13:13:27 |
|           53 | 3000-3      | DEPOSITO      | 571.69 | 2025-12-06 13:12:45 |
|          298 | 1000-1      | DEPOSITO      | 570.96 | 2025-12-06 13:12:48 |
|          203 | 4000-4      | SAQUE         | 570.30 | 2025-12-06 13:12:47 |
|          969 | 4000-4      | TRANSFERENCIA | 570.19 | 2025-12-06 13:13:00 |
|          237 | 2000-2      | TRANSFERENCIA | 569.51 | 2025-12-06 13:12:47 |
|         1069 | 2000-2      | DEPOSITO      | 569.27 | 2025-12-06 13:13:24 |
|          801 | 1000-1      | DEPOSITO      | 568.97 | 2025-12-06 13:12:58 |
|         1400 | 1000-1      | TRANSFERENCIA | 568.10 | 2025-12-06 13:13:28 |
|          616 | 1000-1      | SAQUE         | 567.67 | 2025-12-06 13:12:56 |
|          802 | 4000-4      | SAQUE         | 567.44 | 2025-12-06 13:12:58 |
|         1026 | 1000-1      | TRANSFERENCIA | 567.34 | 2025-12-06 13:13:24 |
|          669 | 1000-1      | SAQUE         | 566.99 | 2025-12-06 13:12:57 |
|          214 | 4000-4      | DEPOSITO      | 565.81 | 2025-12-06 13:12:47 |
|          759 | 1000-1      | TRANSFERENCIA | 565.76 | 2025-12-06 13:12:58 |
|         1382 | 1000-1      | SAQUE         | 565.69 | 2025-12-06 13:13:28 |
|          811 | 3000-3      | DEPOSITO      | 565.68 | 2025-12-06 13:12:58 |
|         1099 | 3000-3      | TRANSFERENCIA | 565.57 | 2025-12-06 13:13:25 |
|          618 | 1000-1      | SAQUE         | 565.42 | 2025-12-06 13:12:56 |
|          248 | 4000-4      | SAQUE         | 564.88 | 2025-12-06 13:12:48 |
|          679 | 1000-1      | DEPOSITO      | 564.65 | 2025-12-06 13:12:57 |
|         1359 | 3000-3      | TRANSFERENCIA | 564.58 | 2025-12-06 13:13:28 |
|          423 | 1000-1      | DEPOSITO      | 563.62 | 2025-12-06 13:12:50 |
|          955 | 1000-1      | TRANSFERENCIA | 561.95 | 2025-12-06 13:13:00 |
|          497 | 1000-1      | TRANSFERENCIA | 561.47 | 2025-12-06 13:12:50 |
|         1233 | 4000-4      | SAQUE         | 561.31 | 2025-12-06 13:13:26 |
|          929 | 3000-3      | DEPOSITO      | 559.93 | 2025-12-06 13:12:59 |
|          522 | 2000-2      | SAQUE         | 558.92 | 2025-12-06 13:12:55 |
|          620 | 1000-1      | TRANSFERENCIA | 558.65 | 2025-12-06 13:12:56 |
|         1249 | 1000-1      | TRANSFERENCIA | 558.09 | 2025-12-06 13:13:26 |
|          962 | 1000-1      | DEPOSITO      | 558.04 | 2025-12-06 13:13:00 |
|          403 | 3000-3      | TRANSFERENCIA | 557.52 | 2025-12-06 13:12:49 |
|          703 | 1000-1      | SAQUE         | 557.42 | 2025-12-06 13:12:57 |
|           40 | 4000-4      | SAQUE         | 556.96 | 2025-12-06 13:12:45 |
|           27 | 2000-2      | SAQUE         | 555.21 | 2025-12-06 13:12:45 |
|          928 | 4000-4      | TRANSFERENCIA | 554.00 | 2025-12-06 13:12:59 |
|          974 | 2000-2      | DEPOSITO      | 553.98 | 2025-12-06 13:13:00 |
|          584 | 3000-3      | SAQUE         | 553.57 | 2025-12-06 13:12:56 |
|          617 | 3000-3      | TRANSFERENCIA | 553.17 | 2025-12-06 13:12:56 |
|          980 | 3000-3      | DEPOSITO      | 551.92 | 2025-12-06 13:13:00 |
|          874 | 2000-2      | DEPOSITO      | 550.44 | 2025-12-06 13:12:59 |
|           24 | 1000-1      | TRANSFERENCIA | 548.54 | 2025-12-06 13:12:45 |
|          144 | 3000-3      | DEPOSITO      | 548.26 | 2025-12-06 13:12:46 |
|         1482 | 4000-4      | SAQUE         | 547.17 | 2025-12-06 13:13:29 |
|          814 | 2000-2      | SAQUE         | 547.16 | 2025-12-06 13:12:58 |
|         1154 | 4000-4      | DEPOSITO      | 546.97 | 2025-12-06 13:13:25 |
|         1309 | 4000-4      | SAQUE         | 545.54 | 2025-12-06 13:13:27 |
|         1363 | 3000-3      | TRANSFERENCIA | 545.22 | 2025-12-06 13:13:28 |
|          789 | 1000-1      | DEPOSITO      | 544.94 | 2025-12-06 13:12:58 |
|         1182 | 4000-4      | SAQUE         | 544.83 | 2025-12-06 13:13:26 |
|          294 | 3000-3      | SAQUE         | 543.51 | 2025-12-06 13:12:48 |
|         1388 | 2000-2      | DEPOSITO      | 543.03 | 2025-12-06 13:13:28 |
|          540 | 3000-3      | TRANSFERENCIA | 542.79 | 2025-12-06 13:12:55 |
|          212 | 4000-4      | SAQUE         | 542.74 | 2025-12-06 13:12:47 |
|          480 | 1000-1      | DEPOSITO      | 542.58 | 2025-12-06 13:12:50 |
|          481 | 2000-2      | SAQUE         | 539.56 | 2025-12-06 13:12:50 |
|          830 | 4000-4      | SAQUE         | 539.25 | 2025-12-06 13:12:58 |
|          102 | 3000-3      | DEPOSITO      | 538.88 | 2025-12-06 13:12:46 |
|          141 | 1000-1      | DEPOSITO      | 538.26 | 2025-12-06 13:12:46 |
|         1051 | 3000-3      | DEPOSITO      | 536.18 | 2025-12-06 13:13:24 |
|         1257 | 4000-4      | TRANSFERENCIA | 534.32 | 2025-12-06 13:13:27 |
|          596 | 4000-4      | TRANSFERENCIA | 533.93 | 2025-12-06 13:12:56 |
|          507 | 1000-1      | TRANSFERENCIA | 533.89 | 2025-12-06 13:12:55 |
|          571 | 3000-3      | TRANSFERENCIA | 533.05 | 2025-12-06 13:12:55 |
|          749 | 2000-2      | DEPOSITO      | 531.94 | 2025-12-06 13:12:57 |
|           93 | 1000-1      | DEPOSITO      | 531.19 | 2025-12-06 13:12:46 |
|            7 | 3000-3      | DEPOSITO      | 530.02 | 2025-12-06 13:12:45 |
|          577 | 2000-2      | TRANSFERENCIA | 529.71 | 2025-12-06 13:12:56 |
|          931 | 4000-4      | TRANSFERENCIA | 528.70 | 2025-12-06 13:12:59 |
|         1213 | 4000-4      | TRANSFERENCIA | 528.29 | 2025-12-06 13:13:26 |
|          651 | 3000-3      | DEPOSITO      | 528.23 | 2025-12-06 13:12:56 |
|          693 | 1000-1      | DEPOSITO      | 527.68 | 2025-12-06 13:12:57 |
|          293 | 4000-4      | SAQUE         | 527.48 | 2025-12-06 13:12:48 |
|         1250 | 1000-1      | TRANSFERENCIA | 526.91 | 2025-12-06 13:13:26 |
|          920 | 3000-3      | SAQUE         | 525.43 | 2025-12-06 13:12:59 |
|          506 | 3000-3      | DEPOSITO      | 524.43 | 2025-12-06 13:12:55 |
|         1064 | 2000-2      | SAQUE         | 524.33 | 2025-12-06 13:13:24 |
|          658 | 4000-4      | TRANSFERENCIA | 524.09 | 2025-12-06 13:12:56 |
|          882 | 4000-4      | DEPOSITO      | 524.08 | 2025-12-06 13:12:59 |
|          972 | 4000-4      | SAQUE         | 523.63 | 2025-12-06 13:13:00 |
|          768 | 4000-4      | TRANSFERENCIA | 522.99 | 2025-12-06 13:12:58 |
|         1494 | 3000-3      | TRANSFERENCIA | 521.38 | 2025-12-06 13:13:29 |
|          704 | 1000-1      | SAQUE         | 519.97 | 2025-12-06 13:12:57 |
|          119 | 3000-3      | DEPOSITO      | 519.30 | 2025-12-06 13:12:46 |
|          589 | 2000-2      | SAQUE         | 519.19 | 2025-12-06 13:12:56 |
|           35 | 2000-2      | DEPOSITO      | 519.00 | 2025-12-06 13:12:45 |
|         1180 | 2000-2      | DEPOSITO      | 518.19 | 2025-12-06 13:13:26 |
|          738 | 3000-3      | SAQUE         | 516.69 | 2025-12-06 13:12:57 |
|          224 | 2000-2      | TRANSFERENCIA | 516.54 | 2025-12-06 13:12:47 |
|          257 | 2000-2      | SAQUE         | 515.26 | 2025-12-06 13:12:48 |
|           22 | 3000-3      | SAQUE         | 515.14 | 2025-12-06 13:12:45 |
|          605 | 4000-4      | TRANSFERENCIA | 514.26 | 2025-12-06 13:12:56 |
|          109 | 4000-4      | SAQUE         | 512.94 | 2025-12-06 13:12:46 |
|         1444 | 4000-4      | DEPOSITO      | 511.58 | 2025-12-06 13:13:29 |
|          252 | 4000-4      | TRANSFERENCIA | 511.50 | 2025-12-06 13:12:48 |
|          223 | 2000-2      | SAQUE         | 511.05 | 2025-12-06 13:12:47 |
|           59 | 2000-2      | TRANSFERENCIA | 510.85 | 2025-12-06 13:12:46 |
|         1205 | 3000-3      | DEPOSITO      | 510.05 | 2025-12-06 13:13:26 |
|          225 | 1000-1      | TRANSFERENCIA | 509.17 | 2025-12-06 13:12:47 |
|         1373 | 1000-1      | DEPOSITO      | 507.32 | 2025-12-06 13:13:28 |
|          295 | 2000-2      | DEPOSITO      | 507.21 | 2025-12-06 13:12:48 |
|          216 | 1000-1      | DEPOSITO      | 507.10 | 2025-12-06 13:12:47 |
|         1148 | 4000-4      | DEPOSITO      | 506.62 | 2025-12-06 13:13:25 |
|          648 | 2000-2      | SAQUE         | 505.65 | 2025-12-06 13:12:56 |
|         1280 | 4000-4      | TRANSFERENCIA | 505.37 | 2025-12-06 13:13:27 |
|         1375 | 2000-2      | TRANSFERENCIA | 504.92 | 2025-12-06 13:13:28 |
|          431 | 4000-4      | DEPOSITO      | 504.81 | 2025-12-06 13:12:50 |
|          935 | 1000-1      | TRANSFERENCIA | 504.33 | 2025-12-06 13:12:59 |
|          226 | 4000-4      | TRANSFERENCIA | 503.97 | 2025-12-06 13:12:47 |
|           56 | 2000-2      | DEPOSITO      | 502.59 | 2025-12-06 13:12:45 |
|          594 | 4000-4      | DEPOSITO      | 501.90 | 2025-12-06 13:12:56 |
|          460 | 1000-1      | SAQUE         | 500.22 | 2025-12-06 13:12:50 |
+--------------+-------------+---------------+--------+---------------------+
466 rows in set (0,01 sec)

  -- --------------------------------------------------
  -- Consulta de Alto Desempenho Combinada
  -- --------------------------------------------------  
  SELECT
    t.id_transacao,
    c_destino.numero_conta AS ContaDestino,
    t.valor,
    t.data_transacao
FROM
    Transacoes t
JOIN
    Contas c_origem ON t.id_conta_origem = c_origem.id_conta
LEFT JOIN
    Contas c_destino ON t.id_conta_destino = c_destino.id_conta
WHERE
    c_origem.numero_conta = '1000-1'
    AND t.tipo = 'TRANSFERENCIA'
ORDER BY
    t.data_transacao DESC
LIMIT 5;

+--------------+--------------+--------+---------------------+
| id_transacao | ContaDestino | valor  | data_transacao      |
+--------------+--------------+--------+---------------------+
|         1452 | 2000-2       | 932.83 | 2025-12-06 13:13:29 |
|         1461 | 3000-3       | 820.07 | 2025-12-06 13:13:29 |
|         1462 | 3000-3       | 995.47 | 2025-12-06 13:13:29 |
|         1465 | 4000-4       | 622.15 | 2025-12-06 13:13:29 |
|         1477 | 2000-2       | 149.62 | 2025-12-06 13:13:29 |
+--------------+--------------+--------+---------------------+
5 rows in set (0,01 sec)
   
-- Módulo Intermediário (Análise e Estrutura)
-- 4. Listar Clientes e Saldos (INNER JOIN)

SELECT
    cl.nome AS NomeCliente,
    c.numero_conta AS NumeroConta,
    c.saldo AS SaldoAtual,
    c.data_abertura AS DataAbertura
FROM
    Clientes cl
INNER JOIN
    Contas c ON cl.id_cliente = c.id_cliente
ORDER BY
    cl.nome;    

+-------------+-------------+------------+--------------+
| NomeCliente | NumeroConta | SaldoAtual | DataAbertura |
+-------------+-------------+------------+--------------+
| Alice Silva | 1000-1      |    5691.86 | 2025-12-06   |
| Bruno Costa | 2000-2      |   24899.43 | 2025-12-06   |
| Carla Souza | 3000-3      |   13802.07 | 2025-12-06   |
| Daniel Lins | 4000-4      |  -10162.01 | 2025-12-06   |
+-------------+-------------+------------+--------------+
4 rows in set (0,00 sec)

-- ------------------------------------------------------------------------
-- 5. Calcular Movimentação Total de Crédito e Débito por Conta
-- Esta consulta calcula o valor total que entrou (crédito) e o valor total
-- que saiu (débito) de cada conta, utilizando SUM e CASE.
-- ------------------------------------------------------------------------
SELECT
    c.numero_conta,
    -- Calcula o total de DÉBITO (Saques e Transferências como origem)
    SUM(CASE 
        WHEN t.tipo IN ('SAQUE', 'TRANSFERENCIA') THEN t.valor 
        ELSE 0.00 
    END) AS TotalDebito,
    -- Calcula o total de CRÉDITO (Depósitos e Transferências como destino)
    SUM(CASE 
        WHEN t.tipo = 'DEPOSITO' THEN t.valor 
        ELSE 0.00 
    END) AS TotalCreditoEntrada,
    -- Adiciona o Crédito das transferências recebidas
    (SELECT SUM(valor) FROM Transacoes WHERE id_conta_destino = c.id_conta) AS TotalCreditoRecebido
FROM
    Contas c
LEFT JOIN
    Transacoes t ON c.id_conta = t.id_conta_origem -- Junta com as transações ONDE a conta é ORIGEM
GROUP BY
    c.id_conta, c.numero_conta
ORDER BY
    TotalDebito DESC;

+--------------+-------------+---------------------+----------------------+
| numero_conta | TotalDebito | TotalCreditoEntrada | TotalCreditoRecebido |
+--------------+-------------+---------------------+----------------------+
| 4000-4       |   129970.70 |            55971.43 |             61337.26 |
| 1000-1       |   129817.04 |            69790.24 |             51414.86 |
| 2000-2       |   124144.87 |            67187.44 |             73856.86 |
| 3000-3       |   116447.18 |            62309.78 |             67439.47 |
+--------------+-------------+---------------------+----------------------+
4 rows in set (0,05 sec)

-- 6. Subqueries e Views: Criar uma VIEW para mostrar o saldo atualizado de todas as contas. 
-- Utilizar SUBQUERY para identificar o cliente que possui a conta com o menor saldo.
CREATE OR REPLACE VIEW SaldoAtualizadoContas AS
SELECT
    c.numero_conta,
    cl.nome AS NomeCliente,
    c.saldo,
    c.status_conta
FROM
    Contas c
JOIN
    Clientes cl ON c.id_cliente = cl.id_cliente
ORDER BY
    c.saldo DESC;

-- Consulta à VIEW para verificar a estrutura
mysql> SELECT * FROM SaldoAtualizadoContas LIMIT 7;
+--------------+-------------+-----------+--------------+
| numero_conta | NomeCliente | saldo     | status_conta |
+--------------+-------------+-----------+--------------+
| 2000-2       | Bruno Costa |  24899.43 | ATIVA        |
| 3000-3       | Carla Souza |  13802.07 | BLOQUEADA    |
| 1000-1       | Alice Silva |   5691.86 | ATIVA        |
| 4000-4       | Daniel Lins | -10162.01 | ATIVA        |
+--------------+-------------+-----------+--------------+
4 rows in set (0,01 sec)

-- -------------------------------------------------------------------------------------
-- 7. Funções e Normalização: Aplicar funções Numéricas (ROUND) para 
-- formatar saldos. Garantir que a modelagem da tabela Clientes e Contas esteja em 3FN.
-- -------------------------------------------------------------------------------------

-- Aplicação de ROUND() para Formatar Saldos

SELECT
    c.numero_conta,
    cl.nome AS NomeCliente,
    -- Aplica ROUND(valor, 2) para formatar o saldo com 2 casas decimais
    ROUND(c.saldo, 2) AS SaldoFormatado,
    c.status_conta
FROM
    Contas c
JOIN
    Clientes cl ON c.id_cliente = cl.id_cliente
ORDER BY
    c.saldo DESC;


+--------------+-------------+----------------+--------------+
| numero_conta | NomeCliente | SaldoFormatado | status_conta |
+--------------+-------------+----------------+--------------+
| 2000-2       | Bruno Costa |       24899.43 | ATIVA        |
| 3000-3       | Carla Souza |       13802.07 | BLOQUEADA    |
| 1000-1       | Alice Silva |        5691.86 | ATIVA        |
| 4000-4       | Daniel Lins |      -10162.01 | ATIVA        |
+--------------+-------------+----------------+--------------+
4 rows in set (0,00 sec)

-- Normalização de Dados (3FN)A Normalização é um processo que organiza as colunas e tabelas em um banco
-- de dados para minimizar a redundância de dados e as anomalias de inserção, atualização e exclusão, garantindo
-- a integridade dos dados. O objetivo é garantir que as tabelas Clientes e Contas estejam na Terceira Forma Normal (3FN).
-- Requisitos da 3FN: 
-- Para que uma tabela esteja em 3FN, ela deve atender aos seguintes critérios:
-- Estar em 2FN (Segunda Forma Normal). 
-- Não conter dependências transitivas: Isto significa que todos os atributos não-chave devem
-- depender diretamente da chave primária (PK) e de nenhum outro atributo não-chave.

-- 1. Análise da Tabela Clientes
-- Coluna			Tipo		Depende de id_cliente(PK)? 		Depende de Outro Atributo Não-Chave? 
-- id_cliente		PK			Sim								Não	
-- nome				Não-chave	Sim								Não
-- cpf				Não-chave	Sim								Não
-- email			Não-chave	Sim								Não
-- data_cadastro	Não-chave	Sim								Não

-- Conclusão:
-- A tabela Clientes está em 3FN. Todos os atributos (nome, cpf, email, data_cadastro) descrevem diretamente o cliente 
-- identificado pelo id_cliente. Não há dependências transitivas.

-- 2. Análise da Tabela Contas
-- Coluna				Tipo		Depende de id_conta (PK)?		Depende de Outro Atributo Não-Chave?
-- id_conta				PK			Sim								Não
-- numero_conta			Não-chave	Sim								Não
-- id_cliente			Não-chave	Sim								Não
-- saldo				Não-chave	Sim								Não
-- data_abertura		Não-chave	Sim								Não
-- status_conta			Não-chave	Sim								Não

-- Conclusão: A tabela Contas está em 3FN. Todas as colunas (numero_conta, id_cliente, saldo, etc.) descrevem as características 
-- da conta identificada pelo id_conta. 

-- Estrutura do SistemaBancario e 3FN
-- A modelagem original de quatro tabelas (Clientes, Contas, Transacoes, Log_Auditoria) já estava em conformidade com as regras da 3FN,
-- pois as informações foram logicamente separadas:
-- * Clientes: Armazena apenas dados do titular.
-- * Contas: Armazena apenas dados específicos da conta (saldo, número, FK para cliente).
-- * Transacoes: Armazena apenas dados da movimentação. 
-- Ao separar os dados do cliente (entidade) dos dados da conta (entidade relacionada), evitamos redundância (não repetimos o nome do
-- cliente em cada registro de conta) e garantimos a 3FN.

-----------------------------------------------------------------------------------------------------------------------------------------------
-- Módulo Avançado (Programação e Controle Transacional)
-----------------------------------------------------------------------------------------------------------------------------------------------
-- 8. Otimização - NOTA: Este índice foi criado automaticamente após a criação do banco de dados sistemabancario.

-- 9. Stored Procedure: Nota: Este índice também foi coberto pelo índice composto anterior.

-- 10. triggers para Auditoria (Registro de Log)
-- TRIGGER AFTER UPDATE na tabela Contas é o mecanismo para registrar automaticamente todas as mudanças de saldo 
-- na tabela Log_Auditoria, garantindo quem e quando mudou o saldo.

-- O script a seguir garante que o log seja registrado após qualquer UPDATE no saldo. 
DELIMITER //

-- DROP TRIGGER IF EXISTS tr_contas_after_update; -- Descomente se precisar recriar
CREATE TRIGGER tr_contas_after_update
AFTER UPDATE ON Contas
FOR EACH ROW
BEGIN
    -- Verifica se o saldo realmente mudou antes de logar
    IF OLD.saldo <> NEW.saldo THEN
        INSERT INTO Log_Auditoria (
            nome_tabela,
            id_registro,
            tipo_operacao,
            dados_antigos,
            dados_novos,
            usuario
        )
        VALUES (
            'Contas',
            NEW.id_conta,
            'UPDATE',
            JSON_OBJECT( 
                'saldo_anterior', OLD.saldo,
                'status_anterior', OLD.status_conta -- Incluindo status_conta para auditoria completa
            ),
            JSON_OBJECT(
                'saldo_novo', NEW.saldo,
                'status_novo', NEW.status_conta
            ),
            USER()
        );
    END IF;
END //

DELIMITER ;

select * from Contas;
+----------+--------------+------------+-----------+---------------+--------------+
| id_conta | numero_conta | id_cliente | saldo     | data_abertura | status_conta |
+----------+--------------+------------+-----------+---------------+--------------+
|        1 | 1000-1       |          1 |   5791.86 | 2025-12-06    | ATIVA        |
|        2 | 2000-2       |          2 |  24999.43 | 2025-12-06    | ATIVA        |
|        3 | 3000-3       |          3 |  13902.07 | 2025-12-06    | BLOQUEADA    |
|        4 | 4000-4       |          4 | -10062.01 | 2025-12-06    | ATIVA        |
+----------+--------------+------------+-----------+---------------+--------------+
4 rows in set (0,00 sec)

--------------------------------------------------------------------------------------
-- Comando UPDATE para disparar a Trigger:
--------------------------------------------------------------------------------------

mysql> UPDATE Contas SET saldo = saldo + 11100.00 WHERE id_conta = 4;
Query OK, 1 row affected (0,01 sec)
Rows matched: 1  Changed: 1  Warnings: 0

-- id_conta 4 saiu do vermelho...

mysql> select * from Contas;
+----------+--------------+------------+----------+---------------+--------------+
| id_conta | numero_conta | id_cliente | saldo    | data_abertura | status_conta |
+----------+--------------+------------+----------+---------------+--------------+
|        1 | 1000-1       |          1 |  5791.86 | 2025-12-06    | ATIVA        |
|        2 | 2000-2       |          2 | 24999.43 | 2025-12-06    | ATIVA        |
|        3 | 3000-3       |          3 | 13902.07 | 2025-12-06    | BLOQUEADA    |
|        4 | 4000-4       |          4 |  1037.99 | 2025-12-06    | ATIVA        |
+----------+--------------+------------+----------+---------------+--------------+
4 rows in set (0,00 sec)

-- Verificação do saldo após execução da Trigger.

mysql> SELECT * FROM Log_Auditoria ORDER BY data_hora DESC LIMIT 10;
+--------+-------------+-------------+---------------+-----------------------------------------------------------------+-----------------------------------------------------------------+---------------------+----------------+
| id_log | nome_tabela | id_registro | tipo_operacao | dados_antigos                                                   | dados_novos                                                     | data_hora           | usuario        |
+--------+-------------+-------------+---------------+-----------------------------------------------------------------+-----------------------------------------------------------------+---------------------+----------------+
|   2002 | Contas      |           4 | UPDATE        | {"saldo_anterior": -10062.01, "status_anterior": "ATIVA"}       | {"saldo_novo": 1037.99, "status_novo": "ATIVA"}                 | 2025-12-06 13:39:37 | root@localhost |
|   2001 | Contas      |           4 | UPDATE        | {"saldo_anterior": -10162.01, "status_anterior": "ATIVA"}       | {"saldo_novo": -10062.01, "status_novo": "ATIVA"}               | 2025-12-06 13:37:22 | root@localhost |
|   2000 | Contas      |           3 | UPDATE        | {"saldo_anterior": 13802.07, "status_anterior": "BLOQUEADA"}    | {"saldo_novo": 13902.07, "status_novo": "BLOQUEADA"}            | 2025-12-06 13:37:19 | root@localhost |
|   1999 | Contas      |           2 | UPDATE        | {"saldo_anterior": 24899.43, "status_anterior": "ATIVA"}        | {"saldo_novo": 24999.43, "status_novo": "ATIVA"}                | 2025-12-06 13:37:14 | root@localhost |
|   1998 | Contas      |           1 | UPDATE        | {"saldo_anterior": 5691.86, "status_anterior": "ATIVA"}         | {"saldo_novo": 5791.86, "status_novo": "ATIVA"}                 | 2025-12-06 13:33:17 | root@localhost |
|   1997 | Contas      |           3 | UPDATE        | {"saldo": 13802.07, "id_cliente": 3, "numero_conta": "3000-3"}  | {"saldo": 13802.07, "id_cliente": 3, "numero_conta": "3000-3"}  | 2025-12-06 13:16:50 | root@localhost |
|   1934 | Contas      |           4 | UPDATE        | {"saldo": -11326.96, "id_cliente": 4, "numero_conta": "4000-4"} | {"saldo": -11690.36, "id_cliente": 4, "numero_conta": "4000-4"} | 2025-12-06 13:13:29 | root@localhost |
|   1932 | Contas      |           1 | UPDATE        | {"saldo": 7190.65, "id_cliente": 1, "numero_conta": "1000-1"}   | {"saldo": 7610.07, "id_cliente": 1, "numero_conta": "1000-1"}   | 2025-12-06 13:13:29 | root@localhost |
|   1933 | Contas      |           1 | UPDATE        | {"saldo": 7610.07, "id_cliente": 1, "numero_conta": "1000-1"}   | {"saldo": 7963.12, "id_cliente": 1, "numero_conta": "1000-1"}   | 2025-12-06 13:13:29 | root@localhost |
|   1936 | Contas      |           3 | UPDATE        | {"saldo": 12451.87, "id_cliente": 3, "numero_conta": "3000-3"}  | {"saldo": 12072.20, "id_cliente": 3, "numero_conta": "3000-3"}  | 2025-12-06 13:13:29 | root@localhost |
+--------+-------------+-------------+---------------+-----------------------------------------------------------------+-----------------------------------------------------------------+---------------------+----------------+
10 rows in set (0,02 sec)

-- 11. Transações Programáticas:
-- Stored Procedure e Transações ACID
-- Esta é a parte mais crítica, onde implementamos a STORED PROCEDURE RealizarTransferencia 
-- garantindo todos os princípios ACID:

-- Atomicidade: Usando START TRANSACTION e COMMIT/ROLLBACK.

-- Consistência: Verificação de saldo e uso de locks (FOR UPDATE).

-- Isolamento: Uso de locks (FOR UPDATE) para evitar que outra transação altere o saldo durante a verificação e o débito/crédito.

-- Durabilidade: COMMIT garante que as alterações persistam.

-- Lógica Implementada:
-- Inicia a transação (START TRANSACTION).
-- Obtém os IDs das contas e bloqueia as linhas (FOR UPDATE).

-- Verifica o saldo insuficiente. Se o saldo for menor que o valor, sinaliza o erro e faz ROLLBACK.

-- Executa o UPDATE de débito.

-- Executa o UPDATE de crédito.

-- Registra a transação na tabela Transacoes.

-- Se todas as etapas ocorrerem sem erro, finaliza com COMMIT.

DELIMITER //

DROP PROCEDURE IF EXISTS RealizarTransferencia; -- Permite recriação

CREATE PROCEDURE RealizarTransferencia (
    IN p_numero_origem VARCHAR(20),
    IN p_numero_destino VARCHAR(20),
    IN p_valor DECIMAL(15, 2)
)
BEGIN
    DECLARE v_id_origem INT;
    DECLARE v_id_destino INT;
    DECLARE v_saldo_origem DECIMAL(15, 2);
    
    -- Inicia a transação para garantir Atomicidade e Consistência (ACID)
    START TRANSACTION;

    -- 1. Recupera IDs, Saldo e aplica BLOQUEIO (Isolamento)
    SELECT id_conta, saldo INTO v_id_origem, v_saldo_origem
    FROM Contas 
    WHERE numero_conta = p_numero_origem
    FOR UPDATE; 
    
    SELECT id_conta INTO v_id_destino
    FROM Contas 
    WHERE numero_conta = p_numero_destino
    FOR UPDATE; 

    -- Validação: Conta origem ou destino não encontrada
    IF v_id_origem IS NULL OR v_id_destino IS NULL THEN
        -- Gerenciamento de Erro e ROLLBACK
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: Conta de origem ou destino não encontrada.';
        ROLLBACK;
    
    -- Validação: Saldo insuficiente (Gerenciamento de Erro)
    ELSEIF v_saldo_origem < p_valor THEN
        -- Gerenciamento de Erro e ROLLBACK
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: Saldo insuficiente para a transferência.';
        ROLLBACK;
        
    ELSE
        -- 2. Débito na conta origem
        UPDATE Contas SET saldo = saldo - p_valor WHERE id_conta = v_id_origem;
        
        -- 3. Crédito na conta destino
        UPDATE Contas SET saldo = saldo + p_valor WHERE id_conta = v_id_destino;
        
        -- 4. Registro da transação (Log da Transação)
        INSERT INTO Transacoes (id_conta_origem, id_conta_destino, tipo, valor)
        VALUES (v_id_origem, v_id_destino, 'TRANSFERENCIA', p_valor);
        
        -- 5. Confirma a transação (Durabilidade)
        COMMIT;
    END IF;
    
END //

DELIMITER ;
 
-- Exemplo de Uso (Teste ACID)
-- Você pode testar a lógica ACID da procedure com o saldo inicial que definimos (ex: Alice 1000-1 com 15000.00).

-- Sucesso (COMMIT):

-- SQL

CALL RealizarTransferencia('1000-1', '2000-2', 500.00);
-- Resultado: Ambas as contas são atualizadas, o TRIGGER registra as duas mudanças na Log_Auditoria, e a Transacoes é registrada.

-- Falha (ROLLBACK - Saldo Insuficiente): (Se a conta '3000-3' tiver saldo de 500.00)

-- SQL

CALL RealizarTransferencia('3000-3', '1000-1', 50000.00);
-- Resultado: A procedure sinaliza o erro de "Saldo insuficiente", e nenhum UPDATE é aplicado às tabelas, garantindo a atomicidade.
mysql> CALL RealizarTransferencia('3000-3', '1000-1', 50000.00);
ERROR 1644 (45000): Erro: Saldo insuficiente para a transferência.
 
/////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

-- Encontrando o ID da transação a ser deletada (Ex: o primeiro registro inserido)

mysql> SET @id_deletar = (SELECT MIN(id_transacao) FROM Transacoes);
Query OK, 0 rows affected (0,01 sec)

-- Executa o DELETE
mysql> DELETE FROM Transacoes
    -> WHERE id_transacao = @id_deletar;
Query OK, 1 row affected (0,02 sec)

-- Confirmação
mysql> SELECT CONCAT('Transação ', @id_deletar, ' foi removida.') AS Status;
+-----------------------------+
| Status                      |
+-----------------------------+
| Transação 2 foi removida.   |
+-----------------------------+
1 row in set (0,01 sec)





