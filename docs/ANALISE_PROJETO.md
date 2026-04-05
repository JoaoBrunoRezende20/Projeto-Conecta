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

*Documento gerado automaticamente a partir de análise estática de todo o código-fonte do projeto.*
