import 'package:dilexit/constants/network.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dilexit/presentation/providers/wallet_provider.dart';
import 'package:dilexit/models/wallet_activity.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final state = provider.state;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Activity',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            onPressed: () => provider.fetchActivities(),
          ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, WalletState state) {
    if (state.isLoadingActivities && state.activities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horizontal_circle_outlined,
              size: 60,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => context.read<WalletProvider>().fetchActivities(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.activities.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final activity = state.activities[index];
          return _ActivityTile(
            activity: activity,
            userAddress: state.wallet?.publicAddress ?? '',
          );
        },
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final WalletActivity activity;
  final String userAddress;

  const _ActivityTile({required this.activity, required this.userAddress});

  @override
  Widget build(BuildContext context) {
    // Determine if it's sent or received
    // In Aptos Indexer, activityType can be "deposit" or "withdraw"
    final isDeposit = activity.activityType.toLowerCase().contains('deposit');
    final amount = (activity.amount / NetworkConstants.octasPerApt).toStringAsFixed(4);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isDeposit
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            child: Icon(
              isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isDeposit ? Colors.greenAccent : Colors.orangeAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeposit ? 'Received' : 'Sent',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Version: ${activity.transactionVersion}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDeposit ? '+' : '-'}$amount APT',
                style: TextStyle(
                  color: isDeposit ? Colors.greenAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                activity.isTransactionSuccess ? 'Success' : 'Failed',
                style: TextStyle(
                  color: activity.isTransactionSuccess
                      ? Colors.grey
                      : Colors.redAccent,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
