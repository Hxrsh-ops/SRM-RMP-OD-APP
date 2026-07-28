import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../authentication/authentication.dart';

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

    final List<Widget> pages = [
      _HomeDashboardView(onNavigate: (index) => setState(() => _currentIndex = index)),
      const _MyRequestsView(),
      const _CreateOdRequestFlowView(),
      const _NotificationsView(),
      const _ProfileView(),
      const _SettingsView(),
    ];

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
          index: _currentIndex < 5 ? _currentIndex : 0,
          children: pages.sublist(0, 5),
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
// TAB 0: HOME DASHBOARD VIEW
// -----------------------------------------------------------------------------
class _HomeDashboardView extends ConsumerWidget {
  final ValueChanged<int> onNavigate;

  const _HomeDashboardView({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).session;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue Student Header Card (UI Kit Specification Section 10)
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
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${session?.role ?? 'STUDENT'} • ${session?.username ?? 'RA2111003010001'}',
                            style: const TextStyle(
                              color: AppColors.accentYellow,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.show_chart_rounded, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DesignSystemShowcase()),
                        );
                      },
                      tooltip: 'UI Showcase',
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
                      _ScheduleCard(
                        subject: 'Physics Lab',
                        time: '10:30 AM',
                        venue: 'Room 301',
                      ),
                      SizedBox(width: AppSpacing.md),
                      _ScheduleCard(
                        subject: 'DEMS Workshop',
                        time: '01:30 PM',
                        venue: 'Lab 04',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Overview Metric Stats Grid
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
                        value: '05',
                        subtext: 'Requests',
                        accentColor: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _SummaryStatCard(
                        title: 'Pending',
                        value: '02',
                        subtext: 'Need Attention',
                        accentColor: AppColors.warning,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Quick Actions Grid
                const Text(
                  'QUICK ACTIONS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuickActionButton(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Create OD',
                      onTap: () => onNavigate(2),
                    ),
                    _QuickActionButton(
                      icon: Icons.assignment_outlined,
                      label: 'My ODs',
                      onTap: () => onNavigate(1),
                    ),
                    _QuickActionButton(
                      icon: Icons.history_rounded,
                      label: 'Timeline',
                      onTap: () {},
                    ),
                    _QuickActionButton(
                      icon: Icons.notifications_active_outlined,
                      label: 'Alerts',
                      onTap: () => onNavigate(3),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Recent OD Requests Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent OD Requests',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    AppTextButton(
                      label: 'View All',
                      size: AppButtonSize.small,
                      onPressed: () => onNavigate(1),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _RecentOdTile(
                  title: 'National Hackathon 2026',
                  dates: 'Jul 24 - Jul 26, 2026',
                  status: 'Approved',
                  statusType: AppStatusType.approved,
                ),
                const SizedBox(height: AppSpacing.md),
                _RecentOdTile(
                  title: 'SRM Sports Tournament',
                  dates: 'Jul 21, 2026',
                  status: 'Pending HOD',
                  statusType: AppStatusType.pending,
                ),
                const SizedBox(height: AppSpacing.md),
                _RecentOdTile(
                  title: 'Workshop on AI & ML',
                  dates: 'Jul 22, 2026',
                  status: 'Approved',
                  statusType: AppStatusType.approved,
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Upcoming OD Events Card
                Text(
                  'UPCOMING EVENTS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: AppRadius.borderMd,
                        ),
                        child: const Icon(Icons.event_outlined, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Technical Symposium 2026',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Jul 28, 2026 • SRM Ramapuram Campus',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
// TAB 1: MY OD REQUESTS VIEW
// -----------------------------------------------------------------------------
class _MyRequestsView extends StatefulWidget {
  const _MyRequestsView();

  @override
  State<_MyRequestsView> createState() => _MyRequestsViewState();
}

class _MyRequestsViewState extends State<_MyRequestsView> {
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

          // Search Field
          AppSearchField(
            hintText: 'Search requests...',
            onChanged: (query) {},
          ),
          const SizedBox(height: AppSpacing.lg),

          // Filter Chips Row (UI Kit Section 07)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AppFilterChip(
                  label: 'All',
                  isSelected: _selectedFilterIndex == 0,
                  onTap: () => setState(() => _selectedFilterIndex = 0),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppFilterChip(
                  label: 'Pending',
                  isSelected: _selectedFilterIndex == 1,
                  onTap: () => setState(() => _selectedFilterIndex = 1),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppFilterChip(
                  label: 'Approved',
                  isSelected: _selectedFilterIndex == 2,
                  onTap: () => setState(() => _selectedFilterIndex = 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppFilterChip(
                  label: 'Rejected',
                  isSelected: _selectedFilterIndex == 3,
                  onTap: () => setState(() => _selectedFilterIndex = 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // List of OD Cards
          _RecentOdTile(
            title: 'National Hackathon 2026',
            dates: 'Jul 24 - Jul 26, 2026 (2 Days)',
            status: 'Approved',
            statusType: AppStatusType.approved,
          ),
          const SizedBox(height: AppSpacing.md),
          _RecentOdTile(
            title: 'SRM Sports Tournament',
            dates: 'Jul 21, 2026 (1 Day)',
            status: 'Pending',
            statusType: AppStatusType.pending,
          ),
          const SizedBox(height: AppSpacing.md),
          _RecentOdTile(
            title: 'Workshop on AI & ML',
            dates: 'Jul 22, 2026 (1 Day)',
            status: 'Approved',
            statusType: AppStatusType.approved,
          ),
          const SizedBox(height: AppSpacing.md),
          _RecentOdTile(
            title: 'Industry Visit - Tech Park',
            dates: 'Jul 15, 2026 (1 Day)',
            status: 'Rejected',
            statusType: AppStatusType.error,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: CREATE OD REQUEST FLOW VIEW (4-STEP SPECIFICATION)
// -----------------------------------------------------------------------------
class _CreateOdRequestFlowView extends StatefulWidget {
  const _CreateOdRequestFlowView();

  @override
  State<_CreateOdRequestFlowView> createState() => _CreateOdRequestFlowViewState();
}

class _CreateOdRequestFlowViewState extends State<_CreateOdRequestFlowView> {
  int _currentStep = 1;
  String _selectedReason = 'Hackathon / Competition';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            'Step $_currentStep of 4',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4-Step Progress Indicator
          Row(
            children: List.generate(4, (index) {
              final stepNum = index + 1;
              final isActive = stepNum <= _currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 3 ? AppSpacing.xs : 0),
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

          // STEP CONTENT
          if (_currentStep == 1) ...[
            const AppSectionHeader(
              title: 'Step 1: Reason',
              subtitle: 'What is the reason for your On Duty request?',
            ),
            const SizedBox(height: AppSpacing.md),
            _ReasonRadioTile(
              title: 'Hackathon / Competition',
              value: 'Hackathon / Competition',
              groupValue: _selectedReason,
              onChanged: (val) => setState(() => _selectedReason = val!),
            ),
            _ReasonRadioTile(
              title: 'Seminar / Workshop',
              value: 'Seminar / Workshop',
              groupValue: _selectedReason,
              onChanged: (val) => setState(() => _selectedReason = val!),
            ),
            _ReasonRadioTile(
              title: 'Sports Event',
              value: 'Sports Event',
              groupValue: _selectedReason,
              onChanged: (val) => setState(() => _selectedReason = val!),
            ),
            _ReasonRadioTile(
              title: 'Placement Activity',
              value: 'Placement Activity',
              groupValue: _selectedReason,
              onChanged: (val) => setState(() => _selectedReason = val!),
            ),
            _ReasonRadioTile(
              title: 'Others',
              value: 'Others',
              groupValue: _selectedReason,
              onChanged: (val) => setState(() => _selectedReason = val!),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppPrimaryButton(
              label: 'Continue',
              onPressed: () => setState(() => _currentStep = 2),
            ),
          ] else if (_currentStep == 2) ...[
            const AppSectionHeader(
              title: 'Step 2: Date & Duration',
              subtitle: 'Select start date, end date, and total days',
            ),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(labelText: 'Start Date', hintText: '24 July 2026'),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(labelText: 'End Date', hintText: '25 July 2026'),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(labelText: 'Duration', hintText: '2 Days'),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: AppOutlineButton(
                    label: 'Back',
                    onPressed: () => setState(() => _currentStep = 1),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Continue',
                    onPressed: () => setState(() => _currentStep = 3),
                  ),
                ),
              ],
            ),
          ] else if (_currentStep == 3) ...[
            const AppSectionHeader(
              title: 'Step 3: Details',
              subtitle: 'Provide additional event details and faculty in-charge',
            ),
            const SizedBox(height: AppSpacing.md),
            const AppMultilineField(
              labelText: 'Purpose / Description',
              hintText: 'Participating in National Level Hackathon',
            ),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(labelText: 'Organizer', hintText: 'Tech Park, Chennai'),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(labelText: 'Faculty in-charge', hintText: 'Dr. Karthik B'),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: AppOutlineButton(
                    label: 'Back',
                    onPressed: () => setState(() => _currentStep = 2),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Continue',
                    onPressed: () => setState(() => _currentStep = 4),
                  ),
                ),
              ],
            ),
          ] else ...[
            const AppSectionHeader(
              title: 'Step 4: Review',
              subtitle: 'Please review your request before submitting',
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reason', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(_selectedReason, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Divider(height: 24),
                  const Text('Dates', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const Text('Jul 24 - Jul 25, 2026 (2 Days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Divider(height: 24),
                  const Text('Organizer', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const Text('Tech Park, Chennai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Divider(height: 24),
                  const Text('Faculty in-charge', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const Text('Dr. Karthik B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: AppOutlineButton(
                    label: 'Back',
                    onPressed: () => setState(() => _currentStep = 3),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Submit Request',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OD Request submitted successfully!')),
                      );
                      setState(() => _currentStep = 1);
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
// TAB 3: NOTIFICATIONS VIEW
// -----------------------------------------------------------------------------
class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  bool _showEmptyState = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_showEmptyState) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              AppEmptyState(
                title: 'No Notifications Yet',
                description: "You'll see notification updates here when your OD status changes.",
                onAction: () => setState(() => _showEmptyState = false),
                actionLabel: 'Show Notifications',
              ),
            ],
          ),
        ),
      );
    }

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
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              AppTextButton(
                label: 'Mark all as read',
                size: AppButtonSize.small,
                onPressed: () => setState(() => _showEmptyState = true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _NotificationTile(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.success,
            title: 'Your OD request has been approved',
            subtitle: 'National Hackathon 2026',
            time: '2m ago',
          ),
          const SizedBox(height: AppSpacing.md),
          _NotificationTile(
            icon: Icons.hourglass_top_rounded,
            iconColor: AppColors.warning,
            title: 'SRM Sports Tournament',
            subtitle: 'Your request is pending HOD approval',
            time: '1h ago',
          ),
          const SizedBox(height: AppSpacing.md),
          _NotificationTile(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.success,
            title: 'Workshop on AI & ML',
            subtitle: 'Your request has been approved',
            time: '3h ago',
          ),
          const SizedBox(height: AppSpacing.md),
          _NotificationTile(
            icon: Icons.notifications_none_rounded,
            iconColor: AppColors.primaryLight,
            title: 'Reminder: Faculty Review Meeting',
            subtitle: 'Tomorrow at 10:00 AM',
            time: '5h ago',
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 4: PROFILE VIEW
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
                AppAvatarPlaceholder(
                  name: session?.name ?? 'Alex Vance',
                  size: 72,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  session?.name ?? 'Alex Vance',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${session?.role ?? 'STUDENT'} • ${session?.username ?? 'RA2111003010001'}',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                _ProfileDetailRow(label: 'Campus', value: 'SRM Ramapuram Campus'),
                _ProfileDetailRow(label: 'Department', value: 'Computer Science & Engineering'),
                _ProfileDetailRow(label: 'Workflow Role', value: session?.role ?? 'STUDENT'),
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

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Settings Placeholder'),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HELPER SUB-WIDGETS
// -----------------------------------------------------------------------------
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.borderMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 12, color: AppColors.primaryLight),
              const SizedBox(width: 4),
              Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 2),
          Text(venue, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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

  const _SummaryStatCard({
    required this.title,
    required this.value,
    required this.subtext,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: accentColor),
          ),
          Text(subtext, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppRadius.borderMd,
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _RecentOdTile extends StatelessWidget {
  final String title;
  final String dates;
  final String status;
  final AppStatusType statusType;

  const _RecentOdTile({
    required this.title,
    required this.dates,
    required this.status,
    required this.statusType,
  });

  @override
  Widget build(BuildContext context) {
    return AppClickableCard(
      onTap: () {},
      child: Row(
        children: [
          const Icon(Icons.assignment_outlined, color: AppColors.primaryBlue, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(dates, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          AppStatusChip(label: status, statusType: statusType),
        ],
      ),
    );
  }
}

class _ReasonRadioTile extends StatelessWidget {
  final String title;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _ReasonRadioTile({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      value: value,
      groupValue: groupValue,
      activeColor: AppColors.primaryBlue,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  const _NotificationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
