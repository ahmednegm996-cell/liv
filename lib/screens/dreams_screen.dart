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
              await state.addDream(Dream(title: state.profile.locale == 'en' ? 'New dream' : 'حلم جديد'));
            },
          ),
        ],
      ),
      body: state.dreams.isEmpty
          ? Center(child: Text(state.profile.locale == 'en' ? 'No dreams yet. Add one!' : 'لا أحلام بعد. أضف واحدًا!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.dreams.length,
              itemBuilder: (context, i) {
                final d = state.dreams[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(d.title),
                      subtitle: LinearProgressIndicator(value: d.progress / 100, color: accent, backgroundColor: accent.withOpacity(0.15)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => state.removeDream(d.id),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
