import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      // iOS-style header (using Cupertino)
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
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                child: const Icon(CupertinoIcons.back),
              )
            : null,
        trailing: actions != null
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
    } else {
      // Material (Android) style header
      return AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              )
            : null,
        actions: actions,
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      );
    }
  }
  
  @override
  Size get preferredSize {
    final bool isIOS = true; // Default to iOS size if we can't determine
    return Size.fromHeight(isIOS ? 44.0 : 56.0);
  }
}
