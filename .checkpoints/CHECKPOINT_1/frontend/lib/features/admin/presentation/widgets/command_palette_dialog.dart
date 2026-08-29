import 'package:flutter/material.dart';

class CommandPaletteDialog extends StatefulWidget {
  final Function(int viewIndex) onSelectView;

  const CommandPaletteDialog({super.key, required this.onSelectView});

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  final List<Map<String, dynamic>> _commands = [
    {'title': 'Executive Dashboard', 'icon': Icons.dashboard_outlined, 'index': 0, 'category': 'Analytics'},
    {'title': 'User Management & Access Control', 'icon': Icons.people_alt_outlined, 'index': 1, 'category': 'Administration'},
    {'title': 'Department Topology & Capacity', 'icon': Icons.account_tree_outlined, 'index': 2, 'category': 'Organization'},
    {'title': 'Faculty Workload & Assignments', 'icon': Icons.badge_outlined, 'index': 3, 'category': 'Administration'},
    {'title': 'Centralized Student Registry', 'icon': Icons.school_outlined, 'index': 4, 'category': 'Registry'},
    {'title': 'Organization System Settings', 'icon': Icons.settings_outlined, 'index': 5, 'category': 'Configuration'},
    {'title': 'Immutable Audit Logs', 'icon': Icons.history_outlined, 'index': 6, 'category': 'Security'},
    {'title': 'Real-time System Monitoring', 'icon': Icons.monitor_heart_outlined, 'index': 7, 'category': 'Infrastructure'},
    {'title': 'Security Control Center', 'icon': Icons.security_outlined, 'index': 8, 'category': 'Security'},
    {'title': 'Advanced Analytics & Reports', 'icon': Icons.analytics_outlined, 'index': 9, 'category': 'Analytics'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _commands.where((cmd) {
      final title = cmd['title'].toString().toLowerCase();
      final cat = cmd['category'].toString().toLowerCase();
      return title.contains(_query.toLowerCase()) || cat.contains(_query.toLowerCase());
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 480,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type a command or search platform modules... (e.g. Users, Security, Audit)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No matching modules found', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final cmd = filtered[index];
                        return ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            child: Icon(cmd['icon'] as IconData, color: Colors.blue[800]),
                          ),
                          title: Text(cmd['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(cmd['category'] as String, style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onSelectView(cmd['index'] as int);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
