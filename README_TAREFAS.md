# 📋 Checklist de Requisitos e Tarefas Pendentes — Projeto Conecta

> **Documento Base:** *Levantamento de Requisitos "Projeto Conecta"* (IFMG Bambuí - 2025).  
> **Status Geral do App:** Núcleo funcional (Autenticação, Cadastros especializados, Catálogo, Estoque, Painel Admin, Histórico e Avaliações) implementado e testado.  
> Este documento funciona como um backlog interativo para guiar as próximas etapas de desenvolvimento.

---

## 📌 Sumário de Progresso
- [x] **Módulo 1: Acesso e Cadastros Base** (Concluído)
- [x] **Módulo 2: Painel Administrativo** (Concluído)
- [x] **Módulo 3: Catálogo e Gestão de Produtos/Serviços** (Concluído)
- [x] **Módulo 4: Avaliações e Histórico** (Concluído)
- [ ] **Módulo 5: Ajustes e Funcionalidades Parciais** (4 pendências)
- [ ] **Módulo 6: Novas Funcionalidades do Documento** (9 pendências)

---

## 🟡 1. Ajustes e Funcionalidades Parciais

Tarefas cuja estrutura já existe no código, mas precisam de refinamento para cumprir o requisito integralmente.

### [x] 1.1 Validação e Aplicação de Cupons de Desconto no Checkout
- **Referência:** Documento pág. 20 e 44 (Figura 27).
- **Descrição:** Atualmente existe apenas um container estático `"Digite aqui o cupom"` na tela de finalização de compra. É necessário transformar o campo em interativo, consultar a coleção de cupons no Firestore, validar data de validade/valor mínimo e aplicar o desconto no subtotal.
- **Arquivos:** `lib/telas/cliente/tela_finalizacao_compra.dart`, Firestore (`cupons`).

---

### [x] 1.2 Tratamento Visual de Produtos Indisponíveis (Filtro Preto e Branco e Estoque em Tempo Real)
- **Referência:** Documento pág. 19 e 31 (Figura 8).
- **Descrição:** Quando o lojista marcar um produto como indisponível (ou estoque zerado), a foto do produto deve receber um filtro em escala de cinza/preto e branco (`ColorFilter.mode`), com uma tag/selo visual de "Indisponível", bloqueando a adição do item ao carrinho.
- **Arquivos:** `lib/telas/cliente/tela_produtos_disponiveis.dart`, `lib/telas/cliente/tela_detalhes_produto.dart`, `lib/telas/lojista/abas/aba_produtos_lojista.dart`.

---

### [x] 1.3 Redefinição de Senha com Envio de Código (PIN de 6 dígitos)
- **Referência:** Documento pág. 4 e 35–38 (Figuras 13, 14, 15 e 16).
- **Descrição:** O app atual usa o link padrão por e-mail do Firebase. O documento prevê fluxo com telas dedicadas in-app:
  1. Digitação do e-mail.
  2. Digitação do código de verificação recebido (com opção de reenvio).
  3. Digitação e confirmação da nova senha com checklist de requisitos.
  4. Confirmação de sucesso e redirecionamento para o login.
- **Arquivos:** `lib/telas/auth/tela_login.dart`, novas telas de redefinição.

---

### [x] 1.4 Lazy Authentication com Persistência da Ação
- **Referência:** Documento pág. 3.
- **Descrição:** Ao navegar como visitante e clicar em ações protegidas (ex: adicionar ao carrinho, favoritar), após o usuário realizar o login, ele deve ser reconduzido automaticamente à mesma tela com a ação executada ou pronta para finalização.
- **Arquivos:** `lib/utils/auth_wrapper.dart`, `lib/telas/auth/tela_login.dart`, `lib/telas/cliente/tela_detalhes_produto.dart`.

---

### [x] 1.5 Notificações em Tempo Real de Pedidos e Serviços
- **Descrição:** Disparo e recepção automática de notificações no app:
  - Lojista é notificado com nome do cliente e valor quando um novo pedido é criado.
  - Prestador é notificado quando uma nova solicitação de serviço é feita.
  - Cliente é notificado em tempo real quando o lojista ou prestador aceita, conclui ou recusa o pedido/serviço.
  - Sino de notificações (`BotaoNotificacao`) com contador de não lidas adicionado na AppBar do Cliente e no Menu Lateral.
- **Arquivos:** `lib/repositories/pedido_repository.dart`, `lib/telas/perfil/tela_notificacoes.dart`, `lib/telas/cliente/tela_inicial_comum.dart`, `lib/telas/lojista/abas/aba_pedidos_lojista.dart`, `lib/telas/prestador/tela_pedidos_pendentes_prestador.dart`, `lib/telas/prestador/tela_servicos_agendados_prestador.dart`.

---

## 🔴 2. Novas Funcionalidades Exigidas no Documento

### [ ] 2.1 Agendamento In-App de Prestadores com Calendário e Horários
- **Referência:** Documento pág. 18, 22 e 48 (Figuras 34, 35 e 35.1).
- **Descrição:** 
  - Listar os serviços reais cadastrados no perfil do prestador.
  - Tela de agendamento in-app onde o cliente escolhe os serviços, seleciona o dia e horário em calendário (baseado nos dias disponíveis do prestador), inclui observações e clica em **"Agendar"**.
  - O agendamento é registrado como `"Aguardando confirmação"` e aparece na tela do prestador para que ele possa aceitar ou recusar com justificativa.
- **Arquivos:** `lib/telas/cliente/tela_detalhes_servico.dart`, `lib/telas/prestador/tela_pedidos_pendentes_prestador.dart`, Firestore (`pedidos`/`agendamentos`).

---

### [x] 2.2 Chat Interno em Tempo Real (Cliente ↔ Lojista / Prestador)
- **Referência:** Documento pág. 23, 45 e 49 (Figuras 29 e 36).
- **Descrição:** Criação de chat integrado in-app para que comprador e vendedor conversem sobre o status do pedido, troquem mensagens de texto e anexem imagens/comprovantes.
  - Botão no histórico de compras do cliente ("Entrar em chat com o vendedor").
  - Botão na aba de pedidos do lojista/prestador ("Entrar em chat com o cliente").
- **Arquivos:** Nova tela `lib/telas/chat/tela_chat.dart`, Firestore (`conversas`/`mensagens`).

---

### [x] 2.3 Status de Disponibilidade "Online / Offline" do Prestador
- **Referência:** Documento pág. 19.
- **Descrição:** Permitir que prestadores de serviço definam seu status como:
  - **Online:** disponível para atendimento imediato ou resposta rápida.
  - **Offline:** indisponível no momento.
  - Indicador visual no card e no perfil público para os clientes.
  - Opcional: marcação automática como offline caso o app fique fechado por 15 minutos.
- **Arquivos:** `lib/telas/prestador/tela_inicial_prestador_servico.dart`, `lib/telas/cliente/tela_perfil_prestador.dart`, `lib/telas/categorias/categoria_servicos.dart`.

---

### [x] 2.4 Transparência para Lojistas sem CNPJ (Tag e Pop-up "Autônomo")
- **Referência:** Documento pág. 17.
- **Descrição:** Lojistas informais cadastrados sem CNPJ devem exibir claramente um selo/link com a palavra `"Autônomo"`. Ao clicar, deve abrir um pop-up explicativo informando a condição de vendedor autônomo.
- **Arquivos:** `lib/telas/categorias/categoria_comidas.dart`, `lib/telas/cliente/tela_produtos_disponiveis.dart`.

---

### [x] 2.5 Canal de Chamados e Suporte ao Usuário
- **Referência:** Documento pág. 20.
- **Descrição:** Além da FAQ informativa atual, criar um formulário para clientes, lojistas e prestadores abrirem chamados:
  - Seleção de categoria do problema (Erro no app, Pedido com problema, Falha de cadastro).
  - Campo descritivo do problema.
  - Confirmação de envio e persistência no Firestore.
  - Aba ou tela no Painel do Administrador para leitura e resolução dos chamados.
- **Arquivos:** `lib/telas/suporte/tela_abrir_chamado.dart`, `lib/telas/admin/tela_inicial_administrador.dart`.

---

### [ ] 2.6 Resposta a Avaliações por Lojistas e Prestadores
- **Referência:** Documento pág. 23.
- **Descrição:** Permitir que os lojistas e prestadores de serviço respondam aos comentários recebidos nas avaliações de seus pedidos/serviços, exibindo a réplica logo abaixo do comentário do cliente.
- **Arquivos:** `lib/telas/cliente/tela_avaliacao_servico.dart`, `lib/telas/perfil/tela_perfil.dart`, Firestore (`avaliacoes/{id}/resposta`).

---

### [ ] 2.7 Ranking e Destaque de Prestadores e Lojistas Melhores Avaliados
- **Referência:** Documento pág. 17 e 21.
- **Descrição:** Adicionar ordenação por nota média (`mediaEstrelas`) e volume de avaliações nas vitrines de serviços e comércios locais, dando mais visibilidade aos fornecedores bem avaliados.
- **Arquivos:** `lib/repositories/categoria_repository.dart`, `lib/telas/categorias/categoria_servicos.dart`, `lib/telas/categorias/categoria_comidas.dart`.

---

### [ ] 2.8 Moderação Automática de Palavras Ofensivas em Avaliações
- **Referência:** Documento pág. 54 (Requisitos de Segurança).
- **Descrição:** Bloquear a submissão de avaliações ou comentários que contenham termos ofensivos ou impróprios utilizando uma blacklist de palavras proibidas.
- **Arquivos:** `lib/telas/cliente/tela_avaliacao_servico.dart`, `lib/utils/formatadores.dart` ou validador dedicado.

---

### [ ] 2.9 Notificação Sonora Diferenciada por Perfil
- **Referência:** Documento pág. 19–20.
- **Descrição:** Emitir alertas sonoros distintos de acordo com o perfil:
  - Lojistas e prestadores: som enfático para novos pedidos ou solicitações de agendamento.
  - Clientes: som suave para atualizações de status e mensagens.
- **Arquivos:** Canais de notificação nativos / `audioplayers` / payloads de notificação.

---

## 🎯 Ordem de Prioridade Recomendada para Execução

```
Fase 1 (Impacto Imediato & Baixa Complexidade):
  ├── 1.1 Cupons de Desconto no Checkout
  ├── 1.2 Imagens de Produtos Indisponíveis em Preto e Branco
  ├── 2.3 Status Online/Offline para Prestadores
  └── 2.4 Tag e Pop-up "Autônomo" para Lojistas sem CNPJ

Fase 2 (Fluxo Central de Serviços):
  ├── 2.1 Agendamento In-App com Calendário e Horários
  ├── 2.7 Ranking e Destaque por Avaliações
  └── 2.8 Moderação Automática de Palavras Ofensivas

Fase 3 (Comunicação e Suporte):
  ├── 2.2 Chat em Tempo Real Cliente <-> Vendedor/Prestador
  ├── 2.5 Canal de Chamados e Suporte ao Usuário
  └── 2.6 Resposta a Avaliações pelo Fornecedor

Fase 4 (Refinamento de UX & Segurança):
  ├── 1.3 Redefinição de Senha com Código/PIN
  ├── 1.4 Lazy Auth com Persistência da Ação
  └── 2.9 Notificação Sonora Diferenciada
```
