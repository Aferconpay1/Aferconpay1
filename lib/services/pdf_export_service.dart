import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/transaction_model.dart';
import '../models/loan_model.dart';
import 'firestore_service.dart';

class PdfExportService {
  final FirestoreService _firestoreService;
  
  PdfExportService({required FirestoreService firestoreService}) : _firestoreService = firestoreService;

  Future<void> generateAndShareStatement() async {
    final querySnapshot = await _firestoreService.transactionsStream.first;
    final transactions = querySnapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildStatementHeader(),
            pw.SizedBox(height: 20),
            _buildTable(context, transactions),
            pw.Flexible(child: pw.Container()), // Empurra o footer para o fim
            _buildFooter(),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'extrato_afercon_pay.pdf');
  }

  Future<void> generateAndShowContract(BuildContext context, LoanType loanType) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    try {
      final pdf = pw.Document();

      final String fileName;
      switch (loanType) {
        case LoanType.personal:
          fileName = 'credito_pessoal.txt';
          break;
        case LoanType.automovel:
          fileName = 'credito_automovel.txt';
          break;
        case LoanType.habitacao:
          fileName = 'credito_habitacao.txt';
          break;
        case LoanType.formacao:
          fileName = 'credito_formacao.txt';
          break;
        case LoanType.negocios:
          fileName = 'credito_negocios.txt';
          break;
      }

      final String filePath = 'assets/contracts/$fileName';
      final String title = 'Termos e Condições - Crédito ${loanType.typeDisplay}';

      final String contractText = await rootBundle.loadString(filePath);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.Text('Afercon Pay', style: const pw.TextStyle(color: PdfColors.grey, fontSize: 12)),
                  ],
                )
              ),
              pw.SizedBox(height: 20),
              ..._buildRichText(contractText),
              pw.SizedBox(height: 40),
              _buildFooter(),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar o contrato: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  List<pw.Widget> _buildRichText(String text) {
    final List<pw.Widget> widgets = [];
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(pw.SizedBox(height: 12));
        continue;
      }

      final List<pw.InlineSpan> spans = [];
      final parts = line.split('**');

      for (int i = 0; i < parts.length; i++) {
        if (i % 2 == 0) {
          spans.add(pw.TextSpan(text: parts[i]));
        } else {
          spans.add(pw.TextSpan(
            text: parts[i],
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ));
        }
      }
      widgets.add(pw.RichText(
        text: pw.TextSpan(children: spans, style: const pw.TextStyle(lineSpacing: 4)),
        textAlign: pw.TextAlign.justify
      ));
    }
    return widgets;
  }

  Future<void> viewPdf(List<Transaction> transactions) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildStatementHeader(),
            pw.SizedBox(height: 20),
            _buildTable(context, transactions),
            pw.SizedBox(height: 40),
            _buildFooter(),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> generateAndShareSingleReceipt(Transaction transaction, String currentUserName) async {
    final pdf = pw.Document();

    String relatedUserName = 'Destinatário desconhecido';
    if (transaction.relatedUserId != null) {
      try {
        DocumentSnapshot userDoc = await _firestoreService.getUser(transaction.relatedUserId!);
        if(userDoc.exists) {
          relatedUserName = (userDoc.data() as Map<String, dynamic>)['displayName'] ?? 'Nome não encontrado';
        }
      } catch (e) {
        // Ignora o erro, o nome padrão será usado
      }
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildReceiptHeader(),
              pw.SizedBox(height: 20),
              pw.Text('Comprovativo de Transação', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 2), pw.SizedBox(height: 20),
              _buildReceiptInfo(transaction, currentUserName, relatedUserName),
              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'comprovativo_${transaction.id}.pdf');
  }

  pw.Widget _buildStatementHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Afercon Pay - Extrato de Transações', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24)),
        pw.SizedBox(height: 10),
        pw.Text('Data de Emissão: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildTable(pw.Context context, List<Transaction> transactions) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yy HH:mm');
    final headers = ['Data', 'Descrição', 'Valor', 'Tipo'];
    
    final data = transactions.map((tx) {
      final value = tx.type == TransactionType.debit ? -tx.amount : tx.amount;
      final color = tx.type == TransactionType.debit ? PdfColors.red700 : PdfColors.green700;
      return [
        dateFormat.format(tx.timestamp),
        tx.description,
        pw.Text(currencyFormat.format(value), style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold)),
        tx.type.toDisplayString(),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: { 0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft, 2: pw.Alignment.centerRight, 3: pw.Alignment.center },
      border: pw.TableBorder.all(),
    );
  }

  pw.Widget _buildReceiptHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.SizedBox(width: 60),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [ 
          pw.Text('Afercon Pay', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
          pw.Text('O seu parceiro de pagamentos digitais'),
        ])
      ]
    );
  }

  pw.Widget _buildReceiptInfo(Transaction transaction, String currentUserName, String relatedUserName) {
    final dateFormat = DateFormat("dd/MM/yyyy 'às' HH:mm");
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);
    String from = transaction.type == TransactionType.credit ? relatedUserName : currentUserName;
    String to = transaction.type == TransactionType.credit ? currentUserName : relatedUserName;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Descrição:', transaction.description),
        _buildInfoRow('Tipo de Operação:', transaction.type.toDisplayString()),
        _buildInfoRow('Montante:', currencyFormat.format(transaction.amount), highlight: true, color: transaction.type == TransactionType.credit ? PdfColors.green700 : PdfColors.red700),
        pw.Divider(height: 10, thickness: 1),
        _buildInfoRow('De:', from),
        _buildInfoRow('Para:', to),
        pw.Divider(height: 10, thickness: 1),
        _buildInfoRow('Data e Hora:', dateFormat.format(transaction.timestamp)),
        _buildInfoRow('ID da Transação:', transaction.id!),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value, {bool highlight = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: highlight ? pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color) : const pw.TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 5),
        pw.Text('Este é um documento gerado automaticamente pela Afercon Pay.', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9)),
      ],
    );
  }
}