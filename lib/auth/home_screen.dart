import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Screens
import '../charts/charts.dart';
import '../forcedirectedgraph/directedgraph.dart';
import '../listscreen/listdeice.dart';
import '../listscreen/server_list_page.dart';
import '../listscreen/switch_list_page.dart';
import '../nextsuspectednode/nextsuspectednode.dart';
import '../settings_screen.dart';
import 'login_screen.dart';
import '../services/graphql_service.dart';
import '../widgets/shared_widgets.dart';
import '../theme/app_theme.dart';
import '../messa/screens/simulation_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root scaffold with drawer + bottom nav
// ─────────────────────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  final String username;
  final String email;

  const HomePage({super.key, required this.username, required this.email});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(username: widget.username),
      const NetworkHubScreen(),
      const SettingsScreen(),
    ];
    _loadProfileImage();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
      _saveProfileImage(picked.path);
    }
  }

  Future<void> _saveProfileImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final user  = FirebaseAuth.instance.currentUser;
    if (user != null) prefs.setString('profile_image_${user.uid}', path);
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final user  = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final path = prefs.getString('profile_image_${user.uid}');
      if (path != null && mounted) setState(() => _image = File(path));
    }
  }

  void _navigate(Widget screen) {
    Navigator.pop(context); // close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // ── Drawer ────────────────────────────────────────────────────────────────
  Widget _buildDrawer(ColorScheme scheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Force correct text colour regardless of Drawer's internal Material
    final textColor = scheme.onSurface;
    return Drawer(
      // Explicit background ensures no dark-surface bleed in light mode
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : Colors.white,
      child: Column(
        children: [
          // Header (always has gradient bg → always white text)
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 20,
              right: 20,
              bottom: 28,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, scheme.tertiary],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        backgroundImage: _image != null
                            ? FileImage(_image!)
                            : const AssetImage('assets/default_profile.png')
                                as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.camera_alt_rounded,
                              size: 12, color: scheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(widget.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 2),
                Text(widget.email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    )),
              ],
            ),
          ),

          // Navigation items – wrapped in DefaultTextStyle to guarantee
          // theme-correct colour even inside Drawer's Material widget
          Expanded(
            child: DefaultTextStyle(
              style: TextStyle(color: textColor),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    textColor: textColor,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 0);
                    },
                  ),
                  _drawerDivider(),
                  _drawerSectionLabel('TOOLS', textColor: textColor),
                  _drawerItem(
                    icon: Icons.hub_rounded,
                    label: 'Neo4j Visualization',
                    textColor: textColor,
                    onTap: () => _navigate(Neo4jForceGraphPage()),
                  ),
                  _drawerItem(
                    icon: Icons.warning_amber_rounded,
                    label: 'Suspected Nodes',
                    textColor: textColor,
                    onTap: () => _navigate(const RiskJsonPage()),
                  ),
                  _drawerItem(
                    icon: Icons.devices_rounded,
                    label: 'All Devices',
                    textColor: textColor,
                    onTap: () => _navigate(const NodeListPage()),
                  ),
                  _drawerItem(
                    icon: Icons.dns_rounded,
                    label: 'Servers',
                    textColor: textColor,
                    onTap: () => _navigate(const ServerListPage()),
                  ),
                  _drawerItem(
                    icon: Icons.device_hub_rounded,
                    label: 'Network Switches',
                    textColor: textColor,
                    onTap: () => _navigate(const SwitchListPage()),
                  ),
                  _drawerItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Charts & Analytics',
                    textColor: textColor,
                    onTap: () => _navigate(const NetworkCharts()),
                  ),
                  _drawerItem(
                    icon: Icons.biotech_rounded,
                    label: 'Infection Simulator',
                    textColor: textColor,
                    onTap: () => _navigate(const SimulationScreen()),
                  ),
                  _drawerDivider(),
                  _drawerSectionLabel('ACCOUNT', textColor: textColor),
                  _drawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    iconColor: AppTheme.brandRose,
                    textColor: AppTheme.brandRose,
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Version footer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              'Detectome v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.35),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    // Always resolve explicitly – never inherit from Drawer's Material
    final resolvedText  = textColor ?? scheme.onSurface;
    final resolvedIcon  = iconColor ?? scheme.primary;
    return ListTile(
      leading: Icon(icon, size: 22, color: resolvedIcon),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: resolvedText,          // ← always explicit, never inherited
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      horizontalTitleGap: 8,
    );
  }

  Widget _drawerDivider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Divider(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      );

  Widget _drawerSectionLabel(String label, {Color? textColor}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            // Always explicit: muted onSurface – dark in light mode, light in dark mode
            color: (textColor ?? Theme.of(context).colorScheme.onSurface)
                .withOpacity(0.45),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Detectome'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Alerts',
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: _buildDrawer(scheme),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub_rounded),
            label: 'Network',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard  – stat grid + quick actions
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GraphQLService _service = GraphQLService();
  Map<String, int> counts = {
    'Routers': 0, 'Switches': 0, 'Servers': 0, 'End Points': 0,
    'Suspected': 0, 'Infected': 0, 'Recovered': 0, 'Vulnerabilities': 0,
  };
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    if (!mounted) return;
    setState(() { isLoading = true; error = null; });
    try {
      final nodes = await _service.fetchNodes();
      final tmp = Map<String, int>.from(counts.map((k, _) => MapEntry(k, 0)));
      for (final n in nodes) {
        final label      = ((n['nodeType'] ?? n['name'] ?? '') as dynamic).toString().toLowerCase();
        final status     = (n['status'] ?? '').toString().toLowerCase();
        final properties = (n['allProperties'] ?? '').toString().toLowerCase();
        if (label.contains('router'))   tmp['Routers'] = tmp['Routers']! + 1;
        else if (label.contains('switch')) tmp['Switches'] = tmp['Switches']! + 1;
        else if (label.contains('server')) tmp['Servers'] = tmp['Servers']! + 1;
        else if (label.contains('endpoint') || label.contains('device')) tmp['End Points'] = tmp['End Points']! + 1;
        if (status.contains('suspected') || properties.contains('suspected')) tmp['Suspected'] = tmp['Suspected']! + 1;
        if (status.contains('infected')  || properties.contains('infected'))  tmp['Infected']  = tmp['Infected']!  + 1;
        if (status.contains('recovered') || properties.contains('recovered')) tmp['Recovered'] = tmp['Recovered']! + 1;
        if (properties.contains('vulnerability')) tmp['Vulnerabilities'] = tmp['Vulnerabilities']! + 1;
      }
      if (mounted) setState(() { counts = Map.from(tmp); isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); isLoading = false; });
    }
  }

  static const _cardMeta = <String, _StatMeta>{
    'Routers':         _StatMeta(Icons.router_rounded,             Color(0xFF3B82F6)),
    'Switches':        _StatMeta(Icons.device_hub_rounded,          Color(0xFF8B5CF6)),
    'Servers':         _StatMeta(Icons.dns_rounded,                 Color(0xFF0EA5E9)),
    'End Points':      _StatMeta(Icons.laptop_rounded,              Color(0xFF14B8A6)),
    'Suspected':       _StatMeta(Icons.warning_amber_rounded,       Color(0xFFF59E0B)),
    'Infected':        _StatMeta(Icons.bug_report_rounded,          Color(0xFFEF4444)),
    'Recovered':       _StatMeta(Icons.healing_rounded,             Color(0xFF10B981)),
    'Vulnerabilities': _StatMeta(Icons.security_rounded,            Color(0xFFEC4899)),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (isLoading) return const LoadingOverlay(label: 'Fetching network data…');
    if (error != null) return ErrorState(message: error!, onRetry: fetchCounts);

    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good morning' : now.hour < 17 ? 'Good afternoon' : 'Good evening';

    return RefreshIndicator(
      onRefresh: fetchCounts,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Header ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$greeting,',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurface.withOpacity(0.55),
                          )),
                  Text(widget.username,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                  const SizedBox(height: 6),
                  // Status pill
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981), shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Network monitoring active',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Section label ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SectionHeader(title: 'Network Overview', icon: Icons.bar_chart_rounded),
          ),

          // ── Stat grid ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: counts.length,
              itemBuilder: (ctx, i) {
                final entry = counts.entries.elementAt(i);
                final meta  = _cardMeta[entry.key]!;
                return StatCard(
                  icon: meta.icon,
                  label: entry.key,
                  value: entry.value.toString(),
                  accentColor: meta.color,
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _StatMeta {
  final IconData icon;
  final Color color;
  const _StatMeta(this.icon, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// Network Hub  – navigation grid for all network tools
// ─────────────────────────────────────────────────────────────────────────────
class NetworkHubScreen extends StatelessWidget {
  const NetworkHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _HubItem(
        icon: Icons.hub_rounded,
        label: 'Neo4j Graph',
        subtitle: 'Force-directed visualization',
        color: const Color(0xFF3B82F6),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Neo4jForceGraphPage())),
      ),
      _HubItem(
        icon: Icons.devices_rounded,
        label: 'All Devices',
        subtitle: 'Browse network nodes',
        color: const Color(0xFF14B8A6),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NodeListPage())),
      ),
      _HubItem(
        icon: Icons.dns_rounded,
        label: 'Servers',
        subtitle: 'Server inventory',
        color: const Color(0xFF0EA5E9)),
      _HubItem(
        icon: Icons.device_hub_rounded,
        label: 'Switches',
        subtitle: 'Network switches',
        color: const Color(0xFF8B5CF6),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SwitchListPage())),
      ),
      _HubItem(
        icon: Icons.warning_amber_rounded,
        label: 'Risk Analysis',
        subtitle: 'Suspected nodes table',
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiskJsonPage())),
      ),
      _HubItem(
        icon: Icons.bar_chart_rounded,
        label: 'Analytics',
        subtitle: 'Charts & distributions',
        color: const Color(0xFFEC4899),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NetworkCharts())),
      ),
      _HubItem(
        icon: Icons.biotech_rounded,
        label: 'Infection Simulator',
        subtitle: 'Mesa virus spread model',
        color: const Color(0xFFEF4444),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimulationScreen())),
      ),
    ];

    // Fix missing onTap for Servers
    items[2] = _HubItem(
      icon: Icons.dns_rounded,
      label: 'Servers',
      subtitle: 'Server inventory',
      color: const Color(0xFF0EA5E9),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServerListPage())),
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Network Hub',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Access all monitoring tools.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                      ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              return NavCard(
                icon: item.icon,
                label: item.label,
                subtitle: item.subtitle,
                color: item.color,
                onTap: item.onTap ?? () {},
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HubItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  const _HubItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
  });
}

// Keep for backward compatibility (used via drawer navigation)
class GraphVisualizationScreen extends StatelessWidget {
  const GraphVisualizationScreen({super.key});
  @override
  Widget build(BuildContext context) => const NetworkHubScreen();
}
