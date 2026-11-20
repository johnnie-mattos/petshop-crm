-- =============================================================
-- 002_dados_ficticios.sql
-- Dados fictícios para desenvolvimento e testes do Pet Shop CRM.
--
-- TODOS OS DADOS SÃO FICTÍCIOS. Nomes, telefones e CPFs não
-- correspondem a pessoas reais (ver nota de LGPD no dicionário de dados).
--
-- Pré-requisito: tabelas recém-criadas pela migração do Flyway
-- (backend/src/main/resources/db/migration/V1__criar_tabelas.sql).
-- Os identificadores (id) referenciados abaixo pressupõem tabelas vazias.
-- Este script não é uma migração: não é executado pelo Flyway e não deve
-- ser aplicado no banco de produção.
--
-- Execução (psql, conectado ao banco petshop_crm):
--   \i 'D:/petshop-crm/sql/002_dados_ficticios.sql'
--
-- Datas relativas (CURRENT_DATE, CURRENT_TIMESTAMP - INTERVAL) mantêm
-- os cenários válidos independentemente do dia da execução.
-- =============================================================

\set ON_ERROR_STOP on
\encoding UTF8

BEGIN;

-- -------------------------------------------------------------
-- funcionario (ids 1 a 3)
-- -------------------------------------------------------------
INSERT INTO funcionario (nome, cargo, ativo) VALUES
    ('Funcionário Teste 1', 'Atendente', TRUE),
    ('Funcionário Teste 2', 'Gerente',   TRUE),
    ('Funcionário Teste 3', NULL,        FALSE);   -- desligado: inativo, sem cargo

-- -------------------------------------------------------------
-- cliente (ids 1 a 4)
-- -------------------------------------------------------------
INSERT INTO cliente (nome, telefone, cpf, endereco, observacoes, ativo) VALUES
    ('Cliente Teste 1', '(00) 00000-0001', '00000000001', 'Rua Fictícia, 100', 'Prefere contato por mensagem', TRUE),
    ('Cliente Teste 2', '(00) 00000-0002', '00000000002', NULL,                NULL,                           TRUE),
    ('Cliente Teste 3', '(00) 00000-0003', NULL,          NULL,                'CPF não informado',            TRUE),
    ('Cliente Teste 4', '(00) 00000-0004', NULL,          NULL,                'Não deseja ser contatado',     FALSE);

-- -------------------------------------------------------------
-- pet (ids 1 a 5)
-- -------------------------------------------------------------
INSERT INTO pet (cliente_id, nome, especie, raca, porte, data_de_nascimento, observacoes) VALUES
    (1, 'Pet Teste A', 'cachorro', 'Sem raça definida', 'médio',   CURRENT_DATE - INTERVAL '3 years', 'Data de nascimento aproximada'),
    (1, 'Pet Teste B', 'gato',     NULL,                'pequeno', NULL,                              NULL),
    (2, 'Pet Teste C', 'cachorro', 'Poodle',            'pequeno', CURRENT_DATE - INTERVAL '8 years', 'Alergia a frango'),
    (3, NULL,          'ave',      NULL,                NULL,      NULL,                              'Nome não informado'),
    (4, 'Pet Teste D', 'gato',     NULL,                NULL,      NULL,                              NULL);

-- -------------------------------------------------------------
-- produto_referencia (ids 1 a 5)
-- -------------------------------------------------------------
INSERT INTO produto_referencia (nome, categoria, marca, preco, codigo) VALUES
    ('Ração Teste Adulto 15 kg',    'ração',     'Marca Teste', 189.90, 'TST-0001'),
    ('Petisco Teste 100 g',         'petisco',   'Marca Teste',  12.50, 'TST-0002'),
    ('Ração Teste a Granel (kg)',   'ração',     'Marca Teste',  18.00, 'TST-0003'),
    ('Brinquedo Teste Bolinha',     'brinquedo', NULL,           NULL,   'TST-0004'),  -- sem preço de referência
    ('Areia Higiênica Teste 4 kg',  'higiene',   'Marca Teste',  29.90, 'TST-0005');

-- -------------------------------------------------------------
-- promocao (ids 1 a 3)
-- -------------------------------------------------------------
INSERT INTO promocao (nome, data_de_inicio, data_de_termino, descricao, percentual_de_desconto, ativa) VALUES
    ('Promoção Teste Vigente',      CURRENT_DATE - 2,  CURRENT_DATE + 5, 'Desconto percentual com término definido', 10.00, TRUE),
    ('Promoção Teste Sem Término',  CURRENT_DATE - 10, NULL,             'Leve 3, pague 2 (não percentual)',          NULL,  TRUE),
    ('Promoção Teste Encerrada',    CURRENT_DATE - 40, CURRENT_DATE - 30, NULL,                                       15.00, TRUE);

-- -------------------------------------------------------------
-- produto_promocao
-- -------------------------------------------------------------
INSERT INTO produto_promocao (produto_referencia_id, promocao_id) VALUES
    (1, 1),   -- ração 15 kg na promoção vigente
    (2, 1),   -- petisco na promoção vigente
    (2, 2),   -- petisco também na promoção sem término (N:N)
    (5, 3);   -- areia na promoção encerrada

-- -------------------------------------------------------------
-- compra (ids 1 a 3) e item_da_compra
-- -------------------------------------------------------------
-- Compra 1: cliente 1, há 5 dias. Total = 189,90 + (2 x 12,50 - 2,50) = 212,40
INSERT INTO compra (cliente_id, funcionario_id, data_da_compra, valor_total, forma_de_pagamento, codigo_externo) VALUES
    (1, 1, CURRENT_TIMESTAMP - INTERVAL '5 days',  212.40, 'pix',      'OPEN-TST-0001');

-- Compra 2: cliente 2, há 45 dias (cenário "30 dias sem comprar"). Total = 1,5 kg x 18,00 = 27,00
INSERT INTO compra (cliente_id, funcionario_id, data_da_compra, valor_total, forma_de_pagamento, codigo_externo) VALUES
    (2, 2, CURRENT_TIMESTAMP - INTERVAL '45 days',  27.00, 'dinheiro', 'OPEN-TST-0002');

-- Compra 3: cliente 1, há 60 dias, vendedor hoje inativo, sem código externo. Total = 29,90
INSERT INTO compra (cliente_id, funcionario_id, data_da_compra, valor_total, forma_de_pagamento, codigo_externo) VALUES
    (1, 3, CURRENT_TIMESTAMP - INTERVAL '60 days',  29.90, NULL,       NULL);

INSERT INTO item_da_compra (compra_id, produto_referencia_id, quantidade, valor_unitario, desconto) VALUES
    (1, 1, 1,     189.90, 0),
    (1, 2, 2,      12.50, 2.50),   -- desconto de 2,50 no item
    (2, 3, 1.500,  18.00, 0),      -- quantidade fracionada (kg)
    (3, 5, 1,      29.90, 0);

-- -------------------------------------------------------------
-- contato (ids 1 a 3)
-- -------------------------------------------------------------
-- Contato 1: automático, pendente, para hoje, sem funcionário.
INSERT INTO contato (cliente_id, motivo) VALUES
    (2, '30 dias sem compra');

-- Contato 2: realizado ontem pelo funcionário 1.
INSERT INTO contato (cliente_id, funcionario_id, data_do_contato, realizado_em, motivo, status, observacoes) VALUES
    (1, 1, CURRENT_DATE - 1, CURRENT_TIMESTAMP - INTERVAL '1 day', 'Produto em promoção', 'realizado', 'Cliente pediu para separar a ração');

-- Contato 3: tentativa sem sucesso.
INSERT INTO contato (cliente_id, funcionario_id, data_do_contato, realizado_em, motivo, status) VALUES
    (3, 2, CURRENT_DATE - 2, CURRENT_TIMESTAMP - INTERVAL '2 days', 'Produto em promoção', 'nao_atendeu');

-- -------------------------------------------------------------
-- tarefa (ids 1 a 3)
-- -------------------------------------------------------------
INSERT INTO tarefa (funcionario_id, contato_id, cliente_id, titulo, data_prevista, status) VALUES
    (1,    2,    1,    'Separar ração para retirada',      CURRENT_DATE,     'pendente'),  -- gerada pelo contato 2
    (NULL, NULL, NULL, 'Conferir o encarte da semana',     CURRENT_DATE + 1, 'pendente'),  -- independente, sem responsável
    (2,    NULL, 3,    'Atualizar telefone do cliente',    NULL,             'pendente');  -- sem data definida

COMMIT;
