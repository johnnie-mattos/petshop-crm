# Fluxo de Uso

## Navegação do funcionário

1. Cadastrar cliente
2. Pesquisar cliente
3. Consultar histórico de compras
4. Consultar produtos em promoção
5. Verificar aba de notificações
6. Realizar contato com o cliente

## Regra de geração de contato

O diagrama abaixo usa a sintaxe [Mermaid](https://mermaid.js.org/), que o GitHub renderiza automaticamente como um fluxograma ao exibir este arquivo — não precisa exportar imagem.

```mermaid
flowchart TD
    A[Cliente realiza compra] --> B[Compra e registrada]
    B --> C{Sistema verifica regras}
    C -->|Cliente ha 30+ dias sem comprar| D[Criar Contato]
    C -->|Produto entrou em promocao| D[Criar Contato]
    D --> E[Funcionario visualiza contatos]
    E --> F[Funcionario executa contato]
    F --> G{Contato gera Tarefa?}
    G -->|Sim| H[Tarefa criada]
    G -->|Nao| I[Fim]
```
