import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_constants.dart';
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
    final session = ref.watch(authControllerProvider).session;
    final role = session?.role ?? 'STUDENT';
    final isStudent = role == 'STUDENT';

    final List<Widget> pages = isStudent
        ? const [
            _HomeDashboardView(),
            _MyRequestsView(),
            _CreateOdRequestFlowView(),
            _NotificationsView(),
            _ProfileView(),
          ]
        : const [
            _HomeDashboardView(),
            _AllRequestsView(),
            _NotificationsView(),
            _ProfileView(),
          ];

    final safeIndex = _currentIndex < pages.length ? _currentIndex : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                AppDesktopSidebar(
                  selectedIndex: safeIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
                  role: role,
                ),
                Expanded(
                  child: Column(
                    children: [
                      _DashboardTopHeader(
                        role: role,
                        name: session?.name ?? 'K.M. Harshanth',
                        onNotificationTap: () {
                          setState(() => _currentIndex = isStudent ? 3 : 2);
                        },
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: safeIndex,
                          children: pages,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _MobileAppBar(
            role: role,
            name: session?.name ?? 'K.M. Harshanth',
            onNotificationTap: () {
              setState(() => _currentIndex = isStudent ? 3 : 2);
            },
          ),
          body: IndexedStack(
            index: safeIndex,
            children: pages,
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: safeIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            role: role,
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// HEADERS
// -----------------------------------------------------------------------------
class _DashboardTopHeader extends StatelessWidget {
  final String role;
  final String name;
  final VoidCallback onNotificationTap;

  const _DashboardTopHeader({
    required this.role,
    required this.name,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFaculty = role == 'FACULTY_ADVISOR';
    final isCoordinator = role == 'COORDINATOR';

    final roleLabel = isFaculty
        ? 'Faculty Advisor'
        : isCoordinator
            ? 'Department Coordinator'
            : 'Student';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Welcome back, $name',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text(
                  roleLabel,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
                onPressed: onNotificationTap,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppAvatarPlaceholder(name: name, size: 36),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String role;
  final String name;
  final VoidCallback onNotificationTap;

  const _MobileAppBar({
    required this.role,
    required this.name,
    required this.onNotificationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: const AppBrandLogo(size: 28, showWordmark: true),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primaryBlue),
          onPressed: onNotificationTap,
        ),
        const SizedBox(width: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: AppAvatarPlaceholder(name: name, size: 32),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// HOME DASHBOARD VIEW
// -----------------------------------------------------------------------------
class _HomeDashboardView extends ConsumerWidget {
  const _HomeDashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final role = session?.role ?? 'STUDENT';

    if (role == 'FACULTY_ADVISOR') {
      return const _FacultyDashboardView();
    } else if (role == 'COORDINATOR') {
      return const _CoordinatorDashboardView();
    }

    return const _StudentHomeDashboardView();
  }
}

class _StudentHomeDashboardView extends ConsumerWidget {
  const _StudentHomeDashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).session;
    final workflowState = ref.watch(workflowControllerProvider);
    final requests = workflowState.requests;

    final pendingCount = requests.where((r) => r.status == OdStatus.pendingFaculty || r.status == OdStatus.pendingCoordinator).length;
    final approvedCount = requests.where((r) => r.status == OdStatus.completed).length;

    return RefreshIndicator(
      onRefresh: () => ref.read(workflowControllerProvider.notifier).loadAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good day, ${session?.name ?? "K.M. Harshanth"} 👋',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'B.Tech CSE (AI & ML) • 2nd Year - Sec G',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Metrics Cards
            Row(
              children: [
                Expanded(
                  child: AppMetricCard(
                    title: 'Pending ODs',
                    value: '$pendingCount',
                    icon: Icons.hourglass_top_rounded,
                    statusType: AppStatusType.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppMetricCard(
                    title: 'Approved ODs',
                    value: '$approvedCount',
                    icon: Icons.check_circle_outline_rounded,
                    statusType: AppStatusType.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Assigned Advisor Banner
            AppInfoCard(
              title: 'Assigned Faculty Advisor',
              description: '${session?.assignedFacultyName ?? "Dr. Karthik B (Mock)"} — Class Counselor',
              icon: Icons.person_search_outlined,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Recent Requests Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent OD Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                AppTextButton(
                  label: 'View All',
                  size: AppButtonSize.small,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (requests.isEmpty)
              const AppEmptyState(
                title: 'No OD Requests Yet',
                description: 'Tap "Create" to submit your first On Duty request.',
              )
            else
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
    );
  }
}

class _FacultyDashboardView extends ConsumerWidget {
  const _FacultyDashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workflowState = ref.watch(workflowControllerProvider);
    final pendingRequests = workflowState.requests.where((r) => r.status == OdStatus.pendingFaculty || r.status == OdStatus.submitted).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(workflowControllerProvider.notifier).loadAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Faculty Review Queue',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Review pending student On Duty approval submissions',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppMetricCard(
              title: 'Pending Faculty Reviews',
              value: '${pendingRequests.length}',
              icon: Icons.assignment_late_outlined,
              statusType: AppStatusType.warning,
            ),
            const SizedBox(height: AppSpacing.xl),

            if (pendingRequests.isEmpty)
              const AppEmptyState(title: 'No Pending Reviews', description: 'All student OD requests assigned to you have been reviewed.')
            else
              Column(
                children: pendingRequests.map((req) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _OdRequestTile(request: req),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _CoordinatorDashboardView extends ConsumerWidget {
  const _CoordinatorDashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workflowState = ref.watch(workflowControllerProvider);
    final pendingRequests = workflowState.requests.where((r) => r.status == OdStatus.pendingCoordinator || r.status == OdStatus.facultyApproved).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(workflowControllerProvider.notifier).loadAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coordinator Approval Queue',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Final institutional sign-off for faculty-approved OD requests',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppMetricCard(
              title: 'Awaiting Coordinator Sign-Off',
              value: '${pendingRequests.length}',
              icon: Icons.approval_outlined,
              statusType: AppStatusType.info,
            ),
            const SizedBox(height: AppSpacing.xl),

            if (pendingRequests.isEmpty)
              const AppEmptyState(title: 'Queue Clear', description: 'No requests currently pending coordinator final approval.')
            else
              Column(
                children: pendingRequests.map((req) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _OdRequestTile(request: req),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CREATE OD REQUEST FLOW VIEW (SECTION 6)
// -----------------------------------------------------------------------------
class _CreateOdRequestFlowView extends ConsumerStatefulWidget {
  const _CreateOdRequestFlowView();

  @override
  ConsumerState<_CreateOdRequestFlowView> createState() => _CreateOdRequestFlowViewState();
}

class _CreateOdRequestFlowViewState extends ConsumerState<_CreateOdRequestFlowView> {
  int _currentStep = 1;
  String _selectedReason = 'Hackathon';
  String _residenceType = 'Day Scholar';
  String? _errorMessage;

  final _purposeController = TextEditingController(text: 'National Level AI Hackathon 2026');
  final _venueController = TextEditingController(text: 'Tech Park Auditorium, SRM Ramapuram');
  final _organizerController = TextEditingController(text: 'Department of CSE & AI Club');
  final _notesController = TextEditingController(text: 'Team Leader for Antigravity Hackers');
  final _cgpaController = TextEditingController(text: '8.8');
  final _attendanceController = TextEditingController(text: '91.5');

  List<AttachmentItem> _attachments = [];
  AttachmentItem? _parentConsentAttachment;

  @override
  void dispose() {
    _purposeController.dispose();
    _venueController.dispose();
    _organizerController.dispose();
    _notesController.dispose();
    _cgpaController.dispose();
    _attendanceController.dispose();
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
          fileUrl: 'https://example.com/invitation.pdf',
          uploadedBy: 'K.M. Harshanth',
          uploadedAt: now,
        ),
      );
    });
  }

  void _addParentConsentAttachment() {
    setState(() {
      final now = DateTime.now();
      _parentConsentAttachment = AttachmentItem(
        id: 'ATT-PARENT-${now.millisecondsSinceEpoch}',
        fileName: 'Signed_Parent_Consent.pdf',
        fileType: 'pdf',
        sizeBytes: 1024 * 420,
        fileUrl: 'https://example.com/parent_consent.pdf',
        uploadedBy: 'K.M. Harshanth',
        uploadedAt: now,
      );
      _errorMessage = null;
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
            const AppTextField(labelText: 'Start Date', hintText: '2026-08-05'),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(labelText: 'End Date', hintText: '2026-08-07'),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(labelText: 'Duration (Days)', hintText: '3 Days'),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(child: AppOutlineButton(label: 'Back', onPressed: () => setState(() => _currentStep = 1))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: AppPrimaryButton(label: 'Continue to Academic & Details', onPressed: () => setState(() => _currentStep = 3))),
              ],
            ),
          ]
          // STEP 3: DETAILS & ACADEMIC INFO
          else if (_currentStep == 3) ...[
            const AppSectionHeader(
              title: 'Step 3: Event & Academic Details',
              subtitle: 'Provide purpose, venue, CGPA, attendance, and residence type',
            ),
            const SizedBox(height: AppSpacing.md),
            AppMultilineField(controller: _purposeController, labelText: 'Purpose / Event Title'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(controller: _venueController, labelText: 'Venue Location'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(controller: _organizerController, labelText: 'Organizer / Institution'),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: AppTextField(controller: _attendanceController, labelText: 'Current Attendance %')),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: AppTextField(controller: _cgpaController, labelText: 'Current CGPA')),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Residence Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Day Scholar', style: TextStyle(fontSize: 13)),
                    value: 'Day Scholar',
                    // ignore: deprecated_member_use
                    groupValue: _residenceType,
                    activeColor: AppColors.primaryBlue,
                    // ignore: deprecated_member_use
                    onChanged: (val) => setState(() => _residenceType = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Hosteller', style: TextStyle(fontSize: 13)),
                    value: 'Hosteller',
                    // ignore: deprecated_member_use
                    groupValue: _residenceType,
                    activeColor: AppColors.primaryBlue,
                    // ignore: deprecated_member_use
                    onChanged: (val) => setState(() => _residenceType = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppMultilineField(controller: _notesController, labelText: 'Additional Notes (Optional)'),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(child: AppOutlineButton(label: 'Back', onPressed: () => setState(() => _currentStep = 2))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: AppPrimaryButton(label: 'Continue to Documents', onPressed: () => setState(() => _currentStep = 4))),
              ],
            ),
          ]
          // STEP 4: SUPPORTING & PARENT CONSENT DOCUMENTS
          else if (_currentStep == 4) ...[
            const AppSectionHeader(
              title: 'Step 4: Documents & Parent Consent',
              subtitle: 'Attach event poster/invitation letter and Parent Consent (Mandatory for Hostellers)',
            ),
            const SizedBox(height: AppSpacing.md),

            // Mandatory Parent Consent Block for Hostellers
            if (_residenceType == 'Hosteller') ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: AppColors.warning),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                        SizedBox(width: AppSpacing.xs),
                        Text('Parent Consent Upload (Mandatory for Hostellers)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.warning)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text('As a Hosteller, you must upload a signed Parent Consent Letter (PDF, PNG, or JPEG) before submitting.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.md),
                    if (_parentConsentAttachment == null)
                      AppOutlineButton(
                        label: '+ Upload Parent Consent Document',
                        prefixIcon: Icons.upload_file_rounded,
                        onPressed: _addParentConsentAttachment,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.borderSm,
                          border: Border.all(color: AppColors.success),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(child: Text(_parentConsentAttachment!.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                              onPressed: () => setState(() => _parentConsentAttachment = null),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Supporting Documents Section
            const Text('Event Invitation / Supporting Document (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: AppSpacing.xs),
            if (_attachments.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.file_present_outlined, size: 36, color: AppColors.textSecondary),
                    SizedBox(height: AppSpacing.xs),
                    Text('No invitation attachments added.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
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
            const SizedBox(height: AppSpacing.md),
            AppOutlineButton(
              label: '+ Add Event Supporting Attachment',
              prefixIcon: Icons.upload_file_outlined,
              onPressed: _addMockAttachment,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13)),
            ],

            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(child: AppOutlineButton(label: 'Back', onPressed: () => setState(() => _currentStep = 3))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Continue to Review',
                    onPressed: () {
                      if (_residenceType == 'Hosteller' && _parentConsentAttachment == null) {
                        setState(() => _errorMessage = 'Hosteller students MUST upload a Parent Consent Document before proceeding!');
                        return;
                      }
                      setState(() {
                        _errorMessage = null;
                        _currentStep = 5;
                      });
                    },
                  ),
                ),
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
                  const Text('Reason & Residence Type', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('$_selectedReason • $_residenceType', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const AppDivider(),
                  const Text('Academic Details', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('Attendance: ${_attendanceController.text}% • CGPA: ${_cgpaController.text}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const AppDivider(),
                  const Text('Event Details', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('${_purposeController.text} • ${_venueController.text}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (_residenceType == 'Hosteller') ...[
                    const AppDivider(),
                    const Text('Parent Consent Document', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(_parentConsentAttachment?.fileName ?? 'Attached', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Automatic Faculty Advisor Assignment Box
            AppInfoCard(
              title: 'Assigned Faculty Advisor (Automatic)',
              description: '${session?.assignedFacultyName ?? "Dr. Karthik B (Mock)"} - Class Counselor',
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
                      final cgpaVal = double.tryParse(_cgpaController.text) ?? 8.8;
                      final attVal = double.tryParse(_attendanceController.text) ?? 91.5;

                      ref.read(workflowControllerProvider.notifier).submitRequest(
                            studentId: session?.username ?? 'RA2511026020400',
                            studentName: session?.name ?? 'K.M. Harshanth',
                            registerNumber: session?.username ?? 'RA2511026020400',
                            reason: _selectedReason,
                            startDate: DateTime.now(),
                            endDate: DateTime.now().add(const Duration(days: 2)),
                            durationDays: 3,
                            purpose: _purposeController.text,
                            venue: _venueController.text,
                            organizer: _organizerController.text,
                            additionalNotes: _notesController.text,
                            cgpa: cgpaVal,
                            attendancePercentage: attVal,
                            residenceType: _residenceType,
                            parentConsentUrl: _parentConsentAttachment?.fileUrl,
                            attachments: _attachments,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OD Request submitted successfully! Assigned to Dr. Karthik B (Mock).')),
                      );
                      setState(() {
                        _currentStep = 1;
                        _attachments = [];
                        _parentConsentAttachment = null;
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

    return RefreshIndicator(
      onRefresh: () => ref.read(workflowControllerProvider.notifier).loadAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }
}

class _AllRequestsView extends ConsumerStatefulWidget {
  const _AllRequestsView();

  @override
  ConsumerState<_AllRequestsView> createState() => _AllRequestsViewState();
}

class _AllRequestsViewState extends ConsumerState<_AllRequestsView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final workflowState = ref.watch(workflowControllerProvider);
    final requests = workflowState.requests;

    final filtered = requests.where((r) {
      final q = _searchQuery.toLowerCase().trim();
      if (q.isEmpty) return true;
      return r.studentName.toLowerCase().contains(q) ||
          r.registerNumber.toLowerCase().contains(q) ||
          r.reason.toLowerCase().contains(q) ||
          r.purpose.toLowerCase().contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(workflowControllerProvider.notifier).loadAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('All Campus OD Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryBlue)),
            const SizedBox(height: AppSpacing.md),
            AppSearchField(
              hintText: 'Search by student name, register number, or event...',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (filtered.isEmpty)
              const AppEmptyState(title: 'No Matching Requests', description: 'No student requests match your search criteria.')
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

    return RefreshIndicator(
      onRefresh: () => ref.read(workflowControllerProvider.notifier).loadAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
    final isStudent = (session?.role ?? 'STUDENT') == 'STUDENT';

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(authControllerProvider.notifier).restoreSession();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  AppAvatarPlaceholder(name: session?.name ?? 'K.M. Harshanth', size: 72),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    session?.name ?? 'K.M. Harshanth',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Role: ${session?.role ?? 'STUDENT'} • ID: ${session?.username ?? 'RA2511026020400'}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  if (isStudent) ...[
                    _ProfileDetailRow(label: 'Program', value: session?.program ?? 'B.Tech CSE (AI & ML)'),
                    _ProfileDetailRow(label: 'Year & Section', value: session?.yearSection ?? '2nd Year - Sec G'),
                    _ProfileDetailRow(label: 'Student Email', value: session?.email ?? 'hk7793@srmist.edu.in'),
                    _ProfileDetailRow(label: 'Faculty Advisor', value: session?.assignedFacultyName ?? 'Dr. Karthik B'),
                    const _ProfileDetailRow(label: 'Campus', value: 'SRM Ramapuram Campus'),
                    const _ProfileDetailRow(label: 'Institution', value: 'SRM Institute of Science & Tech'),
                  ] else ...[
                    _ProfileDetailRow(label: 'Email', value: session?.email ?? 'karthikb@srmist.edu.in'),
                    const _ProfileDetailRow(label: 'Campus', value: 'SRM Ramapuram Campus'),
                    const _ProfileDetailRow(label: 'Institution', value: 'SRM Institute of Science & Tech'),
                    _ProfileDetailRow(label: 'Role Privilege', value: session?.role ?? 'STUDENT'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            const _BuildIdentityCard(),
            const SizedBox(height: AppSpacing.xxl),

            AppDestructiveButton(
              label: 'Sign Out of Account',
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildIdentityCard extends StatelessWidget {
  const _BuildIdentityCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.primaryBlue),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Build Identity & Environment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ProfileDetailRow(label: 'App Version', value: '2.0.0+1'),
          const _ProfileDetailRow(label: 'Commit SHA', value: 'ef2b596'),
          _ProfileDetailRow(label: 'Environment', value: kDebugMode ? 'Development' : 'Production'),
          _ProfileDetailRow(label: 'API Base URL', value: ApiConstants.baseUrl),
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
                Text(
                  '${request.id} • ${request.reason}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${request.studentName} (${request.registerNumber}) • ${request.durationDays} Days',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppStatusChip(label: request.status.displayName, statusType: request.status.statusType),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
