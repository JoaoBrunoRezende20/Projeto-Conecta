# Projeto Conecta

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

---

##  O que é o Conecta? (Visão Geral)

O **Conecta** é mais do que um aplicativo; é uma plataforma digital projetada para fortalecer a economia local. Ele atua como uma ponte entre os moradores de uma comunidade e os comércios locais, quitandas, bem como prestadores de serviços independentes. 

De forma simples e intuitiva, o aplicativo permite que você encontre o que precisa no seu bairro — seja comprar pão na padaria da esquina, encomendar verduras da quitanda ou agendar um encanador — tudo isso na palma da sua mão. 

**O grande diferencial do Conecta é o foco na comunidade e na facilidade de contato**, oferecendo atalhos rápidos para comunicação direta via WhatsApp e gestão de pedidos em tempo real.

###  Para quem é o aplicativo? (Tipos de Perfis)
O sistema adapta sua interface e suas funcionalidades dependendo de quem está fazendo o login:
1. **Consumidores:** Pessoas em busca de produtos frescos, itens de supermercado, ou profissionais para serviços variados. Podem montar carrinhos de compra e realizar agendamentos.
2. **Lojistas:** Comerciantes que desejam digitalizar seu negócio. Têm acesso a um painel de gestão de produtos, controle de estoque, definição de categorias (CNAE) e recebimento de pedidos.
3. **Prestadores de Serviço:** Profissionais autônomos, tais como eletricistas, diaristas e pedreiros, disponibilizam seus serviços com perfis que incluem fotografia e descrição detalhada, além de gerenciarem agendamentos e o histórico de seus clientes. Através de suas informações de contato, o consumidor pode entrar em contato direto com o prestador de serviço para combinar detalhes e valores.
4. **Administradores:** Equipe responsável pela moderação da plataforma.

---

##  Principais Funcionalidades

- **Marketplace Completo:** Listagem dinâmica de lojas e produtos, divididos por categorias intuitivas.
- **Carrinho e Checkout:** Fluxo de compra simples com acompanhamento de status do pedido (Pendente, Confirmado, Concluído).
- **Agendamento de Serviços:** Sistema de requisição para prestadores, permitindo aceitar ou recusar solicitações.
- **Upload de Imagens:** Fotos de perfil, fachadas de lojas e produtos, com armazenamento seguro em nuvem.
- **Notificações e Histórico:** Acompanhamento de todas as transações realizadas no app.
- **Contato Facilitado:** Integração direta com WhatsApp para negociações e dúvidas.

---

##  Para Pessoas Técnicas: Arquitetura e Estrutura

Por trás da interface amigável, o **Conecta** foi construído visando **escalabilidade, manutenibilidade e performance**, adotando boas práticas e padrões de projeto da engenharia de software moderna.

### 🏗️ Padrão de Arquitetura (Repository Pattern)
O projeto utiliza o *Repository Pattern* para garantir que a Interface de Usuário (UI) não se comunique diretamente com o Banco de Dados. Isso traz grandes benefícios:
- **Desacoplamento:** A lógica de negócio fica totalmente separada do código visual (Widgets).
- **Segurança:** Evita o uso de instâncias soltas do Firebase dentro das telas.
- **Testabilidade:** Facilita a criação de *mocks* e testes unitários no futuro.

###  Modelos Tipados (Entities)
Os dados recebidos do Firestore (que originalmente são mapas não-tipados `Map<String, dynamic>`) são rigorosamente convertidos em classes (Modelos) na camada de repositório. Isso previne erros de digitação de chaves (como buscar `"nomeUsuario"` em vez de `"nome_usuario"`) em tempo de execução.
- *Exemplos:* `UsuarioModel`, `ProdutoModel`, `PedidoModel`.

### 🛠️ Tecnologias e Dependências Principais
* **[Flutter](https://flutter.dev/) & [Dart](https://dart.dev/)**: Base do aplicativo.
* **[Firebase Authentication](https://firebase.google.com/products/auth)**: Gerenciamento seguro de sessões, criptografia de senhas e persistência de login.
* **[Cloud Firestore](https://firebase.google.com/products/firestore)**: Banco de dados NoSQL utilizado para armazenamento de dados em tempo real (*streams* para atualização instantânea da tela sem precisar recarregar).
* **[Firebase Storage](https://firebase.google.com/products/storage)**: Armazenamento de arquivos binários (imagens).
* **Pacotes Adicionais:**
  - `image_picker` e `gal`: Para capturar fotos da câmera ou galeria do dispositivo.
  - `url_launcher`: Para abrir links externos (WhatsApp, Mapas).
  - `mask_text_input_formatter`: Para máscaras de texto nativas (CPF, Telefone, CEP).

---

## 📂 Estrutura de Pastas do Código (`/lib`)

O código fonte está localizado dentro da pasta `e_nosso/lib/`, seguindo uma separação rigorosa de responsabilidades:

```text
/e_nosso/lib
 ├── models/          # Classes que representam as tabelas do BD (Ex: produto_model.dart)
 ├── repositories/    # Regras de negócio e comunicação direta com Firebase (Ex: auth_repository.dart)
 ├── telas/           # Código visual, organizado por fluxo de usuário
 │    ├── auth/       # Fluxo de entrada (Login, Cadastro)
 │    ├── consumidor/ # Telas de navegação do cliente final (Lojas, Produtos, Checkout)
 │    ├── lojista/    # Painel administrativo do lojista (Estoque, Pedidos Recebidos)
 │    └── prestador/  # Painel de serviços (Agendamentos Pendentes, Perfil Público)
 ├── widgets/         # Componentes isolados e reutilizáveis (Botões customizados, Cards, Inputs)
 └── main.dart        # Ponto de entrada (Entrypoint), configuração de rotas e injeção inicial
```

---

##  Como Executar e Criar o APK

### 1. Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) versão `>= 3.9.0` instalado e configurado no `PATH`.
- **Android Studio** (para rodar o emulador Android).
- Conta no Firebase configurada (o arquivo `google-services.json` deve estar em `android/app/`).

### 2. Passo a Passo para Desenvolvimento
Abra o seu terminal de preferência e execute:

```bash
# 1. Clone o repositório
git clone [INSERIR-URL-DO-REPOSITORIO]

# 2. Acesse a pasta raiz do código Flutter
cd Projeto-Conecta/e_nosso

# 3. Baixe e atualize todas as dependências do projeto
flutter pub get

# 4. Conecte seu dispositivo (físico ou emulador) e inicie a aplicação
flutter run
```

### 3. Como Gerar o Arquivo Instalável (APK para Android)
Se você deseja gerar o arquivo `.apk` final para enviar para clientes, instalar no seu próprio celular sem precisar do computador, ou publicar na Play Store, execute:

```bash
flutter build apk --release
```
Após o término do processamento, o arquivo gerado estará disponível na pasta do seu computador:  
`e_nosso/build/app/outputs/flutter-apk/app-release.apk`

---

## 👥 Autores e Desenvolvedores

Projeto acadêmico e de inovação desenvolvido por:

* **Gabriel Henrique Silva Duque**
* **João Bruno Faria Rezende**
* **Laís de Paula Oliveira**
* **Rafael Gonçalves Oliveira**
* **Luiz Felipe Gonçalves Pereira**
* **Marcus Vinícius Monteiro Macedo Silva**
* **Markenil Gomes Dos Santos**
* **Rayssa Mendes Da Silva**