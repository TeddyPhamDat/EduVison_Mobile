import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EduVisionHeader extends StatelessWidget implements ObstructingPreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool useGradient;
  final bool isTransparent;
  final Widget? subtitle;
  final Widget? leading;

  const EduVisionHeader({
    Key? key,
    required this.title,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    this.useGradient = true,
    this.isTransparent = false,
    this.subtitle,
    this.leading,
  }) : super(key: key);
  
  @override
  bool shouldFullyObstruct(BuildContext context) {
    // Return true if the header is not transparent
    return !isTransparent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: !isTransparent 
          ? BoxDecoration(
              gradient: useGradient
                  ? const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: useGradient ? null : const Color(0xFF6C5CE7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Leading/Back button
            if (showBackButton)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.back,
                    color: CupertinoColors.white,
                    size: 22,
                  ),
                ),
              )
            else if (leading != null)
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: leading!,
              )
            else
              const SizedBox(width: 16),

            // Title and subtitle
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    subtitle!,
                ],
              ),
            ),

            // Actions
            if (actions != null && actions!.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!.map((action) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: action,
                  );
                }).toList(),
              )
            else
              const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4.0);
}

// Rounded Action Button for Header
class HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  const HeaderActionButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          color: iconColor ?? CupertinoColors.white,
          size: 20,
        ),
      ),
    );
  }
}

// Header với title lớn
class EduVisionLargeHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool useGradient;

  const EduVisionLargeHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    this.useGradient = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        gradient: useGradient
            ? const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: useGradient ? null : const Color(0xFF6C5CE7),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with back button and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button if needed
                if (showBackButton)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        CupertinoIcons.back,
                        color: CupertinoColors.white,
                        size: 22,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 40, height: 40),

                // Actions
                if (actions != null && actions!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  )
                else
                  const SizedBox(width: 40, height: 40),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.white,
              ),
            ),
            
            // Subtitle if provided
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.white.withOpacity(0.85),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
