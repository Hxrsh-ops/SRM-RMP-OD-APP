import 'package:flutter/material.dart';
import '../buttons/ui_buttons.dart';
import '../cards/ui_cards.dart';
import '../chips/ui_chips.dart';
import '../dialogs/ui_dialogs.dart';
import '../feedback/ui_feedback.dart';
import '../inputs/ui_inputs.dart';
import '../layout/ui_layout.dart';
import '../../theme/tokens/theme_tokens.dart';

class DesignSystemShowcase extends StatefulWidget {
  const DesignSystemShowcase({super.key});

  @override
  State<DesignSystemShowcase> createState() => _DesignSystemShowcaseState();
}

class _DesignSystemShowcaseState extends State<DesignSystemShowcase> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _multilineController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    _multilineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design System Showcase'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppPageHeader(
              title: 'Design System Library',
              subtitle: 'Milestone 1.5 - Reusable Production Components Showcase',
            ),

            // SECTION 1: BUTTONS
            const AppSectionHeader(
              title: 'Buttons',
              subtitle: 'Primary, Secondary, Text, Destructive & Loading variants',
            ),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                AppPrimaryButton(label: 'Primary Button', onPressed: () {}),
                AppSecondaryButton(label: 'Secondary Button', onPressed: () {}),
                AppTextButton(label: 'Text Button', onPressed: () {}),
                AppDestructiveButton(label: 'Destructive', onPressed: () {}),
                const AppPrimaryButton(label: 'Loading...', isLoading: true),
                const AppPrimaryButton(label: 'Disabled', isDisabled: true),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            const AppDivider(),

            // SECTION 2: INPUTS
            const AppSectionHeader(
              title: 'Inputs',
              subtitle: 'Text, Password, Search & Multiline form fields',
            ),
            AppTextField(
              controller: _textController,
              labelText: 'Full Name',
              hintText: 'Enter your official name',
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: AppSpacing.md),
            AppPasswordField(
              controller: _passwordController,
            ),
            const SizedBox(height: AppSpacing.md),
            AppSearchField(
              controller: _searchController,
              hintText: 'Search requests or users...',
            ),
            const SizedBox(height: AppSpacing.md),
            AppMultilineField(
              controller: _multilineController,
              labelText: 'Reason for On-Duty Request',
              hintText: 'Provide detailed justification...',
            ),
            const SizedBox(height: AppSpacing.xxl),
            const AppDivider(),

            // SECTION 3: CARDS
            const AppSectionHeader(
              title: 'Cards',
              subtitle: 'Flat, Clickable & Elevated cards',
            ),
            const AppCard(
              child: Text('Standard Flat AppCard container with subtle border.'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppClickableCard(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Clickable Card Tapped!')),
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.touch_app_outlined),
                  SizedBox(width: AppSpacing.md),
                  Text('Interactive Clickable Card (Scale & Hover)'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const AppElevatedCard(
              child: Text('Elevated Card container with low shadow token.'),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const AppDivider(),

            // SECTION 4: CHIPS
            const AppSectionHeader(
              title: 'Status Chips',
              subtitle: 'Domain status indicators',
            ),
            const Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppStatusChip(label: 'Approved', statusType: AppStatusType.approved),
                AppStatusChip(label: 'Pending', statusType: AppStatusType.pending),
                AppStatusChip(label: 'Rejected', statusType: AppStatusType.rejected),
                AppStatusChip(label: 'Success', statusType: AppStatusType.success),
                AppStatusChip(label: 'Warning', statusType: AppStatusType.warning),
                AppStatusChip(label: 'Error', statusType: AppStatusType.error),
                AppStatusChip(label: 'Info', statusType: AppStatusType.info),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            const AppDivider(),

            // SECTION 5: DIALOGS
            const AppSectionHeader(
              title: 'Dialogs',
              subtitle: 'Confirmation, Error & Success modals',
            ),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                AppSecondaryButton(
                  label: 'Show Confirmation',
                  onPressed: () {
                    AppConfirmationDialog.show(
                      context,
                      title: 'Cancel Request?',
                      message: 'Are you sure you want to cancel this OD request?',
                      isDestructive: true,
                    );
                  },
                ),
                AppSecondaryButton(
                  label: 'Show Error Dialog',
                  onPressed: () {
                    AppErrorDialog.show(
                      context,
                      message: 'Failed to submit OD form. Please check network.',
                    );
                  },
                ),
                AppSecondaryButton(
                  label: 'Show Success Dialog',
                  onPressed: () {
                    AppSuccessDialog.show(
                      context,
                      message: 'OD Request submitted successfully to Class Counselor.',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            const AppDivider(),

            // SECTION 6: FEEDBACK & LAYOUT
            const AppSectionHeader(
              title: 'Feedback & Layout',
              subtitle: 'Skeletons, Badges, Avatars & Empty States',
            ),
            const Row(
              children: [
                AppAvatarPlaceholder(name: 'Srm User'),
                SizedBox(width: AppSpacing.md),
                AppBadge(
                  label: '3',
                  child: Icon(Icons.notifications_outlined, size: 28),
                ),
                SizedBox(width: AppSpacing.xl),
                AppSkeletonLoader.circular(size: 40),
                SizedBox(width: AppSpacing.md),
                AppSkeletonLoader.rectangular(width: 120, height: 20),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppEmptyState(
              title: 'No Pending Requests',
              description: 'You have no active On-Duty requests submitted for review.',
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
