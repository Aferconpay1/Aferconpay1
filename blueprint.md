### **Visão Geral do Projeto**

O Afercon Pay é uma aplicação de pagamentos móveis desenvolvida em Flutter, com um backend Firebase. O seu objetivo é fornecer uma plataforma segura e intuitiva para transações financeiras, incluindo transferências, depósitos, levantamentos e pagamentos via QR code. A aplicação dá prioridade à segurança do utilizador, com funcionalidades como autenticação, verificação de e-mail e um PIN de transação para confirmar operações.

### **Funcionalidades e Design Implementados**

*   **Autenticação de Utilizador:**
    *   Registo e login com e-mail e palavra-passe.
    *   Fluxo de verificação de e-mail.
    *   Opção para redefinir a palavra-passe.
    *   Mecanismo de logout seguro.

*   **Segurança:**
    *   Palavra-passe e PIN armazenados de forma segura (hashed no Firestore e encriptado localmente).
    *   PIN de transação de 6 dígitos para autorizar operações financeiras.
    *   Separação de PIN e palavra-passe para diferentes níveis de segurança.

*   **Navegação:**
    *   Estrutura de navegação centralizada com `go_router`.
    *   Rotas protegidas que requerem autenticação.
    *   Barra de navegação inferior para acesso rápido aos ecrãs principais (Início, Histórico).

*   **Perfil do Utilizador:**
    *   Ecrã de perfil com informações do utilizador.
    *   Opção para alterar a palavra-passe.
    *   **Opção para alterar o PIN de transação.**
    *   Botão para terminar a sessão.

*   **Design e UI:**
    *   Interface consistente que segue o estilo da Afercon Pay, utilizando `CustomAppBar`, `CustomButton` e `CustomTextField`.
    *   Suporte para modo claro e escuro.

### **Plano de Implementação Atual: Adicionar Alteração de PIN**

*   **Objetivo:** Permitir que os utilizadores alterem o seu PIN de transação diretamente no ecrã de perfil.

*   **Passos Executados:**
    1.  **Criação do Ecrã de Alteração de PIN:**
        *   Foi criado o ficheiro `lib/screens/pin/change_pin_screen.dart`.
        *   O design do ecrã foi alinhado com o `set_pin_screen.dart` para manter a consistência visual, utilizando os widgets personalizados da Afercon Pay.
        *   O ecrã contém três campos: "PIN Antigo", "Novo PIN" e "Confirmar Novo PIN".

    2.  **Integração no Perfil do Utilizador:**
        *   O ficheiro `lib/screens/profile_screen.dart` foi modificado para adicionar um novo `_SettingsTile` com o título "Alterar PIN de Transação" e um ícone de chave.

    3.  **Configuração da Navegação:**
        *   A rota `/change-pin` foi adicionada ao `go_router` no ficheiro `lib/main.dart`, ligando o novo botão ao `ChangePinScreen`.

    4.  **Correção de Erros e Refatoração:**
        *   O `SecureStorageService` foi atualizado para incluir os métodos `savePin` e `getPin`, centralizando a gestão do PIN.
        *   O método `updateUserPin` foi corrigido para o nome correto, `setTransactionPin`, que já existia no `FirestoreService`.
        *   O `change_pin_screen.dart` foi corrigido para utilizar os métodos corretos dos serviços, resolvendo os erros de compilação.

*   **Resultado:** A funcionalidade foi implementada com sucesso, está totalmente integrada e a funcionar como esperado.