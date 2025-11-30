Desafio 1: Controle de Estoque (Automação de Processos)
 
Verificando Estoque inicial:

SELECT id, nome, estoque FROM produtos WHERE id = 2;
+----+--------------------+---------+
| id | nome               | estoque |
+----+--------------------+---------+
|  2 | Notebook Gamer Pro |      13 |
+----+--------------------+---------+
1 row in set (0,01 sec)

 mysql>INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario) VALUES (2, 2, 3, 50.00);
		Query OK, 1 row affected (0,01 sec)

SELECT id, nome, estoque FROM produtos WHERE id = 2;
+----+--------------------+---------+
| id | nome               | estoque |
+----+--------------------+---------+
|  2 | Notebook Gamer Pro |      10 |
+----+--------------------+---------+
1 row in set (0,00 sec)


Desafio 2: Log de Status (Auditoria de Dados)

Trigger criado:

DELIMITER $$

CREATE TRIGGER log_status_pedidos
AFTER UPDATE ON pedidos
FOR EACH ROW
BEGIN
    -- 1. Verifica se o status mudou
    IF OLD.status <> NEW.status THEN

        -- 2. Insere um registro no log
        INSERT INTO log_status_pedidos (
            pedido_id,
            status_antigo,
            status_novo,
            data_mudanca
        )
        VALUES (
            OLD.id,          -- id do pedido que foi alterado
            OLD.status,      -- status antes da alteração
            NEW.status,      -- status depois da alteração
            NOW()            -- data/hora da mudança
        );

    END IF;
END$$

DELIMITER ;

 
 mysql> select * from pedidos where id = 34;
+----+------------+---------------------+-------------+--------+
| id | cliente_id | data_pedido         | status      | total  |
+----+------------+---------------------+-------------+--------+
| 34 |         10 | 2025-11-30 12:07:36 | Processando | 150.00 |
+----+------------+---------------------+-------------+--------+
1 row in set (0,00 sec)


mysql> select * from log_status_pedidos;
+----+-----------+---------------+-------------+---------------------+
| id | pedido_id | status_antigo | status_novo | data_mudanca        |
+----+-----------+---------------+-------------+---------------------+
|  1 |       123 | Processando   | Enviado     | 2025-11-30 12:01:24 |
+----+-----------+---------------+-------------+---------------------+
1 row in set (0,00 sec)

select * from log_status_pedidos;
+----+-----------+---------------+-------------+---------------------+
| id | pedido_id | status_antigo | status_novo | data_mudanca        |
+----+-----------+---------------+-------------+---------------------+
|  1 |       123 | Processando   | Enviado     | 2025-11-30 12:01:24 |
|  2 |         1 | Pago          | Enviado     | 2025-11-30 12:09:56 |
|  3 |         1 | Pago          | Enviado     | 2025-11-30 12:09:56 |
|  4 |        34 | Processando   | Enviado     | 2025-11-30 12:10:04 |
|  5 |        34 | Processando   | Enviado     | 2025-11-30 12:10:04 |
|  6 |        33 | Pendente      | Enviado     | 2025-11-30 12:10:48 |
|  7 |        33 | Pendente      | Enviado     | 2025-11-30 12:10:48 |
+----+-----------+---------------+-------------+---------------------+
7 rows in set (0,00 sec)

mysql> select * from log_status_pedidos;
+----+-----------+---------------+-------------+---------------------+
| id | pedido_id | status_antigo | status_novo | data_mudanca        |
+----+-----------+---------------+-------------+---------------------+
|  1 |       123 | Processando   | Enviado     | 2025-11-30 12:01:24 |
|  2 |         1 | Pago          | Enviado     | 2025-11-30 12:09:56 |
|  3 |         1 | Pago          | Enviado     | 2025-11-30 12:09:56 |
|  4 |        34 | Processando   | Enviado     | 2025-11-30 12:10:04 |
|  5 |        34 | Processando   | Enviado     | 2025-11-30 12:10:04 |
|  6 |        33 | Pendente      | Enviado     | 2025-11-30 12:10:48 |
|  7 |        33 | Pendente      | Enviado     | 2025-11-30 12:10:48 |
|  8 |         1 | Enviado       | Entregue    | 2025-11-30 12:12:21 |
|  9 |         1 | Enviado       | Entregue    | 2025-11-30 12:12:21 |
| 10 |        34 | Enviado       | Entregue    | 2025-11-30 12:12:43 |
| 11 |        34 | Enviado       | Entregue    | 2025-11-30 12:12:43 |
| 12 |        33 | Enviado       | Entregue    | 2025-11-30 12:12:48 |
| 13 |        33 | Enviado       | Entregue    | 2025-11-30 12:12:48 |
+----+-----------+---------------+-------------+---------------------+
13 rows in set (0,01 sec)

consultando o histórico completo de mudanças de status de um pedido usando a tabela log_status_pedidos.

mysql> SELECT pedido_id, status_antigo, status_novo, data_mudanca FROM log_status_pedidos WHERE pedido_id = 33 ORDER BY data_muda
nca;
+-----------+---------------+-------------+---------------------+
| pedido_id | status_antigo | status_novo | data_mudanca        |
+-----------+---------------+-------------+---------------------+
|        33 | Pendente      | Enviado     | 2025-11-30 12:10:48 |
|        33 | Pendente      | Enviado     | 2025-11-30 12:10:48 |
|        33 | Enviado       | Entregue    | 2025-11-30 12:12:48 |
|        33 | Enviado       | Entregue    | 2025-11-30 12:12:48 |
+-----------+---------------+-------------+---------------------+
4 rows in set (0,00 sec)


 Desafio 3: Validação de Clientes (Qualidade e Padronização)

Trigger criado:

DELIMITER $$

CREATE TRIGGER trg_validacao_usuarios
BEFORE INSERT ON usuarios
FOR EACH ROW
BEGIN
    -- 1. Padroniza o nome em maiúsculas
    SET NEW.nome = UPPER(NEW.nome);

    -- 2. Valida o CPF: não pode ser NULL nem vazio
    IF NEW.cpf IS NULL OR NEW.cpf = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Erro: CPF não pode ser nulo ou vazio';
    END IF;
END$$

DELIMITER ;


1 - Padronização nome com nome todo em letras maiúsculas:

mysql> select nome from usuarios where id = 32;
+--------------+
| nome         |
+--------------+
| CARLOS SILVA |
+--------------+
1 row in set (0,00 sec)


2 - Erro para criação de usuário com campo CPF vazio:

mysql> INSERT INTO usuarios (id, nome, email, senha, celular, cpf, criado_em) VALUES (34, 'João Silva', 'joao@email.com', '123456', '999999999', '
', NOW());
ERROR 1644 (45000): Erro: CPF não pode ser nulo ou vazio



-- Comando para verificar as triggers criada no banco:
mysql> show triggers like 'nome tabela';


-- Comando para remover o Gatilho (TRIGGERS)
mysql> DROP TRIGGER IF EXISTS 'nome da trigger';