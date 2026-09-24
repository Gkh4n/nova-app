class ReactionCounts {
  const ReactionCounts({required this.felt, required this.thought, required this.funny});
  final int felt;
  final int thought;
  final int funny;
  factory ReactionCounts.fromJson(Map<String, dynamic> json) => ReactionCounts(
        felt: json['felt'] as int? ?? 0,
        thought: json['thought'] as int? ?? 0,
        funny: json['funny'] as int? ?? 0,
      );
  int get total => felt + thought + funny;
}

class PostModel {
  const PostModel({
    required this.id,
    required this.content,
    required this.isAnonymous,
    required this.isMine,
    required this.canReveal,
    required this.revealCount,
    required this.reactionCounts,
    required this.viewerReaction,
    required this.commentCount,
    required this.savedByMe,
    required this.saveCount,
    required this.topics,
    this.dailyQuestionText,
  });

  final int id;
  final String content;
  final bool isAnonymous;
  final bool isMine;
  final bool canReveal;
  final int revealCount;
  final ReactionCounts reactionCounts;
  final String? viewerReaction;
  final int commentCount;
  final bool savedByMe;
  final int saveCount;
  final List<String> topics;
  final String? dailyQuestionText;

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'] as int,
        content: json['content'] as String,
        isAnonymous: json['is_anonymous'] as bool,
        isMine: json['is_mine'] as bool? ?? false,
        canReveal: json['can_reveal'] as bool? ?? false,
        revealCount: json['reveal_count'] as int? ?? 0,
        reactionCounts: ReactionCounts.fromJson((json['reaction_counts'] as Map<String, dynamic>?) ?? const {}),
        viewerReaction: json['viewer_reaction'] as String?,
        commentCount: json['comment_count'] as int? ?? 0,
        savedByMe: json['saved_by_me'] as bool? ?? false,
        saveCount: json['save_count'] as int? ?? 0,
        topics: ((json['topics'] as List<dynamic>?) ?? const []).map((e) => e.toString()).toList(),
        dailyQuestionText: json['daily_question_text'] as String?,
      );

  PostModel copyWith({ReactionCounts? reactionCounts, String? viewerReaction, bool clearViewerReaction = false, int? commentCount, bool? savedByMe, int? saveCount}) => PostModel(
        id: id, content: content, isAnonymous: isAnonymous, isMine: isMine, canReveal: canReveal,
        revealCount: revealCount, reactionCounts: reactionCounts ?? this.reactionCounts,
        viewerReaction: clearViewerReaction ? null : (viewerReaction ?? this.viewerReaction),
        commentCount: commentCount ?? this.commentCount, savedByMe: savedByMe ?? this.savedByMe,
        saveCount: saveCount ?? this.saveCount, topics: topics, dailyQuestionText: dailyQuestionText,
      );
}
