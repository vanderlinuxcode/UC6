-----------------------------------------------------------------------------------------
Função 1 - Calcular o Faturamento para o mês 11, ano 2025 para 
            o produto id informado no comando SELECT
-----------------------------------------------------------------------------------------


DELIMITER $$

-- Dropar a função antiga para recriá-la com o novo retorno
DROP FUNCTION IF EXISTS CALCULAR_FATURAMENTO_PRODUTO_MES;

CREATE FUNCTION CALCULAR_FATURAMENTO_PRODUTO_MES(
    p_produto_id INT,
    p_ano INT,
    p_mes INT
)
RETURNS VARCHAR(255) -- Novo tipo de retorno: string
READS SQL DATA
BEGIN
    DECLARE total_faturado DECIMAL(10, 2);
    DECLARE nome_produto VARCHAR(255);
    DECLARE resultado VARCHAR(255);

    -- 1. Obter o faturamento
    SELECT
        COALESCE(SUM(IP.quantidade * IP.preco_unitario), 0.00) INTO total_faturado
    FROM
        itens_pedido IP
    JOIN
        pedidos P ON IP.pedido_id = P.id
    WHERE
        IP.produto_id = p_produto_id
        AND P.status IN ('Entregue', 'Pago', 'Confirmado')
        AND YEAR(P.data_pedido) = p_ano
        AND MONTH(P.data_pedido) = p_mes;

    -- 2. Obter o nome do produto
    SELECT
        nome INTO nome_produto
    FROM
        produtos
    WHERE
        id = p_produto_id;

    -- 3. Formatar a string de saída
    SET resultado = CONCAT(
        'Produto: ', nome_produto, 
        ' | Faturamento em ', p_mes, '/', p_ano, ': R$ ', FORMAT(total_faturado, 2)
    );

    RETURN resultado;
END$$

DELIMITER ;

-----------------------------------------------------------------------------------------

- Resposta 1: Para produto id 1, ano 2025, mês 11:

mysql> SELECT CALCULAR_FATURAMENTO_PRODUTO_MES(1, 2025, 11);
+----------------------------------------------------------+
| CALCULAR_FATURAMENTO_PRODUTO_MES(1, 2025, 11)            |
+----------------------------------------------------------+
| Produto: Smartphone X | Faturamento em 11/2025: R$ 90.00 |
+----------------------------------------------------------+
1 row in set (0,01 sec)


- Resposta 2: Para produto id 2, ano 2025, mês 11:

mysql> SELECT CALCULAR_FATURAMENTO_PRODUTO_MES(2, 2025, 11);
+----------------------------------------------------------------+
| CALCULAR_FATURAMENTO_PRODUTO_MES(2, 2025, 11)                  |
+----------------------------------------------------------------+
| Produto: Notebook Gamer Pro | Faturamento em 11/2025: R$ 60.00 |
+----------------------------------------------------------------+
1 row in set (0,00 sec)


- Resposta 3: Para produto id 1, ano 2025, mês 11:

mysql> SELECT CALCULAR_FATURAMENTO_PRODUTO_MES(4, 2025, 11);
+-------------------------------------------------------------+
| CALCULAR_FATURAMENTO_PRODUTO_MES(4, 2025, 11)               |
+-------------------------------------------------------------+
| Produto: Camiseta Casual | Faturamento em 11/2025: R$ 50.00 |
+-------------------------------------------------------------+
1 row in set (0,00 sec)



-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
Função 2 - Função que informa a quantidade de produtos no estoque disponível para o id
            especificado obtendo como resposta o nome do produto, se possui reserva e se
            disponível para venda
-----------------------------------------------------------------------------------------

DELIMITER $$

-- Dropar a função antiga para recriá-la com o novo retorno
DROP FUNCTION IF EXISTS VERIFICAR_ESTOQUE_DISPONIVEL;

CREATE FUNCTION VERIFICAR_ESTOQUE_DISPONIVEL(
    p_produto_id INT
)
RETURNS VARCHAR(255) -- Novo tipo de retorno: string
READS SQL DATA
BEGIN
    DECLARE estoque_base INT;
    DECLARE estoque_reservado INT;
    DECLARE estoque_disponivel INT;
    DECLARE nome_produto VARCHAR(255);
    DECLARE resultado VARCHAR(255);

    -- 1. Obter estoque base e nome do produto
    SELECT
        estoque, nome INTO estoque_base, nome_produto
    FROM
        produtos
    WHERE
        id = p_produto_id;

    -- 2. Calcular o estoque reservado em pedidos 'Pendente' ou 'Confirmado'
    SELECT
        COALESCE(SUM(IP.quantidade), 0) INTO estoque_reservado
    FROM
        itens_pedido IP
    JOIN
        pedidos P ON IP.pedido_id = P.id
    WHERE
        IP.produto_id = p_produto_id
        AND P.status IN ('Pendente', 'Confirmado'); -- Status que reservam estoque

    -- 3. Calcular o estoque real
    SET estoque_disponivel = estoque_base - estoque_reservado;

    -- 4. Formatar a string de saída
    SET resultado = CONCAT(
        'Produto: ', nome_produto, 
        ' | Estoque Físico: ', estoque_base, 
        ' | Reservado (Pendente/Confirmado): ', estoque_reservado,
        ' | Disponível para Venda: ', estoque_disponivel
    );

    RETURN resultado;
END$$

DELIMITER ;

------------------------------------------------------------------------------------------------------------------

- Resposta 1:

mysql> SELECT VERIFICAR_ESTOQUE_DISPONIVEL(1);
+---------------------------------------------------------------------------------------------------------------+
| VERIFICAR_ESTOQUE_DISPONIVEL(1)                                                                               |
+---------------------------------------------------------------------------------------------------------------+
| Produto: Smartphone X | Estoque Físico: 47 | Reservado (Pendente/Confirmado): 3 | Disponível para Venda: 44   |
+---------------------------------------------------------------------------------------------------------------+
1 row in set (0,00 sec)


- Resposta 2:

mysql> SELECT VERIFICAR_ESTOQUE_DISPONIVEL(2);
+--------------------------------------------------------------------------------------------------------------------+
| VERIFICAR_ESTOQUE_DISPONIVEL(2)                                                                                    |
+--------------------------------------------------------------------------------------------------------------------+
| Produto: Notebook Gamer Pro | Estoque Físico: 10 | Reservado (Pendente/Confirmado): 2 | Disponível para Venda: 8   |
+--------------------------------------------------------------------------------------------------------------------+
1 row in set (0,01 sec)


- Resposta 3:

mysql> SELECT VERIFICAR_ESTOQUE_DISPONIVEL(4);
+--------------------------------------------------------------------------------------------------------------------+
| VERIFICAR_ESTOQUE_DISPONIVEL(4)                                                                                    |
+--------------------------------------------------------------------------------------------------------------------+
| Produto: Camiseta Casual | Estoque Físico: 150 | Reservado (Pendente/Confirmado): 0 | Disponível para Venda: 150   |
+--------------------------------------------------------------------------------------------------------------------+
1 row in set (0,00 sec)



-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
Função 3 - Total Bruto: Soma de (preco * estoque) de todos os produtos.

Imposto (18%): Total Bruto * 0.18.

Total Líquido: Total Bruto - Imposto.
-----------------------------------------------------------------------------------------------------------------------

DELIMITER $$

DROP FUNCTION IF EXISTS CALCULAR_VALOR_TOTAL_GLOBAL;

CREATE FUNCTION CALCULAR_VALOR_TOTAL_GLOBAL()
RETURNS VARCHAR(255) -- Retorna uma string formatada
READS SQL DATA
BEGIN
    DECLARE total_bruto DECIMAL(15, 2);
    DECLARE valor_imposto DECIMAL(15, 2);
    DECLARE total_liquido DECIMAL(15, 2);
    DECLARE ALIQ_IMPOSTO DECIMAL(5, 2) DEFAULT 0.18; -- 18% de alíquota (simulação)
    DECLARE resultado VARCHAR(255);

    -- 1. CALCULAR O VALOR TOTAL BRUTO DE TODOS OS PRODUTOS EM ESTOQUE
    -- (Soma do Preço de cada produto * Quantidade em Estoque)
    SELECT
        COALESCE(SUM(preco * estoque), 0.00) INTO total_bruto
    FROM
        produtos;

    -- 2. CALCULAR IMPOSTO E VALOR LÍQUIDO
    SET valor_imposto = total_bruto * ALIQ_IMPOSTO;
    SET total_liquido = total_bruto - valor_imposto;

    -- 3. FORMATAR A STRING DE SAÍDA (Concatenando os resultados)
    SET resultado = CONCAT(
        'VALORIZAÇÃO GLOBAL DO ESTOQUE:',
        ' | Total Bruto (Venda): R$ ', FORMAT(total_bruto, 2),
        ' | Imposto Simulado (18%): R$ ', FORMAT(valor_imposto, 2),
        ' | Total Líquido (s/ Imposto): R$ ', FORMAT(total_liquido, 2)
    );

    RETURN resultado;
END$$

DELIMITER ;


-----------------------------------------------------------------------------------------------------------------------
- Resposta 

mysql> SELECT CALCULAR_VALOR_TOTAL_GLOBAL();
+-----------------------------------------------------------------------------------------------------------------------------------------------------------+
| CALCULAR_VALOR_TOTAL_GLOBAL()                                                                                                                             |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------+
| VALORIZAÇÃO GLOBAL DO ESTOQUE: | Total Bruto (Venda): R$ 384,205.00 | Imposto Simulado (18%): R$ 69,156.90 | Total Líquido (s/ Imposto): R$ 315,048.10    |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0,00 sec)
