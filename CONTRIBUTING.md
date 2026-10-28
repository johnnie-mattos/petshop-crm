# Guia de contribuição

Fluxo de trabalho e padrões de versionamento do projeto.

## Fluxo para adicionar uma entidade ao dicionário de dados

1. **Conceito:** consultar o [DER](docs/der.md) para identificar os atributos e relacionamentos da entidade e verificar as dependências. Tabelas referenciadas por chave estrangeira devem estar registradas antes.
2. **Tabela:** definir nome da tabela, chave primária, atributos (tipo, tamanho, obrigatoriedade, unicidade e valor padrão) e chaves estrangeiras, segundo os [critérios de modelagem](docs/dicionario-de-dados.md#critérios-de-modelagem).
3. **Registro:** acrescentar a seção da entidade em [`docs/dicionario-de-dados.md`](docs/dicionario-de-dados.md), com as decisões de modelagem e a tabela no formato `Entidade | Atributo | Tipo | Obrigatório | Chave | Observação`. Atualizar o quadro "Andamento" e, quando a definição alterar requisitos ou o DER, os documentos correspondentes.
4. **Commit:** um commit por entidade, seguindo o [padrão de mensagem](#padrão-de-mensagem-de-commit).

## Verificações antes do commit

- Executar `git status` e confirmar que apenas os arquivos esperados foram alterados.
- Confirmar que não há arquivos com sufixos de duplicação (`_1`, `(1)`).
- Confirmar que não há dados reais de clientes em exemplos ou testes.

## Padrão de mensagem de commit

Formato baseado em [Conventional Commits](https://www.conventionalcommits.org/pt-br/):

```
<tipo>: <descrição>
```

Escopo opcional: `<tipo>(<escopo>): <descrição>`.

### Tipos

| Tipo | Uso |
|---|---|
| `docs` | Documentação (requisitos, DER, dicionário de dados) |
| `feat` | Nova funcionalidade |
| `fix` | Correção de erro |
| `refactor` | Reestruturação sem mudança de comportamento |
| `test` | Criação ou ajuste de testes |
| `chore` | Tarefas de manutenção e configuração |

### Regras

- Descrição em português, em minúsculas e sem acentos, no presente (`adiciona`, `corrige`, `atualiza`).
- Até 72 caracteres, sem ponto final.
- Um assunto por commit.

### Exemplos

```
docs: dicionario de dados - produto referencia
docs: atualiza der com entidade pet
docs: corrige nomes dos arquivos e restaura der.png
fix: corrige tipo da coluna preco
feat: adiciona script de criacao das tabelas
```
