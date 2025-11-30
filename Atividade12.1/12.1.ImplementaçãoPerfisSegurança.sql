Desafio Prático: Implementação de Perfis e Segurança

Módulo 1: Criação de Usuários

SHOW GRANTS FOR 'suporte_ti'@'localhost';
+-------------------------------------------------------------------------------+
| Grants for suporte_ti@localhost                                               |
+-------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `suporte_ti`@`localhost`                                |
| GRANT SELECT, INSERT, UPDATE ON `nome_do_banco`.* TO `suporte_ti`@`localhost` |
+-------------------------------------------------------------------------------+
2 rows in set (0,00 sec)

SHOW GRANTS FOR 'bi_analista'@'%';
+-----------------------------------------+
| Grants for bi_analista@%                |
+-----------------------------------------+
| GRANT USAGE ON *.* TO `bi_analista`@`%` |
+-----------------------------------------+
1 row in set (0,01 sec)

SHOW GRANTS FOR 'devolucoes'@'%';
+----------------------------------------+
| Grants for devolucoes@%                |
+----------------------------------------+
| GRANT USAGE ON *.* TO `devolucoes`@`%` |
+----------------------------------------+
1 row in set (0,00 sec)

SHOW GRANTS FOR 'teste_dev'@'localhost';
+-----------------------------------------------+
| Grants for teste_dev@localhost                |
+-----------------------------------------------+
| GRANT USAGE ON *.* TO `teste_dev`@`localhost` |
+-----------------------------------------------+
1 row in set (0,00 sec)


-- Se precisar alterar a senha:
ALTER USER 'suporte_ti'@'localhost' IDENTIFIED BY 'NovaSenhaSegura123!';


Módulo 2: Concessão de Permissões

U1 - Usuário: suporte_ti

-- Conceder permissão para criar VIEW no banco ecommerce
GRANT CREATE VIEW ON ecommerce.* TO 'suporte_ti'@'localhost';

-- Conceder permissão para criar ROUTINE (procedures/functions) no banco ecommerce
GRANT CREATE ROUTINE ON ecommerce.* TO 'suporte_ti'@'localhost';

-- Atualizar privilégios
FLUSH PRIVILEGES;

SHOW GRANTS FOR 'suporte_ti'@'localhost';
+--------------------------------------------------------------------------------+
| Grants for suporte_ti@localhost                                                |
+--------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `suporte_ti`@`localhost`                                 |
| GRANT CREATE VIEW, CREATE ROUTINE ON `ecommerce`.* TO `suporte_ti`@`localhost` |
| GRANT SELECT, INSERT, UPDATE ON `nome_do_banco`.* TO `suporte_ti`@`localhost`  |
+--------------------------------------------------------------------------------+
3 rows in set (0,00 sec)

U2 - Usuário: bi_analista

GRANT SELECT ON ecommerce.* TO 'bi_analista'@'%';
Query OK, 0 rows affected (0,01 sec)

SHOW GRANTS FOR 'bi_analista'@'%';
+----------------------------------------------------+
| Grants for bi_analista@%                           |
+----------------------------------------------------+
| GRANT USAGE ON *.* TO `bi_analista`@`%`            |
| GRANT SELECT ON `ecommerce`.* TO `bi_analista`@`%` |
+----------------------------------------------------+
2 rows in set (0,00 sec)

U3 - Usuário: devolucoes

mysql> GRANT SELECT ON ecommerce.pedidos TO 'devolucoes'@'%';
Query OK, 0 rows affected (0,01 sec)

mysql> GRANT DELETE ON ecommerce.itens_pedido TO 'devolucoes'@'%';
Query OK, 0 rows affected (0,01 sec)

-- Atualizar privilégios
FLUSH PRIVILEGES;

SHOW GRANTS FOR 'devolucoes'@'%';
+----------------------------------------------------------------+
| Grants for devolucoes@%                                        |
+----------------------------------------------------------------+
| GRANT USAGE ON *.* TO `devolucoes`@`%`                         |
| GRANT DELETE ON `ecommerce`.`itens_pedido` TO `devolucoes`@`%` |
| GRANT SELECT ON `ecommerce`.`pedidos` TO `devolucoes`@`%`      |
+----------------------------------------------------------------+
3 rows in set (0,00 sec)

U4 - Usuário: teste_dev

mysql> GRANT DROP ON *.* TO 'teste_dev'@'localhost';
Query OK, 0 rows affected (0,00 sec)

mysql> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0,01 sec)

SHOW GRANTS FOR 'teste_dev'@'localhost';
+----------------------------------------------+
| Grants for teste_dev@localhost               |
+----------------------------------------------+
| GRANT DROP ON *.* TO `teste_dev`@`localhost` |
+----------------------------------------------+
1 row in set (0,00 sec)

📜 Script Final – Módulo 2: Concessão de Permissões

-- ==========================
-- U1: Suporte Técnico (suporte_ti)
-- Permissão para criar VIEW e ROUTINE apenas no banco ecommerce
-- ==========================
GRANT CREATE VIEW ON ecommerce.* TO 'suporte_ti'@'localhost';
GRANT CREATE ROUTINE ON ecommerce.* TO 'suporte_ti'@'localhost';

-- ==========================
-- U2: Analista de BI (bi_analista)
-- Permissão de SELECT em todas as tabelas do banco ecommerce
-- ==========================
GRANT SELECT ON ecommerce.* TO 'bi_analista'@'%';

-- ==========================
-- U3: Gerente de Devoluções (devolucoes)
-- Permissão de SELECT apenas na tabela pedidos
-- Permissão de DELETE apenas na tabela itens_pedido
-- ==========================
GRANT SELECT ON ecommerce.pedidos TO 'devolucoes'@'%';
GRANT DELETE ON ecommerce.itens_pedido TO 'devolucoes'@'%';

-- ==========================
-- U4: Usuário de Teste (teste_dev)
-- Permissão global de DROP TABLE em qualquer banco do servidor
-- ==========================
GRANT DROP ON *.* TO 'teste_dev'@'localhost';

-- Aplicar todas as mudanças
FLUSH PRIVILEGES;



Módulo 3: Desafio de Segurança e Correção

1 - Revogue o acesso total de SELECT na tabela Cliente que foi dado no Módulo 2.

mysql> SHOW GRANTS FOR 'bi_analista'@'%';
+-----------------------------------------------------------------------------------------------------------------------------+
| Grants for bi_analista@%                                                                                                    |
+-----------------------------------------------------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `bi_analista`@`%`                                                                                     |
| GRANT SELECT ON `ecommerce`.* TO `bi_analista`@`%`                                                                          |
| GRANT SELECT (`celular`, `cpf`, `criado_em`, `email`, `id`, `nome`, `senha`) ON `ecommerce`.`usuarios` TO `bi_analista`@`%` |
+-----------------------------------------------------------------------------------------------------------------------------+
3 rows in set (0,00 sec)


mysql> REVOKE SELECT ON ecommerce.usuarios FROM 'bi_analista'@'%';
Query OK, 0 rows affected (0,01 sec)


mysql> SHOW GRANTS FOR 'bi_analista'@'%';
+----------------------------------------------------+
| Grants for bi_analista@%                           |
+----------------------------------------------------+
| GRANT USAGE ON *.* TO `bi_analista`@`%`            |
| GRANT SELECT ON `ecommerce`.* TO `bi_analista`@`%` |
+----------------------------------------------------+
2 rows in set (0,00 sec)


2 - Re-conceda o SELECT na tabela Cliente excluindo a coluna senha_hash.

mysql> SHOW GRANTS FOR 'bi_analista'@'%';
+-----------------------------------------------------------------------------------------------------------------------------+
| Grants for bi_analista@%                                                                                                    |
+-----------------------------------------------------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `bi_analista`@`%`                                                                                     |
| GRANT SELECT ON `ecommerce`.* TO `bi_analista`@`%`                                                                          |
| GRANT SELECT (`celular`, `cpf`, `criado_em`, `email`, `id`, `nome`, `senha`) ON `ecommerce`.`usuarios` TO `bi_analista`@`%` |
+-----------------------------------------------------------------------------------------------------------------------------+
3 rows in set (0,00 sec)

mysql> REVOKE SELECT ON ecommerce.usuarios FROM 'bi_analista'@'%';
Query OK, 0 rows affected (0,01 sec)

mysql> SHOW GRANTS FOR 'bi_analista'@'%';
+----------------------------------------------------+
| Grants for bi_analista@%                           |
+----------------------------------------------------+
| GRANT USAGE ON *.* TO `bi_analista`@`%`            |
| GRANT SELECT ON `ecommerce`.* TO `bi_analista`@`%` |
+----------------------------------------------------+
2 rows in set (0,00 sec)

mysql> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0,01 sec)


-- Após correção da falha de segurança onde se expõem a senha do cliente/usuario


mysql> GRANT SELECT (id, nome, email, celular, cpf, criado_em) ON ecommerce.usuarios TO 'bi_analista'@'%';
Query OK, 0 rows affected (0,01 sec)

mysql> SHOW GRANTS FOR 'bi_analista'@'%';
+--------------------------------------------------------------------------------------------------------------------+
| Grants for bi_analista@%                                                                                           |
+--------------------------------------------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `bi_analista`@`%`                                                                            |
| GRANT SELECT ON `ecommerce`.* TO `bi_analista`@`%`                                                                 |
| GRANT SELECT (`celular`, `cpf`, `criado_em`, `email`, `id`, `nome`) ON `ecommerce`.`usuarios` TO `bi_analista`@`%` |
+--------------------------------------------------------------------------------------------------------------------+
3 rows in set (0,00 sec)

mysql> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0,01 sec)
