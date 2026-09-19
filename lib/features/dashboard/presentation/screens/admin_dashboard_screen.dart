import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/shared/widgets/dashboard_app_bar_actions.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthNotifier>().user?.displayName ?? 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: const [DashboardAppBarActions()],
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Admin\n$userName!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Admin Actions
                  _buildAdminCard(
                    context,
                    icon: Icons.people,
                    title: 'User Management',
                    subtitle: 'Manage users, roles, and permissions',
                    onTap: () {
                      context.push(AppConstants.routeAdminUsers);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildAdminCard(
                    context,
                    icon: Icons.report,
                    title: 'All Reports',
                    subtitle: 'View and manage all reports',
                    onTap: () {
                      context.push(AppConstants.routeReports);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildAdminCard(
                    context,
                    icon: Icons.class_,
                    title: 'Kelas Management',
                    subtitle: 'Manage classes and assignments',
                    onTap: () {
                      context.push(AppConstants.routeAdminKelas);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildAdminCard(
                    context,
                    icon: Icons.campaign,
                    title: 'Sosialisasi',
                    subtitle: 'Materi pencegahan untuk seluruh sekolah',
                    onTap: () {
                      context.push(AppConstants.routeSocialization);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildAdminCard(
                    context,
                    icon: Icons.analytics,
                    title: 'Statistics',
                    subtitle: 'View app statistics and analytics',
                    onTap: () {
                      context.push(AppConstants.routeAdminStats);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildAdminCard(
                    context,
                    icon: Icons.settings,
                    title: 'System Settings',
                    subtitle: 'Configure app settings',
                    onTap: () {
                      context.push(AppConstants.routeAdminSettings);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
