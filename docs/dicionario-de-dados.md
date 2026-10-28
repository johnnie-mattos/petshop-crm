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
- **Chave primária:** coluna `id` do tipo `BIGSERIAL`.
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
- [ ] 4. Produto Referência
- [ ] 5. Promoção
- [ ] 6. Tabela associativa Produto Referência × Promoção *(depende de 4 e 5)*
- [ ] 7. Compra *(depende de Cliente e Funcionário)*
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

## Histórico de revisões

| Data | Entidade | Alteração | Motivo |
|---|---|---|---|
| 2026-10-24 | Cliente | Removido o autorrelacionamento previsto inicialmente | Não faz parte do modelo |
| 2026-10-24 | Pet | Entidade criada (Cliente 1:N Pet) | Atender ao requisito de cadastro de pets sem violar a 1ª Forma Normal |
| 2026-10-25 | Pet | Todos os atributos digitados definidos como opcionais | O cadastro não deve ser bloqueado por informação ausente |
| 2026-10-25 | Cliente | `data_de_cadastro`: `TIMESTAMP` → `TIMESTAMPTZ` | Armazenar o instante exato, com fuso horário |
| 2026-10-25 | Funcionário | `cargo`: obrigatório → opcional | Nenhum processo depende do cargo |
