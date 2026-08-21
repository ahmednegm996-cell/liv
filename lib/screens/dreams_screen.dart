import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../models.dart';

class DreamsScreen extends StatelessWidget {
  const DreamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = L10n.of(state.profile.locale);
    final accent = AppColors.accentFrom(state.profile.accentColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.dreams),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final title = t.add_dream;
              await state.addDream(Dream(title: title));
            },
          ),
        ],
      ),
      body: state.dreams.isEmpty
          ? Center(child: Text(t.no_dreams))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.dreams.length,
              itemBuilder: (context, i) {
                final d = state.dreams[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(d.title),
                          subtitle: d.description != null && d.description!.isNotEmpty
                              ? Text(d.description!)
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => state.removeDream(d.id),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: (d.progress.clamp(0, 100)) / 100,
                                color: accent,
                                backgroundColor: accent.withOpacity(0.15),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('${d.progress}%', style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
