# Levantamento de Requisitos

O sistema deve contar com:

- **Cadastro de clientes**, incluindo nome e telefone;
- **Cadastro de pets do cliente** — cada cliente pode ter zero, um ou vários pets cadastrados (ver detalhamento abaixo);
- **Cadastro de produtos de referência** (catálogo consultivo: nome, categoria, marca, preço — sem controle de estoque, que continua no sistema Open);
- **Encarte da semana**, exibindo produtos em promoção;
- **Aba de notificações**, listando clientes com oportunidade de contato (ver [Fluxo de Uso](fluxo-de-uso.md)).

## Cadastro de pets

Cada pet é registrado individualmente e pertence a um único cliente.

**Dados de cada pet:**

- nome;
- espécie (cachorro, gato, ave etc.) — *opcional*;
- raça — *opcional*;
- porte — *opcional*;
- data de nascimento — *opcional*;
- observações (ex.: alergias, temperamento, cuidados especiais) — *opcional*;
- situação (ativo/inativo).

**Regras:**

- Um cliente pode ter zero, um ou vários pets; um pet sempre pertence a exatamente um cliente.
- A **quantidade de pets** de um cliente não é digitada: o sistema a calcula contando os pets cadastrados daquele cliente. Assim, o número nunca fica diferente da lista real de pets.
- Um pet que deixa de ser atendido não é apagado: é marcado como inativo, preservando o histórico (mesmo princípio já adotado para Funcionário, Produto Referência e Promoção).

**Decisão sobre obrigatoriedade:** espécie, raça, porte e data de nascimento são sempre **opcionais**. O pet shop atende tutores com perfis muito diferentes: nem todo tutor sabe a raça ou a data de nascimento do animal, e o cadastro não pode travar por falta de uma informação. Esses dados servem para segmentar contatos e promoções quando existem, mas o sistema funciona sem eles.

> A obrigatoriedade dos demais campos (por exemplo, o nome do pet) será definida na etapa do Dicionário de Dados (modelo lógico).

## Evolução futura

Planner integrado às demais funções, facilitando o planejamento semanal do atendimento.

## Histórico de revisões

| Data | Alteração |
|---|---|
| 2026-10-24 | Entidade `Pet` incorporada ao modelo (relação 1:N com Cliente). Requisito "quantidade e nome dos pets" detalhado em "Cadastro de pets". Pendência anterior encerrada. |
| 2026-10-24 | Espécie, raça, porte e data de nascimento do pet definidos como opcionais, para acomodar tutores com perfis diversos. |
