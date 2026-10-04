import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laci/core/constants/sync_status.dart';
import 'package:laci/core/di/injection.dart';
import 'package:laci/core/services/sync_service.dart';
import 'package:laci/core/style/app_colors.dart';
import '../blocs/business/business_bloc.dart';
import 'upgrade_pro_sheet.dart';

/// A widget that displays the current synchronization status.
/// It listens to the SyncService and shows different icons/colors
/// based on whether the app is online, syncing, or offline.
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final businessInfo = context.watch<BusinessBloc>().state.businessInfo;
    final isPro = businessInfo?.isPro ?? false;

    if (!isPro) {
      return IconButton(
        onPressed: () => showUpgradeProSheet(
          context,
          featureName: 'Cloud Backup & Multi-Perangkat',
        ),
        tooltip: 'Fitur Pro: Cloud Backup & Multi-Perangkat',
        icon: const Icon(
          Icons.cloud_queue_rounded,
          color: Colors.grey,
          size: 20,
        ),
      );
    }

    final syncService = getIt<SyncService>();

    return StreamBuilder<AppSyncState>(
      stream: syncService.syncState,
      initialData: syncService.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? AppSyncState.idle;

        return IconButton(
          onPressed: () => _handleSyncAction(context, syncService, state),
          tooltip: _getTooltip(state),
          icon: _buildIcon(state),
        );
      },
    );
  }

  Widget _buildIcon(AppSyncState state) {
    switch (state) {
      case AppSyncState.idle:
        return const Icon(Icons.cloud_done, color: Colors.green, size: 20);
      case AppSyncState.syncing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
      case AppSyncState.offline:
        return const Icon(Icons.cloud_off, color: Colors.grey, size: 20);
      case AppSyncState.pending:
        return const Icon(Icons.cloud_upload, color: Colors.orange, size: 20);
      case AppSyncState.error:
        return const Icon(Icons.sync_problem, color: AppColors.error, size: 20);
    }
  }

  String _getTooltip(AppSyncState state) {
    switch (state) {
      case AppSyncState.idle:
        return 'Tersinkronisasi';
      case AppSyncState.syncing:
        return 'Sedang menyinkronkan...';
      case AppSyncState.pending:
        return 'Menunggu sinkronisasi';
      case AppSyncState.offline:
        return 'Mode Offline';
      case AppSyncState.error:
        return 'Gagal sinkronisasi';
    }
  }

  void _handleSyncAction(
    BuildContext context,
    SyncService service,
    AppSyncState state,
  ) {
    if (state == AppSyncState.offline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Anda sedang offline. Sinkronisasi akan berlanjut saat internet tersedia.',
          ),
        ),
      );
    } else if (state == AppSyncState.idle || state == AppSyncState.error) {
      service.fullSync();
    }
  }
}
