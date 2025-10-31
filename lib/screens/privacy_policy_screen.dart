
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidade'),
        centerTitle: true,
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text(
            'Política de Privacidade - Afercon Pay',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Última atualização: 24 de Julho de 2024',
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 24),
          _Section(
            title: '1. Introdução',
            content:
                'Esta Política de Privacidade descreve como a Afercon Pay recolhe, usa e protege as suas informações pessoais quando utiliza a nossa aplicação. Comprometemo-nos a proteger a sua privacidade e a garantir que as suas informações pessoais são tratadas com segurança, em conformidade com a Lei da Proteção de Dados Pessoais de Angola (Lei n.º 22/11, de 17 de Junho).',
          ),
          _Section(
            title: '2. Informações que Recolhemos',
            content:
                'Podemos recolher os seguintes tipos de informações: \n\n- Informações de Identificação Pessoal: Nome, número de Bilhete de Identidade, endereço, número de telefone, e-mail. \n- Informações Financeiras: Histórico de transações, informações de contas bancárias associadas (de forma segura e tokenizada). \n- Informações Técnicas: Endereço IP, tipo de dispositivo, sistema operativo e identificadores únicos do dispositivo.',
          ),
          _Section(
            title: '3. Como Usamos as Suas Informações',
            content:
                'As suas informações são utilizadas para: \n\n- Fornecer, operar e manter os nossos serviços. \n- Processar as suas transações e prevenir fraudes. \n- Melhorar, personalizar e expandir os nossos serviços. \n- Comunicar consigo, incluindo para fins de marketing e promoção, sujeito ao seu consentimento. \n- Cumprir com as obrigações legais e regulamentares em Angola.',
          ),
          _Section(
            title: '4. Partilha de Informações',
            content:
                'Não partilhamos as suas informações pessoais com terceiros, exceto nas seguintes circunstâncias: \n\n- Com o seu consentimento explícito. \n- Com fornecedores de serviços que trabalham em nosso nome e que concordaram com obrigações de confidencialidade. \n- Para cumprir com uma obrigação legal ou ordem judicial, conforme exigido pelas autoridades angolanas. \n- Para proteger os nossos direitos, a nossa propriedade ou a nossa segurança, ou a de outros.',
          ),
          _Section(
            title: '5. Segurança dos Dados',
            content:
                'Implementamos uma variedade de medidas de segurança para manter a segurança das suas informações pessoais. Utilizamos encriptação, firewalls e tecnologias de secure socket layer (SSL) para proteger os seus dados durante a transmissão. O acesso aos seus dados é restrito a funcionários autorizados que necessitam da informação para desempenhar as suas funções.',
          ),
          _Section(
            title: '6. Os Seus Direitos de Proteção de Dados',
            content:
                'De acordo com a Lei de Proteção de Dados de Angola, você tem o direito de aceder, retificar ou apagar as suas informações pessoais. Tem também o direito de se opor ou restringir o processamento dos seus dados. Para exercer estes direitos, por favor, contacte-nos através do nosso suporte ao cliente.',
          ),
          _Section(
            title: '7. Retenção de Dados',
            content:
                'Reteremos as suas informações pessoais apenas pelo tempo necessário para os fins estabelecidos nesta Política de Privacidade e para cumprir as nossas obrigações legais. Após este período, os seus dados serão eliminados de forma segura.',
          ),
           _Section(
            title: '8. Contacto',
            content:
                'Se tiver alguma dúvida sobre esta Política de Privacidade, por favor, contacte-nos através do email: suporte@aferconpay.co.ao.',
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            textAlign: TextAlign.justify,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}
