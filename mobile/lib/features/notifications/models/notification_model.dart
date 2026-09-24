class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.kind,
    required this.message,
    required this.isRead,
    this.actorUsername,
    this.postId,
  });

  final int id;
  final String kind;
  final String message;
  final bool isRead;
  final String? actorUsername;
  final int? postId;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;
    return NotificationModel(
      id: json['id'] as int,
      kind: json['kind'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      actorUsername: actor?['username'] as String?,
      postId: json['post_id'] as int?,
    );
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        kind: kind,
        message: message,
        isRead: isRead ?? this.isRead,
        actorUsername: actorUsername,
        postId: postId,
      );
}
