# Scripts SQL

Scripts SQL executados manualmente no Pet Shop CRM (PostgreSQL 18). O modelo implementado está descrito em [Dicionário de Dados](../docs/dicionario-de-dados.md), que é a fonte da verdade: em caso de divergência, prevalece o dicionário.

## Estrutura do banco: migrações (Flyway)

A estrutura do banco (tabelas, restrições e índices) **não** é criada por scripts desta pasta. Ela é gerenciada pelo [Flyway](https://documentation.red-gate.com/flyway), executado automaticamente na inicialização do backend.

| Item | Local |
|---|---|
| Migrações | `backend/src/main/resources/db/migration/` |
| Migração inicial | `V1__criar_tabelas.sql`: configuração de fuso horário, 10 tabelas, restrições e índices |
| Controle de execução | Tabela `flyway_schema_history`, criada pelo Flyway no próprio banco |

Funcionamento:

- Na inicialização, o Flyway compara as migrações da pasta com as registradas em `flyway_schema_history` e executa, em ordem de versão, apenas as pendentes.
- Cada migração é executada em uma transação: em caso de erro, nenhuma alteração é gravada e o backend não inicia.
- Nome das migrações: `V<versão>__<descrição>.sql` (dois sublinhados). Ex.: `V2__adicionar_login.sql`.
- Migrações já aplicadas **não são editadas**: o Flyway detecta a alteração (checksum) e interrompe a inicialização. Mudanças no modelo são registradas primeiro no [Dicionário de Dados](../docs/dicionario-de-dados.md) e no [DER](../docs/der.md), e depois aplicadas em uma nova migração.
- O Flyway exige um banco vazio na primeira execução. Um banco que já possui tabelas, sem `flyway_schema_history`, interrompe a inicialização.

## Arquivos desta pasta

| Arquivo | Conteúdo |
|---|---|
| `002_dados_ficticios.sql` | Dados fictícios para desenvolvimento e testes. Pressupõe tabelas vazias, recém-criadas pela migração `V1`. Não é uma migração e não deve ser aplicado no banco de produção |

## Pré-requisitos

- PostgreSQL 18 instalado, com o cliente `psql`.
- Acesso com um usuário que possa criar bancos (ex.: `postgres`).
- Backend configurado (ver `backend/src/main/resources/application.properties`), com a senha do banco na variável de ambiente `DB_PASSWORD`.

## Criação do banco de desenvolvimento do zero

1. No `psql`, conectado ao banco `postgres`:

   ```sql
   \! chcp 65001
   \encoding UTF8
   DROP DATABASE IF EXISTS petshop_crm;
   CREATE DATABASE petshop_crm;
   ```

2. Iniciar o backend. O Flyway aplica as migrações e cria as tabelas.

3. No `psql`, carregar os dados fictícios:

   ```sql
   \c petshop_crm
   \i '<caminho-do-repositorio>/sql/002_dados_ficticios.sql'
   ```

Observações:

- `<caminho-do-repositorio>` usa barras normais, inclusive no Windows (ex.: `C:/petshop-crm`).
- `\! chcp 65001` e `\encoding UTF8` são necessários apenas no Windows, para a exibição correta de acentos no console.
- `DROP DATABASE` apaga o banco e todos os seus dados. Não é possível remover o banco ao qual a sessão está conectada; por isso, a sequência parte do banco `postgres`.
- A configuração de fuso horário (`America/Sao_Paulo`) vale para as conexões abertas após a execução da migração `V1`.

## Conferência

| Comando | Resultado esperado |
|---|---|
| `SHOW timezone;` | `America/Sao_Paulo` (após reconectar) |
| `\dt` | 10 tabelas do modelo e `flyway_schema_history` |
| `SELECT version, description, success FROM flyway_schema_history;` | Migração `1`, `criar tabelas`, `t` |
| `\d <tabela>` | Colunas, padrões, índices e restrições da tabela |

## Convenção de nomes das restrições

Restrições nomeadas explicitamente, no padrão do PostgreSQL:

| Restrição | Padrão | Exemplo |
|---|---|---|
| Chave primária | `<tabela>_pkey` | `cliente_pkey` |
| Chave estrangeira | `<tabela>_<coluna>_fkey` | `pet_cliente_id_fkey` |
| `UNIQUE` | `<tabela>_<coluna>_key` | `cliente_cpf_key` |
| `CHECK` | `<tabela>_<coluna>_check` | `contato_status_check` |
| Índice | `<tabela>_<colunas>_idx` | `contato_data_do_contato_status_idx` |

Restrições `NOT NULL` recebem do PostgreSQL o nome `<tabela>_<coluna>_not_null`. Mensagens de erro citam o nome da restrição violada.

## Dados fictícios

Todos os registros do `002` são fictícios (nomes "Cliente Teste N", telefones `(00) 00000-000N`, CPFs `0000000000N`). Dados reais de clientes não devem ser incluídos no repositório (LGPD).

Datas relativas (`CURRENT_DATE`, `CURRENT_TIMESTAMP - INTERVAL`) mantêm os cenários válidos em qualquer dia de execução, entre eles:

- cliente há mais de 30 dias sem comprar, com contato pendente para o dia;
- cliente inativo;
- produto em mais de uma promoção (N:N);
- promoção sem data de término e sem percentual;
- item com quantidade fracionada e item com desconto;
- contato que gerou tarefa e tarefa independente, sem responsável.
