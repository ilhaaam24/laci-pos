/// Sync status for individual records in the local database.
/// Tracks whether a record has been synchronized with Firebase.
enum SyncStatus {
  /// Data is in sync with Firebase
  synced,

  /// Data was created/updated locally, pending upload to Firebase
  pendingUpload,

  /// Data was deleted locally, pending deletion from Firebase
  pendingDelete,
}

/// Extension to convert SyncStatus to/from string for database storage.
extension SyncStatusX on SyncStatus {
  String get value => name;

  static SyncStatus fromString(String? value) {
    switch (value) {
      case 'synced':
        return SyncStatus.synced;
      case 'pendingUpload':
        return SyncStatus.pendingUpload;
      case 'pendingDelete':
        return SyncStatus.pendingDelete;
      default:
        return SyncStatus.synced;
    }
  }
}

/// Overall sync state for the application UI.
enum AppSyncState {
  /// All data is synced, connection is online
  idle,

  /// Currently syncing data
  syncing,

  /// There are pending operations to sync
  pending,

  /// Device is offline
  offline,

  /// Sync failed with an error
  error,
}
