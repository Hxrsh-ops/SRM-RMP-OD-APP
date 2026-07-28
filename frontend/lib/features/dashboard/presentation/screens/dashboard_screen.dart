import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../authentication/authentication.dart';
import '../../../od_workflow/domain/entities/attachment_item.dart';
import '../../../od_workflow/domain/entities/od_request.dart';
import '../../../od_workflow/domain/entities/od_status.dart';
import '../../../od_workflow/presentation/controllers/workflow_controller.dart';
import '../../../od_workflow/presentation/widgets/request_details_modal.dart';

class MainShellDashboardScreen extends ConsumerStatefulWidget {
  const MainShellDashboardScreen({super.key});

  @override
  ConsumerState<MainShellDashboardScreen> createState() => _MainShellDashboardScreenState();
}

class _MainShellDashboardScreenState extends ConsumerState<MainShellDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final session = ref.watch(authControllerProvider).session;
    final role = session?.role ?? 'STUDENT';

    final List<Widget> pages = role == 'FACULTY_ADVISOR'
        ? [
            _FacultyDashboardView(onNavigate: (index) => setState(() => _currentIndex = index)),
            const _AllRequestsView(),
            const _NotificationsView(),
            const _ProfileView(),
          ]
        : (role == 'COORDINATOR'
            ? [
                _CoordinatorDashboardView(onNavigate: (index) => setState(() => _currentIndex = index)),
                const _AllRequestsView(),
                const _NotificationsView(),
                const _ProfileView(),
              ]
            : [
                _HomeDashboardView(onNavigate: (index) => setState(() => _currentIndex = index)),
                const _MyRequestsView(),
                const _CreateOdRequestFlowView(),
                const _NotificationsView(),
                const _ProfileView(),
              ]);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            AppDesktopSidebar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
            ),
            Expanded(
              child: SafeArea(
                child: pages[_currentIndex < pages.length ? _currentIndex : 0],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex < pages.length ? _currentIndex : 0,
          children: pages,
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex < 5 ? _currentIndex : 0,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// STUDENT HOME DASHBOARD VIEW
// -----------------------------------------------------------------------------
class _HomeDashboardView extends ConsumerWidget {
  final ValueChanged<int> onNavigate;

  const _HomeDashboardView({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).session;
    final workflowState = ref.watch(workflowControllerProvider);
    final requests = workflowState.requests;

    final pendingCount = requests.where((r) => r.status == OdStatus.pendingFaculty || r.status == OdStatus.pendingCoordinator).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue Student Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppAvatarPlaceholder(
                      name: session?.name ?? 'Alex Vance',
                      size: 44,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session?.name ?? 'Alex Vance',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${session?.role ?? 'STUDENT'} • ${session?.username ?? 'RA2311003001'}',
                            style: const TextStyle(
                              color: AppColors.accentYellow,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                      onPressed: () => onNavigate(3),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  "TODAY'S SCHEDULE",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: const [
                      _ScheduleCard(subject: 'Physics Lab', time: '10:30 AM', venue: 'Room 301'),
                      SizedBox(width: AppSpacing.md),
                      _ScheduleCard(subject: 'DEMS Workshop', time: '01:30 PM', venue: 'Lab 04'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionHeader(
                  title: 'OD Workflow Summary',
                  subtitle: 'Live On Duty status overview',
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryStatCard(
                        title: 'Total ODs',
                        value: '${requests.length}',
                        subtext: 'Submitted Requests',
                        accentColor: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _SummaryStatCard(
                        title: 'Pending',
                        value: '$pendingCount',
                        subtext: 'Awaiting Sign-Off',
                        accentColor: AppColors.warning,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Quick Actions Grid
                const Text(
                  'QUICK ACTIONS',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Create OD',
                        onTap: () => onNavigate(2),
                      ),
                    ),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.assignment_outlined,
                        label: 'My ODs',
                        onTap: () => onNavigate(1),
                      ),
                    ),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.history_rounded,
                        label: 'Timeline',
                        onTap: () => onNavigate(1),
                      ),
                    ),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.notifications_active_outlined,
                        label: 'Alerts',
                        onTap: () => onNavigate(3),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Recent OD Requests Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent OD Requests', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    AppTextButton(
                      label: 'View All',
                      size: AppButtonSize.small,
                      onPressed: () => onNavigate(1),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Column(
                  children: requests.take(3).map((req) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _OdRequestTile(request: req),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FACULTY ADVISOR DASHBOARD VIEW
// -----------------------------------------------------------------------------
class _FacultyDashboardView extends ConsumerWidget {
  final ValueChanged<int> onNavigate;

  const _FacultyDashboardView({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).session;
    final workflowState = ref.watch(workflowControllerProvider);
    final requests = workflowState.requests;
    final pendingFaculty = requests.where((r) => r.status == OdStatus.pendingFaculty || r.status == OdStatus.submitted).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatarPlaceholder(name: session?.name ?? 'Dr. Karthik B', size: 48),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session?.name ?? 'Dr. Karthik B',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Faculty Advisor • Computer Science',
                      style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          const AppSectionHeader(
            title: 'Faculty Approval Queue',
            subtitle: 'Review student OD requests assigned to your advisory class',
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: _SummaryStatCard(
                  title: 'Pending Review',
                  value: '${pendingFaculty.length}',
                  subtext: 'Requires Action',
                  accentColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SummaryStatCard(
                  title: 'Total Handled',
                  value: '${requests.length}',
                  subtext: 'Department ODs',
                  accentColor: AppColors.primaryBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),
          const Text('PENDING APPROVAL QUEUE', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: AppSpacing.sm),

          if (pendingFaculty.isEmpty)
            const AppEmptyState(
              title: 'No Pending Faculty Approvals',
              description: 'All assigned student OD requests have been reviewed.',
            )
          else
            Column(
              children: pendingFaculty.map((req) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _OdRequestTile(request: req),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// COORDINATOR DASHBOARD VIEW
// -----------------------------------------------------------------------------
class _CoordinatorDashboardView extends ConsumerWidget {
  final ValueChanged<int> onNavigate;

  const _CoordinatorDashboardView({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).session;
    final workflowState = ref.watch(workflowControllerProvider);
    final requests = workflowState.requests;
    final pendingCoord = requests.where((r) => r.status == OdStatus.pendingCoordinator || r.status == OdStatus.facultyApproved).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatarPlaceholder(name: session?.name ?? 'Prof. Ramesh Kumar', size: 48),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session?.name ?? 'Prof. Ramesh Kumar',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'OD Workflow Coordinator • SRM Ramapuram',
                      style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          const AppSectionHeader(
            title: 'Campus Final Approval Queue',
            subtitle: 'Final sign-off on Faculty-approved student On Duty requests',
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: _SummaryStatCard(
                  title: 'Awaiting Sign-Off',
                  value: '${pendingCoord.length}',
                  subtext: 'Final Review',
                  accentColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SummaryStatCard(
                  title: 'Approved Today',
                  value: '${requests.where((r) => r.status == OdStatus.completed).length}',
                  subtext: 'Completed ODs',
                  accentColor: AppColors.success,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),
          const Text('FINAL SIGN-OFF QUEUE', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: AppSpacing.sm),

          if (pendingCoord.isEmpty)
            const AppEmptyState(
              title: 'No Pending Sign-Offs',
              description: 'There are currently no Faculty-approved OD requests awaiting coordinator action.',
            )
          else
            Column(
              children: pendingCoord.map((req) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _OdRequestTile(request: req),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// STUDENT CREATE OD REQUEST - 5 STEP FLOW
// -----------------------------------------------------------------------------
class _CreateOdRequestFlowView extends ConsumerStatefulWidget {
  const _CreateOdRequestFlowView();

  @override
  ConsumerState<_CreateOdRequestFlowView> createState() => _CreateOdRequestFlowViewState();
}

class _CreateOdRequestFlowViewState extends ConsumerState<_CreateOdRequestFlowView> {
  int _currentStep = 1;
  String _selectedReason = 'Hackathon';
  final _purposeController = TextEditingController(text: 'National Level AI Hackathon 2026');
  final _venueController = TextEditingController(text: 'Tech Park Auditorium, SRM Ramapuram');
  final _organizerController = TextEditingController(text: 'Department of CSE & AI Club');
  final _notesController = TextEditingController(text: 'Team Leader for Antigravity Hackers');

  List<AttachmentItem> _attachments = [];

  @override
  void dispose() {
    _purposeController.dispose();
    _venueController.dispose();
    _organizerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addMockAttachment() {
    setState(() {
      final now = DateTime.now();
      _attachments.add(
        AttachmentItem(
          id: 'ATT-${now.millisecondsSinceEpoch}',
          fileName: 'Event_Invitation_Letter.pdf',
          fileType: 'pdf',
          sizeBytes: 1024 * 380,
          fileUrl: 'https://example.com/doc.pdf',
          uploadedBy: 'Alex Vance',
          uploadedAt: now,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).session;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create OD Request',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Step $_currentStep of 5',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 5-Step Progress Indicator Bar
          Row(
            children: List.generate(5, (index) {
              final stepNum = index + 1;
              final isActive = stepNum <= _currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 4 ? AppSpacing.xs : 0),
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryBlue : AppColors.border,
                    borderRadius: AppRadius.borderSm,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // STEP 1: REASON
          if (_currentStep == 1) ...[
            const AppSectionHeader(
              title: 'Step 1: Select Reason',
              subtitle: 'Choose the primary reason for your On Duty request',
            ),
            const SizedBox(height: AppSpacing.md),
            ...[
              'Hackathon',
              'Workshop',
              'Seminar',
              'Sports',
              'Placement',
              'Medical',
              'Department Work',
              'Competition',
              'Others',
            ].map((reason) {
              final isSelected = _selectedReason == reason;
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.3) : Colors.transparent,
                  borderRadius: AppRadius.borderMd,
                ),
                child: RadioListTile<String>(
                  title: Text(reason, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                  value: reason,
                  // Ignore deprecated warning explicitly as per standard
                  // ignore: deprecated_member_use
                  groupValue: _selectedReason,
                  activeColor: AppColors.primaryBlue,
                  // ignore: deprecated_member_use
                  onChanged: (val) => setState(() => _selectedReason = val!),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.xxl),
            AppPrimaryButton(
              label: 'Continue to Dates',
              onPressed: () => setState(() => _currentStep = 2),
            ),
          ]
          // STEP 2: DATES & DURATION
          else if (_currentStep == 2) ...[
            const AppSectionHeader(
              title: 'Step 2: Date & Duration',
              subtitle: 'Select start date, end date, and calculated days',
            ),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(labelText: 'Start Date', hintText: '2026-07-28'),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(labelText: 'End Date', hintText: '2026-07-30'),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(labelText: 'Duration (Days)', hintText: '3 Days'),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(child: AppOutlineButton(label: 'Back', onPressed: () => setState(() => _currentStep = 1))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: AppPrimaryButton(label: 'Continue to Details', onPressed: () => setState(() => _currentStep = 3))),
              ],
            ),
          ]
          // STEP 3: DETAILS (FIXED OVERFLOW BY 26 PIXELS)
          else if (_currentStep == 3) ...[
            const AppSectionHeader(
              title: 'Step 3: Event Details',
              subtitle: 'Provide purpose, venue, organizer and notes',
            ),
            const SizedBox(height: AppSpacing.md),
            AppMultilineField(controller: _purposeController, labelText: 'Purpose / Event Title'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(controller: _venueController, labelText: 'Venue Location'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(controller: _organizerController, labelText: 'Organizer / Institution'),
            const SizedBox(height: AppSpacing.md),
            AppMultilineField(controller: _notesController, labelText: 'Additional Notes (Optional)'),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(child: AppOutlineButton(label: 'Back', onPressed: () => setState(() => _currentStep = 2))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: AppPrimaryButton(label: 'Continue to Attachments', onPressed: () => setState(() => _currentStep = 4))),
              ],
            ),
          ]
          // STEP 4: SUPPORTING DOCUMENTS (OPTIONAL)
          else if (_currentStep == 4) ...[
            const AppSectionHeader(
              title: 'Step 4: Supporting Documents (Optional)',
              subtitle: 'Attach event poster, invitation letter, or receipt (PDF/JPG/PNG)',
            ),
            const SizedBox(height: AppSpacing.md),
            if (_attachments.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.file_present_outlined, size: 40, color: AppColors.textSecondary),
                    SizedBox(height: AppSpacing.sm),
                    Text('No supporting documents attached.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    SizedBox(height: 2),
                    Text('Submission is allowed without attachments.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              Column(
                children: _attachments.map((att) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: AppColors.danger),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(att.fileName, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('Uploaded by ${att.uploadedBy} • ${att.sizeFormatted}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                          onPressed: () => setState(() => _attachments.remove(att)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: AppSpacing.lg),
            AppOutlineButton(
              label: '+ Add Document Attachment',
              prefixIcon: Icons.upload_file_outlined,
              onPressed: _addMockAttachment,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(child: AppOutlineButton(label: 'Back', onPressed: () => setState(() => _currentStep = 3))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: AppPrimaryButton(label: 'Continue to Review', onPressed: () => setState(() => _currentStep = 5))),
              ],
            ),
          ]
          // STEP 5: REVIEW & SUBMIT
          else ...[
            const AppSectionHeader(
              title: 'Step 5: Review & Submit',
              subtitle: 'Please review your request before submitting',
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reason', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(_selectedReason, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const AppDivider(),
                  const Text('Event Details', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('${_purposeController.text} • ${_venueController.text}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const AppDivider(),
                  const Text('Attachments', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(
                    _attachments.isEmpty ? 'No supporting documents attached.' : '${_attachments.length} attachment(s) uploaded',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Automatic Faculty Advisor Assignment Box
            const AppInfoCard(
              title: 'Assigned Faculty Advisor (Automatic)',
              description: 'Dr. Karthik B (FA1001) - Class Counselor',
              icon: Icons.assignment_ind_outlined,
            ),

            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(child: AppOutlineButton(label: 'Back', onPressed: () => setState(() => _currentStep = 4))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Submit Request',
                    onPressed: () {
                      ref.read(workflowControllerProvider.notifier).submitRequest(
                            studentId: session?.username ?? 'RA2311003001',
                            studentName: session?.name ?? 'Alex Vance',
                            registerNumber: session?.username ?? 'RA2311003001',
                            reason: _selectedReason,
                            startDate: DateTime.now(),
                            endDate: DateTime.now().add(const Duration(days: 2)),
                            durationDays: 3,
                            purpose: _purposeController.text,
                            venue: _venueController.text,
                            organizer: _organizerController.text,
                            additionalNotes: _notesController.text,
                            attachments: _attachments,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OD Request submitted successfully! Assigned to Dr. Karthik B.')),
                      );
                      setState(() {
                        _currentStep = 1;
                        _attachments = [];
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MY REQUESTS VIEW
// -----------------------------------------------------------------------------
class _MyRequestsView extends ConsumerStatefulWidget {
  const _MyRequestsView();

  @override
  ConsumerState<_MyRequestsView> createState() => _MyRequestsViewState();
}

class _MyRequestsViewState extends ConsumerState<_MyRequestsView> {
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workflowState = ref.watch(workflowControllerProvider);
    final requests = workflowState.requests;

    List<OdRequest> filtered = requests;
    if (_selectedFilterIndex == 1) {
      filtered = requests.where((r) => r.status == OdStatus.pendingFaculty || r.status == OdStatus.pendingCoordinator).toList();
    } else if (_selectedFilterIndex == 2) {
      filtered = requests.where((r) => r.status == OdStatus.completed).toList();
    } else if (_selectedFilterIndex == 3) {
      filtered = requests.where((r) => r.status == OdStatus.rejected || r.status == OdStatus.facultyRejected).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My OD Requests',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Track your submitted On Duty approval requests',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),

          AppSearchField(hintText: 'Search requests...', onChanged: (q) {}),
          const SizedBox(height: AppSpacing.lg),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AppFilterChip(label: 'All', isSelected: _selectedFilterIndex == 0, onTap: () => setState(() => _selectedFilterIndex = 0)),
                const SizedBox(width: AppSpacing.sm),
                AppFilterChip(label: 'Pending', isSelected: _selectedFilterIndex == 1, onTap: () => setState(() => _selectedFilterIndex = 1)),
                const SizedBox(width: AppSpacing.sm),
                AppFilterChip(label: 'Approved', isSelected: _selectedFilterIndex == 2, onTap: () => setState(() => _selectedFilterIndex = 2)),
                const SizedBox(width: AppSpacing.sm),
                AppFilterChip(label: 'Rejected', isSelected: _selectedFilterIndex == 3, onTap: () => setState(() => _selectedFilterIndex = 3)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          if (filtered.isEmpty)
            const AppEmptyState(title: 'No OD Requests Found', description: 'No requests match the selected filter criteria.')
          else
            Column(
              children: filtered.map((req) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _OdRequestTile(request: req),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _AllRequestsView extends ConsumerWidget {
  const _AllRequestsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowState = ref.watch(workflowControllerProvider);
    final requests = workflowState.requests;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('All Campus OD Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryBlue)),
          const SizedBox(height: AppSpacing.lg),
          Column(
            children: requests.map((req) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _OdRequestTile(request: req),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// NOTIFICATIONS VIEW
// -----------------------------------------------------------------------------
class _NotificationsView extends ConsumerWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workflowState = ref.watch(workflowControllerProvider);
    final notifications = workflowState.notifications;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              ),
              AppTextButton(
                label: 'Mark all as read',
                size: AppButtonSize.small,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          if (notifications.isEmpty)
            const AppEmptyState(title: 'No Notifications Yet', description: "You'll see notification updates here when OD status changes.")
          else
            Column(
              children: notifications.map((n) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notifications_active_outlined, color: AppColors.primaryBlue, size: 22),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(n.message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PROFILE VIEW
// -----------------------------------------------------------------------------
class _ProfileView extends ConsumerWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).session;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Profile',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          AppCard(
            child: Column(
              children: [
                AppAvatarPlaceholder(name: session?.name ?? 'User Account', size: 72),
                const SizedBox(height: AppSpacing.md),
                Text(session?.name ?? 'User Account', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  'Role: ${session?.role ?? 'STUDENT'} • ID: ${session?.username ?? 'RA2311003001'}',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                const _ProfileDetailRow(label: 'Campus', value: 'SRM Ramapuram Campus'),
                const _ProfileDetailRow(label: 'Institution', value: 'SRM Institute of Science & Tech'),
                _ProfileDetailRow(label: 'Role Privilege', value: session?.role ?? 'STUDENT'),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          AppDestructiveButton(
            label: 'Sign Out of Account',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HELPER TILES
// -----------------------------------------------------------------------------
class _OdRequestTile extends StatelessWidget {
  final OdRequest request;

  const _OdRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    return AppClickableCard(
      onTap: () => RequestDetailsModal.show(context, request),
      child: Row(
        children: [
          const Icon(Icons.assignment_outlined, color: AppColors.primaryBlue, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.reason, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${request.studentName} • ${request.durationDays} Days (${request.startDate.toString().split(' ')[0]})',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppStatusChip(label: request.status.displayName, statusType: request.status.statusType),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final String subject;
  final String time;
  final String venue;

  const _ScheduleCard({required this.subject, required this.time, required this.venue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: Colors.white, borderRadius: AppRadius.borderMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 12, color: AppColors.primaryLight),
              const SizedBox(width: 4),
              Expanded(child: Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 2),
          Text(venue, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final Color accentColor;

  const _SummaryStatCard({required this.title, required this.value, required this.subtext, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: accentColor)),
          ),
          Text(subtext, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMd,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: AppRadius.borderMd),
            child: Icon(icon, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
