import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/sms_model.dart';

class SmsCard extends StatelessWidget {
  final Transaction transaction;

  const SmsCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final amountColor = isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed;
    final amountPrefix = isIncome ? '+' : '-';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeIcon(type: transaction.type, isIncome: isIncome),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transaction.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$amountPrefix${Formatters.formatAmount(transaction.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: amountColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            transaction.typeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: amountColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (transaction.counterpartyPhone != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            transaction.counterpartyPhone!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Formatters.formatRelativeDate(transaction.dateTime),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (transaction.balanceAfter != null &&
                            transaction.balanceAfter! > 0) ...[
                          const Spacer(),
                          Text(
                            'Bal: ${Formatters.formatAmount(transaction.balanceAfter!)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TransactionDetail(transaction: transaction),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final String type;
  final bool isIncome;

  const _TypeIcon({required this.type, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (type) {
      case 'SENT': icon = Icons.arrow_upward_rounded; break;
      case 'RECEIVED': icon = Icons.arrow_downward_rounded; break;
      case 'PAYBILL': icon = Icons.receipt_long_rounded; break;
      case 'BUY_GOODS': icon = Icons.shopping_bag_rounded; break;
      case 'AIRTIME': icon = Icons.phone_android_rounded; break;
      case 'WITHDRAWAL': icon = Icons.atm_rounded; break;
      case 'MSHWARI_DEPOSIT':
      case 'MSHWARI_LOAN': icon = Icons.savings_rounded; break;
      case 'FULIZA_CHARGE':
      case 'FULIZA_REPAYMENT': icon = Icons.account_balance_rounded; break;
      case 'POCHI': icon = Icons.storefront_rounded; break;
      case 'REVERSAL': icon = Icons.undo_rounded; break;
      case 'GLOBAL': icon = Icons.language_rounded; break;
      default: icon = Icons.swap_horiz_rounded;
    }

    final color = isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _TransactionDetail extends StatelessWidget {
  final Transaction transaction;

  const _TransactionDetail({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                transaction.displayName,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${transaction.isIncome ? '+' : '-'}${Formatters.formatAmount(transaction.amount)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: transaction.isIncome
                      ? AppTheme.incomeGreen
                      : AppTheme.expenseRed,
                ),
              ),
              const Divider(height: 24),
              _DetailRow('Type', transaction.typeLabel),
              _DetailRow('Code', transaction.transactionCode),
              _DetailRow('Date',
                  Formatters.formatDateTime(transaction.dateTime)),
              if (transaction.counterpartyPhone != null)
                _DetailRow('Phone', transaction.counterpartyPhone!),
              if (transaction.balanceAfter != null)
                _DetailRow('Balance After',
                    Formatters.formatAmount(transaction.balanceAfter!)),
              if (transaction.transactionCost != null &&
                  transaction.transactionCost! > 0)
                _DetailRow('Transaction Cost',
                    Formatters.formatAmount(transaction.transactionCost!)),
              const SizedBox(height: 12),
              const Text('Raw Message',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  transaction.rawMessage,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}