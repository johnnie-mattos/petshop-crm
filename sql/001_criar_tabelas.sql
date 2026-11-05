-- =============================================================
-- 001_criar_tabelas.sql
-- Criação das tabelas do Pet Shop CRM (PostgreSQL 18).
--
-- Fonte: docs/dicionario-de-dados.md, seção 11 (Dicionário consolidado).
-- Em caso de divergência, prevalece o dicionário de dados.
--
-- Execução (psql, conectado ao banco petshop_crm):
--   \i 'D:/petshop-crm/sql/001_criar_tabelas.sql'
--
-- Convenção de nomes das restrições (padrão do PostgreSQL):
--   chave primária ....... <tabela>_pkey
--   chave estrangeira .... <tabela>_<coluna>_fkey
--   UNIQUE ............... <tabela>_<coluna>_key
--   CHECK ................ <tabela>_<coluna>_check
--   índice ............... <tabela>_<colunas>_idx
-- Restrições NOT NULL recebem do PostgreSQL o nome <tabela>_<coluna>_not_null.
-- =============================================================

-- Interrompe a execução no primeiro erro.
\set ON_ERROR_STOP on
-- O arquivo é salvo em UTF-8.
\encoding UTF8

BEGIN;

-- -------------------------------------------------------------
-- Configuração do banco
-- -------------------------------------------------------------
-- Fuso horário America/Sao_Paulo: CURRENT_DATE (contato.data_do_contato)
-- muda à meia-noite local. A configuração vale para as conexões
-- abertas após a execução deste script.
ALTER DATABASE petshop_crm SET timezone = 'America/Sao_Paulo';

-- -------------------------------------------------------------
-- 1. cliente
-- -------------------------------------------------------------
CREATE TABLE cliente (
    id                BIGSERIAL,
    nome              VARCHAR(150) NOT NULL,
    telefone          VARCHAR(20)  NOT NULL,
    cpf               VARCHAR(11),
    endereco          TEXT,
    observacoes       TEXT,
    data_de_cadastro  TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ativo             BOOLEAN      NOT NULL DEFAULT TRUE,

    CONSTRAINT cliente_pkey    PRIMARY KEY (id),
    CONSTRAINT cliente_cpf_key UNIQUE (cpf)
);

-- -------------------------------------------------------------
-- 2. funcionario
-- -------------------------------------------------------------
CREATE TABLE funcionario (
    id     BIGSERIAL,
    nome   VARCHAR(150) NOT NULL,
    cargo  VARCHAR(50),
    ativo  BOOLEAN      NOT NULL DEFAULT TRUE,

    CONSTRAINT funcionario_pkey PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- 3. produto_referencia
-- -------------------------------------------------------------
-- Cópia de referência do catálogo do Open (fonte oficial de preço e estoque).
CREATE TABLE produto_referencia (
    id             BIGSERIAL,
    nome           VARCHAR(200)  NOT NULL,
    categoria      VARCHAR(80),
    marca          VARCHAR(80),
    preco          NUMERIC(10,2),
    codigo         VARCHAR(50)   NOT NULL,
    ativo          BOOLEAN       NOT NULL DEFAULT TRUE,
    atualizado_em  TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT produto_referencia_pkey        PRIMARY KEY (id),
    CONSTRAINT produto_referencia_codigo_key  UNIQUE (codigo),
    CONSTRAINT produto_referencia_preco_check CHECK (preco >= 0)
);

-- -------------------------------------------------------------
-- 4. promocao
-- -------------------------------------------------------------
-- Vigência calculada na consulta: ativa = TRUE e data atual entre
-- data_de_inicio e data_de_termino (ou data_de_termino nula).
CREATE TABLE promocao (
    id                      BIGSERIAL,
    nome                    VARCHAR(120)  NOT NULL,
    data_de_inicio          DATE          NOT NULL,
    data_de_termino         DATE,
    descricao               TEXT,
    percentual_de_desconto  NUMERIC(5,2),
    ativa                   BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT promocao_pkey                         PRIMARY KEY (id),
    CONSTRAINT promocao_data_de_termino_check        CHECK (data_de_termino >= data_de_inicio),
    CONSTRAINT promocao_percentual_de_desconto_check CHECK (percentual_de_desconto BETWEEN 0 AND 100)
);

-- -------------------------------------------------------------
-- 5. pet
-- -------------------------------------------------------------
-- Relacionamento Cliente 1:N Pet. Atributos digitados são opcionais.
CREATE TABLE pet (
    id                  BIGSERIAL,
    cliente_id          BIGINT        NOT NULL,
    nome                VARCHAR(100),
    especie             VARCHAR(50),
    raca                VARCHAR(80),
    porte               VARCHAR(20),
    data_de_nascimento  DATE,
    observacoes         TEXT,
    ativo               BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT pet_pkey           PRIMARY KEY (id),
    CONSTRAINT pet_cliente_id_fkey FOREIGN KEY (cliente_id)
        REFERENCES cliente (id) ON DELETE RESTRICT
);

-- Pets de um cliente.
CREATE INDEX pet_cliente_id_idx ON pet (cliente_id);

-- -------------------------------------------------------------
-- 6. produto_promocao
-- -------------------------------------------------------------
-- Tabela associativa do relacionamento Produto Referência N:N Promoção.
-- A chave primária composta impede vincular o mesmo produto duas vezes
-- à mesma promoção.
CREATE TABLE produto_promocao (
    produto_referencia_id  BIGINT  NOT NULL,
    promocao_id            BIGINT  NOT NULL,

    CONSTRAINT produto_promocao_pkey PRIMARY KEY (produto_referencia_id, promocao_id),
    CONSTRAINT produto_promocao_produto_referencia_id_fkey FOREIGN KEY (produto_referencia_id)
        REFERENCES produto_referencia (id) ON DELETE RESTRICT,
    CONSTRAINT produto_promocao_promocao_id_fkey FOREIGN KEY (promocao_id)
        REFERENCES promocao (id) ON DELETE RESTRICT
);

-- Produtos de uma promoção (encarte). A busca por produto é coberta
-- pela chave primária composta.
CREATE INDEX produto_promocao_promocao_id_idx ON produto_promocao (promocao_id);

-- -------------------------------------------------------------
-- 7. compra
-- -------------------------------------------------------------
-- Venda realizada no Open, registrada por referência.
-- Regra da aplicação: toda compra possui ao menos um item
-- (compra e itens gravados na mesma transação).
CREATE TABLE compra (
    id                  BIGSERIAL,
    cliente_id          BIGINT         NOT NULL,
    funcionario_id      BIGINT         NOT NULL,
    data_da_compra      TIMESTAMPTZ    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valor_total         NUMERIC(10,2)  NOT NULL,
    forma_de_pagamento  VARCHAR(30),
    codigo_externo      VARCHAR(50),
    atualizado_em       TIMESTAMPTZ    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT compra_pkey               PRIMARY KEY (id),
    CONSTRAINT compra_codigo_externo_key UNIQUE (codigo_externo),
    CONSTRAINT compra_valor_total_check  CHECK (valor_total >= 0),
    CONSTRAINT compra_cliente_id_fkey FOREIGN KEY (cliente_id)
        REFERENCES cliente (id) ON DELETE RESTRICT,
    CONSTRAINT compra_funcionario_id_fkey FOREIGN KEY (funcionario_id)
        REFERENCES funcionario (id) ON DELETE RESTRICT
);

-- Histórico do cliente e data da última compra (regra "30 dias sem comprar").
CREATE INDEX compra_cliente_id_data_da_compra_idx ON compra (cliente_id, data_da_compra DESC);
-- Vendas por vendedor.
CREATE INDEX compra_funcionario_id_idx ON compra (funcionario_id);

-- -------------------------------------------------------------
-- 8. item_da_compra
-- -------------------------------------------------------------
-- O item é parte da compra: excluir a compra exclui seus itens (CASCADE).
-- Subtotal calculado: quantidade * valor_unitario - desconto.
-- Regra da aplicação: desconto não excede o valor bruto do item.
CREATE TABLE item_da_compra (
    id                     BIGSERIAL,
    compra_id              BIGINT         NOT NULL,
    produto_referencia_id  BIGINT         NOT NULL,
    quantidade             NUMERIC(10,3)  NOT NULL,
    valor_unitario         NUMERIC(10,2)  NOT NULL,
    desconto               NUMERIC(10,2)  NOT NULL DEFAULT 0,

    CONSTRAINT item_da_compra_pkey                 PRIMARY KEY (id),
    CONSTRAINT item_da_compra_quantidade_check     CHECK (quantidade > 0),
    CONSTRAINT item_da_compra_valor_unitario_check CHECK (valor_unitario >= 0),
    CONSTRAINT item_da_compra_desconto_check       CHECK (desconto >= 0),
    CONSTRAINT item_da_compra_compra_id_fkey FOREIGN KEY (compra_id)
        REFERENCES compra (id) ON DELETE CASCADE,
    CONSTRAINT item_da_compra_produto_referencia_id_fkey FOREIGN KEY (produto_referencia_id)
        REFERENCES produto_referencia (id) ON DELETE RESTRICT
);

-- Itens de uma compra.
CREATE INDEX item_da_compra_compra_id_idx ON item_da_compra (compra_id);
-- Compras de um produto.
CREATE INDEX item_da_compra_produto_referencia_id_idx ON item_da_compra (produto_referencia_id);

-- -------------------------------------------------------------
-- 9. contato
-- -------------------------------------------------------------
-- Criado pelas regras do sistema (sem responsável) ou manualmente.
-- funcionario_id permanece NULL até a execução do contato.
-- Regras da aplicação: a geração automática considera apenas clientes
-- ativos; ao executar, preencher funcionario_id, realizado_em e status.
CREATE TABLE contato (
    id               BIGSERIAL,
    cliente_id       BIGINT        NOT NULL,
    funcionario_id   BIGINT,
    data_do_contato  DATE          NOT NULL DEFAULT CURRENT_DATE,
    realizado_em     TIMESTAMPTZ,
    motivo           VARCHAR(200),
    status           VARCHAR(20)   NOT NULL DEFAULT 'pendente',
    observacoes      TEXT,

    CONSTRAINT contato_pkey         PRIMARY KEY (id),
    CONSTRAINT contato_status_check CHECK (status IN ('pendente', 'realizado', 'nao_atendeu', 'cancelado')),
    CONSTRAINT contato_cliente_id_fkey FOREIGN KEY (cliente_id)
        REFERENCES cliente (id) ON DELETE RESTRICT,
    CONSTRAINT contato_funcionario_id_fkey FOREIGN KEY (funcionario_id)
        REFERENCES funcionario (id) ON DELETE RESTRICT
);

-- Tela de contatos do dia.
CREATE INDEX contato_data_do_contato_status_idx ON contato (data_do_contato, status);
-- Contatos de um cliente.
CREATE INDEX contato_cliente_id_idx ON contato (cliente_id);

-- -------------------------------------------------------------
-- 10. tarefa
-- -------------------------------------------------------------
-- Pode originar-se de um contato ou ser criada de forma independente (planner).
-- Regras da aplicação: em tarefas geradas a partir de um contato,
-- cliente_id é o cliente do contato; ao concluir, preencher concluida_em e status.
CREATE TABLE tarefa (
    id              BIGSERIAL,
    funcionario_id  BIGINT,
    contato_id      BIGINT,
    cliente_id      BIGINT,
    titulo          VARCHAR(150)  NOT NULL,
    data_prevista   DATE,
    concluida_em    TIMESTAMPTZ,
    status          VARCHAR(20)   NOT NULL DEFAULT 'pendente',
    observacoes     TEXT,

    CONSTRAINT tarefa_pkey         PRIMARY KEY (id),
    CONSTRAINT tarefa_status_check CHECK (status IN ('pendente', 'concluida', 'cancelada')),
    CONSTRAINT tarefa_funcionario_id_fkey FOREIGN KEY (funcionario_id)
        REFERENCES funcionario (id) ON DELETE RESTRICT,
    CONSTRAINT tarefa_contato_id_fkey FOREIGN KEY (contato_id)
        REFERENCES contato (id) ON DELETE RESTRICT,
    CONSTRAINT tarefa_cliente_id_fkey FOREIGN KEY (cliente_id)
        REFERENCES cliente (id) ON DELETE RESTRICT
);

-- Tarefas do dia e da semana (planner).
CREATE INDEX tarefa_data_prevista_status_idx ON tarefa (data_prevista, status);
-- Consulta por responsável, cliente e contato de origem.
CREATE INDEX tarefa_funcionario_id_idx ON tarefa (funcionario_id);
CREATE INDEX tarefa_cliente_id_idx     ON tarefa (cliente_id);
CREATE INDEX tarefa_contato_id_idx     ON tarefa (contato_id);

COMMIT;
