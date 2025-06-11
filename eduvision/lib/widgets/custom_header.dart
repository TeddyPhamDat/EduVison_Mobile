import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const CustomHeader({
    Key? key, 
    required this.title,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoNavigationBar(
      middle: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: showBackButton
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.back),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      trailing: actions != null && actions!.isNotEmpty
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            )
          : null,
      backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
      border: const Border(
        bottom: BorderSide(
          color: CupertinoColors.systemGrey4,
          width: 0.5,
        ),
      ),
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(44.0);
}

