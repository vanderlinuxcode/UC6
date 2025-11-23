1 - Lista de medicamentos prestes a vencer (<30 dias) com a quantidade em estoque.

 SELECT     m.nome AS Nome_Medicamento,     e.lote AS Lote_Vencendo,     e.validade_lote AS Data_Vencimento,     e.quantidade AS Quantidade_Em_Estoque FROM     estoque e JOIN     medicamentos m ON e.codigo_medicamento = m.codigo WHERE     e.validade_lote <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)     AND e.validade_lote >= CURDATE()
AND e.quantidade > 0 ORDER BY     e.validade_lote ASC;
Empty set (0,00 sec)

1.1 - Lista de medicamentos prestes a vencer (<60 dias) com a quantidade em estoque.


mysql> SELECT     m.nome AS Nome_Medicamento,     e.lote AS Lote_Vencendo,     e.validade_lote AS Data_Vencimento,     e.quantidade AS Quantidade_Em_Estoque FROM     estoque e JOIN     medicamentos m ON e.codigo_medicamento = m.codigo WHERE     e.validade_lote <= DATE_ADD(CURDATE(), INTERVAL 60 DAY)     AND e.validade_lote >= CURDATE()
AND e.quantidade > 0 ORDER BY     e.validade_lote ASC;
+------------------+---------------+-----------------+-----------------------+
| Nome_Medicamento | Lote_Vencendo | Data_Vencimento | Quantidade_Em_Estoque |
+------------------+---------------+-----------------+-----------------------+
| Amoxicilina      | AMX-001A      | 2025-12-31      |                    50 |
+------------------+---------------+-----------------+-----------------------+
1 row in set (0,00 sec)

2 - Ranking dos 10 medicamentos mais vendidos por quantidade.

SELECT m.nome AS Nome_Medicamento, SUM(iv.quantidade) AS Total_Unidades_Vendidas FROM itens_venda iv JOIN medicamentos m ON iv.codigo_medicamento = m.codigo GROUP B
Y m.codigo, m.nome ORDER BY Total_Unidades_Vendidas DESC LIMIT 10;
+-------------------+-------------------------+
| Nome_Medicamento  | Total_Unidades_Vendidas |
+-------------------+-------------------------+
| Penicilina G      |                       3 |
| Metformina 500mg  |                       3 |
| Amoxicilina       |                       2 |
| Ibuprofeno Gel    |                       2 |
| Insulina NPH      |                       2 |
| Sinvastatina 10mg |                       2 |
| Dipirona 500mg    |                       1 |
| Creme Hidratante  |                       1 |
| Paracetamol Gotas |                       1 |
| Propranolol 40mg  |                       1 |
+-------------------+-------------------------+
10 rows in set (0,01 sec)

3 - Clientes que mais compraram medicamentos controlados (por tipo na tabela Medicamentos).

SELECT c.nome AS Nome_Cliente, c.cpf AS CPF_Cliente, SUM(iv.quantidade) AS Total_Unidades_Compradas_Injetavel FROM clientes c JOIN vendas v ON c.cpf = v.cpf_cliente JOIN itens_venda iv ON v.id = iv.id_venda JOIN medicamentos m ON iv.codigo_medicamento = m.codigo WHERE m.tipo = 'INJETAVEL' GROUP BY c.cpf, c.nome ORDER BY Total_Unidades_Compradas_Injetavel DESC;
+---------------+----------------+------------------------------------+
| Nome_Cliente  | CPF_Cliente    | Total_Unidades_Compradas_Injetavel |
+---------------+----------------+------------------------------------+
| Daniel Alves  | 444.444.444-44 |                                  2 |
| Kleber Mendes | 120.120.120-12 |                                  2 |
| Felipe Gomes  | 666.666.666-66 |                                  1 |
+---------------+----------------+------------------------------------+
3 rows in set (0,01 sec)

4 - Total de vendas por período (dia, semana, mês).

SELECT     c.nome AS Nome_Cliente,     c.cpf AS CPF_Cliente,     SUM(iv.quantidade) AS Total_Unidades_Compradas FROM     clientes c JOIN     vendas v ON c.cpf = v.cpf_cliente JOIN     itens_venda iv ON v.id = iv.id_venda JOIN     medicamentos m ON iv.codigo_medicamento = m.codigo WHERE     m.tipo = 'INJETAVEL' GROUP BY     c.cpf, c.nome ORDER BY     Total_Unidades_Compradas DESC;
+---------------+----------------+--------------------------+
| Nome_Cliente  | CPF_Cliente    | Total_Unidades_Compradas |
+---------------+----------------+--------------------------+
| Daniel Alves  | 444.444.444-44 |                        2 |
| Kleber Mendes | 120.120.120-12 |                        2 |
| Felipe Gomes  | 666.666.666-66 |                        1 |
+---------------+----------------+--------------------------+
3 rows in set (0,00 sec)

5 - Total de vendas por forma de pagamento.

SELECT     p.forma AS Forma_de_Pagamento,     SUM(v.valor_total) AS Total_Arrecadado,     COUNT(v.id) AS Total_Transacoes FROM     pagamentos p JOIN     vendas v ON p.id_venda = v.id GROUP BY     p.forma ORDER BY     Total_Arrecadado DESC;
+--------------------+------------------+------------------+
| Forma_de_Pagamento | Total_Arrecadado | Total_Transacoes |
+--------------------+------------------+------------------+
| CREDITO            |           306.70 |                5 |
| DEBITO             |           281.69 |                5 |
| PIX                |           107.95 |                5 |
| CONVENIO           |            88.00 |                1 |
| DINHEIRO           |            65.49 |                4 |
+--------------------+------------------+------------------+
5 rows in set (0,00 sec)


6 - Itens em estoque abaixo de um limite mínimo.

SELECT     m.nome AS Nome_Medicamento,     SUM(e.quantidade) AS Estoque_Total_Atual FROM     estoque e JOIN     medicamentos m ON e.codigo_medicamento = m.codigo GROUP BY     m.codigo, m.nome HAVING     Estoque_Total_Atual < 50 ORDER BY     Estoque_Total_Atual ASC;
+------------------+---------------------+
| Nome_Medicamento | Estoque_Total_Atual |
+------------------+---------------------+
| Penicilina G     |                  25 |
| Insulina NPH     |                  30 |
| Vacina Gripe     |                  40 |
+------------------+---------------------+
3 rows in set (0,01 sec)

7 - Médicos que mais prescreveram receitas.

SELECT     m.nome AS Nome_Medico,     m.crm AS CRM,     COUNT(r.id) AS Total_Receitas_Prescritas FROM     medicos m JOIN     receitas_medicas r ON m.crm = r.crm_medico GROUP BY     m.crm, m.nome ORDER BY     Total_Receitas_Prescritas DESC;
+----------------------+---------------+---------------------------+
| Nome_Medico          | CRM           | Total_Receitas_Prescritas |
+----------------------+---------------+---------------------------+
| Dra. Carolina Pires  | CRM/DF 334455 |                         5 |
| Dra. Alice Rocha     | CRM/ES 556677 |                         4 |
| Dra. Helena Costa    | CRM/PE 778899 |                         3 |
| Dr. Pedro Henrique   | CRM/MG 345678 |                         2 |
| Dra. Viviane Teles   | CRM/PR 222111 |                         1 |
| Dr. Alexandre Souza  | CRM/MG 111000 |                         1 |
| Dra. Vanessa Dias    | CRM/AM 990011 |                         1 |
| Dra. Sofia Lima      | CRM/PR 901234 |                         1 |
| Dra. Patricia Lima   | CRM/MS 102030 |                         1 |
| Dra. Maria Oliveira  | CRM/RJ 789012 |                         1 |
| Dra. Gisele Mendes   | CRM/SP 708090 |                         1 |
| Dra. Bruna Santos    | CRM/RS 112233 |                         1 |
| Dr. Tiago Matos      | CRM/GO 667788 |                         1 |
| Dr. Roberto Alves    | CRM/MT 889900 |                         1 |
| Dr. Ricardo Neves    | CRM/BA 445566 |                         1 |
| Dr. Lucas Silveira   | CRM/SC 567890 |                         1 |
| Dr. João Pereira     | CRM/SP 123456 |                         1 |
| Dr. Gabriel Ferreira | CRM/CE 001122 |                         1 |
| Dr. Felipe Barros    | CRM/RJ 405060 |                         1 |
| Dr. Eduardo Nunes    | CRM/PA 223344 |                         1 |
+----------------------+---------------+---------------------------+
20 rows in set (0,01 sec)

8 - Funcionários que mais realizaram vendas (por quantidade de vendas ou valor total).

SELECT     f.nome AS Nome_Atendente,     f.matricula AS Matricula,     f.cargo AS Cargo,     SUM(v.valor_total) AS Total_Vendido_Financeiro FROM     funcionarios f
JOIN     vendas v ON f.matricula = v.matricula_atendente GROUP BY     f.matricula, f.nome, f.cargo ORDER BY     Total_Vendido_Financeiro DESC;
+----------------+-----------+-----------+--------------------------+
| Nome_Atendente | Matricula | Cargo     | Total_Vendido_Financeiro |
+----------------+-----------+-----------+--------------------------+
| Ricardo Mendes | F002      | ATENDENTE |                   339.00 |
| Daniel Costa   | F009      | ATENDENTE |                   278.05 |
| Carlos Lima    | F005      | ATENDENTE |                   122.20 |
| Ana Silva      | F004      | ATENDENTE |                    60.89 |
| Luiza Santos   | F010      | ATENDENTE |                    49.69 |
+----------------+-----------+-----------+--------------------------+
5 rows in set (0,00 sec)


9 - Valor total vendido por cada fornecedor.

SELECT     f.razao_social AS Nome_Fornecedor,     f.cnpj AS CNPJ_Fornecedor,     SUM(iv.valor_unitario * iv.quantidade) AS Valor_Total_Vendido_Produtos FROM     fornecedores f JOIN     estoque e ON f.cnpj = e.cnpj_fornecedor JOIN     medicamentos m ON e.codigo_medicamento = m.codigo JOIN     itens_venda iv ON m.codigo = iv.codigo_medicamento GROUP BY     f.cnpj, f.razao_social ORDER BY     Valor_Total_Vendido_Produtos DESC;
+---------------------------+--------------------+------------------------------+
| Nome_Fornecedor           | CNPJ_Fornecedor    | Valor_Total_Vendido_Produtos |
+---------------------------+--------------------+------------------------------+
| Droga Certa Atacado       | 12.121.212/0001-21 |                       285.00 |
| Distrimed Nacional        | 44.444.444/0001-44 |                       176.00 |
| BioLabs Distribuidora     | 11.111.111/0001-11 |                        81.00 |
| MegaGenéricos Comércio    | 88.888.888/0001-88 |                        45.80 |
| Produtos Hospitalares Sul | 66.666.666/0001-66 |                        42.00 |
| FarmaLogistica S.A.       | 00.000.000/0001-01 |                        39.99 |
| Saúde Total Ltda.         | 22.222.222/0001-22 |                        35.75 |
| NutriHealth Suplementos   | 14.141.414/0001-41 |                        33.60 |
| Cosmeticos Bem Estar      | 99.999.999/0001-99 |                        30.00 |
| Produtos Naturais Vida    | 18.181.818/0001-81 |                        19.99 |
| VitaSuprimentos S/A       | 55.555.555/0001-55 |                        18.50 |
| Equipamentos Medicos      | 13.131.313/0001-31 |                        17.00 |
| Medicamentos Populares    | 10.000.000/0001-00 |                        14.90 |
| Remedios Rápidos          | 16.161.616/0001-61 |                        10.50 |
| Laboratório Alfa          | 77.777.777/0001-77 |                         9.50 |
| Distribuidora Central     | 17.171.717/0001-71 |                         7.80 |
+---------------------------+--------------------+------------------------------+
16 rows in set (0,00 sec)

10 - Lista de clientes com compras de alto valor.

SELECT     c.nome AS Nome_Cliente,     c.cpf AS CPF_Cliente,     SUM(v.valor_total) AS Valor_Total_Acumulado FROM     clientes c JOIN     vendas v ON c.cpf = v.cpf_cliente GROUP BY     c.cpf, c.nome HAVING     Valor_Total_Acumulado > 100.00 ORDER BY     Valor_Total_Acumulado DESC;
+---------------+----------------+-----------------------+
| Nome_Cliente  | CPF_Cliente    | Valor_Total_Acumulado |
+---------------+----------------+-----------------------+
| Kleber Mendes | 120.120.120-12 |                190.00 |
| Daniel Alves  | 444.444.444-44 |                183.00 |
+---------------+----------------+-----------------------+
2 rows in set (0,00 sec)

11 - Média de medicamentos por receita.

SELECT     ROUND(AVG(Total_Medicamentos_Por_Receita), 2) AS Media_Medicamentos_por_Receita FROM (     SELECT         COUNT(codigo_medicamento) AS Total_Medicamentos_Por_Receita     FROM         receitas_medicas     GROUP BY         id ) AS Sub_Contagem;
+--------------------------------+
| Media_Medicamentos_por_Receita |
+--------------------------------+
|                           1.00 |
+--------------------------------+
1 row in set (0,00 sec)


12 - Outras consultas para atingir o mínimo de 20.

SELECT     c.nome AS Nome_Cliente_Inativo,     c.cpf AS CPF FROM     clientes c WHERE     c.cpf NOT IN (SELECT DISTINCT cpf_cliente FROM vendas WHERE cpf_cliente IS NOT NULL) ORDER BY     c.nome;
+----------------------+----------------+
| Nome_Cliente_Inativo | CPF            |
+----------------------+----------------+
| Ana Costa            | 111.111.111-11 |
| Otavio Pereira       | 160.160.160-16 |
+----------------------+----------------+
2 rows in set (0,01 sec)

13 - Quantidade por cliente especificando nome do cliente, ID_Venda, quantidade, medicamento, categoria, preço unitário e subtotal.

SELECT     c.nome AS Cliente,     v.id AS ID_Venda,     iv.quantidade AS Quantidade,     m.nome AS Medicamento,     m.tipo AS Categoria,     iv.valor_unitario AS Preco_Unitario,     (iv.quantidade * iv.valor_unitario) AS Subtotal FROM     clientes c INNER JOIN     vendas v ON c.cpf = v.cpf_cliente INNER JOIN     itens_venda iv ON v.id = iv.id_venda INNER JOIN     medicamentos m ON iv.codigo_medicamento = m.codigo WHERE     c.cpf IN ('210.210.210-21','111.111.111-11','333.333.333-33','555.555.555-55','777.777.777-77') ORDER BY c.nome, v.data DESC, m.nome;
+-------------------+----------+------------+---------------------+-----------+----------------+----------+
| Cliente           | ID_Venda | Quantidade | Medicamento         | Categoria | Preco_Unitario | Subtotal |
+-------------------+----------+------------+---------------------+-----------+----------------+----------+
| Carla Souza       |      203 |          2 | Ibuprofeno Gel      | CREME     |          25.00 |    50.00 |
| Elisa Ferreira    |      205 |          1 | Creme Hidratante    | CREME     |          18.50 |    18.50 |
| Gisele Nunes      |      207 |          1 | Paracetamol Gotas   | GOTAS     |           9.50 |     9.50 |
| Tania Vasconcelos |      212 |          1 | Pomada Antibiótica  | CREME     |          17.00 |    17.00 |
+-------------------+----------+------------+---------------------+-----------+----------------+----------+
4 rows in set (0,00 sec)


