import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Neo4jSettingsScreen extends StatefulWidget {
  const Neo4jSettingsScreen({super.key});
  @override
  State<Neo4jSettingsScreen> createState() => _Neo4jSettingsScreenState();
}

class _Neo4jSettingsScreenState extends State<Neo4jSettingsScreen> {
  final _hostCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  String? _connectionStatus; // null = untested
  bool    _isSuccess  = false;
  bool    _isLoading  = false;
  bool    _obscure    = true;

  @override
  void dispose() {
    _hostCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _connectionStatus = null; });
    try {
      final response = await http.post(
        Uri.parse('https://test-connectivity-5ul4qv5gj-faaezs-projects-373a7c11.vercel.app/api/test-neo4j'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'host': _hostCtrl.text,
          'username': _usernameCtrl.text,
          'password': _passwordCtrl.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          _isSuccess = response.statusCode == 200 && data['success'] == true;
          _connectionStatus = data['message'] ?? (_isSuccess ? 'Connected' : 'Connection failed');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSuccess = false;
          _connectionStatus = 'Error: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Neo4j Connection'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Database Connection',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Configure your Neo4j database credentials.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withOpacity(0.55),
                      )),
              const SizedBox(height: 28),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Connection Details',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),

                      // Host
                      TextFormField(
                        controller: _hostCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Host / URL',
                          hintText: 'bolt://localhost:7687',
                          prefixIcon: Icon(Icons.storage_rounded),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter the host URL' : null,
                      ),
                      const SizedBox(height: 16),

                      // Username
                      TextFormField(
                        controller: _usernameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'neo4j',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter your username' : null,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Connection status feedback
              if (_connectionStatus != null)
                Card(
                  color: _isSuccess
                      ? const Color(0xFF10B981).withOpacity(0.08)
                      : const Color(0xFFEF4444).withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                          color: _isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _connectionStatus!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _isSuccess
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_connectionStatus != null) const SizedBox(height: 16),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          height: 52,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                        ),
                      )
                    : ElevatedButton.icon(
                        key: const ValueKey('btn'),
                        onPressed: _testConnection,
                        icon: const Icon(Icons.network_check_rounded),
                        label: const Text('Test Connection'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
