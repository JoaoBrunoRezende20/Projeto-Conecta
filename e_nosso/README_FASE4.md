# Planejamento da Refatoração - Fase 4

Este documento detalha o planejamento para a **Fase 4** da refatoração da arquitetura do aplicativo. A execução desta fase será dividida em 4 partes fundamentais para garantir a escalabilidade, manutenibilidade e performance do código.

Mesmo com o sucesso do *Repository Pattern* implementado nas Fases 1, 2 e 3 (desacoplando a UI do Firebase e limpando avisos do linter), ainda existem problemas de componentização e acoplamento de estado local que serão resolvidos aqui.

---

## Estrutura da Fase 4

A Fase 4 será dividida em 4 etapas/partes:

### Parte 1: Criação de Modelos de Dados (Entities / Models)
- **Problema Atual:** Os repositórios devolvem `DocumentSnapshot` e `QuerySnapshot` diretos do Firebase. Isso obriga a camada de UI a manipular dados como dicionários soltos (`Map<String, dynamic>`), o que é muito inseguro (falta de tipagem) e causa erros em tempo de execução se uma chave for digitada incorretamente.
- **Plano de Ação:** 
  1. Criar o diretório `lib/models/`.
  2. Implementar classes de modelos fortemente tipados: `UsuarioModel`, `ProdutoModel`, `PedidoModel`, `ServicoModel`, `CategoriaModel`, etc.
  3. Adicionar métodos construtores `fromMap(Map<String, dynamic> data)` e `toMap()` nessas classes.
  4. Refatorar os repositórios (ex: `usuario_repository.dart`) para devolver listas/instâncias de Modelos, e não respostas brutas do Firestore.

### Parte 2: Gerenciamento de Estado Consolidado (State Management)
- **Problema Atual:** As telas em `lib/telas/` abrigam extensa lógica de negócios e chamam `setState()` o tempo todo (mais de 75 ocorrências), misturando código visual com controle de fluxo, *loading* de telas e ações assíncronas.
- **Plano de Ação:**
  1. Definir uma arquitetura de Gerência de Estado Oficial para o app (`Provider`, `Riverpod`, ou `BLoC`).
  2. Migrar variáveis que controlam *loading* ou listas de itens para os *Controllers/ViewModels* equivalentes.
  3. Tornar os componentes puramente reativos.

### Parte 3: Componentização da Interface (Widgets)
- **Problema Atual:** Os arquivos da interface (como `tela_finalizacao_compra.dart` e `tela_detalhes_produto.dart`) chegam a mais de 16 KB e abrigam imensas árvores de widgets com alta repetição de trechos (Cards, TextFields, Botões de carregamento). A pasta `lib/widgets` está ociosa, contendo apenas 2 arquivos.
- **Plano de Ação:**
  1. Identificar padrões e blocos visuais repetidos.
  2. Extrair esses blocos de UI da pasta `telas/` e transformá-los em componentes reutilizáveis dentro de `lib/widgets/` ou em uma estrutura separada de *design system*.
  3. Encurtar os arquivos de Tela para que eles se importem majoritariamente com o Layout e Composição, e não com os mínimos detalhes de cada botão.

### Parte 4: Injeção de Dependências (Dependency Injection)
- **Problema Atual:** Instâncias das classes criadas (como `UsuarioRepository`, `ProdutoRepository`) frequentemente são criadas localmente em todas as telas que as utilizam, gerando instâncias redundantes e dificultando *mocks* para testes unitários no futuro.
- **Plano de Ação:**
  1. Integrar um framework de Injeção de Dependências (como o pacote `get_it`).
  2. Configurar a criação das dependências (Repositories/Services) como **Singletons** na inicialização do aplicativo (`main.dart`).
  3. Atualizar todo o sistema (Blocs/Controllers e Telas) para acessar essas dependências globais via o Injetor em vez de instanciá-las manualmente.
