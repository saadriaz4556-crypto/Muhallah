import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<bool>? onValidationChanged;
  final bool enabled;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? accentColor;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.label,
    this.hintText = '03XX-XXXXXXX',
    this.validator,
    this.onChanged,
    this.onValidationChanged,
    this.enabled = true,
    this.backgroundColor,
    this.textColor,
    this.accentColor,
  });

  /// Helper to convert user typed input ("03001234567" or "3001234567")
  /// into standard Firestore E.164 format: "+923001234567"
  static String formatToE164(String input) {
    final clean = input.trim().replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return '';
    if (clean.startsWith('92') && clean.length == 12) {
      return '+$clean';
    }
    if (clean.startsWith('0') && clean.length == 11) {
      return '+92${clean.substring(1)}';
    }
    if (clean.length == 10) {
      return '+92$clean';
    }
    return clean.startsWith('0') ? '+92${clean.substring(1)}' : '+92$clean';
  }

  /// Helper to check if given raw input string is a valid 11-digit Pakistani phone number
  static bool isValidPhoneNumber(String input) {
    final clean = input.trim().replaceAll(RegExp(r'\D'), '');
    if (clean.length == 11 && clean.startsWith('0')) {
      return true;
    }
    if (clean.length == 10 && !clean.startsWith('0')) {
      return true;
    }
    if (clean.length == 12 && clean.startsWith('92')) {
      return true;
    }
    return false;
  }

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  bool _hasTouched = false;
  String _errorText = '';

  bool get isValid => PhoneInputField.isValidPhoneNumber(widget.controller.text);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    final valid = isValid;
    if (_hasTouched) {
      setState(() {
        _validateInternal();
      });
    }
    if (widget.onValidationChanged != null) {
      widget.onValidationChanged!(valid);
    }
    if (widget.onChanged != null) {
      widget.onChanged!(widget.controller.text);
    }
  }

  void _validateInternal() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      _errorText = 'Phone number is required';
    } else if (!isValid) {
      _errorText = 'Enter valid 11-digit phone number (e.g. 03001234567)';
    } else {
      _errorText = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? const Color(0xFF2A303C);
    final txtColor = widget.textColor ?? Colors.white;
    final primaryAccent = widget.accentColor ?? const Color(0xFF08D9D6);
    final hasError = _errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        FormField<String>(
          initialValue: widget.controller.text,
          validator: (value) {
            final val = widget.controller.text;
            if (widget.validator != null) {
              final customErr = widget.validator!(val);
              if (customErr != null) {
                setState(() {
                  _hasTouched = true;
                  _errorText = customErr;
                });
                return customErr;
              }
            }
            if (val.trim().isEmpty) {
              const err = 'Phone number is required';
              setState(() {
                _hasTouched = true;
                _errorText = err;
              });
              return err;
            }
            if (!isValid) {
              const err = 'Enter valid 11-digit phone number';
              setState(() {
                _hasTouched = true;
                _errorText = err;
              });
              return err;
            }
            setState(() {
              _errorText = '';
            });
            return null;
          },
          builder: (field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasError
                          ? Colors.redAccent
                          : Colors.white10,
                      width: hasError ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Fixed +92 Prefix Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: primaryAccent.withValues(alpha: 0.15),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(9),
                            bottomLeft: Radius.circular(9),
                          ),
                          border: Border(
                            right: BorderSide(
                              color: primaryAccent.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: primaryAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '+92',
                              style: TextStyle(
                                color: primaryAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Editable Digits Portion
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          enabled: widget.enabled,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: txtColor, fontSize: 15),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          onChanged: (val) {
                            _hasTouched = true;
                            field.didChange(val);
                          },
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: const TextStyle(
                                color: Colors.white30, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _errorText,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
