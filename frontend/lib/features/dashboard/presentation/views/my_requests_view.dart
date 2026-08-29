import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../od_workflow/domain/entities/od_request.dart';
import '../../../od_workflow/domain/entities/od_status.dart';
import '../../../od_workflow/presentation/controllers/workflow_controller.dart';
import '../../../od_workflow/presentation/widgets/request_details_modal.dart';
import 'shared_dashboard_widgets.dart';

class MyRequestsView extends ConsumerStatefulWidget {
  const MyRequestsView({super.key});

  @override
  ConsumerState<MyRequestsView> createState() => _MyRequestsViewState();
}

class _MyRequestsViewState extends ConsumerState<MyRequestsView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  OdStatus? _selectedStatus;
  OdRequest? _selectedRequest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allRequests = ref.watch(workflowControllerProvider.select((s) => s.requests));
    final requests = allRequests.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          r.reason.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatus == null || r.status == _selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();

    final isDesktop = ResponsiveLayout.isDesktop(context);

    return RefreshIndicator(
      onRefresh: () => ref.read(workflowControllerProvider.notifier).loadAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My On Duty Requests',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Inspect historical On Duty applications, approval statuses, and official documentation',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Search & Filter Header
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Search by ID, reason...',
                        prefixIcon: Icon(Icons.search_rounded, size: 18),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: AppSpacing.md),
                        border: OutlineInputBorder(borderRadius: AppRadius.borderMd, borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                DropdownButton<OdStatus?>(
                  value: _selectedStatus,
                  hint: const Text('All Statuses'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Statuses')),
                    ...OdStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))),
                  ],
                  onChanged: (val) => setState(() => _selectedStatus = val),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Main Content Area
            if (requests.isEmpty)
              const AppEmptyState(
                title: 'No Matching Requests',
                description: 'Try adjusting your search criteria or status filters.',
              )
            else if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: _selectedRequest != null ? 6 : 10,
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                showCheckboxColumn: false,
                                headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                                columns: const [
                                  DataColumn(label: Text('Request ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Event / Reason', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Dates', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: requests.map((req) {
                                  final isSelected = _selectedRequest?.id == req.id;
                                  return DataRow(
                                    selected: isSelected,
                                    onSelectChanged: (_) => setState(() => _selectedRequest = req),
                                    cells: [
                                      DataCell(Text(req.id, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue))),
                                      DataCell(Text(req.reason)),
                                      DataCell(Text('${req.startDate.toString().split(' ')[0]} to ${req.endDate.toString().split(' ')[0]}')),
                                      DataCell(Text('${req.durationDays} Days')),
                                      DataCell(AppStatusChip(label: req.statusDisplayLabel, statusType: req.status.statusType)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (_selectedRequest != null) ...[
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 4,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('ID: ${_selectedRequest!.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() => _selectedRequest = null)),
                              ],
                            ),
                            const AppDivider(),
                            Text('Reason: ${_selectedRequest!.reason}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Purpose: ${_selectedRequest!.purpose} • ${_selectedRequest!.venue}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: AppSpacing.md),
                            AppStatusChip(label: _selectedRequest!.statusDisplayLabel, statusType: _selectedRequest!.status.statusType),
                            const SizedBox(height: AppSpacing.md),
                            ElevatedButton.icon(
                              onPressed: () => RequestDetailsModal.show(context, _selectedRequest!),
                              icon: const Icon(Icons.open_in_new_rounded, size: 16),
                              label: const Text('Open Full Document Modal'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              )
            else
              Column(
                children: requests.map((req) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: OdRequestTile(request: req),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
