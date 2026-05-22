import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // App icon card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withOpacity(0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield_outlined, color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 20),
                    Text('Detectome',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                    const SizedBox(height: 4),
                    Text('Network Intelligence Platform',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withOpacity(0.55),
                            )),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Version 1.0.0',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info tiles
            Card(
              child: Column(
                children: [
                  _infoTile(
                    context,
                    icon: Icons.person_outline_rounded,
                    label: 'Developer',
                    value: 'Umar Farooq',
                  ),
                  Divider(height: 1, indent: 56, color: scheme.outline.withOpacity(0.3)),
                  _infoTile(
                    context,
                    icon: Icons.code_rounded,
                    label: 'Framework',
                    value: 'Flutter 3.x',
                  ),
                  Divider(height: 1, indent: 56, color: scheme.outline.withOpacity(0.3)),
                  _infoTile(
                    context,
                    icon: Icons.storage_rounded,
                    label: 'Backend',
                    value: 'Neo4j + GraphQL',
                  ),
                  Divider(height: 1, indent: 56, color: scheme.outline.withOpacity(0.3)),
                  _infoTile(
                    context,
                    icon: Icons.cloud_rounded,
                    label: 'Auth',
                    value: 'Firebase Authentication',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, size: 20, color: scheme.primary),
      title: Text(label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.5),
              )),
      subtitle: Text(value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
