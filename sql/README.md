# Scripts SQL

Scripts de criação e carga do banco de dados do Pet Shop CRM (PostgreSQL 18). O modelo implementado está descrito em [Dicionário de Dados](../docs/dicionario-de-dados.md), que é a fonte da verdade: em caso de divergência, prevalece o dicionário.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `001_criar_tabelas.sql` | Configuração de fuso horário do banco, 10 tabelas, restrições (chaves primárias, chaves estrangeiras, `CHECK`, `UNIQUE`) e índices |
| `002_dados_ficticios.sql` | Dados fictícios para desenvolvimento e testes. Pressupõe tabelas vazias, recém-criadas pelo `001` |

Os scripts são executados em ordem numérica. Cada script roda em uma única transação (`BEGIN` ... `COMMIT`) e interrompe a execução no primeiro erro (`ON_ERROR_STOP`): em caso de falha, nenhuma alteração é gravada.

## Pré-requisitos

- PostgreSQL 18 instalado, com o cliente `psql`.
- Acesso com um usuário que possa criar bancos (ex.: `postgres`).

## Criação do banco do zero

No `psql`, conectado ao banco `postgres`:

```sql
\! chcp 65001
\encoding UTF8
DROP DATABASE IF EXISTS petshop_crm;
CREATE DATABASE petshop_crm;
\c petshop_crm
\i '<caminho-do-repositorio>/sql/001_criar_tabelas.sql'
\i '<caminho-do-repositorio>/sql/002_dados_ficticios.sql'
```

- `<caminho-do-repositorio>` usa barras normais, inclusive no Windows (ex.: `C:/petshop-crm`).
- `\! chcp 65001` e `\encoding UTF8` são necessários apenas no Windows, para a exibição correta de acentos no console.
- `DROP DATABASE` apaga o banco e todos os seus dados. Não é possível remover o banco ao qual a sessão está conectada; por isso, a sequência parte do banco `postgres`.
- A configuração de fuso horário (`America/Sao_Paulo`) vale para as conexões abertas após a execução do `001`.

## Conferência

| Comando | Resultado esperado |
|---|---|
| `SHOW timezone;` | `America/Sao_Paulo` (após reconectar) |
| `\dt` | 10 tabelas |
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

## Alterações no modelo

Mudanças de estrutura são registradas primeiro no [Dicionário de Dados](../docs/dicionario-de-dados.md) e no [DER](../docs/der.md), e depois aplicadas em um novo script numerado (ex.: `003_...sql`). Scripts já versionados não são editados após o uso em um banco com dados reais.
