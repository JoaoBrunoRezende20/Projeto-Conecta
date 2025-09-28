🚀 GUIA DE PARA EVITAR CONFLITOS  GITHUB - PARA O TIME
📋 REGRAS DE OURO (LEIAM ANTES!)
🚨 NUNCA FAÇAM:
❌ Commitar direto na main

❌ Trabalhar sem atualizar o repositório primeiro

❌ Fazer push sem testar o código

❌ Commitar arquivos desnecessários (.env, node_modules, etc.)

❌ Esquecer de dar git pull antes de começar

✅ SEMPRE FAÇAM:
✅ Commits pequenos e frequentes

✅ Mensagens claras nos commits

✅ Uma funcionalidade por branch

✅ Pull antes de push

✅ Commitar apenas código que funciona

🛠️ COMANDOS BÁSICOS (COPY/PASTE)
1. 🏁 COMEÇANDO NO PROJETO (Primeira Vez)

# Copia o projeto do GitHub para seu PC
git clone https://github.com/seu-usuario/nosso-projeto.git

# Entra na pasta do projeto
cd nosso-projeto

# Abre no VSCode (opcional)
code .

2. 🔄 ATUALIZAR (TODO DIA - ANTES DE TRABALHAR)

# SEMPRE comece com isso - pega as últimas mudanças
git pull origin main

3. 🌱 CRIAR NOVA FUNCIONALIDADE

# Cria uma branch nova para sua tarefa
git checkout -b minha-nova-funcionalidade

# Exemplos de nomes bons:
git checkout -b feature/tela-login
git checkout -b fix/corrige-bug-botao
git checkout -b docs/adiciona-manual

4. 💾 SALVAR SEU TRABALHO

# Verifica o que você modificou
git status

# Prepara os arquivos para commit
git add .

# OU adiciona arquivos específicos
git add arquivo1.js arquivo2.css

# Salva no histórico local com mensagem clara
git commit -m "feat: adiciona tela de login"

5. ☁️ ENVIAR PARA O GITHUB

# Envia sua branch para o GitHub
git push origin minha-nova-funcionalidade

6. 🎯 FINALIZAR NO GITHUB
Vai no repositório no GitHub

Clica em "Pull Request"

Seleciona sua branch → main

Marca alguém para review

Clica em Merge

📝 MENSAGENS DE COMMIT (USE SEMPRE)
Padrão Recomendado:

git commit -m "feat: adiciona funcionalidade X"
git commit -m "fix: corrige bug no botão Y"
git commit -m "docs: atualiza documentação"
git commit -m "style: formata código"
git commit -m "refactor: melhora estrutura do código"

Para Mudanças Pequenas:

git commit -m "fix: typo"
git commit -m "chore: ajuste mínimo"
git commit -m "style: formatação"

🚨 RESOLVENDO PROBLEMAS COMUNS
Se esqueceu de dar pull:

# Se der conflito, não entre em pânico!
git pull origin main

# Edite os arquivos com <<<<<<< HEAD
# Depois:
git add .
git commit -m "resolve conflitos"
Se committou algo errado:

# Desfaz o último commit (mas mantém as mudanças)
git reset --soft HEAD~1

# OU desfaz completamente
git reset --hard HEAD~1
Se fez commit na branch errada:

# Cria nova branch com seus commits
git checkout -b branch-correta
git checkout main
git pull origin main
📋 FLUXO DIÁRIO RESUMIDO

Começar a trabalhar:

git pull origin main
git checkout -b minha-tarefa-de-hoje

Trabalhando:

# A cada 1-2 horas, ou quando terminar uma parte:
git add .
git commit -m "feat: parte 1 da funcionalidade"

Enviar trabalho:

git push origin minha-tarefa-de-hoje

# → Vai no GitHub e abre Pull Request

🎯 DICAS EXTRAS

Ver histórico:
git log --oneline

Ver diferenças:
git diff

Ver status:
git status

Listar branches:
git branch