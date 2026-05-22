import 'package:flutter/material.dart';

class DiscoverySettingsScreen extends StatefulWidget {
  const DiscoverySettingsScreen({super.key});
  @override
  State<DiscoverySettingsScreen> createState() => _DiscoverySettingsScreenState();
}

class _DiscoverySettingsScreenState extends State<DiscoverySettingsScreen> {
  final _ipRangeCtrl = TextEditingController();
  final _snmpCtrl    = TextEditingController();
  bool _isScanning   = false;

  @override
  void dispose() {
    _ipRangeCtrl.dispose();
    _snmpCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanNetwork() async {
    if (_ipRangeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an IP range to scan.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    setState(() => _isScanning = true);
    // Simulate scan
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network scan completed.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Network Discovery'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Discovery Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Configure network scanning parameters.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(0.55),
                    )),
            const SizedBox(height: 28),

            // Config card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan Configuration',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),

                    // IP Range
                    TextFormField(
                      controller: _ipRangeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'IP Range',
                        hintText: 'e.g. 192.168.1.0/24',
                        prefixIcon: Icon(Icons.lan_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SNMP Community
                    TextFormField(
                      controller: _snmpCtrl,
                      decoration: const InputDecoration(
                        labelText: 'SNMP Community String',
                        hintText: 'e.g. public',
                        prefixIcon: Icon(Icons.key_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: scheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Network scanning may take a few minutes depending on the subnet size.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withOpacity(0.65),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Scan button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _isScanning
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        const SizedBox(width: 12),
                        Text('Scanning network…',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface.withOpacity(0.6),
                                )),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: _scanNetwork,
                      icon: const Icon(Icons.radar_rounded),
                      label: const Text('Scan Network'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
