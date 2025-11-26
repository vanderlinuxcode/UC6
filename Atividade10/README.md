
1. Definição: Tabela Virtual
   
Uma View é essencialmente uma tabela virtual ou uma tabela salva de consulta.
    • O que é uma View?
        ◦ É um objeto de banco de dados definido por uma instrução SQL (SELECT).
        ◦ É uma entidade virtual (ou lógica) porque não armazena dados próprios. Ela é apenas o código SQL que é executado no momento da consulta.
    • Como se difere de uma Tabela Física?
        ◦ Tabela Física: É uma estrutura de armazenamento que ocupa espaço no disco e contém os dados reais.
        ◦ View: É uma estrutura lógica que não armazena dados. Ela é uma "janela" que mostra dados atuais das tabelas físicas subjacentes. Se os dados da tabela física mudarem, o conteúdo da View muda instantaneamente, pois a consulta é executada a cada vez.

2. Abstração de Dados
   
Este é o papel fundamental das Views: simplificar a interação com o banco de dados e proteger a complexidade interna.
    • Simplificação de Consultas Complexas: A View permite que você oculte a lógica de buscas complexas. Se você precisa ligar três ou quatro tabelas (como pedidos, itens_pedido e produtos) usando múltiplos JOINs, o usuário ou a aplicação não precisa escrever essa lógica complexa toda vez.
    • Camada de Abstração: A View atua como uma interface simplificada. O usuário final ou a aplicação interage apenas com a View, que apresenta os dados de forma clara e consolidada, sem precisar conhecer o esquema subjacente (nomes de tabelas, chaves primárias/estrangeiras ou a lógica dos JOINs).
        ◦ Exemplo: Em vez de consultar: SELECT ... FROM TabelaA JOIN TabelaB JOIN TabelaC..., o usuário consulta simplesmente: SELECT ... FROM view_dados_consolidados.

3. Reuso de Código
   
A View transforma uma consulta complexa e potencialmente demorada de escrever em um objeto reutilizável.
    • Consulta Padronizada: Uma vez que a View é criada, ela armazena a lógica SQL complexa como um padrão definido. Isso permite que a mesma consulta complexa seja executada repetidamente por diferentes usuários e aplicações, garantindo que todos usem a mesma lógica de negócio exata.
    • Manutenção Centralizada: Promove o princípio "Don't Repeat Yourself" (DRY). Se a lógica de ligação (JOINs) ou a definição dos campos de interesse precisarem ser alteradas, você modifica apenas a definição da View em um local central. Todas as consultas que a utilizam se beneficiam da mudança imediatamente, sem a necessidade de reescrever o código SQL em cada aplicação ou script.
    
Tipos de Views Exploradas (e Seus Benefícios)


View de Consolidação e relatório:

<img width="724" height="482" alt="view_clientes_sem_senha" src="https://github.com/user-attachments/assets/cf2bfb0b-6719-4dae-b59a-f024ae239e2c" />

View de Segurança e acesso:

<img width="724" height="482" alt="view_clientes_sem_senha" src="https://github.com/user-attachments/assets/e88e6110-f3b4-4180-bcbd-f5b741691f8a" />


View de Lógica de Negócio e Filtro:
Obs.: Para os dados não obteve abaixo de 10 em estoque, utilizei abaixo de 30 para um retorno satisfatório do estoque atual.

<img width="798" height="532" alt="view_pedidos_detalhados_menor30" src="https://github.com/user-attachments/assets/cad97c69-f863-4805-8db2-a20d73d43500" />







