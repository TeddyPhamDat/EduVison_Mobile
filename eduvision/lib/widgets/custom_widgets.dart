import 'package:flutter/cupertino.dart';
import '../utils/eduvision_theme.dart';

/// Custom primary button with gradient background
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: onPressed == null
          ? BoxDecoration(
              color: CupertinoColors.systemGrey4,
              borderRadius: BorderRadius.circular(12),
            )
          : EduVisionTheme.primaryButtonDecoration,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : Text(
                text,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Custom secondary button with outline style
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double height;

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.width,
    this.height = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: EduVisionTheme.secondaryButtonDecoration,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            color: EduVisionTheme.primaryBlue,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Custom text input field with modern styling
class CustomTextField extends StatefulWidget {
  final String placeholder;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefix;
  final Widget? suffix;
  final String? errorText;
  final Function(String)? onChanged;

  const CustomTextField({
    Key? key,
    required this.placeholder,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefix,
    this.suffix,
    this.errorText,
    this.onChanged,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: _isFocused
              ? EduVisionTheme.focusedInputDecoration
              : EduVisionTheme.inputDecoration,
          child: CupertinoTextField(
            controller: widget.controller,
            placeholder: widget.placeholder,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            decoration: const BoxDecoration(),
            style: EduVisionTheme.body,
            placeholderStyle: const TextStyle(
              color: EduVisionTheme.textSecondary,
              fontSize: 17,
            ),
            prefix: widget.prefix != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: widget.prefix,
                  )
                : null,
            suffix: widget.suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: widget.suffix,
                  )
                : null,
            padding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: widget.prefix != null ? 8 : 16,
            ),
            onTap: () => setState(() => _isFocused = true),
            onEditingComplete: () => setState(() => _isFocused = false),
            onSubmitted: (_) => setState(() => _isFocused = false),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: EduVisionTheme.systemRed,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom card container
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const CustomCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: EduVisionTheme.cardDecoration,
      child: child,
    );
  }
}

/// Custom app logo
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({
    Key? key,
    this.size = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: EduVisionTheme.primaryGradient,
        borderRadius: BorderRadius.circular(size / 4),
        boxShadow: [
          BoxShadow(
            color: EduVisionTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        CupertinoIcons.book_fill,
        size: size * 0.5,
        color: CupertinoColors.white,
      ),
    );
  }
}

/// Header text widget
class HeaderText extends StatelessWidget {
  final String title;
  final String? subtitle;

  const HeaderText({
    Key? key,
    required this.title,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: EduVisionTheme.title1,
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: EduVisionTheme.body.copyWith(
              color: EduVisionTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
