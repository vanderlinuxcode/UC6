08. Transações SQL em Cenários de E-commerce
Esta atividade foi desenhada para colocar em prática o controle de transações em um ambiente de banco de dados real. O objetivo é que cada grupo compreenda e aplique o conceito de operações atômicas, garantindo a integridade dos dados em cenários críticos de e-commerce.

Cenário 1: Venda por Lote

DELIMITER $$

CREATE PROCEDURE realizar_venda_lote (
    IN p_cliente_id INT,
    IN p_produto1_id INT,
    IN p_qtd1 INT,
    IN p_produto2_id INT,
    IN p_qtd2 INT,
    IN p_total DECIMAL(10,2)
)
BEGIN
    DECLARE estoque1 INT;
    DECLARE estoque2 INT;
    DECLARE pedido_id INT;

    START TRANSACTION;

    -- Verifica estoque
    SELECT estoque INTO estoque1 FROM produtos WHERE id = p_produto1_id FOR UPDATE;
    SELECT estoque INTO estoque2 FROM produtos WHERE id = p_produto2_id FOR UPDATE;

    IF estoque1 >= p_qtd1 AND estoque2 >= p_qtd2 THEN
        -- Gera novo ID de pedido (exemplo simples)
        SELECT IFNULL(MAX(id), 0) + 1 INTO pedido_id FROM pedidos;

        -- Cria pedido
        INSERT INTO pedidos (id, cliente_id, data_pedido, status, total)
        VALUES (pedido_id, p_cliente_id, NOW(), 'Confirmado', p_total);

        -- Insere itens
        INSERT INTO itens_pedido (id, pedido_id, produto_id, quantidade, preco_unitario)
        VALUES
            (pedido_id * 10 + 1, pedido_id, p_produto1_id, p_qtd1, (p_total / (p_qtd1 + p_qtd2))),
            (pedido_id * 10 + 2, pedido_id, p_produto2_id, p_qtd2, (p_total / (p_qtd1 + p_qtd2)));

        -- Atualiza estoque
        UPDATE produtos SET estoque = estoque - p_qtd1 WHERE id = p_produto1_id;
        UPDATE produtos SET estoque = estoque - p_qtd2 WHERE id = p_produto2_id;

        COMMIT;
    ELSE
        ROLLBACK;
    END IF;
END$$

DELIMITER ;

Verificando a confirmação da venda:


mysql> SELECT * FROM pedidos WHERE cliente_id = 1 ORDER BY data_pedido DESC LIMIT 1;
+----+------------+---------------------+------------+--------+
| id | cliente_id | data_pedido         | status     | total  |
+----+------------+---------------------+------------+--------+
| 31 |          1 | 2025-11-13 01:45:05 | Confirmado | 150.00 |
+----+------------+---------------------+------------+--------+
1 row in set (0,01 sec)

Quantidade do estoque antes da execução:
mysql> SELECT id, nome, estoque FROM produtos WHERE id IN (2, 1);
+----+--------------------+---------+
| id | nome               | estoque |
+----+--------------------+---------+
|  1 | Smartphone X       |      50 |
|  2 | Notebook Gamer Pro |      15 |
+----+--------------------+---------+
2 rows in set (0,00 sec)

Após execução demostrando que a procedure foi executada com sucesso:
mysql> SELECT id, nome, estoque FROM produtos WHERE id IN (2, 1);
+----+--------------------+---------+
| id | nome               | estoque |
+----+--------------------+---------+
|  1 | Smartphone X       |      47 |
|  2 | Notebook Gamer Pro |      13 |
+----+--------------------+---------+
2 rows in set (0,00 sec)

Procedure de Consulta da Venda (Cenário 1)
DELIMITER $$

CREATE PROCEDURE consultar_venda (
    IN p_pedido_id INT
)
BEGIN
    -- Consulta o pedido
    SELECT * FROM pedidos WHERE id = p_pedido_id;

    -- Consulta os itens do pedido
    SELECT ip.*, p.nome AS produto_nome
    FROM itens_pedido ip
    JOIN produtos p ON ip.produto_id = p.id
    WHERE ip.pedido_id = p_pedido_id;

    -- Consulta o cliente
    SELECT u.* 
    FROM pedidos pd
    JOIN usuarios u ON pd.cliente_id = u.id
    WHERE pd.id = p_pedido_id;
END$$

DELIMITER ;

Consutando a venda:

mysql> CALL consultar_venda(10);
+----+------------+---------------------+---------+-------+
| id | cliente_id | data_pedido         | status  | total |
+----+------------+---------------------+---------+-------+
| 10 |         10 | 2025-11-10 02:06:15 | Enviado | 25.00 |
+----+------------+---------------------+---------+-------+
1 row in set (0,01 sec)

+----+-----------+------------+------------+----------------+--------------------+
| id | pedido_id | produto_id | quantidade | preco_unitario | produto_nome       |
+----+-----------+------------+------------+----------------+--------------------+
| 10 |        10 |         10 |          1 |          25.00 | Café Gourmet 500g  |
+----+-----------+------------+------------+----------------+--------------------+
1 row in set (0,01 sec)

+----+--------------+--------------------------+-------------------+-----------------+----------------+---------------------+
| id | nome         | email                    | senha             | celular         | cpf            | criado_em           |
+----+--------------+--------------------------+-------------------+-----------------+----------------+---------------------+
| 10 | Rafael Gomes | rafael.gomes@example.com | rafael_gomes_pwd! | (84) 91111-2222 | 567.890.123-45 | 2025-11-10 02:06:15 |
+----+--------------+--------------------------+-------------------+-----------------+----------------+---------------------+
1 row in set (0,01 sec)

Query OK, 0 rows affected (0,01 sec)



Cenário 2: Auditoria de Estoque

CREATE TABLE IF NOT EXISTS auditoria_estoque (
    id INT PRIMARY KEY AUTO_INCREMENT,
    produto_id INT,
    quantidade_ajustada INT,
    motivo VARCHAR(255),
    data_ajuste TIMESTAMP
);

Procedure:

DELIMITER $$

CREATE PROCEDURE ajustar_estoque (
    IN p_produto_id INT,
    IN p_quantidade INT,
    IN p_motivo VARCHAR(255)
)
BEGIN
    START TRANSACTION;

    UPDATE produtos SET estoque = estoque + p_quantidade WHERE id = p_produto_id;

    INSERT INTO auditoria_estoque (produto_id, quantidade_ajustada, motivo, data_ajuste)
    VALUES (p_produto_id, p_quantidade, p_motivo, NOW());

    COMMIT;
END$$

DELIMITER ;

Executando a procedure:
CALL ajustar_estoque(5, 10, 'Reposição de estoque');

Cenário 3: Promoção-Relâmpago
START TRANSACTION;

-- Exemplo: categoria_id = 5, desconto de 20%
UPDATE produtos
SET preco = preco * 0.8
WHERE categoria_id = 5;

-- Verificação opcional
SELECT id, nome, preco FROM produtos WHERE categoria_id = 5;

-- Desfaz a promoção
ROLLBACK;

