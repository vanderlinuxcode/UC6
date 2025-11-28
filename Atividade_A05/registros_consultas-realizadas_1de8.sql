-- 1. Entregas em Andamento com Motorista e Veículo

SELECT E.id_entrega, E.data_saida, E.previsao_entrega, E.status_entrega, M.nome AS motorista, M.telefone AS contato_motorista, V.placa AS veiculo_placa, V.modelo AS veiculo_modelo FROM Entregas E JOIN Motoristas M ON E.motorista_cnh = M.CNH JOIN Veiculos V ON E.veiculo_placa = V.placa WHERE E.status_entrega IN ('Em Trânsito', 'Pendente') ORDER BY E.data_saida DESC;
+------------+------------+------------------+----------------+------------------+-------------------+---------------+----------------------------+
| id_entrega | data_saida | previsao_entrega | status_entrega | motorista        | contato_motorista | veiculo_placa | veiculo_modelo             |
+------------+------------+------------------+----------------+------------------+-------------------+---------------+----------------------------+
|        119 | 2026-01-05 | 2026-01-06       | Pendente       | Túlio Esteves    | 9444-9999         | QRS3Q45       | Caminhão Misto             |
|         59 | 2026-01-05 | 2026-01-06       | Pendente       | Túlio Esteves    | 9444-9999         | QRS3Q45       | Caminhão Misto             |
|         58 | 2026-01-04 | 2026-01-06       | Em Trânsito    | Suelen Duarte    | 9444-8888         | HIJ4N56       | Picape Simples             |
|        118 | 2026-01-04 | 2026-01-06       | Em Trânsito    | Suelen Duarte    | 9444-8888         | HIJ4N56       | Picape Simples             |
|        116 | 2026-01-02 | 2026-01-04       | Em Trânsito    | Quincy Borges    | 9444-6666         | BCD8L90       | Carreta Gaiola             |
|         56 | 2026-01-02 | 2026-01-04       | Em Trânsito    | Quincy Borges    | 9444-6666         | BCD8L90       | Carreta Gaiola             |
|         54 | 2025-12-31 | 2026-01-02       | Pendente       | Orlando Zanetti  | 9444-4444         | MNO3G45       | Caminhão Roll-on           |
|        114 | 2025-12-31 | 2026-01-02       | Pendente       | Orlando Zanetti  | 9444-4444         | MNO3G45       | Caminhão Roll-on           |
|        112 | 2025-12-29 | 2026-01-01       | Em Trânsito    | Murilo Valente   | 9444-2222         | GHI7E89       | Carreta Silo               |
|         52 | 2025-12-29 | 2026-01-01       | Em Trânsito    | Murilo Valente   | 9444-2222         | GHI7E89       | Carreta Silo               |


-- 2. Ranking de Clientes que Mais Contrataram Fretes

 SELECT C.nome AS cliente, COUNT(E.id_entrega) AS total_fretes_contratados FROM Clientes C JOIN Entregas E ON C.CNPJ = E.cliente_cnpj GROUP BY C.CNPJ, C.nome HAVING COUNT(E.id_entrega) > 1 ORDER BY total_fretes_contratados DESC;
+-------------------------------+--------------------------+
| cliente                       | total_fretes_contratados |
+-------------------------------+--------------------------+
| Petro Distribuidora           |                        2 |
| Livros Didáticos              |                        2 |
| Logística Ágil                |                        2 |
| Madeireira Legal              |                        2 |
| Materiais Elétricos P.R.      |                        2 |
| Mecânica Rápida               |                        2 |
| Metal Leve                    |                        2 |
| Metalúrgica Delta             |                        2 |
| Minas Express Log.            |                        2 |
| Mineração Pesada              |                        2 |


-- 3. Motoristas com Maior Índice de Atrasos

 SELECT M.nome AS motorista, SUM(CASE WHEN E.entrega_real > E.previsao_entrega THEN 1 ELSE 0 END) AS total_atrasos, COUNT(E.id_entrega) AS total_entregas, (SUM(CASE WHEN E.entrega_real > E.previsao_entrega THEN 1 ELSE 0 END) * 100.0 / COUNT(E.id_entrega)) AS percentual_atraso FROM Motoristas M JOIN Entregas E ON M.CNH = E.motorista_cnh WHERE E.status_entrega = 'Entregue' GROUP BY M.CNH, M.nome HAVING COUNT(E.id_entrega) > 0 ORDER BY percentual_atraso DESC, total_atrasos DESC;
+------------------+---------------+----------------+-------------------+
| motorista        | total_atrasos | total_entregas | percentual_atraso |
+------------------+---------------+----------------+-------------------+
| Felipe Santos    |             2 |              2 |         100.00000 |
| Bianca Ribeiro   |             2 |              2 |         100.00000 |
| Laura Mendes     |             2 |              2 |         100.00000 |
| Lucas Toledo     |             2 |              2 |         100.00000 |
| Ricardo Castro   |             2 |              4 |          50.00000 |
| Pâmela Almeida   |             2 |              4 |          50.00000 |
| Viviane Freitas  |             0 |              2 |           0.00000 |
| Pedro Silva      |             0 |              2 |           0.00000 |
| Nina Xavier      |             0 |              4 |           0.00000 |
| Lídia Uzeda      |             0 |              4 |           0.00000 |
| Gerson Queiroz   |             0 |              2 |           0.00000 |
| Éder Neves       |             0 |              2 |           0.00000 |
| Caio Lacerda     |             0 |              2 |           0.00000 |
| Yara Holanda     |             0 |              2 |           0.00000 |
| Sandra Barreto   |             0 |              2 |           0.00000 |
| Paulo Xavier     |             0 |              2 |           0.00000 |
| Helen Martins    |             0 |              2 |           0.00000 |
| Ricardo Souza    |             0 |              2 |           0.00000 |
| Roberto Oliveira |             0 |              2 |           0.00000 |
| Camila Martins   |             0 |              2 |           0.00000 |
| Vitória Lima     |             0 |              2 |           0.00000 |
| Marcelo Alves    |             0 |              4 |           0.00000 |
+------------------+---------------+----------------+-------------------+
22 rows in set (0,01 sec)

-- 4. Veículos Mais Utilizados no Semestre

SELECT V.placa, V.modelo, COUNT(E.id_entrega) AS total_utilizacoes FROM Veiculos V JOIN Entregas E ON V.placa = E.veiculo_placa WHERE E.data_saida >= DATE_SUB('2025-11-28', INTERVAL 6 MONTH) GROUP BY V.placa, V.modelo ORDER BY total_utilizacoes DESC;
+---------+----------------------------+-------------------+
| placa   | modelo                     | total_utilizacoes |
+---------+----------------------------+-------------------+
| JKL2M34 | Caminhão Bau Frigorífico   |                 4 |
| WXY9S01 | Carreta Câmera Fria        |                 4 |
| QRS3Q45 | Caminhão Misto             |                 4 |
| HIJ4N56 | Picape Simples             |                 4 |
| EFG1M23 | Caminhão Basculante        |                 4 |
| BCD8L90 | Carreta Gaiola             |                 4 |
| VWX2J34 | Caminhão Frigorífico       |                 4 |
| MNO3G45 | Caminhão Roll-on           |                 4 |
| JKL0F12 | VUC Teto Alto              |                 4 |
| GHI7E89 | Carreta Silo               |                 4 |
| DAB1C23 | Caminhão Coletor           |                 4 |
| TUV2W34 | Caminhão Pipa              |                 4 |
| PQR9S01 | Carreta Boiadeira          |                 4 |
| NOP0P12 | VUC Plataforma             |                 4 |
| EFG0H12 | VUC Bau                    |                 4 |
| VWX1Y23 | Caminhão Leve              |                 4 |
| ABC1A23 | Caminhão Toco              |                 4 |
| YZA3B45 | Caminhão Plataforma        |                 4 |
| QRS7T89 | Carreta Cegonha            |                 4 |
| MNO4P56 | HR                         |                 4 |
| DEF4B56 | Van Sprinter               |                 4 |
| JKL0D12 | VUC                        |                 4 |
| FGH8T90 | Van Carga                  |                 4 |
| WXY9Q01 | Carreta Porta Contêiner    |                 4 |
| NOP0N12 | VUC Refrigerado            |                 4 |
| EFG1K23 | Caminhão Baú               |                 4 |
| VWX2H34 | Caminhão Toco Refrigerado  |                 4 |
| MNO3E45 | Caminhão 3/4               |                 4 |
| HJK1L23 | Caminhão Bi-Truck          |                 2 |
| BCD8J90 | Carreta Tanque             |                 2 |
| HIJ4L56 | Picape Cabine Dupla        |                 2 |
| STU9G01 | Fiorino                    |                 2 |
+---------+----------------------------+-------------------+
32 rows in set (0,00 sec)

-- 5. Rotas com Maior Número de Ocorrências

SELECT R.id_rota, R.origem, R.destino, COUNT(O.id_ocorrencia) AS total_ocorrencias FROM Rotas R JOIN Entregas E ON R.id_rota = E.id_rota JOIN Ocorrencias O ON E.id_entrega = O.id_entrega GROUP BY R.id_rota, R.origem, R.destino ORDER BY total_ocorrencias DESC LIMIT 10;
+---------+----------------+----------------+-------------------+
| id_rota | origem         | destino        | total_ocorrencias |
+---------+----------------+----------------+-------------------+
|       1 | São Paulo      | Rio de Janeiro |                 2 |
|       2 | São Paulo      | Curitiba       |                 2 |
|       3 | Rio de Janeiro | Belo Horizonte |                 2 |
|       4 | Curitiba       | Porto Alegre   |                 2 |
|       5 | Belo Horizonte | Brasília       |                 2 |
|       6 | Brasília       | Goiânia        |                 2 |
|       7 | Porto Alegre   | Florianópolis  |                 2 |
|       8 | Florianópolis  | São Paulo      |                 2 |
|       9 | Recife         | Salvador       |                 2 |
|      10 | Salvador       | Fortaleza      |                 2 |
+---------+----------------+----------------+-------------------+


-- 6. Clientes Inadimplentes e Valor Devido

SELECT C.nome AS cliente_inadimplente, C.status_pagamento AS status_principal, SUM(P.valor) AS valor_total_devido FROM Clientes C JOIN Pagamentos P ON C.CNPJ = P.cliente_cnpj WHERE C.status_pagamento = 'Atrasado' AND P.status_pagamento IN ('Pendente', 'Estornado') GROUP BY C.CNPJ, C.nome, C.status_pagamento HAVING valor_total_devido > 0 ORDER BY valor_total_devido DESC;
+-------------------------------+------------------+--------------------+
| cliente_inadimplente          | status_principal | valor_total_devido |
+-------------------------------+------------------+--------------------+
| Materiais Elétricos P.R.      | Atrasado         |            3600.00 |
| Indústria Alimentícia Delta   | Atrasado         |            2700.00 |
| Importadora Marítima          | Atrasado         |            2600.00 |
| Distribuidora Global          | Atrasado         |            1960.00 |
| Moveleira Design              | Atrasado         |            1780.00 |
| Construtora Forte S.A.        | Atrasado         |            1701.00 |
| Metal Leve                    | Atrasado         |            1160.00 |
| Roupas Infantis               | Atrasado         |             840.00 |
| Pequenas Lojas                | Atrasado         |             560.00 |
| Equipamentos Médicos          | Atrasado         |             420.00 |
+-------------------------------+------------------+--------------------+
10 rows in set (0,00 sec)

-- 7. Média de Distância Percorrida por Veículo

SELECT V.placa, V.modelo, COUNT(E.id_entrega) AS total_entregas, SUM(R.distancia) AS distancia_total_percorrida, AVG(R.distancia) AS media_distancia_por_frete FROM Veiculos V JOIN Entregas E ON V.placa = E.veiculo_placa JOIN Rotas R ON E.id_rota = R.id_rota GROUP BY V.placa, V.modelo ORDER BY media_distancia_por_frete DESC;
+---------+----------------------------+----------------+----------------------------+---------------------------+
| placa   | modelo                     | total_entregas | distancia_total_percorrida | media_distancia_por_frete |
+---------+----------------------------+----------------+----------------------------+---------------------------+
| NOP0P12 | VUC Plataforma             |              4 |                   11560.00 |               2890.000000 |
| HJK1L23 | Caminhão Bi-Truck          |              2 |                    5600.00 |               2800.000000 |
| JKL2M34 | Caminhão Bau Frigorífico   |              4 |                   10240.00 |               2560.000000 |
| MNO4P56 | HR                         |              4 |                    9540.00 |               2385.000000 |
| PQR9S01 | Carreta Boiadeira          |              4 |                    8180.00 |               2045.000000 |
| JKL0F12 | VUC Teto Alto              |              4 |                    6600.00 |               1650.000000 |
| YZA3B45 | Caminhão Plataforma        |              4 |                    6460.00 |               1615.000000 |
| BCD8J90 | Carreta Tanque             |              2 |                    3000.00 |               1500.000000 |
| DAB1C23 | Caminhão Coletor           |              4 |                    5780.00 |               1445.000000 |
| VWX1Y23 | Caminhão Leve              |              4 |                    5560.00 |               1390.000000 |
| STU9G01 | Fiorino                    |              2 |                    2700.00 |               1350.000000 |
| TUV2W34 | Caminhão Pipa              |              4 |                    4940.00 |               1235.000000 |
| GHI7E89 | Carreta Silo               |              4 |                    4520.00 |               1130.000000 |
| QRS7T89 | Carreta Cegonha            |              4 |                    4100.00 |               1025.000000 |
| DEF4B56 | Van Sprinter               |              4 |                    3200.00 |                800.000000 |
| EFG1K23 | Caminhão Baú               |              4 |                    2440.00 |                610.000000 |
| MNO3E45 | Caminhão 3/4               |              4 |                    2000.00 |                500.000000 |
| HIJ4L56 | Picape Cabine Dupla        |              2 |                    1000.00 |                500.000000 |
| EFG1M23 | Caminhão Basculante        |              4 |                    1940.00 |                485.000000 |
| EFG0H12 | VUC Bau                    |              4 |                    1830.00 |                457.500000 |
| NOP0N12 | VUC Refrigerado            |              4 |                    1700.00 |                425.000000 |
| WXY9Q01 | Carreta Porta Contêiner    |              4 |                    1680.00 |                420.000000 |
| JKL0D12 | VUC                        |              4 |                    1640.00 |                410.000000 |
| FGH8T90 | Van Carga                  |              4 |                    1540.00 |                385.000000 |
| VWX2J34 | Caminhão Frigorífico       |              4 |                    1240.00 |                310.000000 |
| BCD8L90 | Carreta Gaiola             |              4 |                    1180.00 |                295.000000 |
| ABC1A23 | Caminhão Toco              |              4 |                    1120.00 |                280.000000 |
| HIJ4N56 | Picape Simples             |              4 |                    1120.00 |                280.000000 |
| VWX2H34 | Caminhão Toco Refrigerado  |              4 |                    1100.00 |                275.000000 |
| WXY9S01 | Carreta Câmera Fria        |              4 |                     640.00 |                160.000000 |
| QRS3Q45 | Caminhão Misto             |              4 |                     380.00 |                 95.000000 |
| MNO3G45 | Caminhão Roll-on           |              4 |                     220.00 |                 55.000000 |
+---------+----------------------------+----------------+----------------------------+---------------------------+
32 rows in set (0,01 sec)


-- 8. Funcionários que Mais Registraram Entregas

SELECT FA.nome AS funcionario_administrativo, FA.setor, COUNT(E.id_entrega) AS entregas_registradas FROM Funcionarios_Administrativos FA JOIN Entregas E ON FA.matricula = E.matricula_adm_responsavel GROUP BY FA.matricula, FA.nome, FA.setor ORDER BY entregas_registradas DESC LIMIT 5;
+----------------------------+------------+----------------------+
| funcionario_administrativo | setor      | entregas_registradas |
+----------------------------+------------+----------------------+
| Quirino Elias              | Logística  |                   10 |
| Kauê Castro                | Logística  |                   10 |
| Vanda Jardim               | Logística  |                   10 |
| Larissa Zanoni             | Logística  |                   10 |
| Gabriel Toledo             | Logística  |                   10 |
+----------------------------+------------+----------------------+
5 rows in set (0,01 sec)