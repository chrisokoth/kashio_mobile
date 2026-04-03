import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/transaction_provider.dart';
import '../../../features/auth/auth_provider.dart';
import 'widgets/sms_card.dart';
import 'widgets/summary_widget.dart';

class SmsScreen extends StatelessWidget {
  const SmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundGrey,
          appBar: AppBar(
            title: const Text('Kashio'),
            actions: [
              if (provider.loadState == LoadState.loaded)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list_rounded),
                  onSelected: provider.setFilter,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'ALL', child: Text('All')),
                    PopupMenuItem(value: 'INCOME', child: Text('Income')),
                    PopupMenuItem(value: 'EXPENSE', child: Text('Expenses')),
                  ],
                ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () => _showLogoutDialog(context),
              ),
            ],
          ),
          body: _buildBody(context, provider),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: provider.isSyncing || provider.loadState == LoadState.loading
                ? null
                : provider.syncToBackend,
            icon: provider.isSyncing || provider.loadState == LoadState.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_rounded),
            label: Text(
              provider.isSyncing
                  ? 'Syncing...'
                  : provider.loadState == LoadState.loading
                      ? 'Reading SMS...'
                      : 'Sync Messages',
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TransactionProvider provider) {
    if (provider.loadState == LoadState.idle) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_rounded,
                  size: 80, color: AppTheme.primaryGreen),
              SizedBox(height: 24),
              Text(
                'Sync your M-PESA messages',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Press "Sync Messages" below to read your M-PESA SMS and send them to Kashio.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
              ElevatedButton.icon(
                onPressed: provider.syncToBackend,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // LoadState.loaded
    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: provider.syncToBackend,
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
                    Icon(Icons.inbox_rounded,
                        size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    const Text('No M-PESA transactions found',
                        style: TextStyle(color: AppTheme.textSecondary)),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Logout',
                style: TextStyle(color: AppTheme.expenseRed)),
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