class CommentModel {
  const CommentModel({
    required this.id,
    required this.postId,
    required this.content,
    required this.parentId,
    required this.username,
    required this.displayName,
    required this.likeCount,
    required this.likedByMe,
  });

  final int id;
  final int postId;
  final String content;
  final int? parentId;
  final String username;
  final String displayName;
  final int likeCount;
  final bool likedByMe;

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>;
    return CommentModel(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      content: json['content'] as String,
      parentId: json['parent_id'] as int?,
      username: author['username'] as String,
      displayName: author['display_name'] as String,
      likeCount: json['like_count'] as int? ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
    );
  }
}
