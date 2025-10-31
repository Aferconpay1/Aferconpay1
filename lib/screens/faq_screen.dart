import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _faqItems = [];
  List<Map<String, String>> _filteredFaqItems = [];

  @override
  void initState() {
    super.initState();
    _faqItems = _getFaqData();
    _filteredFaqItems = _faqItems;
    _searchController.addListener(_filterFaqs);
  }

  void _filterFaqs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFaqItems = _faqItems.where((faq) {
        return faq['question']!.toLowerCase().contains(query) ||
               faq['answer']!.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ - Perguntas Frequentes'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar perguntas...',
                prefixIcon: const Icon(Iconsax.search_normal_1),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredFaqItems.length,
              itemBuilder: (context, index) {
                final faq = _filteredFaqItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 2,
                  child: ExpansionTile(
                    title: Text(
                      faq['question']!,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    childrenPadding: const EdgeInsets.all(16.0),
                    expandedAlignment: Alignment.centerLeft,
                    children: [
                      Text(
                        faq['answer']!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getFaqData() {
    return [
      {
        'question': 'O que é o Afercon Pay?',
        'answer': 'O Afercon Pay é uma aplicação de pagamentos móveis que lhe permite enviar, receber, levantar e depositar dinheiro de forma rápida e segura. Também pode solicitar créditos e gerir as suas finanças pessoais.'
      },
      {
        'question': 'Como posso criar uma conta no Afercon Pay?',
        'answer': 'Para criar uma conta, precisa de descarregar a aplicação, clicar em \'Criar Conta\', preencher os seus dados pessoais, definir uma palavra-passe e verificar o seu número de telefone ou e-mail.'
      },
      {
        'question': 'É seguro usar o Afercon Pay?',
        'answer': 'Sim, a sua segurança é a nossa prioridade. Usamos as mais recentes tecnologias de encriptação e segurança para proteger as suas informações e transações.'
      },
      {
        'question': 'Quais são os custos associados ao uso do Afercon Pay?',
        'answer': 'A maioria das transações, como transferências entre utilizadores, são gratuitas. No entanto, podem existir pequenas taxas para levantamentos e outras operações. Consulte a nossa secção de taxas para mais detalhes.'
      },
      {
        'question': 'Como posso adicionar dinheiro à minha conta Afercon Pay?',
        'answer': 'Pode depositar dinheiro na sua conta através de uma transferência bancária, depósito num agente autorizado ou usando um cartão de débito/crédito associado.'
      },
      {
        'question': 'O que é o pagamento por QR Code?',
        'answer': 'É uma forma rápida e segura de pagar. Basta abrir a opção \'Pagar QR\', apontar a câmara para o código do comerciante e confirmar o valor. Também pode gerar o seu próprio QR Code para receber pagamentos.'
      },
      {
        'question': 'Como posso transferir dinheiro para outro utilizador?',
        'answer': 'Vá a \'Transferir\', procure o utilizador pelo seu nome, número de telefone ou nome de utilizador, insira o valor e confirme a transação com o seu PIN de segurança.'
      },
      {
        'question': 'Posso enviar dinheiro para alguém que não tem Afercon Pay?',
        'answer': 'De momento, as transferências diretas são apenas entre utilizadores do Afercon Pay. No entanto, pode levantar o dinheiro e entregá-lo à pessoa.'
      },
      {
        'question': 'O que faço se me esquecer da minha palavra-passe?',
        'answer': 'No ecrã de início de sessão, clique em \'Esqueci-me da palavra-passe\'. Siga as instruções para redefinir a sua palavra-passe através do seu e-mail ou número de telefone registado.'
      },
      {
        'question': 'Como posso ver o meu histórico de transações?',
        'answer': 'O seu histórico completo de transações está disponível no separador \'Histórico\'. Pode filtrar por data e tipo de transação.'
      },
      {
        'question': 'O que é o PIN de segurança?',
        'answer': 'O PIN de segurança é um código de 4 dígitos que deve ser usado para autorizar todas as transações, garantindo uma camada extra de proteção para a sua conta.'
      },
      {
        'question': 'Como posso alterar o meu PIN de segurança?',
        'answer': 'Vá a \'Perfil\' > \'Segurança\' > \'Alterar PIN\'. Terá de inserir o seu PIN atual e, em seguida, o novo PIN duas vezes.'
      },
      {
        'question': 'Posso usar o Afercon Pay fora de Angola?',
        'answer': 'De momento, o Afercon Pay está otimizado para uso em Angola, com transações em Kwanzas (Kz). Funcionalidades internacionais poderão ser adicionadas no futuro.'
      },
      {
        'question': 'O que acontece se eu perder o meu telemóvel?',
        'answer': 'Se perder o seu telemóvel, entre em contacto com o nosso suporte ao cliente imediatamente para bloquear a sua conta. Pode depois recuperá-la num novo dispositivo.'
      },
      {
        'question': 'Como posso solicitar um crédito pessoal?',
        'answer': 'Na secção \'Créditos\', escolha a opção \'Crédito Pessoal\', preencha o formulário com os seus dados e o montante desejado. A nossa equipa analisará o seu pedido.'
      },
      {
        'question': 'Quais são os requisitos para solicitar um crédito?',
        'answer': 'Os requisitos variam, mas geralmente incluem ter um bom histórico de transações no Afercon Pay, um documento de identificação válido e comprovativo de rendimentos.'
      },
      {
        'question': 'Quanto tempo demora a aprovação de um crédito?',
        'answer': 'O tempo de aprovação pode variar, mas esforçamo-nos para dar uma resposta num prazo de 24 a 48 horas úteis.'
      },
      {
        'question': 'O que é a funcionalidade de \'Levantar\'?',
        'answer': 'Permite-lhe converter o seu saldo Afercon Pay em dinheiro físico. Pode levantar num agente autorizado ou numa caixa automática parceira.'
      },
      {
        'question': 'Como encontro um agente para depósito ou levantamento?',
        'answer': 'Na secção de depósito ou levantamento, haverá um mapa que lhe mostrará os agentes autorizados mais próximos de si.'
      },
      {
        'question': 'Posso cancelar uma transferência depois de a ter enviado?',
        'answer': 'As transferências no Afercon Pay são instantâneas. Uma vez confirmada, não é possível cancelá-la. Verifique sempre os dados antes de confirmar.'
      },
      {
        'question': 'O que devo fazer se enviar dinheiro para a pessoa errada?',
        'answer': 'Recomendamos que contacte a pessoa que recebeu o dinheiro e peça a devolução. O Afercon Pay não pode reverter transações confirmadas.'
      },
      {
        'question': 'Como posso associar um cartão bancário à minha conta?',
        'answer': 'Vá a \'Perfil\' > \'Métodos de Pagamento\' e siga as instruções para adicionar um novo cartão de débito ou crédito.'
      },
      {
        'question': 'Os meus dados bancários estão seguros?',
        'answer': 'Sim. Não armazenamos os dados completos do seu cartão. Toda a informação é processada através de um gateway de pagamento seguro e certificado.'
      },
      {
        'question': 'O que são as notificações push?',
        'answer': 'São alertas que recebe no seu telemóvel sobre a atividade da sua conta, como transferências recebidas, pagamentos efetuados e outras informações importantes.'
      },
      {
        'question': 'Posso desativar as notificações?',
        'answer': 'Sim, pode gerir as suas preferências de notificação nas definições do seu telemóvel ou na secção de notificações da aplicação.'
      },
      {
        'question': 'Como posso contactar o suporte ao cliente?',
        'answer': 'Pode contactar-nos através do chat na aplicação, por e-mail para suporte@aferconpay.com ou pelo nosso número de apoio ao cliente.'
      },
      {
        'question': 'O que é a verificação de identidade?',
        'answer': 'É um processo para confirmar que você é quem diz ser. Pode ser necessário enviar uma foto do seu Bilhete de Identidade e uma selfie. Isto aumenta os seus limites de transação.'
      },
      {
        'question': 'Porque preciso de verificar a minha identidade?',
        'answer': 'A verificação de identidade é uma medida de segurança para proteger a sua conta contra fraudes e para cumprir com as regulamentações financeiras.'
      },
      {
        'question': 'Quais são os limites de transação?',
        'answer': 'Os limites de depósito, transferência e levantamento dependem do nível de verificação da sua conta. Pode consultar os seus limites na secção \'Perfil\'.'
      },
      {
        'question': 'Como posso aumentar os meus limites?',
        'answer': 'Para aumentar os seus limites de transação, precisa de completar o processo de verificação de identidade, fornecendo os documentos solicitados.'
      },
      {
        'question': 'O Afercon Pay funciona sem internet?',
        'answer': 'Não. É necessária uma ligação à internet (dados móveis ou Wi-Fi) para aceder à sua conta e realizar transações.'
      },
      {
        'question': 'Posso ter mais do que uma conta no Afercon Pay?',
        'answer': 'Normalmente, cada utilizador deve ter apenas uma conta associada ao seu número de identificação e número de telemóvel.'
      },
      {
        'question': 'Como posso alterar o meu número de telefone?',
        'answer': 'Por razões de segurança, a alteração do número de telefone requer que entre em contacto com o nosso suporte ao cliente para verificar a sua identidade.'
      },
      {
        'question': 'Posso usar a minha conta Afercon Pay para pagar contas (água, luz)?',
        'answer': 'Esta funcionalidade está nos nossos planos! Estamos a trabalhar para integrar o pagamento de serviços e contas diretamente na aplicação.'
      },
      {
        'question': 'O que é o extrato de conta?',
        'answer': 'O extrato de conta é um documento PDF que resume todas as suas transações num determinado período. Pode gerá-lo e partilhá-lo a partir do ecrã inicial.'
      },
      {
        'question': 'Como posso usar o Afercon Pay para o meu negócio?',
        'answer': 'Oferecemos contas para comerciantes com funcionalidades adicionais. Contacte a nossa equipa comercial para saber mais sobre as soluções Afercon Pay para negócios.'
      },
      {
        'question': 'Posso agendar uma transferência?',
        'answer': 'De momento, não é possível agendar transferências. Todas as transações são processadas em tempo real.'
      },
      {
        'question': 'O que é o modo escuro (Dark Mode)?',
        'answer': 'É uma opção de visualização que altera o esquema de cores da aplicação para tons mais escuros, o que pode ser mais confortável para os olhos em ambientes com pouca luz e poupar bateria.'
      },
      {
        'question': 'Como posso ativar o modo escuro?',
        'answer': 'Pode alternar entre o modo claro e o modo escuro clicando no ícone do sol/lua na barra superior da aplicação.'
      },
      {
        'question': 'Os meus dados são partilhados com terceiros?',
        'answer': 'A sua privacidade é muito importante. Não partilhamos os seus dados pessoais com terceiros sem o seu consentimento, exceto quando exigido por lei. Consulte a nossa Política de Privacidade.'
      },
      {
        'question': 'Como posso encerrar a minha conta?',
        'answer': 'Lamentamos que queira ir embora. Para encerrar a sua conta, por favor, entre em contacto com o nosso suporte ao cliente. Eles irão guiá-lo através do processo.'
      },
      {
        'question': 'Qual é a taxa para levantamentos?',
        'answer': 'É aplicada uma pequena taxa percentual sobre o valor do levantamento para cobrir os custos da operação. O valor exato é mostrado antes de confirmar a transação.'
      },
      {
        'question': 'Há taxas para depósitos?',
        'answer': 'Normalmente, não cobramos taxas para depósitos, mas o seu banco ou o agente autorizado podem aplicar as suas próprias tarifas.'
      },
      {
        'question': 'O que é o \'Crédito Automóvel\'?',
        'answer': 'É uma linha de crédito específica para o ajudar a financiar a compra de um veículo. Pode simular e solicitar diretamente na secção de créditos.'
      },
      {
        'question': 'Como funciona o pagamento do crédito?',
        'answer': 'As prestações do seu crédito serão debitadas automaticamente do seu saldo Afercon Pay na data de vencimento. Certifique-se de que tem saldo suficiente.'
      },
        {
        'question': 'Posso pagar o meu crédito antecipadamente?',
        'answer': 'Sim, geralmente pode fazer pagamentos antecipados ou liquidar o seu crédito a qualquer momento. Contacte o suporte para mais detalhes sobre o procedimento.'
      },
      {
        'question': 'O que acontece se eu não pagar uma prestação do crédito?',
        'answer': 'O não pagamento de uma prestação pode resultar em juros de mora e afetar negativamente o seu historial de crédito. Se tiver dificuldades, contacte-nos o mais rápido possível.'
      },
      {
        'question': 'Como posso saber o estado do meu pedido de crédito?',
        'answer': 'Pode acompanhar o estado do seu pedido de crédito em tempo real na secção \'Créditos\' da aplicação. Também receberá notificações sobre qualquer atualização.'
      },
      {
        'question': 'A aplicação está disponível para iOS e Android?',
        'answer': 'Sim, o Afercon Pay está disponível para ambos os sistemas operativos. Pode descarregá-lo a partir da App Store (para iOS) e da Google Play Store (para Android).'
      },
      {
        'question': 'O que preciso para me registar?',
        'answer': 'Precisa de um smartphone com acesso à internet, um número de telemóvel angolano ativo e um documento de identificação válido (Bilhete de Identidade).'
      },
      {
        'question': 'Por que o meu pagamento com QR Code falhou?',
        'answer': 'Uma falha no pagamento com QR Code pode ocorrer por várias razões: saldo insuficiente, problemas de ligação à internet, QR code inválido ou problemas técnicos. Verifique o seu saldo e ligação e tente novamente.'
      },
      {
        'question': 'O que é a taxa de candidatura ao crédito?',
        'answer': 'É uma pequena taxa administrativa cobrada no momento da submissão do pedido de crédito para cobrir os custos de análise do processo. Esta taxa não é reembolsável.'
      },
      {
        'question': 'Posso ter um perfil de empresa no Afercon Pay?',
        'answer': 'Sim, oferecemos contas para negócios (Merchant) com funcionalidades específicas para empresas, como receber pagamentos de clientes e aceder a relatórios detalhados.'
      },
      {
        'question': 'Como transformo a minha conta pessoal numa conta de negócio?',
        'answer': 'Para fazer o upgrade da sua conta, por favor, entre em contacto com a nossa equipa de suporte ou com o departamento comercial. Eles irão fornecer-lhe toda a informação necessária.'
      },
      {
        'question': 'Quais são as vantagens de uma conta de negócio?',
        'answer': 'As contas de negócio têm limites de transação mais altos, acesso a ferramentas de relatório, a possibilidade de gerar QR Codes para múltiplos pontos de venda e suporte dedicado.'
      },
      {
        'question': 'Como posso adicionar o meu logótipo à minha conta de negócio?',
        'answer': 'Na sua conta de negócio, vá às definições do perfil e encontrará a opção para carregar o logótipo da sua empresa.'
      },
      {
        'question': 'Posso reverter um depósito?',
        'answer': 'Uma vez que um depósito é confirmado e o saldo é creditado na sua conta, a operação não pode ser revertida. O valor fica disponível para o seu uso.'
      },
      {
        'question': 'Como posso atualizar os meus dados pessoais?',
        'answer': 'Pode atualizar algumas informações, como a sua foto de perfil ou e-mail, na secção \'Perfil\' da aplicação. Para alterar dados sensíveis como o nome ou o número de BI, poderá ter de contactar o suporte.'
      },
      {
        'question': 'É possível ter notificações por e-mail?',
        'answer': 'Atualmente, as nossas notificações principais são enviadas via push para a aplicação. A opção de notificações por e-mail pode ser considerada para futuras atualizações.'
      },
      {
        'question': 'O que é o IBAN e por que preciso dele para levantar dinheiro?',
        'answer': 'O IBAN (International Bank Account Number) é o número de identificação da sua conta bancária. É necessário para que possamos transferir o dinheiro do seu saldo Afercon Pay para a sua conta no banco de forma segura.'
      },
      {
        'question': 'Onde encontro o meu IBAN?',
        'answer': 'Pode encontrar o seu IBAN no seu extrato bancário, na aplicação ou site do seu banco, ou contactando diretamente o seu banco.'
      },
      {
        'question': 'O Afercon Pay está associado a algum banco específico?',
        'answer': 'O Afercon Pay é uma entidade independente, mas trabalhamos com vários bancos parceiros para facilitar as operações de depósito e levantamento para os nossos utilizadores.'
      },
      {
        'question': 'O que é um pedido de levantamento pendente?',
        'answer': 'Significa que o seu pedido de levantamento foi recebido e está a ser processado pela nossa equipa. Normalmente, leva algumas horas até o valor ser transferido para a sua conta bancária.'
      },
      {
        'question': 'Por que o meu pedido de levantamento foi rejeitado?',
        'answer': 'Um pedido pode ser rejeitado por vários motivos, como dados do beneficiário incorretos (IBAN ou nome), suspeita de fraude ou problemas técnicos. Receberá uma notificação com o motivo.'
      },
      {
        'question': 'Como posso gerar um QR Code para receber dinheiro?',
        'answer': 'Vá à opção \'Receber QR\'. A aplicação irá gerar um QR Code único para a sua conta. Pode definir um valor específico ou deixar o valor em aberto para quem vai pagar o inserir.'
      },
      {
        'question': 'O meu QR Code de recebimento expira?',
        'answer': 'O seu QR Code estático (sem valor definido) não expira. Se gerar um QR Code para um valor específico, ele pode ter uma validade de alguns minutos por segurança.'
      },
      {
        'question': 'Posso partilhar o meu QR Code?',
        'answer': 'Sim! Pode partilhar uma imagem do seu QR Code através de redes sociais, e-mail ou qualquer outra aplicação de mensagens para que outras pessoas lhe possam pagar facilmente.'
      },
      {
        'question': 'O que é a autenticação de dois fatores (2FA)?',
        'answer': 'É uma camada extra de segurança que, para além da sua palavra-passe, requer um segundo código (geralmente enviado para o seu telemóvel) para aceder à sua conta. Planeamos implementar esta funcionalidade em breve.'
      },
      {
        'question': 'Como posso saber se uma notificação é legítima?',
        'answer': 'Todas as notificações oficiais do Afercon Pay aparecerão dentro da aplicação, na sua área de notificações. Desconfie de mensagens recebidas por SMS ou e-mail que peçam dados sensíveis.'
      },
      {
        'question': 'Posso partilhar um comprovativo de transação?',
        'answer': 'Sim, após cada transação, tem a opção de gerar e partilhar um comprovativo em formato PDF, que inclui todos os detalhes da operação.'
      },
      {
        'question': 'Qual a versão mínima do sistema operativo necessária?',
        'answer': 'Recomendamos que mantenha sempre o seu sistema operativo (iOS ou Android) atualizado para garantir a compatibilidade e a segurança. Os requisitos mínimos estão descritos na página da aplicação na App Store e Play Store.'
      },
      {
        'question': 'Com que frequência a aplicação é atualizada?',
        'answer': 'Lançamos atualizações regularmente para introduzir novas funcionalidades, melhorar o desempenho e reforçar a segurança. Mantenha as atualizações automáticas ativas!'
      },
      {
        'question': 'Posso ter a aplicação instalada em vários dispositivos?',
        'answer': 'Sim, pode ter a aplicação instalada em vários dispositivos, mas por segurança, só pode ter a sessão iniciada num dispositivo de cada vez.'
      },
      {
        'question': 'O que significa a mensagem \'Saldo insuficiente\'?',
        'answer': 'Esta mensagem aparece quando tenta fazer uma transação (transferência, pagamento, levantamento) de um valor superior ao saldo que tem disponível na sua conta Afercon Pay.'
      },
      {
        'question': 'Como posso verificar o meu saldo?',
        'answer': 'O seu saldo disponível é sempre visível no topo do ecrã inicial da aplicação. Pode tocar no ícone do olho para o ocultar ou mostrar.'
      },
      {
        'question': 'O que é a secção \'Créditos\'?',
        'answer': 'É o centro de crédito do Afercon Pay, onde pode ver as ofertas de crédito disponíveis para si, solicitar novos créditos e gerir os seus créditos ativos.'
      },
      {
        'question': 'A análise de crédito tem custos?',
        'answer': 'A submissão do pedido de crédito tem uma taxa de candidatura para cobrir os custos administrativos da análise. O valor é apresentado antes de confirmar o pedido.'
      },
      {
        'question': 'Posso usar o Afercon Pay para fazer compras online?',
        'answer': 'Estamos a trabalhar para integrar o Afercon Pay como método de pagamento em várias lojas online em Angola. Fique atento às novidades!'
      },
      {
        'question': 'Qual é a diferença entre saldo disponível e saldo contabilístico?',
        'answer': 'O saldo disponível é o montante que pode usar livremente. O saldo contabilístico pode incluir valores que estão pendentes (como um pedido de levantamento) e que ainda não foram efetivamente deduzidos.'
      },
      {
        'question': 'Como posso dar feedback ou sugerir uma nova funcionalidade?',
        'answer': 'Adoramos receber feedback! Pode usar a secção de \'Ajuda e Suporte\' na aplicação ou enviar um e-mail para feedback@aferconpay.com.'
      },
      {
        'question': 'O que acontece se a aplicação bloquear a meio de uma transação?',
        'answer': 'Se a aplicação bloquear, reinicie-a e verifique o seu saldo e o histórico de transações. Se a transação não foi processada, pode tentar novamente. Se o saldo foi debitado mas a outra parte não recebeu, contacte o suporte.'
      },
      {
        'question': 'Como posso exportar o meu extrato de conta?',
        'answer': 'No ecrã inicial, clique no ícone de download/extrato. Poderá selecionar o período desejado e a aplicação irá gerar um ficheiro PDF que pode guardar ou partilhar.'
      },
      {
        'question': 'Posso adicionar notas a uma transferência?',
        'answer': 'Sim, ao fazer uma transferência, existe um campo opcional para adicionar uma nota ou descrição, que ficará visível para si e para o destinatário.'
      },
      {
        'question': 'É possível bloquear um utilizador?',
        'answer': 'De momento, não existe uma função para bloquear utilizadores diretamente. Se estiver a receber contactos indesejados, por favor, reporte a situação ao nosso suporte.'
      },
      {
        'question': 'A minha conta pode ser bloqueada?',
        'answer': 'Sim, uma conta pode ser temporariamente bloqueada por motivos de segurança, como várias tentativas de login falhadas ou atividade suspeita, para proteger os seus fundos.'
      },
      {
        'question': 'Como desbloqueio a minha conta?',
        'answer': 'Se a sua conta for bloqueada, receberá instruções sobre os passos a seguir. Normalmente, envolve contactar o suporte ao cliente para verificar a sua identidade.'
      },
      {
        'question': 'O que é o programa de referências?',
        'answer': 'É um programa onde pode convidar amigos para se juntarem ao Afercon Pay. Quando eles se registam e fazem a primeira transação, ambos podem receber um bónus!'
      },
      {
        'question': 'Onde encontro o meu código de referência?',
        'answer': 'Poderá encontrar o seu código ou link de referência na secção \'Convidar Amigos\' ou no seu perfil.'
      },
      {
        'question': 'Posso alterar a moeda da minha conta?',
        'answer': 'Atualmente, todas as contas Afercon Pay operam exclusivamente em Kwanzas (Kz), a moeda nacional de Angola.'
      },
      {
        'question': 'Como sei se a minha aplicação está atualizada?',
        'answer': 'Vá à App Store ou Google Play Store e procure por Afercon Pay. Se houver um botão a dizer \'Atualizar\', significa que tem uma nova versão disponível.'
      },
      {
        'question': 'Os meus dados estão seguros na nuvem?',
        'answer': 'Sim, todos os seus dados são armazenados de forma segura nos nossos servidores, com múltiplas camadas de proteção e encriptação para garantir a sua confidencialidade.'
      },
      {
        'question': 'Posso usar a mesma conta Afercon Pay para fins pessoais e de negócio?',
        'answer': 'Recomendamos a criação de uma conta de negócio separada para a sua atividade comercial. Isto ajuda a manter as suas finanças organizadas e a aproveitar as funcionalidades para empresas.'
      },
      {
        'question': 'O que fazer em caso de atividade suspeita na minha conta?',
        'answer': 'Se notar alguma transação que não reconhece ou qualquer outra atividade suspeita, altere a sua palavra-passe e PIN imediatamente e contacte o nosso suporte ao cliente.'
      },
      {
        'question': 'O Afercon Pay tem algum programa de cashback?',
        'answer': 'Estamos constantemente a explorar novas formas de recompensar os nossos utilizadores. Fique atento às nossas campanhas e anúncios para saber sobre possíveis programas de cashback ou outras promoções.'
      },
      {
        'question': 'Como posso ver os detalhes de uma transação específica?',
        'answer': 'No seu histórico, clique em qualquer transação para ver todos os seus detalhes, como a data e hora exatas, ID da transação, e notas associadas.'
      },
      {
        'question': 'O que é o ID da transação?',
        'answer': 'É um número de referência único para cada operação realizada. É útil para identificar uma transação específica quando contacta o suporte ao cliente.'
      },
      {
        'question': 'Posso usar o Afercon Pay para receber o meu salário?',
        'answer': 'Se a sua entidade empregadora o permitir, pode fornecer os seus dados Afercon Pay para receber o seu salário diretamente na sua conta. Fale com o seu departamento de RH.'
      }
    ];
  }
}
