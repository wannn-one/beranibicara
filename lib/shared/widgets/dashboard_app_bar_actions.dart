import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/balasan/presentation/providers/balasan_notifier.dart';
import 'package:beranibicara/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:beranibicara/features/reports/presentation/providers/report_notifier.dart';
import 'package:beranibicara/shared/widgets/dialogs.dart';

class DashboardAppBarActions extends StatelessWidget {
  const DashboardAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NotificationBellButton(),
        IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: 'Profil',
          onPressed: () => context.push(AppConstants.routeProfile),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Keluar',
          onPressed: () => _signOut(context),
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final authNotifier = context.read<AuthNotifier>();
    final reportNotifier = context.read<ReportNotifier>();
    final balasanNotifier = context.read<BalasanNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    showLoadingDialog(context, message: 'Sedang keluar...');

    var success = false;
    try {
      success = await authNotifier.signOut();
    } finally {
      if (context.mounted) {
        hideLoadingDialog(context);
      }
    }

    if (!context.mounted) return;

    if (success) {
      reportNotifier.clearReports();
      balasanNotifier.reset();
      router.go(AppConstants.routeSplash);
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Gagal logout'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
