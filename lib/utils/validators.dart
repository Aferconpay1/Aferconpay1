class Validators {
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira um montante.';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Por favor, insira um montante válido.';
    }
    return null;
  }

  static String? validateIban(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira o número de conta (21 dígitos).';
    }
    
    final sanitizedValue = value.replaceAll('.AO06', '');

    if (!RegExp(r'^\d{21}$').hasMatch(sanitizedValue)) {
      return 'O IBAN deve conter exatamente 21 dígitos numéricos.';
    }
    
    return null;
  }

  static String? validateGeneric(String? value, {String fieldName = 'campo'}) {
    if (value == null || value.isEmpty) {
      return 'Por favor, preencha este $fieldName.';
    }
    return null;
  }

   static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira o seu email.';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Por favor, insira um email válido.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira a sua senha.';
    }
    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    return null;
  }
}
