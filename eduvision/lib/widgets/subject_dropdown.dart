import 'package:flutter/cupertino.dart';

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
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 8),
              Text(
                labelText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.black,
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: CupertinoColors.systemRed,
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
              color: CupertinoColors.systemGrey4,
              width: 1.5,
            ),
            color: CupertinoColors.systemGrey6,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
            onPressed: () async {
              final selected = await showCupertinoModalPopup<String>(
                context: context,
                builder: (context) {
                  return CupertinoActionSheet(
                    title: Text(labelText),
                    message: Text(hintText),
                    actions: items.map((item) {
                      return CupertinoActionSheetAction(
                        onPressed: () {
                          Navigator.of(context).pop(item);
                        },
                        child: Text(item),
                      );
                    }).toList(),
                    cancelButton: CupertinoActionSheetAction(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                  );
                },
              );
              if (selected != null) {
                onChanged(selected);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value ?? hintText,
                  style: TextStyle(
                    color: value == null
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.black,
                    fontSize: 16,
                  ),
                ),
                const Icon(CupertinoIcons.chevron_down, size: 20),
              ],
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

