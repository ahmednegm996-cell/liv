import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const GlassCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

class Gaps {
  static const h4 = SizedBox(height: 4);
  static const h6 = SizedBox(height: 6);
  static const h8 = SizedBox(height: 8);
  static const h12 = SizedBox(height: 12);
  static const h14 = SizedBox(height: 14);
  static const h16 = SizedBox(height: 16);
  static const h20 = SizedBox(height: 20);
  static const h24 = SizedBox(height: 24);
  static const w8 = SizedBox(width: 8);
  static const w12 = SizedBox(width: 12);
  static const w16 = SizedBox(width: 16);
}

/// Phase 8H+ thin UI wrapper over GlassCard
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final String? title;
  const SectionCard({super.key, required this.child, this.padding, this.title});

  @override
  Widget build(BuildContext context) {
    if (title == null) {
      return GlassCard(padding: padding, child: child);
    }
    return GlassCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Phase 8H+ simple text input dialog helper
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String initial = '',
  String hint = '',
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('OK')),
      ],
    ),
  );
  controller.dispose();
  return (result == null || result.isEmpty) ? null : result;
}

/// Phase 8H+ architecture-neutral secondary text color (used by AiChatScreen)
Color secondaryText(BuildContext context) {
  return Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
}

/// Phase 8H+ thin visual adapter for protected home_screen HeartsRow caller.
/// Accepts the existing named parameter `hearts` (int from UserProfile.hearts).
class HeartsRow extends StatelessWidget {
  final int hearts;
  const HeartsRow({super.key, required this.hearts});

  @override
  Widget build(BuildContext context) {
    final count = hearts.clamp(0, 10);
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < count;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(
            filled ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: filled ? accent : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        );
      }),
    );
  }
}
