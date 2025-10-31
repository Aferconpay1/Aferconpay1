import 'package:flutter/services.dart';

class IbanInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'[\.\s]'), '').toUpperCase();

    if (text.isEmpty) {
      return newValue;
    }

    var buffer = StringBuffer();
    
    // Force AO06 prefix
    if (text.length >= 4) {
      buffer.write(text.substring(0, 4));
    } else {
      buffer.write(text);
    }
    
    if (text.length > 4) {
      buffer.write('.');
      if(text.length > 8) {
        buffer.write(text.substring(4, 8));
        buffer.write('.');
        if(text.length > 12) {
          buffer.write(text.substring(8, 12));
          buffer.write('.');
           if(text.length > 16) {
            buffer.write(text.substring(12, 16));
            buffer.write('.');
            if(text.length > 20) {
              buffer.write(text.substring(16, 20));
              buffer.write('.');
              buffer.write(text.substring(20, text.length > 25 ? 25 : text.length));
            } else {
              buffer.write(text.substring(16));
            }
          } else {
            buffer.write(text.substring(12));
          }
        } else {
          buffer.write(text.substring(8));
        }
      } else {
        buffer.write(text.substring(4));
      }
    }

    String newText = buffer.toString();

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
