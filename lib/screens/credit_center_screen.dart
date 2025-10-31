import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/firestore_service.dart';
import '../services/pdf_export_service.dart';
import '../models/loan_model.dart';
import '../models/credit_request_model.dart'; // Import the new model
import '../widgets/gradient_app_bar.dart';
import '../widgets/primary_button.dart';

class CreditCenterScreen extends StatelessWidget {
  const CreditCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: GradientAppBar(
          title: const Text('Centro de Crédito'),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              const Tab(icon: Icon(Iconsax.add_square), text: 'Solicitar Crédito').animate().fadeIn(),
              const Tab(icon: Icon(Iconsax.document_text), text: 'Meu Histórico').animate().fadeIn(delay: 100.ms),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RequestLoanView(),
            _LoanHistoryView(), // This now uses the corrected history view
          ],
        ),
      ),
    );
  }
}

// --- VISTA DE SOLICITAÇÃO DE CRÉDITO ---
class _RequestLoanView extends StatefulWidget {
  const _RequestLoanView();

  @override
  State<_RequestLoanView> createState() => _RequestLoanViewState();
}

class _RequestLoanViewState extends State<_RequestLoanView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  LoanType _selectedLoanType = LoanType.personal; // Kept for UI selection
  double _currentAmount = 100000; // Loan amount
  double _currentTerm = 2; // Term in months
  bool _isLoading = false;

  // Simulation variables
  double _monthlyPayment = 0;
  double _totalInterest = 0;
  double _totalRepayment = 0;
  static const double _interestRate = 0.07; // 7% monthly interest rate

  @override
  void initState() {
    super.initState();
    _amountController.text = NumberFormat('#,##0', 'pt_PT').format(_currentAmount);
    _calculateLoanDetails();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculateLoanDetails() {
    final term = _currentTerm.round();
    if (term == 0) return;
    final simpleInterest = _currentAmount * _interestRate * term;
    
    setState(() {
      _totalInterest = simpleInterest;
      _totalRepayment = _currentAmount + _totalInterest;
      _monthlyPayment = _totalRepayment / term;
    });
  }

  // CORRECTED: This function now calls the secure Cloud Function via the service
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final theme = Theme.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Solicitação'),
        content: RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium,
            children: const [
              TextSpan(text: 'Será cobrada uma taxa de adesão não reembolsável de '),
              TextSpan(
                text: '1.000,00 Kz',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ' do seu saldo para processar este pedido. Deseja continuar?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar e Pagar'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
        setState(() => _isLoading = true);
        try {
          // CORRECTED: Using the new secure method
          await firestoreService.submitCreditRequest(
              creditAmount: _currentAmount,
              // Creating a descriptive reason from the form data
              reason: '${_selectedLoanType.typeDisplay} em ${_currentTerm.round()} meses'
          );
          
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Pedido enviado! A taxa de 1.000 Kz foi deduzida do seu saldo.'),
                backgroundColor: Colors.green,
              ),
            );
            // Reset the form
            setState(() {
                _currentAmount = 100000;
                _currentTerm = 2;
                _amountController.text = NumberFormat('#,##0', 'pt_PT').format(_currentAmount);
                _calculateLoanDetails();
            });
          }
        } catch (e) {
          if(mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceAll("Exception: ", "")),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AbsorbPointer(
      absorbing: _isLoading,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Que tipo de crédito procura?', style: theme.textTheme.titleLarge).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 16),
                  _buildLoanTypeSelector(),

                  const SizedBox(height: 32),
                  Text('Qual o montante que precisa?', style: theme.textTheme.titleLarge).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 20),
                  _buildAmountDisplay(theme),
                  const SizedBox(height: 12),
                  _buildAmountSlider(),
                  const SizedBox(height: 12),
                  _buildAmountTextField(),

                  const SizedBox(height: 32),
                  Text('Em quantos meses quer pagar?', style: theme.textTheme.titleLarge).animate().fadeIn(delay: 500.ms),
                   const SizedBox(height: 20),
                  _buildTermDisplay(theme),
                  const SizedBox(height: 12),
                  _buildTermSlider(),

                  const SizedBox(height: 32),
                  _LoanSummaryCard(
                    loanType: _selectedLoanType,
                    monthlyPayment: _monthlyPayment,
                    totalRepayment: _totalRepayment,
                    totalInterest: _totalInterest,
                    interestRate: _interestRate,
                  ).animate().fadeIn(delay: 700.ms),

                  const SizedBox(height: 40),
                   PrimaryButton(
                    text: 'Solicitar Crédito Agora',
                    onPressed: _submitRequest, 
                    icon: Iconsax.send_1,
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(128), // CORRECTED: Replaced withOpacity with withAlpha
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildLoanTypeSelector() {
    return Animate(
      effects: const [FadeEffect(delay: Duration(milliseconds: 200)), SlideEffect(begin: Offset(-0.1, 0))],
      child: SizedBox(
        height: 130,
        child: ListView( 
          scrollDirection: Axis.horizontal,
          children: LoanType.values.map((type) {
            final isSelected = _selectedLoanType == type;
            return LoanTypeCard(
              type: type,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedLoanType = type),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAmountDisplay(ThemeData theme) {
    return Center(
      child: Text(
        NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2).format(_currentAmount),
        style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
      ).animate().scale(delay: 350.ms).fadeIn(),
    );
  }

  Widget _buildAmountSlider() {
    return Animate(
      effects: const [FadeEffect(delay: Duration(milliseconds: 400)), SlideEffect(begin: Offset(0, 0.2))],
      child: Slider(
        value: _currentAmount,
        min: 10000,   
        max: 5000000, 
        divisions: 499,
        label: NumberFormat('#,##0', 'pt_PT').format(_currentAmount),
        onChanged: (value) {
          setState(() {
            _currentAmount = value;
            _amountController.text = NumberFormat('#,##0', 'pt_PT').format(value);
            _calculateLoanDetails();
          });
        },
      ),
    );
  }

   Widget _buildAmountTextField() {
    return Animate(
      effects: const [FadeEffect(delay: Duration(milliseconds: 450))],
      child: TextFormField(
        controller: _amountController,
        decoration: const InputDecoration(
          labelText: 'Ou insira o valor exato',
          prefixIcon: Icon(Iconsax.money_recive),
          suffixText: 'Kz',
        ),
        keyboardType: TextInputType.number,
         onChanged: (value) {
          final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');
          final doubleValue = double.tryParse(cleanedValue);
          if (doubleValue != null && doubleValue >= 10000 && doubleValue <= 5000000) {
            setState(() {
              _currentAmount = doubleValue;
              _calculateLoanDetails();
            });
          }
        },
        validator: (value) {
           final cleanedValue = value?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
           final doubleValue = double.tryParse(cleanedValue);
           if (doubleValue == null) return 'Valor inválido.';
           if (doubleValue < 10000) return 'O mínimo é Kz 10.000';
           if (doubleValue > 5000000) return 'O máximo é Kz 5.000.000';
           return null;
        },
      ),
    );
  }

    Widget _buildTermDisplay(ThemeData theme) {
    return Center(
      child: Text(
        '${_currentTerm.round()} meses',
        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
      ).animate().scale(delay: 550.ms).fadeIn(),
    );
  }

  Widget _buildTermSlider() {
    return Animate(
      effects: const [FadeEffect(delay: Duration(milliseconds: 600)), SlideEffect(begin: Offset(0, 0.2))],
      child: Slider(
        value: _currentTerm,
        min: 2,
        max: 10,
        divisions: 8,
        label: '${_currentTerm.round()} meses',
        onChanged: (value) {
          setState(() {
            _currentTerm = value;
             _calculateLoanDetails();
          });
        },
      ),
    );
  }
}

class _LoanSummaryCard extends StatefulWidget {
  final LoanType loanType;
  final double monthlyPayment;
  final double totalRepayment;
  final double totalInterest;
  final double interestRate;

  const _LoanSummaryCard({
    required this.loanType,
    required this.monthlyPayment,
    required this.totalRepayment,
    required this.totalInterest,
    required this.interestRate,
  });

  @override
  __LoanSummaryCardState createState() => __LoanSummaryCardState();
}

class __LoanSummaryCardState extends State<_LoanSummaryCard> {
  bool _isGeneratingPdf = false;

  Future<void> _showContract() async {
    setState(() => _isGeneratingPdf = true);
    final pdfService = Provider.of<PdfExportService>(context, listen: false);
    await pdfService.generateAndShowContract(context, widget.loanType);
    if (mounted) {
      setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);

    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer.withAlpha(80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo da Simulação', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _SummaryRow(label: 'Prestação Mensal', value: currencyFormat.format(widget.monthlyPayment), isHeader: true),
            const Divider(height: 24, thickness: 0.5),
            _SummaryRow(label: 'Total de Juros a Pagar', value: currencyFormat.format(widget.totalInterest)),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Montante Total a Pagar', value: currencyFormat.format(widget.totalRepayment)),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Taxa de Juro Aplicada', value: '${(widget.interestRate * 100).toStringAsFixed(0)}% ao mês'),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: _isGeneratingPdf
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator())
                  : TextButton.icon(
                      onPressed: _showContract,
                      icon: const Icon(Iconsax.document_download),
                      label: const Text('Ver Termos e Condições'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHeader;

  const _SummaryRow({required this.label, required this.value, this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = isHeader
        ? theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)
        : theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value, 
            style: valueStyle,
            textAlign: TextAlign.end,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}


class LoanTypeCard extends StatelessWidget {
  final LoanType type;
  final bool isSelected;
  final VoidCallback onTap;

  const LoanTypeCard({super.key, required this.type, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withAlpha(40) : theme.colorScheme.surfaceContainerHighest.withAlpha(100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: theme.colorScheme.primary.withAlpha(30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type.icon, size: 36, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(
                  type.typeDisplay,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- VISTA DO HISTÓRICO DE CRÉDITOS (CORRIGIDA) ---
class _LoanHistoryView extends StatelessWidget {
  const _LoanHistoryView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    // CORRECTED: Using getCreditRequestsStream to point to the secure collection
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getCreditRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar o histórico: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(theme);
        }

        // CORRECTED: Using the new CreditRequestModel
        final requests = snapshot.data!.docs.map((doc) => CreditRequestModel.fromFirestore(doc)).toList();

        return Animate(
          effects: const [FadeEffect()],
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              // Using a new, adapted card for the new data model
              return CreditHistoryCard(request: request).animate().fadeIn(delay: (100 * index).ms).slideX(begin: -0.1);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.document_text, size: 60, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'O seu histórico de créditos está vazio.',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
             const SizedBox(height: 8),
            const Text(
              'Quando solicitar um crédito, ele aparecerá aqui.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),  
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}


// --- CARD PARA O HISTÓRICO (CORRIGIDO) ---
class CreditHistoryCard extends StatelessWidget {
  final CreditRequestModel request;

  const CreditHistoryCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = request.status.color(theme);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withAlpha(80), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    request.reason, // Display the reason from the request
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.status.statusDisplay.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz').format(request.amount),
              style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Row(
                   children: [
                     Icon(Iconsax.calendar_1, color: theme.colorScheme.onSurfaceVariant, size: 20),
                     const SizedBox(width: 8),
                     Text(
                      'Pedido em ${DateFormat('dd MMM yyyy').format(request.createdAt.toDate())}',
                      style: theme.textTheme.bodySmall,
                    ),
                   ],
                 ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
