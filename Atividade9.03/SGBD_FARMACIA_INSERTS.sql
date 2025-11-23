-- ============================================================
-- ARQUIVO SQL COMPLETO: SGBD FARMÁCIA
-- DDL | OTIMIZAÇÃO (ÍNDICES) | DML | STORED PROCEDURE
-- ============================================================

-- 1. RESETAR BANCO E USAR SCHEMA
-- ============================================================
DROP DATABASE IF EXISTS SGBD_FARMACIA;
CREATE DATABASE SGBD_FARMACIA
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE SGBD_FARMACIA;

-- 2. DDL: DEFINIÇÃO DO ESQUEMA (TABELAS)
-- ============================================================

-- Tabela: Fornecedores
CREATE TABLE fornecedores (
  cnpj VARCHAR(18) PRIMARY KEY,
  razao_social VARCHAR(150) NOT NULL UNIQUE,
  contato VARCHAR(100) NULL
) ENGINE=InnoDB;

-- Tabela: Funcionarios
CREATE TABLE funcionarios (
  matricula VARCHAR(50) PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  cargo ENUM('ATENDENTE', 'FARMACEUTICO', 'GERENTE') NOT NULL,
  turno ENUM('MANHA', 'TARDE', 'NOITE') NOT NULL
) ENGINE=InnoDB;

-- Tabela: Clientes
CREATE TABLE clientes (
  cpf VARCHAR(14) PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  telefone VARCHAR(20) NULL,
  email VARCHAR(100) NULL UNIQUE
) ENGINE=InnoDB;

-- Tabela: Medicos
CREATE TABLE medicos (
  crm VARCHAR(20) PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  especialidade VARCHAR(100) NULL,
  contato VARCHAR(100) NULL
) ENGINE=InnoDB;

-- Tabela: Medicamentos
CREATE TABLE medicamentos (
  codigo INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(150) NOT NULL UNIQUE,
  principio_ativo VARCHAR(150) NOT NULL,
  tipo ENUM('COMPRIMIDO', 'XAROPE', 'INJETAVEL', 'CREME', 'GOTAS') NOT NULL,
  validade_med YEAR NOT NULL,
  preco DECIMAL(10, 2) NOT NULL
) ENGINE=InnoDB;

-- Tabela: Estoque (Controle por Lote e Validade)
CREATE TABLE estoque (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  codigo_medicamento INT UNSIGNED NOT NULL,
  cnpj_fornecedor VARCHAR(18) NOT NULL,
  quantidade INT UNSIGNED NOT NULL,
  lote VARCHAR(50) NOT NULL,
  validade_lote DATE NOT NULL,
  data_entrada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (codigo_medicamento) REFERENCES medicamentos(codigo)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  FOREIGN KEY (cnpj_fornecedor) REFERENCES fornecedores(cnpj)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  UNIQUE KEY uk_estoque_lote_med (codigo_medicamento, lote)
) ENGINE=InnoDB;

-- Tabela: Vendas (Cabeçalho)
CREATE TABLE vendas (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cpf_cliente VARCHAR(14) NULL,
  matricula_atendente VARCHAR(50) NOT NULL,
  data DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  valor_total DECIMAL(10, 2) NOT NULL,
  FOREIGN KEY (cpf_cliente) REFERENCES clientes(cpf)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  FOREIGN KEY (matricula_atendente) REFERENCES funcionarios(matricula)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Tabela: Itens_Venda
CREATE TABLE itens_venda (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_venda BIGINT UNSIGNED NOT NULL,
  codigo_medicamento INT UNSIGNED NOT NULL,
  quantidade INT UNSIGNED NOT NULL,
  valor_unitario DECIMAL(10, 2) NOT NULL,
  FOREIGN KEY (id_venda) REFERENCES vendas(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY (codigo_medicamento) REFERENCES medicamentos(codigo)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Tabela: Pagamentos
CREATE TABLE pagamentos (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_venda BIGINT UNSIGNED NOT NULL UNIQUE,
  forma ENUM('CREDITO', 'DEBITO', 'PIX', 'DINHEIRO', 'CONVENIO') NOT NULL,
  status ENUM('APROVADO', 'PENDENTE', 'CANCELADO') NOT NULL DEFAULT 'APROVADO',
  FOREIGN KEY (id_venda) REFERENCES vendas(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabela: Receitas_Medicas
CREATE TABLE receitas_medicas (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cpf_cliente VARCHAR(14) NOT NULL,
  crm_medico VARCHAR(20) NOT NULL,
  codigo_medicamento INT UNSIGNED NOT NULL,
  validade_receita DATE NOT NULL,
  data_emissao DATE NOT NULL,
  FOREIGN KEY (cpf_cliente) REFERENCES clientes(cpf)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  FOREIGN KEY (crm_medico) REFERENCES medicos(crm)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  FOREIGN KEY (codigo_medicamento) REFERENCES medicamentos(codigo)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 3. OTIMIZAÇÃO: CRIAÇÃO DE ÍNDICES PARA DESEMPENHO
-- ============================================================

-- Medicamentos
CREATE INDEX idx_medicamentos_nome ON medicamentos (nome);
CREATE INDEX idx_medicamentos_principio_ativo ON medicamentos (principio_ativo);

-- Clientes
CREATE INDEX idx_clientes_nome ON clientes (nome);

-- Medicos
CREATE INDEX idx_medicos_nome ON medicos (nome);

-- Estoque (idx_estoque_validade já existe)
CREATE INDEX idx_estoque_fornecedor ON estoque (cnpj_fornecedor);
CREATE INDEX idx_estoque_validade ON estoque (validade_lote);

-- Vendas
CREATE INDEX idx_vendas_data ON vendas (data);
CREATE INDEX idx_vendas_atendente ON vendas (matricula_atendente);

-- Receitas Médicas
CREATE INDEX idx_receitas_validade ON receitas_medicas (validade_receita);
CREATE INDEX idx_receitas_crm ON receitas_medicas (crm_medico);


-- 4. DML: INSERÇÃO DE 20 DADOS POR TABELA (NA ORDEM CORRETA)
-- ============================================================

-- 4.1. Fornecedores (20 Inserções)
INSERT INTO fornecedores (cnpj, razao_social, contato) VALUES
('00.000.000/0001-01', 'FarmaLogistica S.A.', 'vendas@farmalog.com'),
('11.111.111/0001-11', 'BioLabs Distribuidora', 'contato@biolabs.com'),
('22.222.222/0001-22', 'Saúde Total Ltda.', 'comercial@saudetotal.net'),
('33.333.333/0001-33', 'Quimica Pharma Eireli', 'pedidos@quimicapharma.br'),
('44.444.444/0001-44', 'Distrimed Nacional', 'suporte@distrimed.com'),
('55.555.555/0001-55', 'VitaSuprimentos S/A', 'vitasupri@vitasupri.com'),
('66.666.666/0001-66', 'Produtos Hospitalares Sul', 'phs@hospitalaresul.com.br'),
('77.777.777/0001-77', 'Laboratório Alfa', 'labalfa@labalfa.ind.br'),
('88.888.888/0001-88', 'MegaGenéricos Comércio', 'megagen@megagen.net'),
('99.999.999/0001-99', 'Cosmeticos Bem Estar', 'vendas@bemestar.com'),
('10.000.000/0001-00', 'Medicamentos Populares', 'popmed@popmed.com.br'),
('12.121.212/0001-21', 'Droga Certa Atacado', 'drogacerta@drogacerta.com'),
('13.131.313/0001-31', 'Equipamentos Medicos', 'equip@eqmedicos.net'),
('14.141.414/0001-41', 'NutriHealth Suplementos', 'nutri@nutrihealth.com'),
('15.151.515/0001-51', 'Insumos Essenciais', 'essenciais@insumos.br'),
('16.161.616/0001-61', 'Remedios Rápidos', 'rapidos@remedios.com'),
('17.171.717/0001-71', 'Distribuidora Central', 'central@distribuidora.net'),
('18.181.818/0001-81', 'Produtos Naturais Vida', 'vidanatural@vida.com.br'),
('19.191.919/0001-91', 'Farmaceutica do Leste', 'lestepharma@leste.com'),
('20.202.020/0001-20', 'Biotech Inovação', 'inovacao@biotech.br');

-- 4.2. Funcionarios (20 Inserções)
INSERT INTO funcionarios (matricula, nome, cargo, turno) VALUES
('F001', 'Paula Abreu', 'FARMACEUTICO', 'MANHA'),
('F002', 'Ricardo Mendes', 'ATENDENTE', 'TARDE'),
('F003', 'Julia Castro', 'GERENTE', 'NOITE'),
('F004', 'Ana Silva', 'ATENDENTE', 'MANHA'),
('F005', 'Carlos Lima', 'ATENDENTE', 'TARDE'),
('F006', 'Sofia Rangel', 'ATENDENTE', 'NOITE'),
('F007', 'Pedro Rocha', 'FARMACEUTICO', 'TARDE'),
('F008', 'Mariana Gomes', 'FARMACEUTICO', 'MANHA'),
('F009', 'Daniel Costa', 'ATENDENTE', 'MANHA'),
('F010', 'Luiza Santos', 'ATENDENTE', 'TARDE'),
('F011', 'Rafael Alves', 'ATENDENTE', 'NOITE'),
('F012', 'Bruna Dias', 'FARMACEUTICO', 'NOITE'),
('F013', 'Thiago Melo', 'ATENDENTE', 'MANHA'),
('F014', 'Isabela Pires', 'ATENDENTE', 'TARDE'),
('F015', 'Lucas Souza', 'ATENDENTE', 'NOITE'),
('F016', 'Camila Neves', 'FARMACEUTICO', 'MANHA'),
('F017', 'Felipe Oliveira', 'ATENDENTE', 'TARDE'),
('F018', 'Amanda Barros', 'ATENDENTE', 'NOITE'),
('F019', 'Guilherme Freire', 'GERENTE', 'MANHA'),
('F020', 'Viviane Nolasco', 'ATENDENTE', 'TARDE');

-- 4.3. Clientes (20 Inserções)
INSERT INTO clientes (cpf, nome, telefone) VALUES
('111.111.111-11', 'Ana Costa', '(11) 98888-7777'),
('222.222.222-22', 'Bruno Silva', '(21) 97777-6666'),
('333.333.333-33', 'Carla Souza', '(31) 96666-5555'),
('444.444.444-44', 'Daniel Alves', '(41) 95555-4444'),
('555.555.555-55', 'Elisa Ferreira', '(51) 94444-3333'),
('666.666.666-66', 'Felipe Gomes', '(61) 93333-2222'),
('777.777.777-77', 'Gisele Nunes', '(71) 92222-1111'),
('888.888.888-88', 'Hugo Rocha', '(81) 91111-0000'),
('999.999.999-99', 'Igor Santos', '(91) 90000-9999'),
('100.000.000-00', 'Juliana Lima', '(11) 99999-8888'),
('120.120.120-12', 'Kleber Mendes', '(21) 98765-4321'),
('130.130.130-13', 'Laura Pinheiro', '(31) 96543-2109'),
('140.140.140-14', 'Marcelo Vieira', '(41) 91234-5678'),
('150.150.150-15', 'Nadia Oliveira', '(51) 98012-3456'),
('160.160.160-16', 'Otavio Pereira', '(61) 97890-1234'),
('170.170.170-17', 'Priscila Queiroz', '(71) 96789-0123'),
('180.180.180-18', 'Quirino Ramos', '(81) 95678-9012'),
('190.190.190-19', 'Renata Telles', '(91) 94567-8901'),
('200.200.200-20', 'Sergio Urbano', '(11) 93456-7890'),
('210.210.210-21', 'Tania Vasconcelos', '(21) 92345-6789');

-- 4.4. Medicos (20 Inserções)
INSERT INTO medicos (crm, nome, especialidade, contato) VALUES
('CRM/SP 123456', 'Dr. João Pereira', 'Clínico Geral', 'joao.p@med.com'),
('CRM/RJ 789012', 'Dra. Maria Oliveira', 'Pediatra', 'maria.o@med.com'),
('CRM/MG 345678', 'Dr. Pedro Henrique', 'Cardiologista', 'pedro.h@med.com'),
('CRM/PR 901234', 'Dra. Sofia Lima', 'Ginecologista', 'sofia.l@med.com'),
('CRM/SC 567890', 'Dr. Lucas Silveira', 'Dermatologista', 'lucas.s@med.com'),
('CRM/RS 112233', 'Dra. Bruna Santos', 'Oftalmologista', 'bruna.s@med.com'),
('CRM/BA 445566', 'Dr. Ricardo Neves', 'Ortopedista', 'ricardo.n@med.com'),
('CRM/PE 778899', 'Dra. Helena Costa', 'Neurologista', 'helena.c@med.com'),
('CRM/CE 001122', 'Dr. Gabriel Ferreira', 'Psiquiatra', 'gabriel.f@med.com'),
('CRM/DF 334455', 'Dra. Carolina Pires', 'Endocrinologista', 'carolina.p@med.com'),
('CRM/GO 667788', 'Dr. Tiago Matos', 'Clínico Geral', 'tiago.m@med.com'),
('CRM/AM 990011', 'Dra. Vanessa Dias', 'Gastroenterologista', 'vanessa.d@med.com'),
('CRM/PA 223344', 'Dr. Eduardo Nunes', 'Otorrinolaringologista', 'eduardo.n@med.com'),
('CRM/ES 556677', 'Dra. Alice Rocha', 'Urologista', 'alice.r@med.com'),
('CRM/MT 889900', 'Dr. Roberto Alves', 'Geriatra', 'roberto.a@med.com'),
('CRM/MS 102030', 'Dra. Patricia Lima', 'Infectologista', 'patricia.l@med.com'),
('CRM/RJ 405060', 'Dr. Felipe Barros', 'Cirurgião Geral', 'felipe.b@med.com'),
('CRM/SP 708090', 'Dra. Gisele Mendes', 'Oftalmologista', 'gisele.m@med.com'),
('CRM/MG 111000', 'Dr. Alexandre Souza', 'Cardiologista', 'alexandre.s@med.com'),
('CRM/PR 222111', 'Dra. Viviane Teles', 'Pediatra', 'viviane.t@med.com');

-- 4.5. Medicamentos (20 Inserções) - IDs de 101 a 120
INSERT INTO medicamentos (codigo, nome, principio_ativo, tipo, validade_med, preco) VALUES
(101, 'Amoxicilina', 'Amoxicilina', 'COMPRIMIDO', 2028, 15.50),
(102, 'Dipirona 500mg', 'Dipirona Sódica', 'COMPRIMIDO', 2030, 8.99),
(103, 'Ibuprofeno Gel', 'Ibuprofeno', 'CREME', 2027, 25.00),
(104, 'Xarope Guaco', 'Mikania glomerata', 'XAROPE', 2026, 12.00),
(105, 'Omeprazol 20mg', 'Omeprazol', 'COMPRIMIDO', 2029, 35.75),
(106, 'Insulina NPH', 'Insulina', 'INJETAVEL', 2026, 88.00),
(107, 'Creme Hidratante', 'Ureia', 'CREME', 2027, 18.50),
(108, 'Propranolol 40mg', 'Propranolol', 'COMPRIMIDO', 2028, 42.00),
(109, 'Paracetamol Gotas', 'Paracetamol', 'GOTAS', 2029, 9.50),
(110, 'Sinvastatina 10mg', 'Sinvastatina', 'COMPRIMIDO', 2031, 22.90),
(111, 'Colírio Seco', 'Carmelose', 'GOTAS', 2027, 30.00),
(112, 'Loratadina Xarope', 'Loratadina', 'XAROPE', 2028, 14.90),
(113, 'Penicilina G', 'Penicilina', 'INJETAVEL', 2025, 95.00),
(114, 'Pomada Antibiótica', 'Neomicina', 'CREME', 2026, 17.00),
(115, 'Metformina 500mg', 'Metformina', 'COMPRIMIDO', 2030, 11.20),
(116, 'Vacina Gripe', 'Influenza', 'INJETAVEL', 2025, 60.00),
(117, 'Dipropionato de Betametasona', 'Betametasona', 'CREME', 2029, 10.50),
(118, 'Captopril 25mg', 'Captopril', 'COMPRIMIDO', 2028, 7.80),
(119, 'Buscofem', 'Ibuprofeno', 'COMPRIMIDO', 2027, 19.99),
(120, 'Vitamina C Gotas', 'Ácido Ascórbico', 'GOTAS', 2031, 13.50);

-- 4.6. Estoque (20 Inserções) - Depende de Fornecedores e Medicamentos
INSERT INTO estoque (codigo_medicamento, cnpj_fornecedor, quantidade, lote, validade_lote, data_entrada) VALUES
(101, '00.000.000/0001-01', 50, 'AMX-001A', '2025-12-31', '2024-01-01 10:00:00'),
(101, '11.111.111/0001-11', 150, 'AMX-002B', '2026-06-30', '2024-06-15 11:30:00'),
(102, '00.000.000/0001-01', 300, 'DIP-L01', '2027-01-15', '2024-03-01 12:00:00'),
(103, '11.111.111/0001-11', 80, 'IBU-GEL05', '2025-11-20', '2024-09-01 13:00:00'),
(104, '33.333.333/0001-33', 120, 'GUA-XR7', '2026-04-01', '2024-05-20 14:00:00'),
(105, '22.222.222/0001-22', 90, 'OME-PZ03', '2028-08-01', '2024-07-10 15:00:00'),
(106, '44.444.444/0001-44', 30, 'INS-NPH01', '2025-01-01', '2024-02-01 16:00:00'),
(107, '55.555.555/0001-55', 200, 'CRE-HID01', '2027-10-10', '2024-10-01 17:00:00'),
(108, '66.666.666/0001-66', 70, 'PRO-PRN02', '2028-03-01', '2024-04-05 18:00:00'),
(109, '77.777.777/0001-77', 180, 'PAR-GT01', '2029-05-01', '2024-05-10 19:00:00'),
(110, '88.888.888/0001-88', 110, 'SIN-VAT04', '2031-01-01', '2024-08-01 20:00:00'),
(111, '99.999.999/0001-99', 60, 'COL-SC01', '2027-04-01', '2024-03-05 09:00:00'),
(112, '10.000.000/0001-00', 140, 'LOR-XR10', '2028-07-01', '2024-06-20 08:30:00'),
(113, '12.121.212/0001-21', 25, 'PEN-G003', '2025-06-01', '2024-01-25 07:00:00'),
(114, '13.131.313/0001-31', 95, 'POM-ANT02', '2026-11-01', '2024-09-15 06:00:00'),
(115, '14.141.414/0001-41', 210, 'MET-FRM05', '2030-02-01', '2024-10-20 05:30:00'),
(116, '15.151.515/0001-51', 40, 'VAC-GRIPE1', '2025-04-01', '2024-03-10 04:00:00'),
(117, '16.161.616/0001-61', 130, 'BET-DIP07', '2029-12-01', '2024-07-25 03:00:00'),
(118, '17.171.717/0001-71', 250, 'CAP-PRL08', '2028-09-01', '2024-08-15 02:00:00'),
(119, '18.181.818/0001-81', 160, 'BUS-FEM01', '2027-07-01', '2024-05-05 01:00:00');

-- 4.7. Vendas (20 Inserções) - Depende de Clientes e Funcionários
INSERT INTO vendas (id, cpf_cliente, matricula_atendente, data, valor_total) VALUES
(201, '111.111.111-11', 'F002', NOW() - INTERVAL 10 DAY, 31.00),
(202, '222.222.222-22', 'F004', NOW() - INTERVAL 9 DAY, 8.99),
(203, '333.333.333-33', 'F005', NOW() - INTERVAL 8 DAY, 50.00),
(204, '444.444.444-44', 'F009', NOW() - INTERVAL 7 DAY, 183.00),
(205, '555.555.555-55', 'F010', NOW() - INTERVAL 6 DAY, 18.50),
(206, '666.666.666-66', 'F002', NOW() - INTERVAL 5 DAY, 88.00),
(207, '777.777.777-77', 'F004', NOW() - INTERVAL 4 DAY, 9.50),
(208, '888.888.888-88', 'F005', NOW() - INTERVAL 3 DAY, 42.00),
(209, '999.999.999-99', 'F009', NOW() - INTERVAL 2 DAY, 45.80),
(210, '100.000.000-00', 'F010', NOW() - INTERVAL 1 DAY, 14.90),
(211, '120.120.120-12', 'F002', NOW(), 190.00),
(212, NULL, 'F004', NOW(), 17.00),
(213, '130.130.130-13', 'F005', NOW(), 22.40),
(214, '140.140.140-14', 'F009', NOW(), 35.75),
(215, '150.150.150-15', 'F010', NOW(), 11.20),
(216, '160.160.160-16', 'F002', NOW(), 30.00),
(217, '170.170.170-17', 'F004', NOW(), 10.50),
(218, '180.180.180-18', 'F005', NOW(), 7.80),
(219, '190.190.190-19', 'F009', NOW(), 13.50),
(220, '200.200.200-20', 'F010', NOW(), 19.99);

-- 4.8. Itens_Venda (20 Inserções) - Depende de Vendas e Medicamentos
INSERT INTO itens_venda (id_venda, codigo_medicamento, quantidade, valor_unitario) VALUES
(201, 101, 2, 15.50),
(202, 102, 1, 8.99),
(203, 103, 2, 25.00),
(204, 106, 1, 88.00),
(204, 113, 1, 95.00),
(205, 107, 1, 18.50),
(206, 106, 1, 88.00),
(207, 109, 1, 9.50),
(208, 108, 1, 42.00),
(209, 110, 2, 22.90),
(210, 112, 1, 14.90),
(211, 113, 2, 95.00),
(212, 114, 1, 17.00),
(213, 115, 2, 11.20),
(214, 105, 1, 35.75),
(215, 115, 1, 11.20),
(216, 111, 1, 30.00),
(217, 117, 1, 10.50),
(218, 118, 1, 7.80),
(219, 120, 1, 13.50),
(220, 119, 1, 19.99);

-- 4.9. Pagamentos (20 Inserções) - Depende de Vendas
INSERT INTO pagamentos (id_venda, forma, status) VALUES
(201, 'PIX', 'APROVADO'),
(202, 'DINHEIRO', 'APROVADO'),
(203, 'CREDITO', 'APROVADO'),
(204, 'DEBITO', 'APROVADO'),
(205, 'PIX', 'APROVADO'),
(206, 'CONVENIO', 'APROVADO'),
(207, 'DINHEIRO', 'APROVADO'),
(208, 'CREDITO', 'APROVADO'),
(209, 'DEBITO', 'APROVADO'),
(210, 'PIX', 'APROVADO'),
(211, 'CREDITO', 'APROVADO'),
(212, 'DINHEIRO', 'APROVADO'),
(213, 'DEBITO', 'APROVADO'),
(214, 'PIX', 'APROVADO'),
(215, 'CREDITO', 'APROVADO'),
(216, 'DINHEIRO', 'APROVADO'),
(217, 'DEBITO', 'APROVADO'),
(218, 'PIX', 'APROVADO'),
(219, 'CREDITO', 'APROVADO'),
(220, 'DEBITO', 'APROVADO');

-- 4.10. Receitas_Medicas (20 Inserções) - Depende de Clientes, Médicos e Medicamentos
INSERT INTO receitas_medicas (cpf_cliente, crm_medico, codigo_medicamento, validade_receita, data_emissao) VALUES
('111.111.111-11', 'CRM/SP 123456', 101, '2026-03-30', '2025-09-23'),
('222.222.222-22', 'CRM/RJ 789012', 105, '2026-06-15', '2025-10-01'),
('333.333.333-33', 'CRM/MG 345678', 108, '2026-01-20', '2025-08-10'),
('444.444.444-44', 'CRM/PR 901234', 110, '2025-12-01', '2025-06-01'),
('555.555.555-55', 'CRM/SC 567890', 106, '2026-02-14', '2025-11-01'),
('666.666.666-66', 'CRM/RS 112233', 113, '2026-05-01', '2025-07-20'),
('777.777.777-77', 'CRM/BA 445566', 105, '2026-04-10', '2025-10-15'),
('888.888.888-88', 'CRM/PE 778899', 101, '2026-03-01', '2025-09-05'),
('999.999.999-99', 'CRM/CE 001122', 108, '2026-07-01', '2025-11-10'),
('100.000.000-00', 'CRM/DF 334455', 110, '2025-11-25', '2025-05-01'),
('120.120.120-12', 'CRM/GO 667788', 106, '2026-08-01', '2025-10-20'),
('130.130.130-13', 'CRM/AM 990011', 113, '2026-05-15', '2025-09-01'),
('140.140.140-14', 'CRM/PA 223344', 105, '2026-02-28', '2025-07-10'),
('150.150.150-15', 'CRM/ES 556677', 108, '2025-12-31', '2025-06-15'),
('160.160.160-16', 'CRM/MT 889900', 110, '2026-04-20', '2025-11-05'),
('170.170.170-17', 'CRM/MS 102030', 101, '2026-07-05', '2025-10-30'),
('180.180.180-18', 'CRM/RJ 405060', 106, '2026-01-01', '2025-08-01'),
('190.190.190-19', 'CRM/SP 708090', 113, '2026-05-20', '2025-09-15'),
('200.200.200-20', 'CRM/MG 111000', 105, '2026-03-05', '2025-10-01'),
('210.210.210-21', 'CRM/PR 222111', 108, '2026-06-01', '2025-11-20');
