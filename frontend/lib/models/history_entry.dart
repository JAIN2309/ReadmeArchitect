/// Data model for a history entry returned by the backend.
library;

class HistoryEntry {
  final int id;
  final String githubUrl;
  final String repoOwner;
  final String repoName;
  final String presentationMode;
  final String markdown;
  final String createdAt;

  const HistoryEntry({
    required this.id,
    required this.githubUrl,
    required this.repoOwner,
    required this.repoName,
    required this.presentationMode,
    required this.markdown,
    required this.createdAt,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as int,
      githubUrl: json['github_url'] as String,
      repoOwner: json['repo_owner'] as String,
      repoName: json['repo_name'] as String,
      presentationMode: json['presentation_mode'] as String,
      markdown: json['markdown'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  /// Human-readable time label (e.g., "2 min ago", "1 hr ago").
  String get timeAgo {
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().toUtc().difference(dt);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return createdAt;
    }
  }
}
