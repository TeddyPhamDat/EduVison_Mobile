import 'package:flutter/cupertino.dart';

class CustomFooter extends StatelessWidget {
  final String text;
  final List<Widget>? actions;

  const CustomFooter({
    Key? key,
    required this.text,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: CupertinoColors.systemGrey6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
