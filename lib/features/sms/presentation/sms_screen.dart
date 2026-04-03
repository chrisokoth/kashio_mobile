import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/transaction_provider.dart';
import '../../../features/auth/auth_provider.dart';
import 'widgets/sms_card.dart';
import 'widgets/summary_widget.dart';
import '../../auth/auth_screen.dart';

class SmsScreen extends StatefulWidget {
  const SmsScreen({super.key});

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, AuthProvider>(
      builder: (context, provider, authProvider, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundGrey,
          appBar: AppBar(
            title: const Text('Kashio'),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list_rounded),
                onSelected: provider.setFilter,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'ALL', child: Text('All')),
                  PopupMenuItem(value: 'INCOME', child: Text('Income')),
                  PopupMenuItem(value: 'EXPENSE', child: Text('Expenses')),
                ],
              ),
              if (authProvider.status == AuthStatus.authenticated)
                IconButton(
                  icon: const Icon(Icons.person_rounded),
                  onPressed: () => _showAccountDialog(context, authProvider),
                )
              else
                TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                    // Reload after login
                    if (mounted) {
                      context.read<TransactionProvider>().loadTransactions();
                    }
                  },
                  child: const Text('Login',
                      style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
          body: _buildBody(context, provider),
          floatingActionButton: authProvider.status == AuthStatus.authenticated
              ? FloatingActionButton.extended(
                  onPressed: provider.isSyncing ? null : provider.syncToBackend,
                  icon: provider.isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(provider.isSyncing ? 'Syncing...' : 'Sync'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TransactionProvider provider) {
    if (provider.loadState == LoadState.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            SizedBox(height: 16),
            Text('Reading M-PESA messages...',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    if (provider.loadState == LoadState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: AppTheme.expenseRed),
              const SizedBox(height: 16),
              Text(
                provider.error ?? 'An error occurred',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              if (provider.permissionDeniedPermanently)
                ElevatedButton.icon(
                  onPressed: () async {
                    await ph.openAppSettings();
                  },
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text('Open App Settings'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white),
                )
              else
                ElevatedButton.icon(
                  onPressed: provider.loadTransactions,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: provider.loadTransactions,
      child: CustomScrollView(
        slivers: [
          if (provider.syncMessage != null)
            SliverToBoxAdapter(
              child: _SyncBanner(message: provider.syncMessage!),
            ),
          const SliverToBoxAdapter(child: SummaryWidget()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${provider.transactions.length} Transactions',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (provider.filter != 'ALL')
                    Chip(
                      label: Text(provider.filter,
                          style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => provider.setFilter('ALL'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    ),
                ],
              ),
            ),
          ),
          if (provider.transactions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    const Text('No M-PESA transactions found',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: provider.loadTransactions,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reload'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => SmsCard(transaction: provider.transactions[i]),
                childCount: provider.transactions.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  void _showAccountDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Account'),
        content: const Text(
            'You are logged in to Kashio.\nSync transactions using the button below.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.logout();
            },
            child: const Text('Logout',
                style: TextStyle(color: AppTheme.expenseRed)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  final String message;
  const _SyncBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final isSuccess = message.startsWith('✓');
    return Container(
      color: isSuccess
          ? AppTheme.incomeGreen.withOpacity(0.1)
          : AppTheme.expenseRed.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            color: isSuccess ? AppTheme.incomeGreen : AppTheme.expenseRed,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isSuccess ? AppTheme.incomeGreen : AppTheme.expenseRed,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}