# Refatoração da Arquitetura - Fases 1 e 2

Este documento detalha as mudanças realizadas no projeto Conecta durante as Fases 1 e 2 da refatoração de arquitetura, focando na implementação do **Repository Pattern** para desacoplar a interface do usuário das chamadas diretas ao Firebase.

## Objetivo Principal
Remover a dependência direta do `FirebaseFirestore` e `FirebaseAuth` dentro dos arquivos das telas (`lib/telas/`), centralizando a lógica de banco de dados e autenticação na camada de repositórios (`lib/repositories/`). Isso melhora a testabilidade, legibilidade e manutenção do código.

---

## Fase 1: Autenticação e Usuários

Na primeira fase, focamos na extração das lógicas relacionadas à identidade do usuário (Auth) e na busca do perfil e seus dados no Firestore.

### Repositórios Criados:
- **`AuthRepository`** (`lib/repositories/auth_repository.dart`): Centraliza as chamadas do FirebaseAuth.
- **`UsuarioRepository`** (`lib/repositories/usuario_repository.dart`): Responsável por salvar, atualizar e consultar dados nas diferentes coleções de usuários (`lojistas`, `prestadorServicos`, `usuarioComum`, `admins`), além de otimizar a descoberta do perfil do usuário utilizando `Future.wait` para chamadas paralelas.

### Principais Telas Afetadas (Fase 1):
- `lib/main.dart` e `AuthWrapper`: Atualizados para verificar a sessão utilizando o `AuthRepository`.
- `lib/telas/auth/tela_login.dart` e `tela_cadastro.dart`: Lógica de validação de e-mail/senha e criação de conta isolada.
- Telas de Perfil (ex: `tela_perfil.dart`, `tela_perfil_prestador.dart`): Modificadas para usar `UsuarioRepository` no carregamento dos dados, histórico e notificações.
- `UsuarioUtil`: Utilitário atualizado para mapear uniformemente o nome completo do usuário, substituindo mocks em diversas telas (ex: `TelaInicialPrestador`).

---

## Fase 2: Produtos, Categorias e Pedidos

A segunda fase visou separar as lógicas de negócios comerciais, estruturando repositórios para os itens e as transações.

### Repositórios Criados:
- **`ProdutoRepository`** (`lib/repositories/produto_repository.dart`): Centraliza a adição, exclusão, consulta de *streams* e atualizações de estoque dos produtos dos lojistas.
- **`CategoriaRepository`** (`lib/repositories/categoria_repository.dart`): Concentra as lógicas de listar e filtrar prestadores de serviços por status de aprovação e as categorias das lojas (CNAE).
- **`PedidoRepository`** (`lib/repositories/pedido_repository.dart`): Centraliza as operações de agendamento de serviços, solicitações de compras, mudança de status de pedidos (Pendente, Confirmado, Cancelado, Concluído) e o histórico dos mesmos.

### Principais Telas Afetadas (Fase 2):
- **Telas de Lojista:**
  - `tela_inicial_lojista.dart` (Abas de Produtos, Serviços e Pedidos refatoradas).
  - `tela_admin_conteudo_lojista.dart` (Atualizada para usar o repositório de exclusão e busca de produtos).
- **Telas de Clientes (Consumidores):**
  - `tela_produtos_disponiveis.dart` (Usa `ProdutoRepository` para exibir os itens da loja).
  - Categorias (Quitandas/Comidas, Bebidas, Feira Livre, Outros, Serviços) refatoradas para usar o `CategoriaRepository`.
  - `tela_checkout_servico.dart`, `tela_confirmacao_servico.dart` e `tela_finalizacao_compra.dart` refatoradas para salvar e consultar *streams* via `PedidoRepository` e `UsuarioRepository`.
  - `tela_historico_pedidos.dart` atualizada para consolidar pedidos de clientes.
- **Telas de Prestadores:**
  - `tela_pedidos_pendentes_prestador.dart`, `tela_servicos_agendados_prestador.dart` e `tela_historico_servicos_prestador.dart` limpas, retirando *queries* complexas do Firestore e injetando instâncias do `PedidoRepository` e `UsuarioRepository`.

## Como solucionar eventuais problemas
Se houver problemas ao ler dados após essa refatoração:
1. **Erros de permissão/regras do Firestore**: Certifique-se de que os repositórios estão apontando para as coleções exatas com letras minúsculas adequadas (`lojistas`, `pedidos`, etc.) e as regras definidas no console suportem a *query*.
2. **Dados em branco nas *Streams***: Confirme se os IDs (ex: `uid`, `prestadorId`, `lojistaId`) estão sendo preenchidos corretamente nos construtores dos repositórios.
3. **Erros de sintaxe ou tela não reflete as mudanças**: Use `flutter clean` e `flutter pub get`. A arquitetura nova conta com chamadas estritas; se houver chamadas residuais de `FirebaseFirestore.instance` que tentam manipular os dados refatorados, conflitos podem ocorrer. Mantenha-se utilizando estritamente as classes na pasta `repositories`.
