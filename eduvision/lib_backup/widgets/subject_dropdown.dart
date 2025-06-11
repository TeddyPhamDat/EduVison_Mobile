import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class SubjectDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final List<String> items;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final bool isRequired;

  const SubjectDropdown({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.items,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.isRequired = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(
                prefixIcon,
                size: 16,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                labelText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
            color: Colors.grey.shade50,
          ),
          child: ButtonTheme(
            alignedDropdown: true,
            child: DropdownButtonFormField<String>(
              value: value,
              icon: const Icon(Icons.arrow_drop_down),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
              style: TextStyle(
                color: Colors.grey.shade900,
                fontSize: 16,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
              validator: (value) {
                if (isRequired && (value == null || value.isEmpty)) {
                  return 'Vui lòng chọn $labelText';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }
}

class AnimatedSubjectDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final List<String> items;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final bool isRequired;
  final Duration delay;

  const AnimatedSubjectDropdown({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.items,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.isRequired = true,
    this.delay = Duration.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: snapshot.connectionState == ConnectionState.done ? 1.0 : 0.0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 500),
            offset: snapshot.connectionState == ConnectionState.done
                ? Offset.zero
                : const Offset(0, 0.05),
            child: SubjectDropdown(
              value: value,
              onChanged: onChanged,
              items: items,
              labelText: labelText,
              hintText: hintText,
              prefixIcon: prefixIcon,
              isRequired: isRequired,
            ),
          ),
        );
      },
    );
  }
}
