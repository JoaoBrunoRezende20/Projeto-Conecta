# 🚀 GUIA DEFINITIVO: FLUXO DE TRABALHO GITHUB
*Manual prático para o time programar em paz e evitar dores de cabeça com conflitos.*

## 📋 1. AS REGRAS DE OURO
Leia antes de escrever sua primeira linha de código!

### 🚨 O QUE NUNCA FAZER:
* ❌ **Commitar direto na `main`:** A `main` é sagrada. Use sempre branches.
* ❌ **Trabalhar com o repositório desatualizado:** O risco de conflito aumenta 100%.
* ❌ **Fazer push de código quebrado:** Teste antes de enviar.
* ❌ **Commitar lixo:** Arquivos `.env`, pastas `node_modules`, `__pycache__` ou binários não sobem (use o `.gitignore`).
* ❌ **Fazer commits gigantes:** "Fiz o backend inteiro" é um pesadelo para revisar.

### ✅ O QUE SEMPRE FAZER:
* ✅ **Pull antes de tudo:** Começou o dia? Atualize sua máquina.
* ✅ **Uma branch = Uma funcionalidade/correção:** Mantenha o escopo isolado.
* ✅ **Commits pequenos e com propósito:** Salve o progresso a cada etapa lógica concluída.
* ✅ **Mensagens descritivas:** Explique *o que* foi feito de forma clara.

---

## 🔄 2. O FLUXO DE TRABALHO DIÁRIO (Passo a Passo)

### Passo 0: A Primeira Vez (Setup)
Se você acabou de entrar no projeto, baixe o código para sua máquina:
```bash
git clone https://github.com/seu-usuario/nosso-projeto.git
cd nosso-projeto
code . # Abre no VS Code
```

### Passo 1: Atualizar (Sempre que for começar a trabalhar)
Garanta que você tem o código mais recente da equipe:
```bash
git checkout main
git pull origin main
```

### Passo 2: Isolar sua Tarefa (Criar Branch)
Nunca trabalhe na `main`. Crie um ambiente seguro para sua tarefa:
```bash
git checkout -b tipo/nome-da-tarefa

# Exemplos práticos:
git checkout -b feature/tela-login
git checkout -b fix/bug-botao-enviar
git checkout -b docs/readme-setup
```

### Passo 3: Trabalhar e Salvar (Commits Frequentes)
Codificou uma parte que funciona? Salve!
```bash
git status # Veja o que foi modificado
git add .  # Prepara todos os arquivos modificados (cuidado para não enviar lixo)
# OU
git add arquivo1.js arquivo2.css # Prepara arquivos específicos

git commit -m "feat: cria estrutura inicial do formulário de login"
```

### Passo 4: Enviar para a Nuvem
Terminou a tarefa? Envie sua branch para o GitHub:
```bash
git push origin nome-da-sua-branch
```

### Passo 5: Integrar (Pull Request - PR)
1. Vá até a página do repositório no GitHub.
2. Clique no botão verde **Compare & pull request**.
3. Confirme se a base é a `main` e a comparação é a sua branch.
4. Adicione um título claro e marque um colega do time como *Reviewer*.
5. Após a aprovação, clique em **Merge pull request**.

---

## 📝 3. PADRÃO DE MENSAGENS DE COMMIT
Usamos o padrão *Conventional Commits* para manter o histórico organizado. Comece sempre com uma destas tags:

* **`feat:`** Adiciona uma nova funcionalidade (ex: *feat: adiciona botão de exportar PDF*)
* **`fix:`** Corrige um bug (ex: *fix: resolve erro de cálculo na tabela*)
* **`docs:`** Mudanças apenas na documentação (ex: *docs: atualiza guia de instalação*)
* **`style:`** Formatação, pontuação, espaços (não altera a lógica) (ex: *style: ajusta indentação*)
* **`refactor:`** Refatoração de código (melhora a estrutura sem mudar o que faz)
* **`chore:`** Atualização de dependências, configurações (ex: *chore: atualiza versão do React*)

---

## 🆘 4. RESOLVENDO PROBLEMAS (S.O.S)

### ⚠️ "Deu Conflito na hora de fazer Pull ou Merge!"
Calma, o Git só não sabe qual versão do código manter.
1. No terminal, na sua branch, puxe as atualizações: `git pull origin main`
2. Abra os arquivos no VS Code. Eles estarão marcados com `<<<<<<< HEAD` e `>>>>>>> origin/main`.
3. O VS Code mostrará opções como *Accept Current Change* (manter o seu) ou *Accept Incoming Change* (manter o que veio da main). Escolha a correta (ou edite manualmente).
4. Salve o arquivo e finalize:
```bash
git add .
git commit -m "fix: resolve conflitos de merge com a main"
```

### ↩️ "Fiz um commit errado na branch certa"
Desfaz o último commit, mas **mantém** seus arquivos do jeito que estão para você arrumar:
```bash
git reset --soft HEAD~1
```

### 🛑 "Fiz uma bagunça gigantesca e quero apagar tudo que fiz hoje"
**Cuidado!** Isso apaga todas as alterações não commitadas e volta ao estado do último commit:
```bash
git reset --hard HEAD~1
```

### 🔀 "Comecei a codar na `main` por engano! E agora?"
Se você ainda **não** fez o commit:
```bash
git checkout -b minha-nova-branch # Cria a branch levando suas alterações não salvas junto
```

---

## 🛠️ 5. COMANDOS ÚTEIS PARA O DIA A DIA
* `git log --oneline` → Vê o histórico de commits de forma resumida.
* `git branch` → Lista as branches locais (a que tem um `*` é a que você está).
* `git diff` → Mostra linha por linha o que você alterou antes de commitar.

---

Como este guia foi pensado para evitar atritos na equipe, você gostaria que eu incluísse também um template de descrição padrão para abrir os **Pull Requests** (PRs) no GitHub? Isso ajuda bastante na hora da revisão do código!
