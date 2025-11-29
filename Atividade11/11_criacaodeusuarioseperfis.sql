Módulo 1: Criação e Concessão (CREATE USER e GRANT)

Cenário P1: Gestor de Preços


-- 1. Criação do Usuário (acesso de qualquer host)
mysql>CREATE USER 'gestor_preco'@'%' IDENTIFIED BY 'preco_123';
Query OK, 0 rows affected (0,05 sec)

-- 2. Concede SELECT em toda a tabela Produto.
mysql>GRANT SELECT ON ecommerce.produtos TO 'gestor_preco'@'%';
Query OK, 0 rows affected (0,01 sec)

-- 3. Concede UPDATE APENAS na coluna 'preco'.
mysql> GRANT UPDATE (preco) ON ecommerce.produtos TO 'gestor_preco'@'%';
Query OK, 0 rows affected (0,01 sec)

Cenário P2: Atendente de Log

-- 1. Criação do Usuário
mysql> CREATE USER 'log_atend'@'%' IDENTIFIED BY 'log_456';
Query OK, 0 rows affected (0,05 sec)

-- 2. Concede SELECT nas três tabelas essenciais (acesso consultivo).
mysql> GRANT SELECT ON ecommerce.usuarios TO 'log_atend'@'%';
Query OK, 0 rows affected (0,01 sec)

mysql> GRANT SELECT ON ecommerce.pedidos TO 'log_atend'@'%';
Query OK, 0 rows affected (0,01 sec)

mysql> GRANT SELECT ON ecommerce.produtos TO 'log_atend'@'%';
Query OK, 0 rows affected (0,01 sec)

Cenário P3: Integração de Estoque

-- 1. Criação do Usuário (Geralmente local, mas usaremos '%' para simplicidade)
mysql> CREATE USER 'integracao_estoque'@'%' IDENTIFIED BY 'int_789';
Query OK, 0 rows affected (0,04 sec)

-- 2. Concede UPDATE e INSERT APENAS na coluna 'estoque'.
mysql> GRANT UPDATE (estoque) ON ecommerce.produtos TO 'integracao_estoque'@'%';
Query OK, 0 rows affected (0,01 sec)

mysql> GRANT INSERT (estoque) ON ecommerce.produtos TO 'integracao_estoque'@'%';
Query OK, 0 rows affected (0,01 sec)

Cenário P4: Auditor


-- 1. Criação do Usuário
mysql> CREATE USER 'auditor'@'localhost' IDENTIFIED BY 'audit_101';
Query OK, 0 rows affected (0,04 sec)

-- 2. Concede permissão de SELECT em *todos* os bancos de dados (*.*).
mysql> GRANT SELECT ON *.* TO 'auditor'@'localhost';
Query OK, 0 rows affected (0,01 sec)


Módulo 2: Correção e Exclusão (REVOKE e DROP USER)


Cenário R1: Correção de Falha (P1)


O Gestor de Preços (gestor_preco) precisa ser impedido de visualizar a coluna estoque para evitar conflitos de informação. Ele só deve ver o preço.

-- Revogar o SELECT geral na tabela Produto que foi concedido no P1.
mysql>REVOKE SELECT ON ecommerce.produtos FROM 'gestor_preco'@'%';
Query OK, 0 rows affected (0,01 sec)

-- Conceder o SELECT APENAS nas colunas que ele realmente precisa (id, nome, preco).
mysql>GRANT SELECT (id, nome, preco) ON ecommerce.produtos TO 'gestor_preco'@'%';
Query OK, 0 rows affected (0,01 sec)

Cenário R2: Desligamento (P3)
-- Revogar explicitamente as permissões concedidas.
mysql> REVOKE UPDATE (estoque) ON ecommerce.produtos FROM 'integracao_est
oque'@'%';
Query OK, 0 rows affected (0,01 sec)

mysql> REVOKE INSERT (estoque) ON ecommerce.produtos FROM 'integracao_est
oque'@'%';
Query OK, 0 rows affected (0,01 sec)


-- Excluir a conta de usuário permanentemente.
mysql> SELECT user, host FROM mysql.user;
+--------------------+-----------+
| user               | host      |
+--------------------+-----------+
| gestor_preco       | %         |
| integracao_estoque | %         |  <---
| log_atend          | %         |
| auditor            | localhost |
| mysql.infoschema   | localhost |
| mysql.session      | localhost |
| mysql.sys          | localhost |
| root               | localhost |
| vander             | localhost |
+--------------------+-----------+
9 rows in set (0,00 sec)

mysql> DROP USER 'integracao_estoque'@'%';
Query OK, 0 rows affected (0,02 sec)

mysql> SELECT user, host FROM mysql.user;
+------------------+-----------+
| user             | host      |
+------------------+-----------+
| gestor_preco     | %         |
| log_atend        | %         |
| auditor          | localhost |
| mysql.infoschema | localhost |
| mysql.session    | localhost |
| mysql.sys        | localhost |
| root             | localhost |
| vander           | localhost |
+------------------+-----------+
8 rows in set (0,00 sec)

mysql> 
