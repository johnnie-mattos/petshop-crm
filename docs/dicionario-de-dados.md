# Dicionário de Dados (Modelo Lógico)

Este documento traduz o [DER conceitual](der.md) para o modelo lógico: para cada entidade, define a tabela, as colunas, os tipos de dado exatos do PostgreSQL, o que é obrigatório e como as tabelas se ligam por chaves estrangeiras. Ele é a ponte para o script SQL de criação das tabelas.

## Andamento

Ordem de trabalho: as tabelas que **não dependem de ninguém** vêm primeiro, porque uma chave estrangeira só pode apontar para uma tabela que já existe (o mesmo vale no script SQL).

- [x] 1. Cliente
- [x] 2. Funcionário
- [x] 3. Pet *(depende de Cliente)*
- [ ] 4. Produto Referência
- [ ] 5. Promoção
- [ ] 6. Tabela associativa Produto Referência × Promoção *(depende de 4 e 5)*
- [ ] 7. Compra *(depende de Cliente e Funcionário)*
- [ ] 8. Item da Compra *(depende de Compra e Produto Referência)*
- [ ] 9. Contato *(depende de Cliente e Funcionário)*
- [ ] 10. Tarefa *(depende de Funcionário, Contato e Cliente)*
- [ ] 11. Dicionário completo consolidado

---

## Conceitos usados neste documento

| Conceito | O que é |
|---|---|
| **Tabela / coluna / linha** | Tabela é a versão "de banco" de uma entidade. Colunas são os atributos. Cada linha é um registro (um cliente, um pet...). |
| **Chave primária (PK)** | Coluna que identifica cada linha de forma única e nunca vazia. Aqui é sempre `id`. |
| **`BIGSERIAL`** | Inteiro grande que o PostgreSQL numera sozinho (1, 2, 3...) a cada novo registro. Não é um tipo "de verdade": é um atalho que cria uma coluna `BIGINT` mais um contador automático. |
| **Chave estrangeira (FK)** | Coluna que guarda o `id` de uma linha de **outra** tabela, criando o vínculo entre elas. Como `BIGSERIAL` é só um atalho para `BIGINT`, a FK que aponta para ele é declarada como **`BIGINT`**. |
| **`NULL`** | "Não informado". É diferente de texto vazio e de zero. |
| **`NOT NULL`** | A coluna não aceita `NULL`: é o que significa "obrigatório" no banco. |
| **`UNIQUE`** | Não pode haver dois valores iguais na coluna. Vários `NULL` são permitidos. |
| **`DEFAULT`** | Valor que o banco preenche sozinho quando ninguém informa. |
| **`VARCHAR(n)`** | Texto com limite de `n` caracteres. |
| **`TEXT`** | Texto sem limite de tamanho. |
| **`DATE`** | Só a data (ano-mês-dia). |
| **`TIMESTAMPTZ`** | Data e hora **com fuso horário**. O PostgreSQL guarda o instante exato e converte para o horário local ao exibir. |
| **`BOOLEAN`** | Verdadeiro ou falso. |
| **`ON DELETE RESTRICT`** | Regra de uma FK: o banco **recusa** apagar uma linha que ainda é apontada por outras (ex.: cliente que ainda tem pets). |

## Convenções adotadas

- **Nomes de tabela:** no singular, minúsculas, sem acento e sem espaço (`cliente`, `funcionario`, `pet`). Em PostgreSQL, nomes sem aspas viram minúsculos, e acentos ou espaços obrigariam a usar aspas em toda consulta.
- **Nomes de coluna:** `snake_case` (palavras separadas por `_`), sem acento (`data_de_cadastro`, `observacoes`).
- **Chave primária:** sempre uma coluna `id` do tipo `BIGSERIAL`.
- **Chave estrangeira:** nome da tabela referenciada + `_id`, tipo `BIGINT` (ex.: `cliente_id`).
- **Coluna "Obrigatório":** `Sim` = `NOT NULL`; `Não` = aceita `NULL`.
- **Princípio de obrigatoriedade:** um campo só é obrigatório quando o sistema **não funciona sem ele**, ou quando é exigência técnica que o usuário nunca digita (como `id` e valores com `DEFAULT`). Cadastro não deve travar por falta de informação.
- **Não apagar, desativar:** entidades que deixam de ser usadas (funcionário, pet, produto, promoção) têm uma coluna booleana (`ativo`/`ativa`) em vez de serem apagadas, para o histórico continuar consultável.

---

## 1. Cliente — tabela `cliente`

**Passo a passo**

1. **Chave primária:** `id BIGSERIAL`, numerado pelo banco.
2. **Nome e telefone são obrigatórios.** O sistema existe para entrar em contato com o cliente: sem nome não se identifica quem é, e sem telefone não há como contatá-lo. É uma decisão de negócio; se algum dia vocês cadastrarem clientes sem telefone, basta trocar `Sim` por `Não` em `telefone`.
3. **Telefone é texto, não número.** Número perderia o `+55`, parênteses e zeros à esquerda, e não se faz conta com telefone.
4. **CPF é opcional e único.** Opcional porque nem todo cliente informa. `UNIQUE` impede dois clientes com o mesmo CPF; como o PostgreSQL aceita vários `NULL` em coluna `UNIQUE`, clientes sem CPF não conflitam entre si. Guardado só com dígitos (11), sem pontos nem traço.
5. **Endereço e observações:** `TEXT`, opcionais. O endereço ficou em um campo único, como no DER.
6. **Data de cadastro:** `TIMESTAMPTZ` com `DEFAULT CURRENT_TIMESTAMP`; o banco preenche no momento do `INSERT`.

| Entidade | Atributo | Tipo | Obrigatório | Chave | Observação |
|---|---|---|---|---|---|
| Cliente | `id` | BIGSERIAL | Sim | PK | Gerado automaticamente |
| Cliente | `nome` | VARCHAR(150) | Sim | - | Nome completo |
| Cliente | `telefone` | VARCHAR(20) | Sim | - | Texto, para preservar `+55`, DDD e formatação |
| Cliente | `cpf` | VARCHAR(11) | Não | UNIQUE | Só dígitos; único quando preenchido |
| Cliente | `endereco` | TEXT | Não | - | Campo único, conforme DER |
| Cliente | `observacoes` | TEXT | Não | - | Anotações livres da equipe |
| Cliente | `data_de_cadastro` | TIMESTAMPTZ | Sim | - | `DEFAULT CURRENT_TIMESTAMP` |

**Cuidado com dados pessoais.** CPF, telefone e endereço são dados pessoais (LGPD). Neste repositório, use sempre **dados fictícios** em exemplos e testes. Nunca suba dados reais de clientes para o GitHub.

---

## 2. Funcionário — tabela `funcionario`

**Passo a passo**

1. **Chave primária:** `id BIGSERIAL`.
2. **Nome obrigatório:** a compra e o contato precisam mostrar quem os realizou.
3. **Cargo opcional, em texto livre.** Nenhum processo do sistema depende do cargo (ele só informa), então, pelo princípio de obrigatoriedade, não trava o cadastro. Texto livre, sem lista fixa, para não ser preciso mexer no banco quando surgir um cargo novo.
4. **`ativo BOOLEAN NOT NULL DEFAULT TRUE`:** funcionário que sai da loja é desativado, não apagado, porque compras, contatos e tarefas antigas continuam apontando para ele. É `NOT NULL` com `DEFAULT TRUE`, então ninguém precisa preencher: todo funcionário novo nasce ativo.

| Entidade | Atributo | Tipo | Obrigatório | Chave | Observação |
|---|---|---|---|---|---|
| Funcionário | `id` | BIGSERIAL | Sim | PK | Gerado automaticamente |
| Funcionário | `nome` | VARCHAR(150) | Sim | - | Nome completo |
| Funcionário | `cargo` | VARCHAR(50) | Não | - | Texto livre (ex.: Atendente, Veterinário, Gerente) |
| Funcionário | `ativo` | BOOLEAN | Sim | - | `DEFAULT TRUE`; desativar em vez de apagar |

---

## 3. Pet — tabela `pet`

Entidade nova, criada para guardar vários pets por cliente sem colocar uma lista dentro de um único campo (1ª Forma Normal). Relação do DER: **Cliente 1:N Pet**.

**Passo a passo**

1. **Chave primária:** `id BIGSERIAL`.
2. **Chave estrangeira `cliente_id`.** Em um relacionamento 1:N, a FK fica sempre na tabela do lado "N" (muitos). Um cliente tem vários pets, então a coluna que aponta para o cliente fica em `pet`. Tipo `BIGINT`, o mesmo tipo do `id` de `cliente`.
3. **`cliente_id` é a única coluna de negócio obrigatória**, por exigência do próprio DER: "um pet sempre pertence a exatamente um cliente". Sem ela, existiria um pet sem dono, que não aparece em nenhuma tela. Ela nunca é digitada: o sistema a preenche ao cadastrar o pet dentro de um cliente, então não trava nenhum processo.
4. **Nada digitado é obrigatório.** Nome, espécie, raça, porte, data de nascimento e observações são opcionais, como você decidiu. Quando o nome faltar, a tela pode exibir algo como "Pet sem nome".
5. **Porte como texto curto.** Valores esperados: pequeno, médio, grande. O banco aceita qualquer texto; se um dia for preciso restringir, dá para acrescentar uma regra `CHECK` sem perder dados (`CHECK` aceita `NULL`).
6. **Data de nascimento é `DATE`.** Não há necessidade de hora. Se o tutor só souber a idade aproximada ("uns 3 anos"), a equipe informa uma data aproximada e anota isso em `observacoes`.
7. **`ativo BOOLEAN NOT NULL DEFAULT TRUE`:** mesmo padrão de Funcionário. O pet que deixa de ser atendido é desativado, não apagado.
8. **`ON DELETE RESTRICT` na FK:** o banco recusa apagar um cliente que ainda tem pets cadastrados. É a mesma ideia de "não apagar, desativar": evita perder pets por acidente.

| Entidade | Atributo | Tipo | Obrigatório | Chave | Observação |
|---|---|---|---|---|---|
| Pet | `id` | BIGSERIAL | Sim | PK | Gerado automaticamente |
| Pet | `cliente_id` | BIGINT | Sim | FK → `cliente.id` | Tutor do pet; `ON DELETE RESTRICT`. Preenchido pelo sistema, não digitado |
| Pet | `nome` | VARCHAR(100) | Não | - | Opcional |
| Pet | `especie` | VARCHAR(50) | Não | - | Opcional (cachorro, gato, ave...) |
| Pet | `raca` | VARCHAR(80) | Não | - | Opcional |
| Pet | `porte` | VARCHAR(20) | Não | - | Opcional (pequeno, médio, grande) |
| Pet | `data_de_nascimento` | DATE | Não | - | Opcional; pode ser data aproximada |
| Pet | `observacoes` | TEXT | Não | - | Opcional (alergias, temperamento, cuidados) |
| Pet | `ativo` | BOOLEAN | Sim | - | `DEFAULT TRUE`; desativar em vez de apagar |

**Quantidade de pets de um cliente:** não existe coluna para isso. O número é calculado contando as linhas de `pet` daquele cliente, para nunca ficar diferente da lista real.

---

## O que mudou em relação à versão anterior (Cliente e Funcionário)

| Entidade | Mudança | Motivo |
|---|---|---|
| Cliente | `data_de_cadastro`: `TIMESTAMP` → `TIMESTAMPTZ` | `TIMESTAMP` guarda data e hora sem dizer em que fuso. `TIMESTAMPTZ` guarda o instante exato e é a escolha recomendada no PostgreSQL; evita erros se o servidor ou o horário de verão mudarem. |
| Funcionário | `cargo`: obrigatório → opcional | Nenhum processo depende do cargo; aplica o princípio "só é obrigatório o que o sistema não consegue funcionar sem". |
| Cliente | Acrescentado o aviso de dados pessoais (LGPD) | Projeto de portfólio público não deve conter dados reais de clientes. |
| Convenções | Nomes sem acento e `snake_case` formalizados | Evita aspas obrigatórias em todo SQL. |

Os demais campos de Cliente e Funcionário permanecem como aprovados.

---

## Como seguir com as próximas entidades

Para cada entidade, repetimos o mesmo ciclo:

1. **Conceito:** explico o que for novo (por exemplo, `NUMERIC` para dinheiro, ou a tabela associativa do N:N).
2. **Tabela:** definimos juntos nome da tabela, PK, atributos, tipos, obrigatoriedade e FKs, usando as 5 perguntas por atributo:
   - Que tipo de informação é (texto, número, data, sim/não)?
   - Qual o tamanho máximo razoável?
   - O sistema funciona sem ela? (decide `NOT NULL`)
   - Precisa ser única? (`UNIQUE`)
   - O banco pode preencher sozinho? (`DEFAULT`)
3. **Registro:** a tabela entra neste arquivo.
4. **Commit:** um commit por entidade, por exemplo `docs: dicionario de dados - produto referencia`.

No fim, este arquivo terá o dicionário completo e servirá de base para o script `sql/001_criar_tabelas.sql`.
