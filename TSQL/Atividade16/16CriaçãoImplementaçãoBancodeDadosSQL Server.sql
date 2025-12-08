-- Filtrando Registro com comando Where - DML
select 
	[code]
	,[Nome]
	,[Address]
	,[Phone]
	,[Birthdate]
	from [dbo].[tbcostumer]
WHERE CODE > 1

Este código maior que 1 obteve o retorno de todos os dados da tabela do banco de dados.
Maior que 7 por só possuir 6 registros não retorna nenhum dado.

code	Nome				Address								Phone		Birthdate
6		Guilherme da Silva	Rua das Pedras, 132Santa Rosa, SC	48-32334567	1987-12-18 00:00:00.00



-- Consulta Registro com Operador AND- DML
select 
	[code]
	,[Nome]
	,[Address]
	,[Phone]
	,[Birthdate]
	from [dbo].[tbcostumer]
WHERE CODE> 5
and [Birthdate]>'1980-01-01';

code	Nome				Address								Phone		Birthdate
6		Guilherme da Silva	Rua das Pedras, 132Santa Rosa, SC	48-32334567	1987-12-18 00:00:00.00

-- Consulta Registro com Operador OR- DML
select 
	[code]
	,[Nome]
	,[Address]
	,[Phone]
	,[Birthdate]
	from [dbo].[tbcostumer]
WHERE CODE> 7
or [Birthdate]>'1980-01-01';

1	Paulo Roberto	Ruas das Pedras, 132, Santa Rosa, SC	48-32334567	1987-12-18 00:00:00.000
2	Maria Paula	Ruas das Tainhas,54, Santa Rosa, SC	48-323342643	1981-11-13 00:00:00.000
5	Paulo Dutra	Rua das Bromelias, 11, Santa Rosa, SC	48-91918282	1986-01-01 00:00:00.000
6	Guilherme da Silva	Rua das Pedras, 132Santa Rosa, SC	48-32334567	1987-12-18 00:00:00.000


-- Consulta Registro com Operador Between- DML
select 
	[code]
	,[Nome]
	,[Address]
	,[Phone]
	,[Birthdate]
	from [dbo].[tbcostumer]
WHERE CODE> 2
and Birthdate Between '19700101' and '19850101'

3	Rodrigo Ruas	Ruas das Esmeraldas, 165, Santa Rosa, SC	48-998988776	1980-01-01 00:00:00.000
4	Maria das Dores	Rua dos Badejos, 9898, Santa Rosa, SC	65861413	1977-01-02 00:00:00.000


-- Consulta Registro com Operador Like - DML
select 
	[code]
	,[Nome]
	,[Address]
	,[Phone]
	from [dbo].[tbcostumer]
where Nome like '%Dutra%'

5	Paulo Dutra	Rua das Bromelias, 11, Santa Rosa, SC	48-91918282


-- Consulta Registro com Comando top- DML
select top 3
[code]
	,[Nome]
	,[Address]
	,[Phone]
	from [dbo].[tbcostumer]
where Nome like '%Silva%'

6	Guilherme da Silva	Rua das Pedras, 132Santa Rosa, SC	48-32334567


-- Consulta registros com ordenação
select
	[code]
	,[Nome]
	,[Address]
	,[Phone]
	from [dbo].[tbcostumer]
order by nome

6	Guilherme da Silva	Rua das Pedras, 132Santa Rosa, SC	48-32334567
4	Maria das Dores	Rua dos Badejos, 9898, Santa Rosa, SC	65861413
2	Maria Paula	Ruas das Tainhas,54, Santa Rosa, SC	48-323342643
5	Paulo Dutra	Rua das Bromelias, 11, Santa Rosa, SC	48-91918282
1	Paulo Roberto	Ruas das Pedras, 132, Santa Rosa, SC	48-32334567
3	Rodrigo Ruas	Ruas das Esmeraldas, 165, Santa Rosa, SC	48-998988776


-- Atualização de Registros
update
	tbcostumer
set
	Address = 'Rua da Saudade, Florianopolis,SC'
	,Phone = '48-23345657'
where
	code = 1

	select * from tbcostumer

-- Remover ou exlcuir registos
DELETE tbcostumer
WHERE CODE = 10;
-- Remover todos os registros da tabela

truncate table tbcostumer

1	Paulo Roberto	Rua da Saudade, Florianopolis,SC	48-23345657	joao@hotmail.com	1987-12-18 00:00:00.000
2	Maria Paula	Ruas das Tainhas,54, Santa Rosa, SC	48-323342643	mario@hotmail.com	1981-11-13 00:00:00.000
3	Rodrigo Ruas	Ruas das Esmeraldas, 165, Santa Rosa, SC	48-998988776	paulo@hotmail.com	1980-01-01 00:00:00.000
4	Maria das Dores	Rua dos Badejos, 9898, Santa Rosa, SC	65861413	maria@hotmail.com	1977-01-02 00:00:00.000
5	Paulo Dutra	Rua das Bromelias, 11, Santa Rosa, SC	48-91918282	paula@hotmail.com	1986-01-01 00:00:00.000
6	Guilherme da Silva	Rua das Pedras, 132Santa Rosa, SC	48-32334567	joao@hotmail.com	1987-12-18 00:00:00.000

-- Criando tabelas temporarias
create table #tbcostumer(
	code int identity(1,1) primary key,
	nome varchar(100) null,
	address varchar(200) null,
	phone varchar(25) null,
	email varchar(100) null,
	birthdate datetime not null)

Comandos concluídos com êxito.

Horário de conclusão: 2025-12-08T16:51:56.3053816-03:00


-- Relacionamentos e Integridade Referencial
create table tbproduct(
	code int identity(1,1) not null,
	description varchar (150) null,
	salevalue decimal(18,2) null,
	active bit default 1,
	primary key (code)
);

create table tbsale(
	code int identity(1,1) not null,
	costumer int null
	REFERENCES tbcostumer(code),
	saledate datetime default getdate(),
	primary key (code)
);
create table tbsaledetail(
	sale int not null
		references tbsale(code)
			on delete no action,
	product int not null,
	quantity int not null,
	salevalue decimal(18,2) null,
	primary key (product, sale)
);

sp_help tbsale  -- acusa erro aqui
sp_help tbsaledetail

alter table tbsaledetail
add constraint fkProdutos
foreign key(Product)references tbproduct(code) 

select * from tbsaledetail



create table tbcategory(
	code int identity(1,1) not null,
	description varchar(150) null,
	primary key(code)
);

alter table tbproduct
add category int null

alter table tbproduct
add constraint fkcategory
foreign key(category)references tbcategory(code);

sp_help tbcategory


-- 1. Inserindo registros na tabela categorias
insert into [dbo].[tbcategory](description)
values
('Books'),
('Cell Phones'),
('Tablets'),
('Notebooks'),
('Office Supply');
GO

-- Consulta a ser executada em um lote separado
select * from tbproduct
GO

-- 2. Inserindo registros na tabela produtos (Removido o caractere inválido)
insert into tbproduct 
(description, salevalue, active, category)
values
('Cathcer in Rye', 55.00, 1, 1),
('How to make Friends and Influencer People', 55.00, 1, 1), -- Corrigido o espaço
('Samsumg Galaxy S III', 1999.00, 1, 2),
('Apple Iphone 5', 2199.00, 1, 2),
('Samsumg Galaxy Tab II', 1999.00, 1, 3),
('Motorola Xoom', 1099.00, 1, 3),
('Dell Ultrabook 14', 2499.00, 1, 4),
('ASUS Ultrabook 14', 2599.00, 1, 4),
('Paper Sheredder', 1099.00, 1, 5),
('Notebook Stand', 1099.00, 1, 5);
GO

code	description	salevalue	active	category
1	Cathcer in Rye	55.00	1	1
2	How to make Friends and Influencer People	55.00	1	1
3	Samsumg Galaxy S III	1999.00	1	2
4	Apple Iphone 5	2199.00	1	2
5	Samsumg Galaxy Tab II	1999.00	1	3
6	Motorola Xoom	1099.00	1	3
7	Dell Ultrabook 14	2499.00	1	4
8	ASUS Ultrabook 14	2599.00	1	4
9	Paper Sheredder	1099.00	1	5
10	Notebook Stand	1099.00	1	5


