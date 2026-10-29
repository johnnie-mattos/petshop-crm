# Dicionário de Dados (Modelo Lógico)

Tradução do [DER conceitual](der.md) para o modelo lógico: tabelas, colunas, tipos de dado do PostgreSQL, obrigatoriedade e chaves estrangeiras. Base para o script SQL de criação das tabelas. O fluxo para acrescentar entidades está descrito em [CONTRIBUTING.md](../CONTRIBUTING.md).

## Critérios de modelagem

### Critérios por atributo

Cada atributo é definido pela aplicação dos cinco critérios abaixo.

| # | Critério | Regra aplicada |
|---|---|---|
| 1 | **Tipo de informação** | Texto → `VARCHAR(n)` ou `TEXT`. Valor monetário → `NUMERIC(p,s)`. Data → `DATE`. Data e hora → `TIMESTAMPTZ`. Verdadeiro/falso → `BOOLEAN`. Identificadores que não participam de cálculo (telefone, CPF, códigos) são texto, para preservar zeros à esquerda e símbolos. |
| 2 | **Tamanho máximo** | `VARCHAR(n)` com limite compatível com o domínio do dado. `TEXT` para campos livres sem limite natural. |
| 3 | **Obrigatoriedade (`NOT NULL`)** | Um atributo é obrigatório somente quando o sistema não opera sem ele, ou quando o valor é preenchido pelo próprio sistema (`id`, chaves estrangeiras, valores com `DEFAULT`). Os demais aceitam `NULL`. |
| 4 | **Unicidade (`UNIQUE`)** | Aplicada a atributos que não podem se repetir entre registros (ex.: `cpf`). Múltiplos `NULL` são permitidos. |
| 5 | **Valor padrão (`DEFAULT`)** | Aplicado quando o banco pode preencher o valor sem intervenção do usuário (ex.: `ativo = TRUE`, `data_de_cadastro = CURRENT_TIMESTAMP`). |

### Convenções

- **Tabelas:** singular, minúsculas, sem acento e sem espaço (`cliente`, `funcionario`, `pet`).
- **Colunas:** `snake_case`, sem acento (`data_de_cadastro`, `observacoes`).
- **Chave primária:** coluna `id` do tipo `BIGSERIAL`. Exceção: tabelas associativas (relacionamentos N:N sem atributos próprios) usam chave primária composta pelas duas chaves estrangeiras.
- **Chave estrangeira:** nome da tabela referenciada + `_id`, tipo `BIGINT` (ex.: `cliente_id`). O tipo é `BIGINT` porque `BIGSERIAL` é um atalho para `BIGINT` com sequência automática.
- **Coluna "Obrigatório":** `Sim` equivale a `NOT NULL`; `Não` aceita `NULL`.
- **Desativação em vez de exclusão:** entidades que deixam de ser utilizadas (funcionário, pet, produto, promoção) possuem coluna booleana (`ativo`/`ativa`), preservando o histórico.
- **Integridade referencial:** chaves estrangeiras usam `ON DELETE RESTRICT`, que impede excluir um registro ainda referenciado por outro.

## Glossário

| Termo | Definição |
|---|---|
| Chave primária (PK) | Coluna que identifica cada linha de forma única; nunca nula. |
| Chave estrangeira (FK) | Coluna que referencia a chave primária de outra tabela. |
| `BIGSERIAL` | Inteiro de 8 bytes com numeração automática. |
| `NULL` | Valor não informado. |
| `TIMESTAMPTZ` | Data e hora com fuso horário; armazena o instante exato e converte para o horário local na exibição. |
| `CHECK` | Regra de validação aplicada a uma coluna; valores `NULL` não a violam. |

## Andamento

As tabelas são registradas em ordem de dependência: uma chave estrangeira só pode referenciar uma tabela já definida (o mesmo vale para o script SQL).

- [x] 1. Cliente
- [x] 2. Funcionário
- [x] 3. Pet *(depende de Cliente)*
- [x] 4. Produto Referência
- [x] 5. Promoção
- [x] 6. Tabela associativa Produto Referência × Promoção *(depende de 4 e 5)*
- [x] 7. Compra *(depende de Cliente e Funcionário)*
- [ ] 8. Item da Compra *(depende de Compra e Produto Referência)*
- [ ] 9. Contato *(depende de Cliente e Funcionário)*
- [ ] 10. Tarefa *(depende de Funcionário, Contato e Cliente)*
- [ ] 11. Dicionário consolidado

---

## 1. Cliente — tabela `cliente`

**Decisões de modelagem**

- `nome` e `telefone` são obrigatórios: o fluxo de contato depende de identificar e de poder contatar o cliente. A obrigatoriedade de `telefone` pode ser revista caso passem a existir clientes cadastrados sem telefone.
- `telefone` é armazenado como texto, para preservar `+55`, DDD e formatação.
- `cpf` é opcional e `UNIQUE`: nem todo cliente o informa, e não pode haver dois clientes com o mesmo CPF. Armazenado apenas com dígitos (11).
- `endereco` é um campo único, conforme o DER.
- `data_de_cadastro` é `TIMESTAMPTZ` com `DEFAULT CURRENT_TIMESTAMP`, preenchida pelo banco no `INSERT`.

| Entidade | Atributo | Tipo | Obrigatório | Chave | Observação |
|---|---|---|---|---|---|
| Cliente | `id` | BIGSERIAL | Sim | PK | Gerado automaticamente |
| Cliente | `nome` | VARCHAR(150) | Sim | - | Nome completo |
| Cliente | `telefone` | VARCHAR(20) | Sim | - | Texto, para preservar `+55`, DDD e formatação |
| Cliente | `cpf` | VARCHAR(11) | Não | UNIQUE | Só dígitos; único quando preenchido |
| Cliente | `endereco` | TEXT | Não | - | Campo único, conforme DER |
| Cliente | `observacoes` | TEXT | Não | - | Anotações livres da equipe |
| Cliente | `data_de_cadastro` | TIMESTAMPTZ | Sim | - | `DEFAULT CURRENT_TIMESTAMP` |

> **Dados pessoais (LGPD):** `cpf`, `telefone` e `endereco` são dados pessoais. Exemplos, testes e arquivos deste repositório utilizam apenas dados fictícios.

---

## 2. Funcionário — tabela `funcionario`

**Decisões de modelagem**

- `nome` é obrigatório: compras e contatos exibem quem os realizou.
- `cargo` é opcional e de texto livre: nenhum processo depende dele, e a ausência de lista fixa evita alteração no banco a cada novo cargo.
- `ativo` é `NOT NULL` com `DEFAULT TRUE`: o funcionário é desativado, não excluído, porque compras, contatos e tarefas antigas o referenciam.

| Entidade | Atributo | Tipo | Obrigatório | Chave | Observação |
|---|---|---|---|---|---|
| Funcionário | `id` | BIGSERIAL | Sim | PK | Gerado automaticamente |
| Funcionário | `nome` | VARCHAR(150) | Sim | - | Nome completo |
| Funcionário | `cargo` | VARCHAR(50) | Não | - | Texto livre (ex.: Atendente, Veterinário, Gerente) |
| Funcionário | `ativo` | BOOLEAN | Sim | - | `DEFAULT TRUE`; desativar em vez de excluir |

---

## 3. Pet — tabela `pet`

Relacionamento do DER: **Cliente 1:N Pet**. A entidade evita armazenar uma lista de pets em um único campo do cliente (1ª Forma Normal).

**Decisões de modelagem**

- A chave estrangeira `cliente_id` fica em `pet`, o lado "N" do relacionamento. É obrigatória: todo pet pertence a exatamente um cliente. É preenchida pelo sistema, não digitada.
- Nenhum dado digitado é obrigatório (`nome`, `especie`, `raca`, `porte`, `data_de_nascimento`, `observacoes`): o cadastro não deve ser bloqueado por informação ausente. Pet sem nome é exibido com um texto padrão pela aplicação.
- `porte` é texto curto (valores esperados: pequeno, médio, grande). Uma restrição `CHECK` pode ser acrescentada sem perda de dados.
- `data_de_nascimento` é `DATE`. Datas aproximadas são aceitas, com a observação registrada em `observacoes`.
- `ativo` é `NOT NULL` com `DEFAULT TRUE`; o pet é desativado, não excluído.
- A quantidade de pets de um cliente é derivada (contagem das linhas de `pet`); não há coluna correspondente.

| Entidade | Atributo | Tipo | Obrigatório | Chave | Observação |
|---|---|---|---|---|---|
| Pet | `id` | BIGSERIAL | Sim | PK | Gerado automaticamente |
| Pet | `cliente_id` | BIGINT | Sim | FK → `cliente.id` | Tutor do pet; `ON DELETE RESTRICT`; preenchido pelo sistema |
| Pet | `nome` | VARCHAR(100) | Não | - | Opcional |
| Pet | `especie` | VARCHAR(50) | Não | - | Opcional (cachorro, gato, ave...) |
| Pet | `raca` | VARCHAR(80) | Não | - | Opcional |
| Pet | `porte` | VARCHAR(20) | Não | - | Opcional (pequeno, médio, grande) |
| Pet | `data_de_nascimento` | DATE | Não | - | Opcional; pode ser data aproximada |
| Pet | `observacoes` | TEXT | Não | - | Opcional (alergias, temperamento, cuidados) |
| Pet | `ativo` | BOOLEAN | Sim | - | `DEFAULT TRUE`; desativar em vez de excluir |

---

## 4. Produto Referência — tabela `produto_referencia`

Catálogo de consulta dos produtos vendidos. O sistema de vendas (Open) permanece como fonte oficial de preço e estoque; esta tabela mantém uma cópia de referência para uso no CRM. Não possui chaves estrangeiras: a relação com Item da Compra (1:N) é mantida em `item_da_compra`, e a relação com Promoção (N:N) em tabela associativa.

**Decisões de modelagem**

- `codigo` é obrigatório e `UNIQUE`: é o identificador do produto no Open, e impede o cadastro duplicado do mesmo produto. Armazenado como texto, para preservar zeros à esquerda e letras.
- `preco` é `NUMERIC(10,2)` (valor exato, sem arredondamento binário) e opcional: a ausência de preço não impede a operação do sistema. `CHECK (preco >= 0)` impede valores negativos.
- `categoria` e `marca` são texto livre, conforme o DER. A padronização dos valores é responsabilidade da aplicação. Evolução possível: tabelas próprias de categoria e marca, referenciadas por chave estrangeira, caso a inconsistência de digitação se torne um problema.
- O preço praticado em cada venda é registrado em `item_da_compra.valor_unitario`; alterações em `preco` não afetam o histórico de compras.
- `atualizado_em` recebe `DEFAULT CURRENT_TIMESTAMP` no `INSERT`. A atualização nos `UPDATE` é responsabilidade da aplicação (ou de *trigger*).
- `ativo` é `NOT NULL` com `DEFAULT TRUE`; o produto é desativado, não excluído.

| Entidade | Atributo | Tipo | Obrigatório | Chave | Observação |
|---|---|---|---|---|---|
| Produto Referência | `id` | BIGSERIAL | Sim | PK | Gerado automaticamente |
| Produto Referência | `nome` | VARCHAR(200) | Sim | - | Nome completo do produto |
| Produto Referência | `categoria` | VARCHAR(80) | Não | - | Texto livre (ração, brinquedo, medicamento...) |
| Produto Referência | `marca` | VARCHAR(80) | Não | - | Texto livre |
| Produto Referência | `preco` | NUMERIC(10,2) | Não | - | Cópia de referência do preço do Open; `CHECK (preco >= 0)` |
| Produto Referência | `codigo` | VARCHAR(50) | Sim | UNIQUE | Código do produto no Open; texto |
| Produto Referência | `ativo` | BOOLEAN | Sim | - | `DEFAULT TRUE`; desativar em vez de excluir |
| Produto Referência | `atualizado_em` | TIMESTAMPTZ | Sim | - | `DEFAULT CURRENT_TIMESTAMP` |

---

## 5. Promoção — tabela `promocao`

Campanha promocional que pode envolver vários produtos. Não possui chaves estrangeiras: a relação N:N com Produto Referência é mantida em tabela associativa.

**Decisões de modelagem**

- `nome` e `data_de_inicio` são obrigatórios: o fluxo de contato ("produto entrou em promoção") e o encarte dependem de situar a promoção no tempo, e o nome identifica a campanha.
- `data_de_inicio` e `data_de_termino` são `DATE`: a vigência é medida em dias.
- `data_de_termino` é opcional: `NULL` indica promoção sem data de término definida. `CHECK (data_de_termino >= data_de_inicio)` impede término anterior ao início.
- `percentual_de_desconto` é opcional, `NUMERIC(5,2)`, com `CHECK (percentual_de_desconto BETWEEN 0 AND 100)`. Promoções que não são percentuais (ex.: "leve 3, pague 2") são descritas em `descricao`.
- `ativa` é uma chave manual de ativação, `NOT NULL` com `DEFAULT TRUE`, que permite suspender a promoção antes do término.
- A vigência não é armazenada: é calculada na consulta. Promoção vigente = `ativa = TRUE` e a data atual entre `data_de_inicio` e `data_de_termino` (ou `data_de_termino` nula).

| Entidade | Atributo | Tipo | Obrigatório | Chave | Observação |
|---|---|---|---|---|---|
| Promoção | `id` | BIGSERIAL | Sim | PK | Gerado automaticamente |
| Promoção | `nome` | VARCHAR(120) | Sim | - | Identifica a campanha (ex.: "Semana do Banho") |
| Promoção | `data_de_inicio` | DATE | Sim | - | Primeiro dia de vigência |
| Promoção | `data_de_termino` | DATE | Não | - | `NULL` = sem data de término definida; `CHECK (data_de_termino >= data_de_inicio)` |
| Promoção | `descricao` | TEXT | Não | - | Detalhes da campanha |
| Promoção | `percentual_de_desconto` | NUMERIC(5,2) | Não | - | `CHECK (percentual_de_desconto BETWEEN 0 AND 100)` |
| Promoção | `ativa` | BOOLEAN | Sim | - | `DEFAULT TRUE`; chave manual de suspensão |

---

## 6. Produto × Promoção — tabela `produto_promocao`

Tabela associativa do relacionamento **Produto Referência N:N Promoção** (zero ou muitos nos dois lados). Cada linha representa o vínculo "este produto participa desta promoção". Uma promoção pode existir sem produtos vinculados, e um produto pode não estar em nenhuma promoção.

**Decisões de modelagem**

- A chave primária é composta por `produto_referencia_id` e `promocao_id`: cada coluna pode se repetir, mas o par não. Isso impede vincular o mesmo produto duas vezes à mesma promoção.
- Ambas as colunas são chaves estrangeiras obrigatórias, com `ON DELETE RESTRICT`: não é possível excluir um produto ou uma promoção que ainda possua vínculos. Remover um produto de uma promoção corresponde a excluir a linha desta tabela.
- A tabela não possui atributos próprios: o desconto é definido por promoção (`promocao.percentual_de_desconto`) e vale para todos os seus produtos. Caso passe a ser necessário um preço ou desconto específico por produto, a coluna correspondente é acrescentada a esta tabela.
- Índice adicional em `promocao_id` (consulta dos produtos de uma promoção, como no encarte): a ser definido no script SQL.

| Entidade | Atributo | Tipo | Obrigatório | Chave | Observação |
|---|---|---|---|---|---|
| Produto × Promoção | `produto_referencia_id` | BIGINT | Sim | PK composta; FK → `produto_referencia.id` | `ON DELETE RESTRICT` |
| Produto × Promoção | `promocao_id` | BIGINT | Sim | PK composta; FK → `promocao.id` | `ON DELETE RESTRICT` |

---

## 7. Compra — tabela `compra`

Venda realizada no sistema Open, registrada no CRM por referência, para formar o histórico de compras do cliente. Relacionamentos do DER: **Cliente 1:N Compra**, **Funcionário 1:N Compra** e **Compra 1:N Item da Compra** (a chave estrangeira desta última fica em `item_da_compra`).

**Decisões de modelagem**

- `cliente_id` e `funcionario_id` são obrigatórios, conforme o DER (cada compra tem exatamente um cliente e exatamente um vendedor). Sem cliente não há histórico nem contato; o vendedor responsável deve ser sempre identificado, para apuração de resultados por vendedor. Ambas usam `ON DELETE RESTRICT`: cliente e funcionário com compras registradas não podem ser excluídos, e o funcionário que sai da loja é desativado (`ativo = FALSE`), preservando o histórico de vendas.
- Cada compra tem um único vendedor. Caso futuramente uma venda precise ser compartilhada entre vendedores, o relacionamento passa a N:N e exige tabela associativa.
- `data_da_compra` corresponde ao atributo `data` do DER. O nome descritivo evita ambiguidade com os atributos `data` de Contato e Tarefa. É `TIMESTAMPTZ` (data e hora), com `DEFAULT CURRENT_TIMESTAMP`.
- `valor_total` é armazenado, conforme o DER. Representa o total oficial da venda no Open e pode diferir da soma dos itens (descontos e arredondamentos). É preenchido pelo sistema, não digitado. `CHECK (valor_total >= 0)`.
- `forma_de_pagamento` é opcional e de texto livre: nenhum processo depende dela.
- `codigo_externo` é opcional e `UNIQUE`: identificador da venda no Open. Permite localizar a venda de origem e evitar o registro duplicado da mesma venda na importação. Atributo acrescentado ao DER (não previsto na primeira versão).
- A regra "toda compra possui ao menos um item" não é imposta pelo banco: é garantida pela aplicação, que registra a compra e seus itens na mesma transação.
- `atualizado_em` recebe `DEFAULT CURRENT_TIMESTAMP` no `INSERT`; a atualização nos `UPDATE` é responsabilidade da aplicação (ou de *trigger*).

| Entidade | Atributo | Tipo | Obrigatório | Chave | Observação |
|---|---|---|---|---|---|
| Compra | `id` | BIGSERIAL | Sim | PK | Gerado automaticamente |
| Compra | `cliente_id` | BIGINT | Sim | FK → `cliente.id` | `ON DELETE RESTRICT`; preenchido pelo sistema |
| Compra | `funcionario_id` | BIGINT | Sim | FK → `funcionario.id` | `ON DELETE RESTRICT`; vendedor responsável |
| Compra | `data_da_compra` | TIMESTAMPTZ | Sim | - | `DEFAULT CURRENT_TIMESTAMP` (DER: `data`) |
| Compra | `valor_total` | NUMERIC(10,2) | Sim | - | `CHECK (valor_total >= 0)`; total oficial da venda; preenchido pelo sistema |
| Compra | `forma_de_pagamento` | VARCHAR(30) | Não | - | Texto livre (dinheiro, pix, cartão...) |
| Compra | `codigo_externo` | VARCHAR(50) | Não | UNIQUE | Identificador da venda no Open |
| Compra | `atualizado_em` | TIMESTAMPTZ | Sim | - | `DEFAULT CURRENT_TIMESTAMP` |

---

## Histórico de revisões

| Data | Entidade | Alteração | Motivo |
|---|---|---|---|
| 2026-10-24 | Cliente | Removido o autorrelacionamento previsto inicialmente | Não faz parte do modelo |
| 2026-10-24 | Pet | Entidade criada (Cliente 1:N Pet) | Atender ao requisito de cadastro de pets sem violar a 1ª Forma Normal |
| 2026-10-25 | Pet | Todos os atributos digitados definidos como opcionais | O cadastro não deve ser bloqueado por informação ausente |
| 2026-10-25 | Cliente | `data_de_cadastro`: `TIMESTAMP` → `TIMESTAMPTZ` | Armazenar o instante exato, com fuso horário |
| 2026-10-25 | Funcionário | `cargo`: obrigatório → opcional | Nenhum processo depende do cargo |
| 2026-10-27 | Produto Referência | Entidade registrada; `codigo` obrigatório e único, `preco` opcional | `codigo` é o elo com o Open e evita duplicidade; `preco` não é essencial à operação |
| 2026-10-28 | Promoção | Entidade registrada; `data_de_termino` e `percentual_de_desconto` opcionais; `ativa` definida como chave manual e vigência calculada | Permitir promoções sem término definido e não percentuais, evitando contradição entre `ativa` e as datas |
| 2026-10-28 | Produto × Promoção | Tabela associativa registrada, com chave primária composta e sem atributos próprios | Representar o relacionamento N:N entre Produto Referência e Promoção |
| 2026-10-28 | Compra | Entidade registrada; acrescentado `codigo_externo` (não previsto no DER); `data` renomeado para `data_da_compra` | Permitir a ligação e a deduplicação com as vendas do Open; evitar ambiguidade entre atributos `data` |
