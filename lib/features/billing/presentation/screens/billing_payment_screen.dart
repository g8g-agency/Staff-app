// lib/features/billing/presentation/screens/billing_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/money.dart';
import '../../../orders/presentation/state/active_order_notifier.dart';

class BillingPaymentScreen extends ConsumerStatefulWidget {
  final String tableId;

  const BillingPaymentScreen({
    super.key,
    required this.tableId,
  });

  @override
  ConsumerState<BillingPaymentScreen> createState() => _BillingPaymentScreenState();
}

class _BillingPaymentScreenState extends ConsumerState<BillingPaymentScreen> {
  double _tipPercentage = 0.15;
  String _paymentMethod = 'Card';

  @override
  Widget build(BuildContext context) {
    final activeOrderAsync = ref.watch(activeOrderNotifierProvider(widget.tableId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Table ${widget.tableId} - Settlement Checkout'),
      ),
      body: activeOrderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error loading billing summary: $err')),
        data: (order) {
          if (order == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.success),
                  const SizedBox(height: 16),
                  Text('No outstanding balances found for this table.', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Return to Floor Layout'),
                  ),
                ],
              ),
            );
          }

          // Financial Math
          final subtotalCents = order.totalPrice.amountInCents;
          final taxCents = (subtotalCents * 0.08).round();
          final serviceCents = (subtotalCents * 0.10).round();
          final tipCents = (subtotalCents * _tipPercentage).round();
          final grandTotalCents = subtotalCents + taxCents + serviceCents + tipCents;

          final subtotal = Money(amountInCents: subtotalCents);
          final tax = Money(amountInCents: taxCents);
          final service = Money(amountInCents: serviceCents);
          final tip = Money(amountInCents: tipCents);
          final total = Money(amountInCents: grandTotalCents);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Item Details
                Card(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Ledger Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Divider(),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: order.items.length,
                          itemBuilder: (context, index) {
                            final item = order.items[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('${item.quantity}x ${item.product.name}'),
                              subtitle: item.selectedModifiers.isEmpty
                                  ? null
                                  : Text(item.selectedModifiers.map((m) => m.name).join(', ')),
                              trailing: Text(item.totalPrice.formatted, style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tip Options
                Text('Gratuity Selection', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    ...[0.10, 0.15, 0.20, 0.25].map((pct) {
                      final isSelected = _tipPercentage == pct;
                      return ChoiceChip(
                          selected: isSelected,
                          label: Text('${(pct * 100).toInt()}%'),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _tipPercentage = pct;
                              });
                            }
                          },
                        );
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // Payment Method
                Text('Payment Gateway Options', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    ...['Card', 'Cash', 'Mobile Pay'].map((method) {
                      final isSelected = _paymentMethod == method;
                      return ChoiceChip(
                          selected: isSelected,
                          label: Text(method),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _paymentMethod = method;
                              });
                            }
                          },
                        );
                    }),
                  ],
                ),
                const SizedBox(height: 24),

                // Financial Breakdown
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Subtotal', subtotal.formatted, theme),
                      _buildSummaryRow('Tax (8%)', tax.formatted, theme),
                      _buildSummaryRow('Service (10%)', service.formatted, theme),
                      _buildSummaryRow('Tip', tip.formatted, theme),
                      const Divider(),
                      _buildSummaryRow('Total Balance', total.formatted, theme, isBold: true, isPrimary: true),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Checkout Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      await ref.read(activeOrderNotifierProvider(widget.tableId).notifier).payAndComplete();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Payment processed via $_paymentMethod! Table resetting to cleaning state.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        context.pop();
                      }
                    },
                    child: Text(
                      _splitCount > 1
                          ? 'Collect Payment (${splitShare.formatted} each)'
                          : 'Process Payment (${total.formatted})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String val, ThemeData theme, {bool isBold = false, bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isPrimary ? 18 : 14,
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isPrimary ? AppColors.primary : null,
              fontSize: isPrimary ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
