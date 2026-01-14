/// Model for trashed items.
/// Stores deletion timestamp for auto-cleanup after a retention period.
class TrashDetails {
  final int id; // References AvesEntry.contentId
  final String? path; // Original path before deletion
  final int dateMillis; // Deletion timestamp

  TrashDetails({required this.id, this.path, required this.dateMillis});

  factory TrashDetails.fromMap(Map<String, dynamic> map) {
    return TrashDetails(
      id: map['id'] as int,
      path: map['path'] as String?,
      dateMillis: map['dateMillis'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'path': path, 'dateMillis': dateMillis};
  }

  DateTime get deletionDate => DateTime.fromMillisecondsSinceEpoch(dateMillis);

  /// Checks if this item should be auto-deleted (older than 30 days)
  bool get shouldAutoDelete {
    final daysSinceDeletion = DateTime.now().difference(deletionDate).inDays;
    return daysSinceDeletion > 30;
  }
}
