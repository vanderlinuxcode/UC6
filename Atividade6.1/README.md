Segue atividade 6.1:

mysql> select * from enderecos where estado = 'SP';
+----+------------+-----------------------+--------+---------+------------+--------+-----------+
| id | cliente_id | rua                   | numero | bairro  | cidade     | estado | cep       |
+----+------------+-----------------------+--------+---------+------------+--------+-----------+
|  1 |          1 | Rua das Flores        | 123    | Centro  | São Paulo  | SP     | 01000-000 |
| 18 |         18 | Avenida das Américas  | 666    | Jardins | São Paulo  | SP     | 01234-567 |
| 20 |         20 | Rua do Cedro          | 888    | Moema   | São Paulo  | SP     | 04000-123 |
+----+------------+-----------------------+--------+---------+------------+--------+-----------+
3 rows in set (0,00 sec)


mysql> select * from usuarios where nome like 'A%';
+----+-----------------+----------------------------+-----------------+-----------------+----------------+---------------------+
| id | nome            | email                      | senha           | celular         | cpf            | criado_em           |
+----+-----------------+----------------------------+-----------------+-----------------+----------------+---------------------+
|  1 | Ana Clara Silva | anaclara.silva@example.com | senha123!       | (11) 98765-4321 | 123.456.789-01 | 2025-11-10 02:06:15 |
| 18 | Ana Paula Gomes | anapaula.gomes@example.org | anapaula_g@2024 | (94) 92222-6666 | 901.234.567-90 | 2025-11-10 02:06:15 |
| 24 | Amanda Rocha    | amanda.rocha@example.org   | amanda_r_pwd#   | (11) 99888-7777 | 789.012.345-89 | 2025-11-10 02:06:15 |
+----+-----------------+----------------------------+-----------------+-----------------+----------------+---------------------+
3 rows in set (0,01 sec)

SELECT u.nome AS nome_cliente,  SUM(ip.quantidade) AS total_itens,   p.total AS valor_total_pedido   FROM pedidos AS p  JOIN usuarios AS u ON p.cliente_id = u.id   JOIN itens_pedido AS ip ON p.id = pedido_id  GROUP BY u.nome, p.total;
+------------------------+-------------+--------------------+
| nome_cliente           | total_itens | valor_total_pedido |
+------------------------+-------------+--------------------+
| Ana Clara Silva        |           1 |             180.00 |
| João Pedro Santos      |           1 |            2500.00 |
| Maria Eduarda Oliveira |           1 |              35.50 |
| Pedro Henrique Costa   |           1 |              50.00 |
| Juliana Almeida        |           1 |             400.00 |
| Carlos Roberto Souza   |           1 |             120.00 |
| Mariana Ferreira       |           1 |              85.00 |
| Gabriel Lima           |           1 |              60.00 |
| Larissa Mendes         |           1 |              45.00 |
| Rafael Gomes           |           1 |              25.00 |
| Isabela Martins        |           1 |              70.00 |
| Lucas Santos           |           1 |              40.00 |
| Beatriz Pires          |           1 |              30.00 |
| Fernanda Costa         |           1 |             250.00 |
| Gustavo Souza          |           1 |              20.00 |
| Camila Rocha           |           1 |              90.00 |
| Felipe Oliveira        |           1 |              15.00 |
| Ana Paula Gomes        |           1 |            1200.00 |
| Daniel Fernandes       |           1 |            2000.00 |
| Luiza Ribeiro          |           1 |             180.00 |
| Guilherme Castro       |           1 |             100.00 |
| Sofia Lima             |           1 |              65.00 |
| Rodrigo Barbosa        |           1 |             150.00 |
| Amanda Rocha           |           1 |             300.00 |
| Vitor Gomes            |           1 |              25.00 |
| Bruna Fernandes        |           1 |             180.00 |
| Thiago Lima            |           1 |             800.00 |
| Paula Ribeiro          |           1 |             110.00 |
| Eduardo Martins        |           1 |             120.00 |
| Julia Dias             |           1 |             950.00 |
| Ana Clara Silva        |           5 |             150.00 |
+------------------------+-------------+--------------------+
31 rows in set (0,00 sec)

mysql> select * from categorias order by id asc limit 10;
+----+---------------------+------------------------------------------------------+
| id | nome                | descricao                                            |
+----+---------------------+------------------------------------------------------+
|  1 | Eletrônicos         | Dispositivos eletrônicos e gadgets.                  |
|  2 | Livros              | Livros de ficção, não ficção, e literatura.          |
|  3 | Roupas              | Vestuário masculino, feminino e infantil.            |
|  4 | Casa & Decoração    | Artigos para o lar e decoração.                      |
|  5 | Esportes            | Equipamentos e acessórios para atividades físicas.   |
|  6 | Beleza & Saúde      | Produtos de cuidados pessoais e bem-estar.           |
|  7 | Brinquedos          | Brinquedos para crianças e jogos.                    |
|  8 | Ferramentas         | Ferramentas manuais e elétricas.                     |
|  9 | Alimentos & Bebidas | Produtos alimentícios e bebidas.                     |
| 10 | Jardinagem          | Equipamentos e acessórios para jardinagem.           |
+----+---------------------+------------------------------------------------------+
10 rows in set (0,00 sec)

mysql> select u.nome, p.status
    -> from usuarios as u
    -> join pedidos as p on u.id = p.cliente_id;
+------------------------+------------+
| nome                   | status     |
+------------------------+------------+
| Ana Clara Silva        | Pago       |
| Ana Clara Silva        | Confirmado |
| João Pedro Santos      | Enviado    |
| Maria Eduarda Oliveira | Cancelado  |
| Pedro Henrique Costa   | Pago       |
| Juliana Almeida        | Enviado    |
| Carlos Roberto Souza   | Pago       |
| Mariana Ferreira       | Enviado    |
| Gabriel Lima           | Pago       |
| Larissa Mendes         | Cancelado  |
| Rafael Gomes           | Enviado    |
| Isabela Martins        | Pago       |
| Lucas Santos           | Enviado    |
| Beatriz Pires          | Pago       |
| Fernanda Costa         | Cancelado  |
| Gustavo Souza          | Pago       |
| Camila Rocha           | Enviado    |
| Felipe Oliveira        | Pendente   |
| Ana Paula Gomes        | Pago       |
| Daniel Fernandes       | Enviado    |
| Luiza Ribeiro          | Pago       |
| Guilherme Castro       | Enviado    |
| Sofia Lima             | Pago       |
| Rodrigo Barbosa        | Enviado    |
| Amanda Rocha           | Pendente   |
| Vitor Gomes            | Cancelado  |
| Bruna Fernandes        | Pago       |
| Thiago Lima            | Enviado    |
| Paula Ribeiro          | Pendente   |
| Eduardo Martins        | Pago       |
| Julia Dias             | Enviado    |
+------------------------+------------+
31 rows in set (0,00 sec)

