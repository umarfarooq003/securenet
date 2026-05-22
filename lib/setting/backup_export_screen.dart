import 'package:flutter/material.dart';
import '../CSV file/csv.dart';

class BackupExportScreen extends StatelessWidget {
  const BackupExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Export'), leading: const BackButton()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Data Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Manage your network data backups and exports.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(0.55),
                  )),
          const SizedBox(height: 24),

          Card(
            child: Column(
              children: [
                _actionTile(
                  context,
                  icon: Icons.file_download_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Export Data',
                  subtitle: 'Download network data as CSV',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ExportCSVScreen()),
                  ),
                ),
                Divider(height: 1, indent: 56, color: scheme.outline.withOpacity(0.3)),
                _actionTile(
                  context,
                  icon: Icons.file_upload_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Import Configuration',
                  subtitle: 'Restore settings from a backup file',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Import feature coming soon.')),
                    );
                  },
                ),
                Divider(height: 1, indent: 56, color: scheme.outline.withOpacity(0.3)),
                _actionTile(
                  context,
                  icon: Icons.delete_outline_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Clear App Data',
                  subtitle: 'Reset all cached and local data',
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear App Data'),
                        content: const Text(
                            'This will remove all locally cached data. This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Clear Data'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('App data cleared.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right_rounded,
          color: scheme.onSurface.withOpacity(0.35), size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
