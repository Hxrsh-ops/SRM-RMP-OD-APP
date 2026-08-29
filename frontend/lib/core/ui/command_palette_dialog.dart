import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/authentication/authentication.dart';
import '../../features/od_workflow/presentation/controllers/workflow_controller.dart';
import '../../features/od_workflow/presentation/widgets/request_details_modal.dart';

class CommandPaletteDialog extends ConsumerStatefulWidget {
  final Function(int pageIndex)? onNavigate;

  const CommandPaletteDialog({super.key, this.onNavigate});

  static void show(BuildContext context, {Function(int pageIndex)? onNavigate}) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => CommandPaletteDialog(onNavigate: onNavigate),
    );
  }

  @override
  ConsumerState<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends ConsumerState<CommandPaletteDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).session;
    final role = session?.role ?? 'STUDENT';
    final isStudent = role == 'STUDENT';
    final allRequests = ref.watch(workflowControllerProvider.select((s) => s.requests));

    final List<_PaletteAction> defaultActions = [
      _PaletteAction(
        title: isStudent ? 'Dashboard Overview' : 'Approval Workspace',
        subtitle: 'Jump to main home view',
        icon: Icons.dashboard_rounded,
        category: 'Navigation',
        onTap: () {
          Navigator.pop(context);
          widget.onNavigate?.call(0);
        },
      ),
      _PaletteAction(
        title: isStudent ? 'My OD Requests' : 'Requests Stream',
        subtitle: 'View submitted OD history and status tracking',
        icon: Icons.list_alt_rounded,
        category: 'Navigation',
        onTap: () {
          Navigator.pop(context);
          widget.onNavigate?.call(1);
        },
      ),
      if (isStudent)
        _PaletteAction(
          title: 'Submit New On Duty Request',
          subtitle: 'Create and submit a new OD application',
          icon: Icons.add_circle_outline_rounded,
          category: 'Actions',
          onTap: () {
            Navigator.pop(context);
            widget.onNavigate?.call(2);
          },
        )
      else
        _PaletteAction(
          title: role == 'FACULTY_ADVISOR' ? 'My Advisees Directory' : 'Department Student Directory',
          subtitle: 'Browse enrolled students and class sections',
          icon: Icons.people_outline_rounded,
          category: 'Navigation',
          onTap: () {
            Navigator.pop(context);
            widget.onNavigate?.call(2);
          },
        ),
      _PaletteAction(
        title: 'Notifications & Alerts',
        subtitle: 'View workflow alerts and updates',
        icon: Icons.notifications_none_rounded,
        category: 'Navigation',
        onTap: () {
          Navigator.pop(context);
          widget.onNavigate?.call(3);
        },
      ),
      _PaletteAction(
        title: 'User Profile & Settings',
        subtitle: 'View your account details and credentials',
        icon: Icons.person_outline_rounded,
        category: 'Account',
        onTap: () {
          Navigator.pop(context);
          widget.onNavigate?.call(4);
        },
      ),
    ];

    // Filter requests matching search query
    final matchingRequests = _query.trim().isEmpty
        ? <_PaletteAction>[]
        : allRequests
            .where((r) =>
                r.id.toLowerCase().contains(_query.toLowerCase()) ||
                r.reason.toLowerCase().contains(_query.toLowerCase()) ||
                r.studentName.toLowerCase().contains(_query.toLowerCase()) ||
                r.registerNumber.toLowerCase().contains(_query.toLowerCase()))
            .take(5)
            .map((r) => _PaletteAction(
                  title: '${r.id} • ${r.reason}',
                  subtitle: '${r.studentName} (${r.registerNumber}) — ${r.status.displayName}',
                  icon: Icons.description_outlined,
                  category: 'OD Requests',
                  onTap: () {
                    Navigator.pop(context);
                    RequestDetailsModal.show(context, r);
                  },
                ))
            .toList();

    final matchingActions = _query.trim().isEmpty
        ? defaultActions
        : defaultActions
            .where((a) => a.title.toLowerCase().contains(_query.toLowerCase()) || a.subtitle.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    final allItems = [...matchingRequests, ...matchingActions];

    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 600;
    final availableHeight = media.size.height - media.viewInsets.bottom - (isMobile ? 30 : 60);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: isMobile ? 12 : 40),
      alignment: Alignment.topCenter,
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: availableHeight > 180 ? availableHeight : 180,
        ),
        margin: EdgeInsets.only(top: isMobile ? 8 : 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 8)),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF1A365D), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Search requests, actions, or jump to page... (Esc to close)',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => setState(() {
                        _query = val;
                        _selectedIndex = 0;
                      }),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text('ESC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                ],
              ),
            ),

            // Results List
            Flexible(
              child: allItems.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 32, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No matching commands or requests found', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: allItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                      itemBuilder: (context, idx) {
                        final item = allItems[idx];
                        final isSelected = idx == _selectedIndex;

                        return InkWell(
                          onTap: item.onTap,
                          hoverColor: const Color(0xFF1A365D).withValues(alpha: 0.06),
                          child: Container(
                            color: isSelected ? const Color(0xFF1A365D).withValues(alpha: 0.08) : Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A365D).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(item.icon, size: 18, color: const Color(0xFF1A365D)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text(item.subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(item.category, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Footer Shortcut Guide
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.keyboard_outlined, size: 14, color: Colors.grey),
                  SizedBox(width: 6),
                  Text('Tip: Press Ctrl + K anywhere to open spotlight palette', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final String category;
  final VoidCallback onTap;

  _PaletteAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
    required this.onTap,
  });
}
