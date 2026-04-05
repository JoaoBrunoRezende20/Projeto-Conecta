# Contribuindo para o Projeto Conecta

Guia de trabalho para o time. Leia antes de escrever cdigo.

---

## 1. Regras de Ouro

### O que nunca fazer

- **Commitar direto na `main`.** A `main` e sagrada. Trabalhe sempre em branches isoladas.
- **Trabalhar com repositorio desatualizado.** Comecou o dia? Atualize.
- **Fazer push de codigo quebrado.** Teste no emulador/dispositivo antes de enviar.
- **Commitar arquivos gerados.** `build/`, `.dart_tool/`, `*.iml`, `.flutter-plugins`, `pubspec.lock`, `google-services.json` de producao — nada disso sobe (use o `.gitignore`).
- **Commits gigantes.** `"fiz a tela toda"` e impossivel de revisar.

### O que sempre fazer

- **`git pull` antes de tudo.**
- **Uma branch = uma funcionalidade ou correcao.**
- **Commits pequenos e com proposito.**
- **Mensagens descritivas usando Conventional Commits** (veja abaixo).

---

## 2. Setup do Projeto

### Primeira vez

```bash
# Clone o repositorio
git clone https://github.com/seu-usuario/nosso-projeto.git
cd nosso-projeto

# Instale as dependencias do Flutter
cd e_nosso
flutter pub get

# Configure o Firebase (se ainda nao tiver google-services.json)
dart pub global activate flutterfire_cli
flutterfire configure --project=enosso-e1144

# Rode o projeto
flutter run
```

### Dependencias

- Flutter SDK **>= 3.9.0**
- Conta no Firebase com acesso ao projeto `enosso-e1144`

---

## 3. Fluxo de Trabalho Diario

### Atualizar antes de trabalhar

```bash
git checkout main
git pull origin main
```

### Criar branch para sua tarefa

```bash
git checkout -b tipo/nome-da-tarefa

# Exemplos:
git checkout -b feature/tela-carrinho
git checkout -b fix/validacao-cpf-cadastro
git checkout -b docs/contributing-guide
```

### Commitar

```bash
git status
git add lib/telas/cliente/tela_carrinho.dart
git commit -m "feat: cria tela de carrinho com contador de itens"
```

### Enviar e abrir PR

```bash
git push origin feature/tela-carrinho
```

1. Abra o repositorio no GitHub.
2. Clique em **Compare & pull request**.
3. Confirme **base: `main`** e **compare: `feature/tela-carrinho`**.
4. Preencha o template do PR (secao 7).
5. Marque um colega como reviewer.
6. Apos aprovacao, clique em **Merge**.

---

## 4. Padrao de Commits

Usamos **Conventional Commits**. Comece com uma tag:

| Tag | Quando usar | Exemplo |
|---|---|---|
| `feat:` | Nova funcionalidade | `feat: adiciona filtro por bairro nos prestadores` |
| `fix:` | Correcao de bug | `fix: resolve login falhando para usuarios comuns` |
| `docs:` | Documentacao | `docs: adiciona guia de setup no CONTRIBUTING` |
| `style:` | Formatacao/espacos (sem logica) | `style: ajusta indentacao do menu lateral` |
| `refactor:` | Refatoracao sem mudar comportamento | `refactor: extrai Widget de card de produto` |
| `chore:` | Dependencias, config, limpeza | `chore: remove codigo comentado em tela_conteudo_produtos` |

---

## 5. Estrutura de Pastas

```
lib/
  telas/
    auth/          — Login, cadastro, selecao de tipo
    cliente/       — Telas do usuario comum
    lojista/       — Telas do lojista
    prestador/     — Telas do prestador de servico
    admin/         — Telas do administrador
    categorias/    — Telas de cada categoria (quitandas, bebidas, etc.)
    perfil/        — Perfil e notificacoes
  widgets/         — Widgets reutilizaveis (menu lateral, badge notificacoes)
```

### Convencao de nomes de arquivo

- Nomes em **snake_case**: `tela_carrinho.dart`, `botao_notificacao.dart`
- Classes em **PascalCase**: `TelaCarrinho`, `BotaoNotificacao`
- Prefixo `tela_` para telas, sem prefixo para widgets reutilizaveis

---

## 6. Resolvendo Problemas (S.O.S)

### Conflito de merge

```bash
# Na sua branch, puxe a main
git pull origin main

# Abra os arquivos conflitantes no editor
# Resolva os marcadores <<<<<<< e >>>>>>>
# Salve e finalize
git add .
git commit -m "fix: resolve conflitos com a main"
```

### Commit errado na branch

```bash
# Desfaz o ultimo commit mantendo as alteracoes
git reset --soft HEAD~1
```

### Comecou a codar na `main` sem querer?

```bash
# Se nao fez commit ainda - cria branch levando as mudancas
git checkout -b minha-nova-branch
```

### Flutter nao compila apos git pull

```bash
flutter clean
flutter pub get
flutter run
```

---

## 7. Template de Pull Request

Ao abrir um PR, siga este modelo:

```markdown
## O que foi feito

Descreva em 1-2 frases o que mudou.

## Telas afetadas

- `lib/telas/cliente/tela_carrinho.dart`
- `lib/widgets/botao_notificacao.dart`

## Como testar

1. Logar como usuario X
2. Navegar para a tela Y
3. Clicar no botao Z

## Print (se for alteracao visual)

Cole o print aqui.

## Checklist

- [ ] Testei no emulador/dispositivo
- [ ] Nao commitei arquivos gerados (build/, .dart_tool/, etc.)
- [ ] Commits seguem o padrao Conventional Commits
```

---

## 8. Dicas rapidas

- `flutter pub get` sempre que modificar `pubspec.yaml`
- `flutter clean` se algo parecer corrompido apos atualizar branches
- ` flutter analyze` antes de abrir o PR — captura erros estaticos
- Evite `git add .` sem verificar `git status` — arquivos de build entram facil
