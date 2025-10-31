
import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos e Condições'),
        centerTitle: true,
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text(
            'Termos e Condições de Uso - Afercon Pay',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Última atualização: 24 de Julho de 2024',
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 24),
          _Section(
            title: '1. Aceitação dos Termos',
            content:
                'Ao criar uma conta e utilizar a aplicação Afercon Pay ("Serviço"), você concorda em cumprir e estar sujeito a estes Termos e Condições ("Termos"). Se não concordar com estes Termos, não deverá aceder ou utilizar o Serviço. Estes termos aplicam-se a todos os utilizadores e visitantes em conformidade com a legislação da República de Angola.',
          ),
          _Section(
            title: '2. Descrição do Serviço',
            content:
                'A Afercon Pay é uma aplicação de serviços financeiros que permite aos seus utilizadores realizar transferências, pagamentos, depósitos e gestão de crédito pessoal. O serviço visa facilitar as transações financeiras diárias de forma segura e eficiente.',
          ),
          _Section(
            title: '3. Elegibilidade e Registo de Conta',
            content:
                'Para utilizar o Serviço, deve ter pelo menos 18 anos de idade e residir em Angola. Você concorda em fornecer informações precisas, atuais e completas durante o processo de registo e em atualizar tais informações para mantê-las precisas.',
          ),
          _Section(
            title: '4. Segurança da Conta',
            content:
                'Você é responsável por manter a confidencialidade da sua senha e conta. Concorda em notificar-nos imediatamente sobre qualquer uso não autorizado da sua conta. A Afercon Pay não será responsável por qualquer perda que possa incorrer como resultado de alguém usar a sua senha ou conta, com ou sem o seu conhecimento.',
          ),
          _Section(
            title: '5. Conduta do Utilizador',
            content:
                'Você concorda em não utilizar o Serviço para qualquer finalidade ilegal ou proibida por estes Termos. É estritamente proibido usar o Serviço para atividades fraudulentas, lavagem de dinheiro ou financiamento de terrorismo, em conformidade com as leis angolanas.',
          ),
          _Section(
            title: '6. Limitação de Responsabilidade',
            content:
                'A Afercon Pay não garante que o serviço será ininterrupto ou livre de erros. Em nenhuma circunstância a Afercon Pay será responsável por quaisquer danos diretos, indiretos, incidentais, especiais ou consequenciais resultantes do uso ou da incapacidade de usar o serviço.',
          ),
          _Section(
            title: '7. Alterações aos Termos',
            content:
                'Reservamo-nos o direito de modificar ou substituir estes Termos a qualquer momento. Se uma revisão for material, faremos o possível para fornecer um aviso com pelo menos 30 dias de antecedência antes de quaisquer novos termos entrarem em vigor. O que constitui uma alteração material será determinado a nosso exclusivo critério.',
          ),
          _Section(
            title: '8. Lei Aplicável e Jurisdição',
            content:
                'Estes Termos serão regidos e interpretados de acordo com as leis da República de Angola, sem levar em conta o conflito de disposições legais. Qualquer disputa que surja destes Termos será resolvida nos tribunais competentes de Luanda.',
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
