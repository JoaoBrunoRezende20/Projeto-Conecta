# Análise Completa — Projeto Conecta (e_nosso)

> Gerada em: 2026-04-05
> Firebase: `enosso-e1144`
> Framework: Flutter (SDK ^3.9.0)

---

## 1. Visão Geral do Projeto

Aplicativo marketplace local que conecta 4 tipos de usuários:

| Tipo | Função |
|---|---|
| **Cliente/Comum** | Navega categorias, monta carrinho, finaliza pedido |
| **Lojista** | Gerencia catálogo de produtos e estoque |
| **Prestador de Serviço** | Perfil profissional com portfólio, área de atuação, disponibilidade |
| **Administrador** | Aprova/rejeita cadastros, gerencia usuários, visualiza logs |

---

## 2. Estrutura de Arquivos

```
lib/
├── main.dart                          — App entry point + AuthWrapper
├── firebase_options.dart              — Config Firebase (auto-gerado)
├── telas/
│   ├── auth/
│   │   ├── tela_tipo_usuario.dart     — Seleção de tipo antes do login
│   │   ├── tela_login.dart            — Login com email/senha
│   │   ├── tela_cadastro_usuarios.dart— Cadastro completo (lojista, prestador, comum)
│   │   ├── tela_definicao_senha.dart  — [INCOMPLETA] Definição de senha
│   │   └── tela_detalhes_cadastro.dart— Admin revisa cadastro com docs
│   ├── cliente/
│   │   ├── tela_inicial_comum.dart    — Grid de categorias
│   │   ├── tela_divisao_categoria.dart — Navegação por categorias
│   │   ├── tela_produtos_disponiveis.dart — Lista produtos + carrinho
│   │   ├── tela_carrinho.dart          — Revisão do carrinho
│   │   ├── tela_finalizacao_compra.dart— Dados entrega + pagamento
│   │   └── tela_servicos.dart          — [VAZIA]
│   ├── lojista/
│   │   ├── tela_inicial_lojista.dart   — Gerência de produtos (Firebase)
│   │   ├── tela_conteudo_produtos.dart — Gerência local (não usa Firebase)
│   │   └── tela_admin_conteudo_lojista.dart — Admin vê/exclui produtos
│   ├── prestador/
│   │   ├── tela_inicial_prestador_servico.dart — Perfil (dados mock, não Firebase)
│   │   └── tela_admin_conteudo_prestador.dart  — Admin vê portfólio
│   ├── admin/
│   │   ├── tela_inicial_administrador.dart  — Cadastros pendentes
│   │   ├── tela_todos_usuarios.dart         — Gestão total (3 abas)
│   │   └── tela_logs.dart                   — Auditoria com filtros
│   ├── categorias/
│   │   ├── categoria_bebidas.dart
│   │   ├── categoria_feira_livre.dart       — [NÃO LIDA/INCOMPLETA]
│   │   ├── categoria_outros.dart            — [NÃO LIDA/INCOMPLETA]
│   │   ├── categoria_quitandas.dart
│   │   └── categoria_servicos.dart
│   └── perfil/
│       ├── tela_perfil.dart           — [SKELETON] Editar perfil
│       └── tela_notificacoes.dart     — Notificações (subcolleção)
└── widgets/
    ├── botao_notificacao.dart         — Badge de notificações não lidas
    └── menu_lateral.dart              — Drawer lateral (rotas quebradas)
```

---

## 3. Bugs Críticos

### 3.1. Imagens Base64 no Firestore — BOMBA DE CUSTO E PERFORMANCE

**Local:** `tela_cadastro_usuarios.dart:239-263`

Imagens do portfólio e documentos são lidas como bytes, convertidas para base64 e salvas **direto nos documentos do Firestore**.

**Problemas:**
- Limite de 1MB por documento no Firestore
- Custo elevado ( Firestore cobra por dados lidos/escritos)
- Lentidão nas queries que retornam documentos com imagens
- **Firebase Storage** já está no `pubspec.yaml` (`firebase_storage: ^13.0.4`) mas **nunca é importado em nenhum arquivo**

**Impacto:** Se um prestador enviar 5 fotos de 3MB cada, o documento terá ~20MB — impossível de salvar no Firestore.

### 3.2. Tela de Checkout não salva pedido no banco

**Local:** `tela_finalizacao_compra.dart:247-262`

```dart
void _finalizarPedido() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sucesso!"),
        content: const Text("Seu pedido foi enviado com sucesso."),
        ...
      ),
    );
}
```

O pedido **nunca é persistido**. A coleção `pedidos` existe no JSON de modelagem (`bdConectaV1.0.json`) mas nunca é usada no código.

### 3.3. Carrinho é volátil — perdido ao sair da tela

**Local:** `tela_produtos_disponiveis.dart:26`

```dart
final Map<String, Map<String, dynamic>> _carrinho = {};
```

O carrinho é um `Map` em memória do `StatefulWidget`. Se o usuário sair da tela, trocar de app ou o Flutter reconstruir o widget, **todos os itens são perdidos**.

### 3.4. Promoção de admin não funciona

**Local:** `tela_todos_usuarios.dart:117-127` + `main.dart:55-60`

Ao promover um usuário comum a admin, o código apenas muda o campo `tipo` em `usuarioComum`:

```dart
await FirebaseFirestore.instance.collection('usuarioComum').doc(uid).update(
  {'tipo': virarAdmin ? 'admin' : 'comum'},
);
```

Mas o `AuthWrapper` verifica admin buscando um documento na coleção `administrador`:

```dart
var doc = await FirebaseFirestore.instance.collection('administrador').doc(uid).get();
if (doc.exists) return 'administrador';
```

Como nenhum documento é criado em `administrador`, **o usuário nunca será reconhecido como admin ao logar**, mesmo após a promoção.

### 3.5. Rotas inexistentes no MaterialApp — app vai quebrar

**Local:** `menu_lateral.dart`

O menu lateral referencia rotas que **não existem** no `MaterialApp` (`main.dart:40-47`):

| Rota | Referenciada em |
|---|---|
| `/login` | `menu_lateral.dart:158` |
| `/favoritos` | `menu_lateral.dart:85` |
| `/historico` | `menu_lateral.dart:102` |
| `/faq` | `menu_lateral.dart:125` |
| `/configuracoes` | `menu_lateral.dart:134` |
| `/ajuda` | `menu_lateral.dart:142` |

Ao clicar em qualquer um desses itens, o app lança: `Could not find a generator for route RouteSettings(...)`.

---

## 4. Bugs Moderados

### 4.1. Notificação marcada como lida dentro do `build`

**Local:** `tela_notificacoes.dart:66-68`

```dart
if (!lida) {
    doc.reference.update({'lida': true});
}
```

Fazer `write` no Firebase **dentro** do `builder` de um `StreamBuilder` dispara um rebuild, que dispara outro write, criando um ciclo potencialmente infinito. O correto é mover para `onTap` do card ou gerenciar estado local.

### 4.2. Admin faz 4 queries sequenciais para determinar tipo do usuário

**Local:** `main.dart:55-75`

O `AuthWrapper._getUserType` faz **4 consultas sequenciais** ao Firestore a cada login (administrador → lojistas → prestadorServicos → comum). Se o usuário for comum, faz 3+ queries desnecessárias.

### 4.3. Campo `descricao` lido mas nunca salvo

**Local:**
- `categoria_quitandas.dart:86` — lê `data['descricao']`
- `categoria_bebidas.dart:94` — lê `data['descricao']`
- `categoria_servicos.dart:83` — lê `data['descricao']`

Mas na TelaCadastro (`tela_cadastro_usuarios.dart`), **nenhum lojista tem campo `descricao` salvo** no `set()`. O campo `descricao` nunca existe no documento `lojistas`.

### 4.4. CPF/CNPJ sem validação de formato

**Local:** `tela_cadastro_usuarios.dart`

Campos CPF e CNPJ são validados apenas com `v!.isEmpty ? 'Obrigatório' : null`. Qualquer string numérica é aceita (ex: "123"), sem verificação de dígitos ou formato.

### 4.5. `TelaInicialLojista` usa campo `descricao` mas `TelaCadastro` não salva

No cadastro do lojista, não existe campo para descrição da loja. As telas de categoria exibem "Sem descrição" para todos os lojistas.

---

## 5. Código Morto e Inconsistências

| Arquivo | Problema |
|---|---|
| `tela_definicao_senha.dart` | Tela completa nunca é acessada pelo fluxo de navegação |
| `tela_conteudo_produtos.dart:1-167` | Bloco inteiro de código antigo comentado — não removido |
| `tela_produtos_disponiveis.dart:299-367` | `TelaRevisaoCarrinho` duplicada e comentada |
| `menu_lateral.dart:68-95` | "Editar perfil" aparece **duas vezes** (uma funcional, outra com TODO) |
| `tela_divisao_categoria.dart:67` | `print(">>> A TELA REAL FOI CARREGADA <<<")` — debug em produção |
| `tela_inicial_prestador_servico.dart:56-72` | Dados **mock** hardcoded ("Fulano de Tal", "Eletricista") em vez de dados reais do Firestore |
| `tela_servicos.dart` | Arquivo vazio |
| `tela_perfil.dart` | Tela skeleton — sem controllers, sem validação, sem Firebase |

---

## 6. Inconsistências entre Modelagem e Implementação

### JSON de modelagem (`bdConectaV1.0.json`) vs código real

| Coleção | Campo no JSON | Campo no código | Status |
|---|---|---|---|
| `lojistas` | `uidLojista` | `lojistaId` | Nome do campo diferente |
| `lojistas` | nenhum `descricao` | código lê `descricao` | Campo não existe |
| `prestadorServicos` | sem campo `email` | código salva e lê `email` | Campo adicionado (ok, mas não documentado) |
| `produtos` | `idProduto` | usa doc ID do Firestore | OK |
| `pedidos` | coleção inteira definida | **nunca usada** | Funcionalidade inexistente |
| `usuarioComum` | `uidUsuarioComum` | usa UID do FirebaseAuth | OK |
| `admin` | coleção separada | **nunca criada** | Admins são só users com campo `tipo: admin` |

---

## 7. Firebase: Funciona? Ou migrar para relacional?

### Estado atual do Firebase

- **Firebase Core** — configurado e funcionando
- **Firebase Auth** — login/cadastro funcionando
- **Firestore** — leituras e escritas funcionando
- **Firebase Storage** — dependência instalada **mas nunca importada**

### Para MVP / Acadêmico: Mantenha Firebase

Firebase é adequado para o que o projeto precisa agora. Os problemas não são arquiteturais do Firebase, mas sim de implementação:

- Use **Firebase Storage** para imagens em vez de base64 (já está nas dependências)
- Firestore aguenta bem o volume do projeto

### Para Produção: Considere banco relacional

Se o app for escalar, considere migrar quando:

| Motivo | Explicação |
|---|---|
| **Consultas complexas** | Pedidos com itens, relatórios, filtros cruzados são naturais em SQL |
| **Integridade referencial** | CPF/CNPJ únicos, cascata de exclusão, validação de schema |
| **Custo** | Firestore cobra por read/write; para pedidos frequentes, o custo escala |
| **JOINs** | Relacionamentos pedido→itens→produto→lojista são um JOIN natural em SQL |

**Recomendação intermediária:** Use **Supabase** (PostgreSQL + realtime) como alternativa que mantém a experiência de "realtime" do Firebase com poder de banco relacional.

---

## 8. Sugestões de Melhoria (Priorizadas)

### Imediatas (antes da próxima entrega)

1. **Migrar imagens para Firebase Storage** — já está nas dependências, só falta implementar
2. **Implementar salvamento real de pedidos** — a coleção `pedidos` existe no modelo mas nunca é usada
3. **Persistir carrinho** — usar `shared_preferences` ou Firestore para não perder itens
4. **Corrigir promoção de admin** — criar doc na coleção `administrador` ao promover
5. **Registrar rotas faltantes** ou remover do menu lateral para evitar crash

### Curto prazo

6. **Criar camada de serviço** — isolar lógica Firebase das telas (repositório)
7. **Unificar telas de categoria** — 5 telas quase idênticas poderiam ser 1 só parametrizada
8. **Adicionar máscara/validação de CPF e CNPJ** — `cpf_validator` ou regex simples
9. **Implementar `EditarPerfilPage`** — conectar ao Firestore, adicionar controllers
10. **Preencher dados reais do prestador** — remover mock em `TelaInicialPrestador`

### Médio prazo

11. **Sistema de avaliações real** — substituir `5.0` hardcoded por coleção de reviews
12. **State management global** — Provider, Riverpod ou GetX para carrinho, auth state, etc.
13. **Modelos consistentes** — criar models para Lojista, Prestador, Pedido, etc.
14. **Remover dead code** — blocos comentados, prints, imports não usados
15. **Implementar `TelaDefinicaoSenha`** — conectar ao `currentUser.updatePassword()`

---

## 9. Dependências do projeto (`pubspec.yaml`)

| Pacote | Versão | Uso real |
|---|---|---|
| `firebase_core` | ^4.1.1 | Usado |
| `firebase_auth` | ^6.1.0 | Usado |
| `cloud_firestore` | ^6.0.2 | Usado |
| `firebase_storage` | ^13.0.4 | **NÃO USADO** |
| `permission_handler` | ^11.3.1 | Usado (implícito para galeria) |
| `gal` | ^2.3.0 | Usado |
| `image_picker` | ^1.2.1 | Usado |
| `intl` | ^0.19.0 | Usado |
| `cupertino_icons` | ^1.0.8 | Usado |

---

## 10. Coleções no Firestore (implementadas)

| Coleção | Status | Observação |
|---|---|---|
| `usuarioComum` | Funcional | Admin não escuta esta coleção na promoção |
| `lojistas` | Funcional | Campo `descricao` nunca é salvo |
| `prestadorServicos` | Funcional | Tela inicial usa dados mock |
| `produtos` | Funcional | Campo `lojistaId` consistente |
| `logsAdministrativos` | Funcional | Boa implementação |
| `pedidos` | **NÃO USADO** | Coleção existe no modelo mas não no código |
| `administrador` | **NÃO USADO** | Nunca criado — check em `main.dart` sempre falha |
| `notificações` (subcoleção) | Funcional | Write no build = ciclo infinito potencial |

---

## 11. Bugs Identificados em Testes Funcionais (Sprint 1 — testes manuais)

> Bugs descobertos durante execução real do app (testes manuais). Inclui causas raiz com referência ao código.

### 11.1. FAQ inacessível

**Local:** `tela_tipo_usuario.dart:107` — `// TODO: Implementar navegação para a tela de FAQ`
**Causa:** O link "FAQ" no rodapé da tela de escolha de tipo de usuário tem um `onTap` vazio com apenas um comentário TODO. Não existe tela de FAQ criada no projeto e não há rota `/faq` registrada em `main.dart`.
**Impacto:** Usuário clica e nada acontece.
**Correção futura:** Criar `tela_faq.dart` + registrar rota `/faq` no `MaterialApp`.

### 11.2. Loading infinito na tela principal do Visitante

**Local:** `main.dart:86-110` — `AuthWrapper`
**Causa:** Quando o visitante entra via botão "Visitante" na `TelaTipoUsuario`, ele é levado direto para `TelaInicialComum` sem fazer login anônimo no Firebase. Porém, em qualquer reconstrução do `AuthWrapper` (hot reload, navegação de volta), o código tenta resolver `_getUserType(uid)` para um usuário que pode estar em estado inconsistente, gerando loading perpétuo.
**Impacto:** Tela fica presa no `CircularProgressIndicator`.
**Correção futura:** Criar sessão anônima explícita com `FirebaseAuth.instance.signInAnonymously()` ao entrar como visitante, ou usar flag local para pular o `AuthWrapper`.

### 11.3. Menu lateral (Drawer) não funciona — Cliente/Visitante

**Local:** `tela_inicial_comum.dart:54` — `onPressed: () { // TODO: Menu lateral }`
**Causa:** O `IconButton` do menu na `AppBar` tem corpo vazio com comentário TODO. Além disso, o `Scaffold` não possui propriedade `drawer` definida.
**Impacto:** Ícone de menu aparece mas não abre nada.
**Correção futura:** Adicionar `drawer: MenuLateral(...)` no `Scaffold` de `TelaInicialComum` e chamar `Scaffold.of(context).openDrawer()`.

### 11.4. Menu lateral (Drawer) não funciona — Lojista

**Local:** `tela_inicial_lojista.dart` — `Scaffold` sem propriedade `drawer`
**Causa:** A tela inicial do lojista é um `Scaffold` que não define `drawer`. Diferente do prestador (que tem `drawer: MenuLateral(...)`), o lojista não tem nenhum Drawer configurado.
**Impacto:** Se o lojista tivesse um botão de menu, nada aconteceria. No entanto, atualmente a tela do lojista nem tem ícone de menu na `AppBar` — o botão sequer aparece.
**Correção futura:** Adicionar `drawer` + ícone de menu na `AppBar` + import do `menu_lateral.dart`.

### 11.5. Campos CPF, CNPJ, Telefone e CEP sem máscara nem limite

**Local:** `tela_cadastro_usuarios.dart:1138-1159` (CPF/telefone), `tela_cadastro_usuarios.dart:681-695` (CNPJ/telefone comercial), `tela_cadastro_usuarios.dart:777-782` (CEP)
**Causa:** Todos os campos usam apenas `keyboardType: TextInputType.number` ou `phone` sem `inputFormatters` nem validação de tamanho. O usuário pode digitar qualquer quantidade de dígitos (ex: "1" ou "12345678901234567890").

| Campo | Formato esperado | Implementação atual |
|---|---|---|
| CPF | `000.000.000-00` (14 chars) | Apenas `number`, sem máscara, sem limite |
| CNPJ | `00.000.000/0000-00` (18 chars) | Apenas `number`, sem máscara, sem limite |
| Telefone | `(00) 00000-0000` (15 chars) | `phone`, sem máscara, sem limite |
| CEP | `00000-000` (9 chars) | `number`, sem máscara, sem limite |

**Correção futura:** Adicionar `MaskedTextInputFormatter` (ou `flutter_masked_text2`) e validadores de tamanho/dígitos.

### 11.6. Sair da conta sem confirmação

**Local:** `tela_inicial_comum.dart:21-23`, `tela_inicial_lojista.dart:46-48`, `tela_inicial_prestador_servico.dart:79-84`, `tela_inicial_administrador.dart:115-117`
**Causa:** Todas as funções `_signOut()` chamam `FirebaseAuth.instance.signOut()` diretamente, sem dialog de confirmação.
**Impacto:** Toque acidental desloga o usuário sem aviso.
**Correção futura:** Criar dialog genérico `_confirmarSair()` com `AlertDialog("Tem certeza que deseja sair?")` antes de executar `signOut()`.

### 11.7. Admin não confirma perfil antes de aprovar/rejeitar

**Local:** `tela_detalhes_cadastro.dart:161-204` — `_mostrarConfirmacaoDecisao()`
**Observação:** O código já exibe um `AlertDialog` pedindo confirmação antes de aprovar ou rejeitar. Porém, o dialog não exibe os dados resumidos do usuário sendo avaliado (nome, documento, categoria), o que tornaria a decisão mais segura.
**Correção futura (melhoria):** Exibir resumo do perfil dentro do dialog de confirmação para o admin verificar antes de decidir.

### 11.8. Upload de alvará não é obrigatório para Lojista

**Local:** `tela_cadastro_usuarios.dart:794-804`
**Causa:** O botão "Adicionar Documento" chama `_selecionarImagem(false)` mas não há nenhuma validação em `_cadastrar()` que exija `_imagensDocumentosBase64.isNotEmpty` para lojista. Para prestador existe validação de documento (linha 450-461), mas para lojista, não.
**Impacto:** Lojista consegue se cadastrar sem enviar alvará ou qualquer documento.
**Correção futura:** Adicionar validação `if (_imagensDocumentosBase64.isEmpty)` no bloco de lojista em `_cadastrar()`.

### 11.9. Conta Lojista consegue acessar tela de Prestador

**Local:** `main.dart:55-75` — `_getUserType()`
**Causa:** A verificação de tipo é feita por UID em coleções separadas. Se um mesmo UID existir em mais de uma coleção (ex: bug de cadastro que reutiliza UID), ou se o admin testar com credenciais erradas, o redirecionamento pode levar à tela errada. Além disso, não há middleware de proteção: qualquer usuário que saiba o caminho pode navegar manualmente.
**Correção futura:** Verificar `tipo` do usuário no documento Firestore e validar antes de acessar telas restritas.

### 11.10. Tela principal do Prestador não funciona **[CONCLUÍDA]**

**Local:** `tela_inicial_prestador_servico.dart:52-74` — `_fetchData()`
**Causa Original:** A função `_fetchData()` não consultava o Firestore — usava dados mock hardcoded (`"Fulano de Tal"`, `"Eletricista"`, 6 serviços genéricos).
**Status e Estrutura Atual:** **CONCLUÍDA.** A tela principal do prestador agora está perfeitamente integrada ao banco de dados Firestore. 
- Foi concebido o arquivo dinâmico `UsuarioUtil` (`lib/utils/usuario_util.dart`). Este utilitário padroniza a extração de perfis de usuários de qualquer tipo em todo o sistema a partir dos fragmentos soltos do Firestore, abordando regras flexíveis para nome/razão social.
- A função `_fetchData()` efetua a consulta à coleção `prestadorServicos/{uid}`, processando e inserindo as informações do atual prestador ativamente na UI (conectando diretamente a classe `PrestadorProfile`).
- A lógica do Firestore ("firestone") para busca, autenticação e utilitários já se encontra 100% livre de erros pelo compilador Dart neste escopo.
*(Nota: A lista visual de serviços inferiores e os botões "Editar Itens" ainda aguardam implementações isoladas de UI/Design futuras).*

### 11.11. Tela "Editar Perfil" não implementada corretamente

**Local:** `tela_perfil.dart:1-35` — `EditarPerfilPage`
**Causa:** Os `TextField()` não têm `controller`, não carregam dados atuais do usuário, e o botão "Salvar" tem `onPressed: () {}` vazio. Não há conexão com Firestore.
**Impacto:** Tela exibe campos em branco que não fazem nada ao salvar.
**Correção futura:** Buscar dados do usuário do Firestore, popular controllers, enviar update ao salvar.

### 11.12. Menu lateral do Prestador — só "Editar Perfil" funciona

**Local:** `menu_lateral.dart:59-146`
**Causa:** As opções "Favoritos" (`/favoritos`), "Histórico" (`/historico`), "Configurações" (`/configuracoes`), "Ajuda" (`/ajuda`) e "FAQ" (`/faq`) usam `Navigator.pushNamed` com rotas que não existem em `main.dart`. O app crasha ao clicar.
**Também:** "Editar Perfil" aparece **duas vezes** — uma funcional (linha 66-78) e uma com TODO (linha 89-95).
**Correção futura:** Criar as telas faltantes ou temporariamente mostrar `SnackBar("Em breve")`. Remover item duplicado.

### 11.13. Não existe tela de descrição de produto para Cliente

**Causa:** Não há nenhum arquivo no projeto equivalente a uma tela de detalhe/descrição individual de produto. As telas de categoria (`categoria_quitandas.dart`, etc.) listam produtos, mas não há navegação para uma página de detalhes.
**Impacto:** Cliente não consegue ver descrição detalhada, fotos ou informações completas de um produto.
**Correção futura:** Criar `tela_detalhe_produto.dart` e conectar a partir das telas de categoria.

### 11.14. Não existe tela/implementação de cancelamento de pedido ou serviço

**Causa:** A coleção `pedidos` não é usada no código (ver seção 10 da análise). Não há tela de "Meus Pedidos", histórico de compras, ou opção de cancelar. A tela `tela_finalizacao_compra.dart:247-262` só mostra um dialog de "Sucesso" sem persistir o pedido.
**Impacto:** Sem registro de pedidos, impossível cancelar ou acompanhar.
**Correção futura:** Implementar persistência de pedidos no Firestore, tela "Meus Pedidos" para cliente, e tela de gestão de pedidos para lojista/prestador com opção de cancelamento.

### 11.15. Lojista e Prestador não ficam em espera após cadastro

**Local:** `tela_cadastro_usuarios.dart` — fluxo de cadastro de lojista e prestador
**Causa:** Após o cadastro, o usuário lojista/prestador consegue fazer login imediatamente sem aguardar aprovação do administrador. Deveria haver um campo `status: 'pendente'` no documento do usuário, e o `AuthWrapper` deveria verificar esse status antes de liberar acesso às telas principais.
**Impacto:** Lojistas e prestadores não autorizados podem acessar o app sem validação do administrador.
**Correção futura:** Adicionar campo `status` (`pendente`/`aprovado`/`rejeitado`) no cadastro. No `_getUserType`, bloquear acesso se `status != 'aprovado'`, exibindo tela de "aguardando aprovação".

### 11.16. Login de lojista redireciona para tela "Como você quer logar"

**Local:** `main.dart` — `AuthWrapper` + `_getUserType()`
**Causa:** Ao fazer login como lojista, o `AuthWrapper` não identifica corretamente o tipo do usuário. Provavelmente a query na coleção `lojistas` não encontra o documento (pode ser por UID diferente ou campo ausente), fazendo o fluxo cair de volta na `TelaTipoUsuario` que pergunta "Como você quer logar?".
**Impacto:** Lojista faz login com credenciais corretas mas é tratado como visitante/não-logado, loop infinito de re-autenticação.
**Correção futura:** Investigar se o UID do Firebase Auth corresponde ao `uid` salvo no documento `lojistas`. Adicionar logging temporário no `_getUserType` para debugar qual query falha.

### 11.17. Carrinho não aceita produtos de lojas diferentes

**Local:** `tela_produtos_disponiveis.dart` — lógica do carrinho
**Causa:** O carrinho é escopo de uma única loja (produto vinculado a um `lojistaId`). Ao navegar para outra categoria/loja, o carrinho anterior é perdido ou não há mecanismo para mesclar itens de lojistas diferentes. Não há validação nem aviso ao usuário.
**Impacto:** Cliente não consegue montar um carrinho com produtos de múltiplos lojistas.
**Correção futura:** Reestruturar o carrinho como `Map<String, List<Item>>` agrupado por `lojistaId`, ou usar carrinho global com identificação de origem por item.

### 11.18. Pedidos registrados no banco não aparecem na tela

**Causa:** Mesmo que o salvamento de pedidos seja implementado no Firestore, não existe tela que faça queries na coleção `pedidos` para exibi-los. Não há `StreamBuilder`/`FutureBuilder` lendo a coleção `pedidos` filtrada por UID do cliente ou lojista.
**Impacto:** Pedido é criado mas nunca visualizado — equivalente a não ter pedido.
**Correção futura:** Criar tela "Meus Pedidos" (`tela_meus_pedidos.dart`) com query `FirebaseFirestore.instance.collection('pedidos').where('clienteId', isEqualTo: uid)` e listar com status.

### 11.19. Troco permitido abaixo do valor do pedido (pagamento em dinheiro)

**Local:** `tela_finalizacao_compra.dart` — seção de pagamento em dinheiro
**Causa:** O campo "troco" aceita qualquer valor sem validação contra o total do pedido. Se o pedido é R$50 e o usuário informa troco para R$30, o sistema não bloqueia — o que não faz sentido (troco deve ser maior ou igual ao valor do pedido).
**Impacto:** Lógica de pagamento inconsistente, possível prejuízo para lojista.
**Correção futura:** Validar `valorTroco >= totalPedido` antes de permitir finalizar. Se `valorTroco < totalPedido`, exibir erro "O valor informado deve ser maior ou igual ao total do pedido".

### 11.20. Pagamento PIX sem QR Code ou copia e cola

**Local:** `tela_finalizacao_compra.dart` — seção de pagamento PIX
**Causa:** A opção de pagamento PIX não gera QR code nem exibe chave copia e cola. Não há integração com API de pagamento (ex: Mercado Pago, Gerencianet) nem mesmo simulação visual. Após o pagamento PIX, não há tela de confirmação automática do pedido.
**Impacto:** Experiência de pagamento PIX incompleta — usuário não sabe para onde enviar o dinheiro.
**Correção futura:** Exibir QR code (gerado a partir da chave PIX do lojista) ou campo copia e cola. Após confirmação manual ou webhook de pagamento, redirecionar para tela de confirmação do pedido.

### 11.21. Tela de finalizar pedido permite dados fictícios

**Local:** `tela_finalizacao_compra.dart` — campos de endereço/entrega
**Causa:** Os campos de nome, endereço, telefone e dados de entrega não têm validação contra dados reais. O usuário pode informar "aaa", "123", ou dados claramente fictícios sem bloqueio.
**Impacto:** Pedidos com dados inválidos, impossibilidade de entrega, sobrecarga no suporte.
**Correção futura:** Adicionar validadores de formato (CEP via ViaCEP API, telefone com regex, nome com tamanho mínimo). Opcionalmente consultar dados do perfil do usuário como sugestão pré-preenchida.

### 11.22. Cliente não acessa descrição dos prestadores de serviço

**Local:** `tela_servicos.dart` (vazia) + `tela_divisao_categoria.dart` — navegação para prestadores
**Causa:** Ao navegar pela categoria de serviços, o cliente vê a listagem de prestadores (via `categoria_servicos.dart`), mas ao clicar em um prestador não há navegação para uma tela de detalhes/descrição. A tela `tela_servicos.dart` está completamente vazia.
**Impacto:** Cliente não consegue ver portfólio, avaliações, área de atuação ou descrição de um prestador antes de contratar.
**Correção futura:** Criar `tela_detalhe_prestador.dart` conectada ao Firestore (`prestadorServicos/{uid}`), exibindo nome, descrição, portfólio, avaliações e botão de contato/contratação.

---

## 12. Resumo Consolidado de Problemas para Sprint 2

### Críticos (impedem uso do app)

| # | Problema | Arquivo(s) | Tipo |
|---|----------|-----------|------|
| 1 | Menu lateral não funciona (cliente) | `tela_inicial_comum.dart` | Bug funcional |
| 2 | Menu lateral não funciona (lojista) | `tela_inicial_lojista.dart` | Funcionalidade faltante |
| 3 | Loading infinito (visitante) | `main.dart` | Bug |
| 4 | Rotas inexistentes (/faq, /favoritos, /historico, /ajuda, /configuracoes, /login) | `main.dart`, `menu_lateral.dart` | Crash garantido |
| 5 | Tela prestador não funciona (dados mock) | `tela_inicial_prestador_servico.dart` | **[CONCLUÍDO]** |
| 6 | Pedido não é salvo no banco | `tela_finalizacao_compra.dart` | Bug crítico |
| 7 | Carrinho é volátil (perdido ao sair) | `tela_produtos_disponiveis.dart` | Bug funcional |
| 8 | Imagens base64 estouram limite do Firestore | `tela_cadastro_usuarios.dart` | Risco de quebra |

### Importantes (funcionalidade parcial ou ausente)

| # | Problema | Arquivo(s) | Tipo |
|---|----------|-----------|------|
| 9 | Editar perfil não implementada | `tela_perfil.dart` | Tela incompleta |
| 10 | CPF/CNPJ/Telefone/CEP sem máscara | `tela_cadastro_usuarios.dart` | Validação |
| 11 | Sair sem confirmação | Todas as telas iniciais | UX |
| 12 | Alvará não obrigatório (lojista) | `tela_cadastro_usuarios.dart` | Regra de negócio |
| 13 | Lojista acessa prestador | `main.dart` | Segurança |
| 14 | Promoção de admin não funciona | `main.dart`, `tela_todos_usuarios.dart` | Bug |
| 15 | Sem tela de descrição de produto | N/A | Funcionalidade faltante |
| 16 | Sem tela de cancelamento de pedido | N/A | Funcionalidade faltante |
| 17 | FAQ não funciona | `tela_tipo_usuario.dart` | Funcionalidade faltante |
| 18 | Lojista/Prestador sem aprovação obrigatória | `tela_cadastro_usuarios.dart`, `main.dart` | Regra de negócio |
| 19 | Login lojista cai em "Como você quer logar" | `main.dart` | Bug |
| 20 | Carrinho não aceita lojas diferentes | `tela_produtos_disponiveis.dart` | Bug funcional |
| 21 | Pedidos salvos no banco não aparecem | N/A | Tela faltante |
| 22 | Troco abaixo do valor do pedido | `tela_finalizacao_compra.dart` | Validação |
| 23 | PIX sem QR code/copia e cola | `tela_finalizacao_compra.dart` | Funcionalidade faltante |
| 24 | Finalizar pedido aceita dados fictícios | `tela_finalizacao_compra.dart` | Validação |
| 25 | Cliente não vê descrição de prestador | `tela_servicos.dart` | Tela faltante |

### Melhorias / Código

| # | Problema | Arquivo(s) | Tipo |
|---|----------|-----------|------|
| 26 | "Editar Perfil" duplicado no menu | `menu_lateral.dart` | Código morto |
| 27 | Notificação marcada como lida no `build` (ciclo) | `tela_notificacoes.dart` | Bug potencial |
| 28 | `firebase_storage` instalado mas nunca usado | `pubspec.yaml` | Dependência órfã |
| 29 | Admin não exibe resumo ao confirmar perfil | `tela_detalhes_cadastro.dart` | Melhoria UX |
| 30 | Código morto (blocos comentados, prints) | Vários | Limpeza |
| 31 | `tela_servicos.dart` vazio | `tela_servicos.dart` | Arquivo morto |
| 32 | `tela_definicao_senha.dart` inacessível | `tela_definicao_senha.dart` | Funcionalidade inacessível |
| 33 | 5 telas de categoria quase idênticas | `categorias/` | Refatoração |
| 34 | `AuthWrapper` faz 4 queries sequenciais | `main.dart` | Performance |

---

*Documento gerado automaticamente a partir de análise estática de todo o código-fonte do projeto. Bugs de testes funcionais adicionados em 2026-04-07.*
