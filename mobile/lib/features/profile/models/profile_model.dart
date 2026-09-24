class ProfilePostModel {
  const ProfilePostModel({required this.id, required this.content, required this.isAnonymous, required this.reactionCount, required this.commentCount, required this.saveCount});
  final int id; final String content; final bool isAnonymous; final int reactionCount; final int commentCount; final int saveCount;
  factory ProfilePostModel.fromJson(Map<String, dynamic> json) => ProfilePostModel(
    id: json['id'] as int, content: json['content'] as String, isAnonymous: json['is_anonymous'] as bool? ?? false,
    reactionCount: json['reaction_count'] as int? ?? 0, commentCount: json['comment_count'] as int? ?? 0, saveCount: json['save_count'] as int? ?? 0,
  );
}

class ProfileModel {
  const ProfileModel({required this.id, required this.username, required this.displayName, required this.bio, required this.postCount, required this.reactionsReceived, required this.followedByMe, required this.blockedByMe, required this.isMe, required this.recentPosts});
  final int id; final String username; final String displayName; final String bio; final int postCount; final int reactionsReceived; final bool followedByMe; final bool blockedByMe; final bool isMe; final List<ProfilePostModel> recentPosts;
  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['id'] as int, username: json['username'] as String, displayName: json['display_name'] as String, bio: json['bio'] as String? ?? '',
    postCount: json['post_count'] as int? ?? 0, reactionsReceived: json['reactions_received'] as int? ?? 0,
    followedByMe: json['followed_by_me'] as bool? ?? false, blockedByMe: json['blocked_by_me'] as bool? ?? false, isMe: json['is_me'] as bool? ?? false,
    recentPosts: ((json['recent_posts'] as List<dynamic>?) ?? const []).map((e) => ProfilePostModel.fromJson(e as Map<String, dynamic>)).toList(),
  );
  ProfileModel copyWith({bool? followedByMe, bool? blockedByMe}) => ProfileModel(id: id, username: username, displayName: displayName, bio: bio, postCount: postCount, reactionsReceived: reactionsReceived, followedByMe: followedByMe ?? this.followedByMe, blockedByMe: blockedByMe ?? this.blockedByMe, isMe: isMe, recentPosts: recentPosts);
}
