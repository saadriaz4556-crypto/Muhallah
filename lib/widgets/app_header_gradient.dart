import 'package:flutter/material.dart';

class GradientHeaderAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final double toolbarHeight;

  const GradientHeaderAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.bottom,
    this.actions,
    this.onBackPressed,
    this.centerTitle = false,
    this.toolbarHeight = 90,
  });

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(toolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      toolbarHeight: toolbarHeight,
      leadingWidth: 56,
      leading: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onBackPressed ??
            () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A303C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: Color(0xFFEAEAEA)),
        ),
      ),
      title: titleWidget ??
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
      actions: actions,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF252A34),
              const Color(0xFF08D9D6).withValues(alpha: 0.2),
            ],
          ),
        ),
      ),
      bottom: bottom,
    );
  }
}
