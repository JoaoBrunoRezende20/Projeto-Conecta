from fpdf import FPDF

DARK = (45, 45, 45)
PURPLE = (106, 13, 173)
GRAY = (110, 110, 110)
WHITE = (255, 255, 255)
RED = (199, 37, 78)
BG = (245, 240, 250)
CODE_BG = (30, 30, 46)
CODE_TXT = (205, 214, 244)
LINE = (204, 204, 204)
ROW_BG = (245, 240, 250)


class PDF(FPDF):
    def header(self):
        if self.page_no() == 1:
            return
        self.set_font("Helvetica", "I", 7)
        self.set_text_color(170, 170, 170)
        self.cell(0, 8, "Projeto Conecta - Analise do Código-Fonte", align="L")
        self.cell(0, 8, f"Pag. {self.page_no()}", align="R")
        self.ln(10)
        self.set_draw_color(LINE)
        self.set_line_width(0.2)
        self.line(self.l_margin, self.get_y(), self.w - self.r_margin, self.get_y())
        self.ln(4)

    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica", "I", 7)
        self.set_text_color(170, 170, 170)
        self.cell(0, 10, f"Projeto Conecta - Analise do Codigo-Fonte  |  Pagina {self.page_no()}/{{nb}}", align="C")

    def title_page(self):
        self.ln(70)
        self.set_font("Helvetica", "B", 30)
        self.set_text_color(*DARK)
        self.cell(0, 16, "Analise Completa", align="C", new_x="LMARGIN", new_y="NEXT")
        self.set_font("Helvetica", "B", 24)
        self.set_text_color(*PURPLE)
        self.cell(0, 14, "Projeto Conecta (e_nosso)", align="C", new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(*PURPLE)
        self.set_line_width(1.2)
        y = self.get_y() + 5
        self.line(self.w / 2 - 40, y, self.w / 2 + 40, y)
        self.ln(18)
        self.set_font("Helvetica", "", 11)
        self.set_text_color(*GRAY)
        for line in ["Gerada em: 2026-04-05", "Firebase: enosso-e1144", "Framework: Flutter (SDK ^3.9.0)"]:
            self.cell(0, 8, line, align="C", new_x="LMARGIN", new_y="NEXT")

    def section_title(self, title):
        self.ln(6)
        self.set_font("Helvetica", "B", 14)
        self.set_text_color(*PURPLE)
        self.cell(0, 10, title, new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(LINE)
        self.set_line_width(0.4)
        y = self.get_y()
        self.line(self.l_margin, y, self.w - self.r_margin, y)
        self.ln(5)

    def subsection(self, title):
        self.ln(3)
        self.set_font("Helvetica", "B", 11)
        self.set_text_color(*DARK)
        self.cell(0, 8, title, new_x="LMARGIN", new_y="NEXT")
        self.ln(2)

    def p(self, text):
        self.set_font("Helvetica", "", 10)
        self.set_text_color(40, 40, 40)
        self.multi_cell(0, 5.5, text)
        self.ln(2)

    def bold_p(self, text):
        self.set_font("Helvetica", "B", 10)
        self.set_text_color(40, 40, 40)
        self.multi_cell(0, 5.5, text)
        self.ln(1)

    def bullet(self, text):
        x0 = self.get_x()
        self.set_font("Helvetica", "", 9.5)
        self.set_text_color(40, 40, 40)
        self.set_x(x0 + 4)
        self.cell(5, 5.5, "- ")
        self.multi_cell(self.w - self.r_margin - self.get_x(), 5.5, text)
        self.ln(1)

    def code(self, text):
        self.ln(2)
        self._check_page_break(len(text.split("\n")) * 4.5 + 8)
        x0 = self.l_margin
        w = self.w - self.l_margin - self.r_margin
        lh = 4
        lines = text.strip().split("\n")
        h = lh * len(lines) + 10
        y0 = self.get_y()
        self.set_fill_color(*CODE_BG)
        self.rect(x0, y0, w, h, "F")
        self.set_xy(x0 + 4, y0 + 5)
        self.set_font("Courier", "", 7.5)
        self.set_text_color(*CODE_TXT)
        for line in lines:
            self.cell(0, lh, line[:95], new_x="LMARGIN", new_y="NEXT")
            if self.get_y() > self.h - 20:
                self.add_page()
                self.set_font("Courier", "", 7.5)
                self.set_text_color(*CODE_TXT)
        self.ln(4)
        self.set_text_color(40, 40, 40)

    def italic_p(self, text):
        self.set_font("Helvetica", "I", 10)
        self.set_text_color(80, 80, 80)
        self.multi_cell(0, 5.5, text)
        self.ln(2)

    def _check_page_break(self, h_needed):
        if self.get_y() + h_needed > self.h - 20:
            self.add_page()

    def simple_table(self, headers, rows, col_widths):
        """Draw a simple table with purple header."""
        self._check_page_break(12 * (len(rows) + 1) + 8)
        lh = 6.5
        # Header
        self.set_fill_color(*PURPLE)
        self.set_text_color(*WHITE)
        self.set_font("Helvetica", "B", 9)
        for i, h in enumerate(headers):
            self.cell(col_widths[i], lh, h, border=0, fill=True)
        self.ln(lh)
        # Rows
        self.set_text_color(40, 40, 40)
        for j, row in enumerate(rows):
            self._check_page_break(10)
            if j % 2 == 1:
                x0 = self.get_x()
                y0 = self.get_y()
                self.set_fill_color(*ROW_BG)
                self.rect(x0, y0, sum(col_widths), lh + 2, "F")
            for i, cell in enumerate(row):
                if "NÃO" in str(cell) or "NAO" in str(cell):
                    self.set_text_color(199, 37, 78)
                    self.set_font("Helvetica", "B", 8.5)
                elif "OK" == str(cell):
                    self.set_text_color(40, 150, 40)
                    self.set_font("Helvetica", "B", 8.5)
                else:
                    self.set_text_color(40, 40, 40)
                    self.set_font("Helvetica", "", 8.5)
                self.cell(col_widths[i], lh, str(cell)[:60])
            self.ln(lh)
        self.ln(5)


pdf = PDF()
pdf.alias_nb_pages()
pdf.set_auto_page_break(auto=True, margin=20)
pdf.set_margins(18, 18)

# COVER
pdf.add_page()
pdf.title_page()

# 1
pdf.add_page()
pdf.section_title("1. Visao Geral do Projeto")
pdf.p("Aplicativo marketplace local que conecta 4 tipos de usuarios:")
pdf.simple_table(
    ["Tipo", "Funcao"],
    [
        ["Cliente / Comum", "Navega categorias, monta carrinho, finaliza pedido"],
        ["Lojista", "Gerencia catalogo de produtos e estoque"],
        ["Prestador de Servico", "Perfil profissional com portfolio, area de atuacao, disponibilidade"],
        ["Administrador", "Aprova/rejeita cadastros, gerencia usuarios, visualiza logs"],
    ],
    [50, 130],
)

# 2
pdf.section_title("2. Estrutura de Arquivos")
pdf.code("""lib/
  main.dart                          -> App entry point + AuthWrapper
  firebase_options.dart              -> Config Firebase (auto-gerado)
  telas/
    auth/
      tela_tipo_usuario.dart         -> Selecao de tipo antes do login
      tela_login.dart                -> Login com email/senha
      tela_cadastro_usuarios.dart    -> Cadastro completo
      tela_definicao_senha.dart      -> [INCOMPLETA] Definicao de senha
      tela_detalhes_cadastro.dart    -> Admin revisa cadastro com docs
    cliente/
      tela_inicial_comum.dart        -> Grid de categorias
      tela_divisao_categoria.dart    -> Navegacao por categorias
      tela_produtos_disponiveis.dart -> Lista produtos + carrinho
      tela_carrinho.dart             -> Revisao do carrinho
      tela_finalizacao_compra.dart   -> Dados entrega + pagamento
      tela_servicos.dart             -> [VAZIA]
    lojista/
      tela_inicial_lojista.dart      -> Gerencia de produtos (Firebase)
      tela_conteudo_produtos.dart    -> Gerencia local (nao Firebase)
      tela_admin_conteudo_lojista.dart -> Admin ve/exclui produtos
    prestador/
      tela_inicial_prestador_servico.dart -> Perfil (dados mock)
      tela_admin_conteudo_prestador.dart  -> Admin ve portfolio
    admin/
      tela_inicial_administrador.dart  -> Cadastros pendentes
      tela_todos_usuarios.dart         -> Gestao total (3 abas)
      tela_logs.dart                   -> Auditoria com filtros
    categorias/
      categoria_bebidas.dart, categoria_quitandas.dart, categoria_servicos.dart
      categoria_feira_livre.dart       -> [NAO ANALISADA]
      categoria_outros.dart            -> [NAO ANALISADA]
    perfil/
      tela_perfil.dart              -> [SKELETON] Editar perfil
      tela_notificacoes.dart        -> Notificacoes (subcolecao)
  widgets/
    botao_notificacao.dart          -> Badge de notificacoes nao lidas
    menu_lateral.dart               -> Drawer lateral (rotas quebradas)""")

# 3
pdf.add_page()
pdf.section_title("3. Bugs Criticos")

pdf.subsection("3.1. Imagens Base64 no Firestore")
pdf.bold_p("Local: tela_cadastro_usuarios.dart, linhas 239-263")
pdf.p("Imagens do portfolio e documentos sao lidas como bytes, convertidas para base64 e salvas DIRETAMENTE nos documentos do Firestore.")
pdf.bullet("Limite de 1MB por documento no Firestore")
pdf.bullet("Custo elevado (Firestore cobra por dados lidos/escritos)")
pdf.bullet("Lentidao em queries com documentos inchados")
pdf.bullet("Firebase Storage ja esta no pubspec.yaml mas NUNCA e importado")
pdf.italic_p("Impacto: Se um prestador enviar 5 fotos de 3MB, o documento tera ~20MB -- impossivel salvar no Firestore.")

pdf.subsection("3.2. Tela de Checkout nao salva pedido")
pdf.bold_p("Local: tela_finalizacao_compra.dart, linhas 247-262")
pdf.p("O metodo _finalizarPedido() apenas mostra um dialog de Sucesso. O pedido NUNCA e salvo no banco. A colecao pedidos existe no JSON de modelagem mas nunca e usada no codigo.")

pdf.subsection("3.3. Carrinho e volatil -- perdido ao sair da tela")
pdf.bold_p("Local: tela_produtos_disponiveis.dart, linha 26")
pdf.p("O carrinho e um Map em memoria local do StatefulWidget. Se o usuario sair da tela, trocar de app ou o widget for reconstruido, todos os itens sao perdidos.")

pdf.subsection("3.4. Promocao de admin nao funciona")
pdf.bold_p("Local: tela_todos_usuarios.dart + main.dart")
pdf.p("Ao promover usuario a admin, so muda o campo tipo em usuarioComum. Mas o AuthWrapper verifica se existe doc na colecao administrador. Como nenhum documento e criado nessa colecao, o usuario promovido NUNCA sera reconhecido como admin ao logar.")

pdf.subsection("3.5. Rotas inexistentes -- app vai quebrar")
pdf.bold_p("Local: menu_lateral.dart")
pdf.simple_table(
    ["Rota", "Referenciada em"],
    [
        ["/login", "menu_lateral.dart:158"],
        ["/favoritos", "menu_lateral.dart:85"],
        ["/historico", "menu_lateral.dart:102"],
        ["/faq", "menu_lateral.dart:125"],
        ["/configuracoes", "menu_lateral.dart:134"],
        ["/ajuda", "menu_lateral.dart:142"],
    ],
    [45, 135],
)
pdf.p("Ao clicar em qualquer item: Could not find a generator for route.")

# 4
pdf.add_page()
pdf.section_title("4. Bugs Moderados")

pdf.subsection("4.1. Notificacao marcada como lida dentro do build")
pdf.bold_p("Local: tela_notificacoes.dart, linhas 66-68")
pdf.p("Fazer write no Firebase dentro do builder de um StreamBuilder dispara rebuild, que dispara outro write, criando um ciclo potencialmente infinito. Correto: mover para onTap do card.")

pdf.subsection("4.2. Admin faz 4 queries sequenciais por login")
pdf.bold_p("Local: main.dart, linhas 55-75")
pdf.p("AuthWrapper._getUserType faz 4 consultas sequenciais ao Firestore a cada login. Se o usuario for comum, faz 3+ queries desnecessarias.")

pdf.subsection("4.3. Campo descricao lido mas nunca salvo")
pdf.p("Telas de categoria (quitandas, bebidas, servicos) leem data['descricao'], mas na TelaCadastro nenhum lojista tem campo descricao salvo. O resultado exibido e sempre Sem descricao.")

pdf.subsection("4.4. CPF/CNPJ sem validacao de formato")
pdf.p("Campos validados apenas com v!.isEmpty. Qualquer string numerica e aceita sem verificacao de digitos ou formato valido.")

pdf.subsection("4.5. Prestador usa dados mock em vez do Firestore")
pdf.bold_p("Local: tela_inicial_prestador_servico.dart, linhas 56-72")
pdf.p("O metodo _fetchData() usa hardcoded Fulano de Tal / Eletricista em vez de buscar dados reais do Firestore.")

# 5
pdf.section_title("5. Codigo Morto e Inconsistencias")
pdf.simple_table(
    ["Arquivo", "Problema"],
    [
        ["tela_definicao_senha.dart", "Tela nunca acessada pelo fluxo"],
        ["tela_conteudo_produtos.dart:1-167", "Bloco de codigo antigo comentado"],
        ["tela_produtos_disponiveis.dart:299-367", "TelaRevisaoCarrinho duplicada e comentada"],
        ["menu_lateral.dart:68-95", "Editar perfil aparece DUAS vezes"],
        ["tela_divisao_categoria.dart:67", "print() debug em producao"],
        ["tela_inicial_prestador_servico.dart", "Dados mock em vez de dados reais"],
        ["tela_servicos.dart", "Arquivo vazio"],
        ["tela_perfil.dart", "Skeleton -- sem Firebase, sem controllers"],
    ],
    [55, 128],
)

# 6
pdf.section_title("6. Inconsistencias: Modelagem vs Codigo")
pdf.simple_table(
    ["Colecao", "No JSON", "No Codigo", "Status"],
    [
        ["lojistas", "uidLojista", "lojistaId", "Nome dif."],
        ["lojistas", "sem descricao", "le descricao", "Nao existe"],
        ["prestadorServicos", "sem email", "salva email", "OK"],
        ["produtos", "idProduto", "doc ID", "OK"],
        ["pedidos", "colecao criada", "nunca usada", "NAO USADO"],
        ["usuarioComum", "uidUsuarioComum", "UID Auth", "OK"],
        ["admin", "colecao separada", "nunca criada", "NAO USADO"],
    ],
    [35, 32, 28, 85],
)

# 7
pdf.add_page()
pdf.section_title("7. Firebase: Funciona? Ou migrar para relacional?")

pdf.subsection("Estado atual")
pdf.simple_table(
    ["Componente", "Situacao"],
    [
        ["Firebase Core", "Configurado e funcionando"],
        ["Firebase Auth", "Login/cadastro funcionando"],
        ["Firestore", "Leituras e escritas OK"],
        ["Firebase Storage", "Dependencia instalada, NAO USADO"],
    ],
    [45, 135],
)

pdf.subsection("Para MVP / Academico: Mantenha Firebase")
pdf.p("Firebase e adequado para o projeto agora. Os problemas sao de implementacao, nao arquiteturais. Solucao imediata: usar Firebase Storage para imagens em vez de Base64.")

pdf.subsection("Para Producao: Considere relacional")
pdf.simple_table(
    ["Motivo", "Explicacao"],
    [
        ["Consultas complexas", "Pedidos-item-produto-lojista sao JOINs naturais SQL"],
        ["Integridade ref.", "CPF/CNPJ unicos, constraints, validacao schema"],
        ["Custo", "Firestore cobra por read/write; pedidos frequentes = custo alto"],
        ["Relatorios", "Consultas multi-colecao sao caras no NoSQL"],
    ],
    [40, 140],
)
pdf.italic_p("Alternativa: Supabase (PostgreSQL + realtime) mantem realtime do Firebase com SQL.")

# 8
pdf.add_page()
pdf.section_title("8. Sugestoes de Melhoria (Priorizadas)")

pdf.subsection("Imediatas")
pdf.bullet("Migrar imagens para Firebase Storage -- ja nas dependencias, so implementar")
pdf.bullet("Implementar salvamento real de pedidos no Firestore")
pdf.bullet("Persistir carrinho (shared_preferences ou Hive)")
pdf.bullet("Corrigir promocao de admin -- criar doc na colecao administrador")
pdf.bullet("Registrar rotas faltantes ou remover referencias do menu lateral")

pdf.subsection("Curto prazo")
pdf.bullet("Criar camada de servico/repo -- isolar logica Firebase das telas")
pdf.bullet("Unificar telas de categoria -- 5 telas quase identicas em 1 parametrizada")
pdf.bullet("Adicionar mascara/validacao de CPF e CNPJ")
pdf.bullet("Implementar EditarPerfilPage com conexao ao Firestore")
pdf.bullet("Preencher dados reais do prestador -- remover mock")

pdf.subsection("Medio prazo")
pdf.bullet("Sistema de avaliacoes real -- substituir 5.0 hardcoded")
pdf.bullet("State management global (Provider, Riverpod)")
pdf.bullet("Modelos consistentes para Lojista, Prestador, Pedido")
pdf.bullet("Remover dead code -- blocos comentados, prints, TODOs")
pdf.bullet("Implementar TelaDefinicaoSenha com updatePassword()")

# 9
pdf.section_title("9. Dependencias (pubspec.yaml)")
pdf.simple_table(
    ["Pacote", "Versao", "Uso"],
    [
        ["firebase_core", "^4.1.1", "Usado"],
        ["firebase_auth", "^6.1.0", "Usado"],
        ["cloud_firestore", "^6.0.2", "Usado"],
        ["firebase_storage", "^13.0.4", "NAO USADO"],
        ["permission_handler", "^11.3.1", "Usado"],
        ["gal", "^2.3.0", "Usado"],
        ["image_picker", "^1.2.1", "Usado"],
        ["intl", "^0.19.0", "Usado"],
        ["cupertino_icons", "^1.0.8", "Usado"],
    ],
    [45, 28, 107],
)

# 10
pdf.section_title("10. Colecoes no Firestore")
pdf.simple_table(
    ["Colecao", "Status", "Observacao"],
    [
        ["usuarioComum", "Funcional", "Admin nao escuta na promocao"],
        ["lojistas", "Funcional", "Campo descricao nunca salvo"],
        ["prestadorServicos", "Funcional", "Tela inicial usa dados mock"],
        ["produtos", "Funcional", "Campo lojistaId consistente"],
        ["logsAdministrativos", "Funcional", "Boa implementacao"],
        ["pedidos", "NAO USADO", "Existe no modelo, nao no codigo"],
        ["administrador", "NAO USADO", "Nunca criada -- check falha"],
        ["notificacoes (sub)", "Funcional", "Write no build = ciclo"],
    ],
    [42, 28, 110],
)

# 11
pdf.add_page()
pdf.section_title("11. Bugs Identificados em Testes Funcionais (Sprint 1)")
pdf.p("Bugs descobertos durante execucao real do app (testes manuais). Inclui causas raiz com referencia ao codigo.")

pdf.subsection("11.1. FAQ inacessivel")
pdf.bold_p("Local: tela_tipo_usuario.dart:107")
pdf.p("O link FAQ no rodape tem onTap vazio com TODO. Nao existe tela FAQ e nao ha rota /faq no main.dart. Usuario clica e nada acontece.")

pdf.subsection("11.2. Loading infinito na tela do Visitante")
pdf.bold_p("Local: main.dart:86-110 (AuthWrapper)")
pdf.p("Visitante entra direto em TelaInicialComum sem login anonimo. Em reconstrucoes do AuthWrapper, o codigo tenta resolver _getUserType(uid) para usuario em estado inconsistente, gerando loading perpetuo.")

pdf.subsection("11.3. Menu lateral nao funciona -- Cliente/Visitante")
pdf.bold_p("Local: tela_inicial_comum.dart:54")
pdf.p("onPressed vazio com TODO. Scaffold nao tem propriedade drawer definida.")

pdf.subsection("11.4. Menu lateral nao funciona -- Lojista")
pdf.bold_p("Local: tela_inicial_lojista.dart")
pdf.p("Scaffold sem drawer. A tela tambem nao tem icone de menu na AppBar.")

pdf.subsection("11.5. CPF, CNPJ, Telefone e CEP sem mascara nem limite")
pdf.bold_p("Local: tela_cadastro_usuarios.dart")
pdf.simple_table(
    ["Campo", "Esperado", "Atual"],
    [
        ["CPF", "000.000.000-00", "number, sem mascara, sem limite"],
        ["CNPJ", "00.000.000/0000-00", "number, sem mascara, sem limite"],
        ["Telefone", "(00) 00000-0000", "phone, sem mascara, sem limite"],
        ["CEP", "00000-000", "number, sem mascara, sem limite"],
    ],
    [30, 45, 105],
)

pdf.subsection("11.6. Sair da conta sem confirmacao")
pdf.bold_p("Local: Todas as telas iniciais")
pdf.p("Todas as funcoes _signOut() chamam signOut() diretamente, sem dialog. Toque acidental desloga o usuario.")

pdf.subsection("11.7. Admin nao tem resumo ao confirmar perfil")
pdf.bold_p("Local: tela_detalhes_cadastro.dart:161-204")
pdf.p("O dialog de confirmacao nao exibe dados resumidos do usuario (nome, documento, categoria). Melhoria: incluir resumo no dialog.")

pdf.subsection("11.8. Upload de alvara nao e obrigatorio (Lojista)")
pdf.bold_p("Local: tela_cadastro_usuarios.dart:794-804")
pdf.p("Nao ha validacao que exija pelo menos um documento para lojista. Para prestador existe, para lojista nao.")

pdf.subsection("11.9. Conta Lojista consegue acessar tela de Prestador")
pdf.bold_p("Local: main.dart:55-75")
pdf.p("Sem middleware de protecao: qualquer usuario que saiba navegar pode acessar telas restritas. Verificar tipo no documento antes de acessar.")

pdf.subsection("11.10. Tela principal do Prestador nao funciona")
pdf.bold_p("Local: tela_inicial_prestador_servico.dart:52-74")
pdf.p("_fetchData() usa dados mock hardcoded. Botoes Editar Itens, Servicos Agendados e Servicos Pendentes tem TODO vazio. FAB sem acao.")

pdf.subsection("11.11. Editar Perfil nao implementada corretamente")
pdf.bold_p("Local: tela_perfil.dart:1-35")
pdf.p("TextFields sem controller, nao carregam dados do usuario. Botao Salvar com onPressed vazio. Sem conexao com Firestore.")

pdf.subsection("11.12. Menu lateral do Prestador -- so Editar Perfil funciona")
pdf.bold_p("Local: menu_lateral.dart:59-146")
pdf.p("Rotas /favoritos, /historico, /configuracoes, /ajuda, /faq nao existem no main.dart -- app crasha ao clicar. Editar Perfil aparece duas vezes.")

pdf.subsection("11.13. Sem tela de descricao de produto para Cliente")
pdf.p("Nao ha nenhum arquivo equivalente a tela de detalhe individual de produto. Cliente nao consegue ver descricao detalhada de um produto.")

pdf.subsection("11.14. Sem tela/implementacao de cancelamento de pedido")
pdf.p("Colecao pedidos nao e usada. Nao ha tela de Meus Pedidos ou opcao de cancelar. tela_finalizacao_compra.dart so mostra dialog de Sucesso sem persistir.")

# 12
pdf.add_page()
pdf.section_title("12. Resumo Consolidado de Problemas para Sprint 2")

pdf.subsection("Criticos (impedem uso do app)")
pdf.simple_table(
    ["#", "Problema", "Arquivo(s)", "Tipo"],
    [
        ["1", "Menu lateral nao funciona (cliente)", "tela_inicial_comum.dart", "Bug funcional"],
        ["2", "Menu lateral nao funciona (lojista)", "tela_inicial_lojista.dart", "Func. faltante"],
        ["3", "Loading infinito (visitante)", "main.dart", "Bug"],
        ["4", "Rotas inexistentes (6 rotas)", "main.dart, menu_lateral.dart", "Crash"],
        ["5", "Tela prestador nao funciona", "tela_inicial_prestador.dart", "Bug funcional"],
        ["6", "Pedido nao e salvo no banco", "tela_finalizacao_compra.dart", "Bug critico"],
        ["7", "Carrinho e volatil", "tela_produtos_disponiveis.dart", "Bug funcional"],
        ["8", "Imagens base64 estouram Firestore", "tela_cadastro_usuarios.dart", "Risco de quebra"],
    ],
    [10, 60, 55, 55],
)

pdf.subsection("Importantes (funcionalidade parcial ou ausente)")
pdf.simple_table(
    ["#", "Problema", "Arquivo(s)", "Tipo"],
    [
        ["9", "Editar perfil nao implementada", "tela_perfil.dart", "Tela incompleta"],
        ["10", "CPF/CNPJ/Tel/CEP sem mascara", "tela_cadastro_usuarios.dart", "Validacao"],
        ["11", "Sair sem confirmacao", "Todas telas iniciais", "UX"],
        ["12", "Alvara nao obrigatorio (lojista)", "tela_cadastro_usuarios.dart", "Regra negocio"],
        ["13", "Lojista acessa prestador", "main.dart", "Seguranca"],
        ["14", "Promocao de admin nao funciona", "main.dart, tela_todos_usuarios.dart", "Bug"],
        ["15", "Sem tela descricao de produto", "N/A", "Func. faltante"],
        ["16", "Sem tela cancelamento de pedido", "N/A", "Func. faltante"],
        ["17", "FAQ nao funciona", "tela_tipo_usuario.dart", "Func. faltante"],
    ],
    [10, 60, 55, 55],
)

pdf.subsection("Melhorias / Codigo")
pdf.simple_table(
    ["#", "Problema", "Arquivo(s)", "Tipo"],
    [
        ["18", "Editar Perfil duplicado no menu", "menu_lateral.dart", "Codigo morto"],
        ["19", "Notificacao lida no build (ciclo)", "tela_notificacoes.dart", "Bug potencial"],
        ["20", "firebase_storage nunca usado", "pubspec.yaml", "Dep. orfa"],
        ["21", "Admin sem resumo ao confirmar", "tela_detalhes_cadastro.dart", "Melhoria UX"],
        ["22", "Codigo morto (blocos, prints)", "Varios", "Limpeza"],
        ["23", "tela_servicos.dart vazio", "tela_servicos.dart", "Arquivo morto"],
        ["24", "tela_definicao_senha.dart inacessivel", "tela_definicao_senha.dart", "Func. inacessivel"],
        ["25", "5 telas de categoria quase identicas", "categorias/", "Refatoracao"],
        ["26", "AuthWrapper faz 4 queries sequenciais", "main.dart", "Performance"],
    ],
    [10, 60, 55, 55],
)

# SAVE
out = r"C:\Users\gabri\Documents\Conecta\Projeto-Conecta\docs\ANALISE_PROJETO.pdf"
pdf.output(out)
print(f"PDF gerado com sucesso: {out}")
