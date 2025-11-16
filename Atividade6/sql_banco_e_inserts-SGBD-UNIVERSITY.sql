-- ============================================================
-- RESETAR BANCO E USAR SCHEMA
-- ============================================================
DROP DATABASE IF EXISTS SGBD_UNIVERSITY;
CREATE DATABASE SGBD_UNIVERSITY
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE SGBD_UNIVERSITY;

-- ============================================================
-- TABELAS (DDL)
-- ============================================================

CREATE TABLE usuarios (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tipo ENUM('ALUNO','PROFESSOR','BIBLIOTECARIO','VISITANTE') NOT NULL,
  nome VARCHAR(150) NOT NULL,
  email VARCHAR(180) NOT NULL UNIQUE,
  matricula VARCHAR(50) NULL UNIQUE,
  ativo TINYINT(1) NOT NULL DEFAULT 1,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE INDEX idx_usuarios_nome ON usuarios (nome);

CREATE TABLE alunos (
  id BIGINT UNSIGNED PRIMARY KEY,
  curso VARCHAR(120) NOT NULL,
  periodo INT NOT NULL,
  FOREIGN KEY (id) REFERENCES usuarios(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE professores (
  id BIGINT UNSIGNED PRIMARY KEY,
  departamento VARCHAR(120) NOT NULL,
  FOREIGN KEY (id) REFERENCES usuarios(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE bibliotecarios (
  id BIGINT UNSIGNED PRIMARY KEY,
  turno ENUM('MANHA','TARDE','NOITE') NOT NULL,
  FOREIGN KEY (id) REFERENCES usuarios(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE livros (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  isbn VARCHAR(20) NOT NULL UNIQUE,
  titulo VARCHAR(200) NOT NULL,
  autor VARCHAR(150) NOT NULL,
  editora VARCHAR(120) NOT NULL,
  ano INT NOT NULL,
  categoria VARCHAR(120) NOT NULL,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE INDEX idx_livros_titulo ON livros (titulo);
CREATE INDEX idx_livros_autor ON livros (autor);
CREATE INDEX idx_livros_editora ON livros (editora);

CREATE TABLE exemplares (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  livro_id BIGINT UNSIGNED NOT NULL,
  codigo_tombamento VARCHAR(50) NOT NULL UNIQUE,
  status ENUM('DISPONIVEL','EMPRESTADO','RESERVADO','MANUTENCAO') NOT NULL DEFAULT 'DISPONIVEL',
  localizacao VARCHAR(80) NOT NULL,
  FOREIGN KEY (livro_id) REFERENCES livros(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE INDEX idx_exemplares_livro ON exemplares (livro_id);

CREATE TABLE emprestimos (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  exemplar_id BIGINT UNSIGNED NOT NULL,
  usuario_id BIGINT UNSIGNED NOT NULL,
  bibliotecario_id BIGINT UNSIGNED NOT NULL,
  data_emprestimo DATE NOT NULL,
  data_prevista_devolucao DATE NOT NULL,
  data_devolucao DATE NULL,
  status ENUM('ATIVO','DEVOLVIDO','ATRASO') NOT NULL DEFAULT 'ATIVO',
  multa_calculada DECIMAL(10,2) NULL,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (exemplar_id) REFERENCES exemplares(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  FOREIGN KEY (bibliotecario_id) REFERENCES bibliotecarios(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE INDEX idx_emprestimos_usuario ON emprestimos (usuario_id);
CREATE INDEX idx_emprestimos_exemplar ON emprestimos (exemplar_id);
CREATE INDEX idx_emprestimos_status ON emprestimos (status);

CREATE TABLE reservas (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  livro_id BIGINT UNSIGNED NOT NULL,
  usuario_id BIGINT UNSIGNED NOT NULL,
  data_reserva DATE NOT NULL,
  status ENUM('ATIVA','ATENDIDA','CANCELADA') NOT NULL DEFAULT 'ATIVA',
  prioridade INT NOT NULL DEFAULT 1,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (livro_id) REFERENCES livros(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE INDEX idx_reservas_livro ON reservas (livro_id);
CREATE INDEX idx_reservas_usuario ON reservas (usuario_id);
CREATE INDEX idx_reservas_status ON reservas (status);

CREATE TABLE penalidades (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id BIGINT UNSIGNED NOT NULL,
  emprestimo_id BIGINT UNSIGNED NULL,
  tipo ENUM('ATRASO','DANO','PERDA','CONDUTA') NOT NULL,
  valor DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  descricao VARCHAR(255) NULL,
  data_aplicacao DATE NOT NULL,
  data_fim DATE NULL,
  ativa TINYINT(1) NOT NULL DEFAULT 1,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  FOREIGN KEY (emprestimo_id) REFERENCES emprestimos(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_penalidades_usuario ON penalidades (usuario_id);
CREATE INDEX idx_penalidades_tipo ON penalidades (tipo);

-- ============================================================
-- INSERÇÕES (10 REGISTROS EM CADA TABELA)
-- ============================================================

-- 1) USUÁRIOS (40: 10 ALUNO, 10 PROFESSOR, 10 BIBLIOTECARIO, 10 VISITANTE)
INSERT INTO usuarios (tipo,nome,email,matricula,ativo) VALUES
-- Alunos (IDs 1–10)
('ALUNO','Ana Souza','ana.souza@uni.br','A2025001',1),
('ALUNO','Bruno Lima','bruno.lima@uni.br','A2025002',1),
('ALUNO','Carla Nunes','carla.nunes@uni.br','A2025003',1),
('ALUNO','Diego Santos','diego.santos@uni.br','A2025004',1),
('ALUNO','Eduarda Alves','eduarda.alves@uni.br','A2025005',1),
('ALUNO','Karen Dias','karen.dias@uni.br','A2025006',1),
('ALUNO','Lucas Ferreira','lucas.ferreira@uni.br','A2025007',1),
('ALUNO','Mariana Costa','mariana.costa@uni.br','A2025008',1),
('ALUNO','Paulo Henrique','paulo.henrique@uni.br','A2025009',1),
('ALUNO','Renata Silva','renata.silva@uni.br','A2025010',1),
-- Professores (IDs 11–20)
('PROFESSOR','Felipe Rocha','felipe.rocha@uni.br',NULL,1),
('PROFESSOR','Gabriela Teixeira','gabriela.teixeira@uni.br',NULL,1),
('PROFESSOR','Leandro Melo','leandro.melo@uni.br',NULL,1),
('PROFESSOR','Sofia Almeida','sofia.almeida@uni.br',NULL,1),
('PROFESSOR','Ricardo Torres','ricardo.torres@uni.br',NULL,1),
('PROFESSOR','Patrícia Gomes','patricia.gomes@uni.br',NULL,1),
('PROFESSOR','Marcelo Vieira','marcelo.vieira@uni.br',NULL,1),
('PROFESSOR','Daniela Freitas','daniela.freitas@uni.br',NULL,1),
('PROFESSOR','Rodrigo Pires','rodrigo.pires@uni.br',NULL,1),
('PROFESSOR','Camila Fernandes','camila.fernandes@uni.br',NULL,1),
-- Bibliotecários (IDs 21–30)
('BIBLIOTECARIO','Helena Prado','helena.prado@uni.br',NULL,1),
('BIBLIOTECARIO','Igor Martins','igor.martins@uni.br',NULL,1),
('BIBLIOTECARIO','Marina Costa','marina.costa@uni.br',NULL,1),
('BIBLIOTECARIO','Fernanda Lopes','fernanda.lopes@uni.br',NULL,1),
('BIBLIOTECARIO','Gustavo Azevedo','gustavo.azevedo@uni.br',NULL,1),
('BIBLIOTECARIO','Larissa Moura','larissa.moura@uni.br',NULL,1),
('BIBLIOTECARIO','Mateus Carvalho','mateus.carvalho@uni.br',NULL,1),
('BIBLIOTECARIO','Priscila Duarte','priscila.duarte@uni.br',NULL,1),
('BIBLIOTECARIO','Rafael Oliveira','rafael.oliveira@uni.br',NULL,1),
('BIBLIOTECARIO','Tatiane Barbosa','tatiane.barbosa@uni.br',NULL,1),
-- Visitantes (IDs 31–40)
('VISITANTE','João Pereira','joao.pereira@gmail.com',NULL,1),
('VISITANTE','Nicolas Reis','nicolas.reis@gmail.com',NULL,1),
('VISITANTE','Olivia Ramos','olivia.ramos@gmail.com',NULL,1),
('VISITANTE','Thiago Costa','thiago.costa@gmail.com',NULL,1),
('VISITANTE','Beatriz Souza','beatriz.souza@gmail.com',NULL,1),
('VISITANTE','Caio Almeida','caio.almeida@gmail.com',NULL,1),
('VISITANTE','Fernanda Silva','fernanda.silva@gmail.com',NULL,1),
('VISITANTE','Guilherme Rocha','guilherme.rocha@gmail.com',NULL,1),
('VISITANTE','Isabela Torres','isabela.torres@gmail.com',NULL,1),
('VISITANTE','Mateus Oliveira','mateus.oliveira@gmail.com',NULL,1);

-- 2) ALUNOS (IDs 1–10)
INSERT INTO alunos (id,curso,periodo) VALUES
(1,'Engenharia de Software',3),
(2,'Direito',5),
(3,'Administração',2),
(4,'Matemática',4),
(5,'Letras',1),
(6,'Ciência da Computação',6),
(7,'Arquitetura',2),
(8,'Física',1),
(9,'História',3),
(10,'Biologia',5);

-- 3) PROFESSORES (IDs 11–20)
INSERT INTO professores (id,departamento) VALUES
(11,'Computação'),
(12,'Economia'),
(13,'Matemática'),
(14,'Letras'),
(15,'Física'),
(16,'Direito'),
(17,'Administração'),
(18,'Engenharia'),
(19,'Arquitetura'),
(20,'História');

-- 4) BIBLIOTECÁRIOS (IDs 21–30)
INSERT INTO bibliotecarios (id,turno) VALUES
(21,'MANHA'),
(22,'TARDE'),
(23,'NOITE'),
(24,'MANHA'),
(25,'TARDE'),
(26,'NOITE'),
(27,'MANHA'),
(28,'TARDE'),
(29,'NOITE'),
(30,'MANHA');

-- 5) LIVROS (IDs 1–10)
INSERT INTO livros (isbn,titulo,autor,editora,ano,categoria) VALUES
('9788575221234','Estruturas de Dados','N. Wirth','BookTech',2010,'Computação'),
('9788535214567','Cálculo Diferencial e Integral','J. Stewart','MathPress',2015,'Matemática'),
('9788522119876','Introdução ao Direito','M. Silva','Lex Editora',2018,'Direito'),
('9788547001123','Administração Moderna','P. Kotler','BizBooks',2012,'Administração'),
('9788595153344','Gramática Avançada','C. Cunha','Letras Vivas',2011,'Letras'),
('9788532601230','História do Brasil','B. Fausto','Historiar',2006,'História'),
('9788576054321','Física 1','H. Resnick','SciPress',2009,'Física'),
('9788521223412','Biologia Celular','A. Alberts','BioEditora',2014,'Biologia'),
('9788567893210','Arquitetura e Urbanismo','R. Monteiro','ArqTec',2016,'Arquitetura'),
('9788572834456','Economia Básica','T. Sowell','EconoPub',2013,'Economia');

-- 6) EXEMPLARES (IDs 1–10) vinculados aos livros 1–10
INSERT INTO exemplares (livro_id,codigo_tombamento,status,localizacao) VALUES
(1,'TMB-0001','DISPONIVEL','Estante C1'),
(1,'TMB-0002','DISPONIVEL','Estante C1'),
(2,'TMB-0003','DISPONIVEL','Estante M2'),
(3,'TMB-0004','DISPONIVEL','Estante D1'),
(4,'TMB-0005','MANUTENCAO','Estante A3'),
(5,'TMB-0006','DISPONIVEL','Estante L1'),
(6,'TMB-0007','DISPONIVEL','Estante H1'),
(7,'TMB-0008','DISPONIVEL','Estante F1'),
(8,'TMB-0009','RESERVADO','Estante B2'),
(9,'TMB-0010','DISPONIVEL','Estante AR1');

-- 7) EMPRÉSTIMOS (IDs 1–10) usando exemplares 1–10, usuários válidos e bibliotecários 21–30
INSERT INTO emprestimos (exemplar_id,usuario_id,bibliotecario_id,data_emprestimo,data_prevista_devolucao,data_devolucao,status,multa_calculada) VALUES
(1,1,21,'2025-10-01','2025-10-15',NULL,'ATIVO',NULL),             -- aluno 1
(2,2,22,'2025-09-20','2025-10-04','2025-10-03','DEVOLVIDO',0.00),  -- aluno 2
(3,3,23,'2025-09-25','2025-10-09','2025-10-20','ATRASO',12.50),    -- aluno 3
(4,4,24,'2025-10-03','2025-10-17',NULL,'ATIVO',NULL),              -- aluno 4
(5,11,25,'2025-09-10','2025-09-24','2025-09-24','DEVOLVIDO',0.00), -- professor 11
(6,12,26,'2025-09-15','2025-09-29','2025-10-05','ATRASO',8.00),    -- professor 12
(7,31,27,'2025-10-05','2025-10-19',NULL,'ATIVO',NULL),             -- visitante 31
(8,32,28,'2025-10-06','2025-10-20',NULL,'ATIVO',NULL),             -- visitante 32
(9,5,29,'2025-09-28','2025-10-12','2025-10-14','DEVOLVIDO',2.00),  -- aluno 5
(10,6,30,'2025-10-07','2025-10-21',NULL,'ATIVO',NULL);             -- aluno 6

-- 8) RESERVAS (10) sobre livros 1–10 e usuários existentes
INSERT INTO reservas (livro_id,usuario_id,data_reserva,status,prioridade) VALUES
(8,1,'2025-10-01','ATIVA',1),      -- aluno 1
(1,2,'2025-09-20','ATIVA',2),      -- aluno 2
(2,3,'2025-09-22','ATIVA',1),      -- aluno 3
(3,4,'2025-09-25','CANCELADA',1),  -- aluno 4
(4,5,'2025-09-27','ATIVA',1),      -- aluno 5
(5,11,'2025-10-01','ATENDIDA',1),  -- professor 11
(6,12,'2025-10-02','ATIVA',2),     -- professor 12
(7,31,'2025-10-03','ATIVA',1),     -- visitante 31
(9,32,'2025-10-04','ATIVA',1),     -- visitante 32
(10,6,'2025-10-05','ATIVA',3);     -- aluno 6

-- 9) PENALIDADES (10) referenciando usuários e empréstimos 1–10
INSERT INTO penalidades (usuario_id,emprestimo_id,tipo,valor,descricao,data_aplicacao,data_fim,ativa) VALUES
(3,3,'ATRASO',12.50,'Devolução com 11 dias de atraso','2025-10-20',NULL,1),   -- aluno 3 / empréstimo 3
(12,6,'ATRASO',8.00,'Atraso de 6 dias','2025-10-05',NULL,1),                  -- professor 12 / empréstimo 6
(2,2,'CONDUTA',0.00,'Comportamento inadequado em sala de leitura','2025-10-03','2025-10-10',0),
(11,5,'DANO',35.00,'Capa danificada','2025-09-24',NULL,1),                    -- professor 11 / empréstimo 5
(5,9,'ATRASO',2.00,'Devolução 2 dias após prazo','2025-10-14',NULL,1),
(31,7,'CONDUTA',0.00,'Conversas em voz alta recorrentes','2025-10-07','2025-10-14',0),
(6,10,'ATRASO',5.00,'Atraso moderado','2025-10-19',NULL,1),
(32,8,'PERDA',120.00,'Exemplar perdido','2025-10-20',NULL,1),
(4,4,'CONDUTA',0.00,'Uso indevido de tomadas','2025-10-02','2025-10-09',0),
(1,1,'ATRASO',10.00,'Atraso ainda em aberto','2025-10-21',NULL,1);
