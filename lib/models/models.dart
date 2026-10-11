/// 数据模型（与后端 schemas.py 一一对应）
DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
String? _s(dynamic v) => v?.toString();
int _i(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

class User {
  final String id;
  final String phone;
  final String nickname;
  final String? avatarUrl;
  final String? roleName;
  final bool elderMode;

  User({
    required this.id,
    required this.phone,
    required this.nickname,
    this.avatarUrl,
    this.roleName,
    this.elderMode = false,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as String,
        phone: _s(j['phone']) ?? '',
        nickname: _s(j['nickname']) ?? '家人',
        avatarUrl: _s(j['avatar_url']),
        roleName: _s(j['role_name']),
        elderMode: j['elder_mode'] == true,
      );

  User copyWith({bool? elderMode, String? nickname, String? roleName}) => User(
        id: id,
        phone: phone,
        nickname: nickname ?? this.nickname,
        avatarUrl: avatarUrl,
        roleName: roleName ?? this.roleName,
        elderMode: elderMode ?? this.elderMode,
      );
}

class Family {
  final String id;
  final String name;
  final String inviteCode;
  final String? motto;
  final String? coverUrl;
  final String ownerId;
  final int memberCount;
  final int albumCount;
  final int photoCount;

  Family({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.motto,
    this.coverUrl,
    required this.ownerId,
    this.memberCount = 0,
    this.albumCount = 0,
    this.photoCount = 0,
  });

  factory Family.fromJson(Map<String, dynamic> j) => Family(
        id: j['id'] as String,
        name: _s(j['name']) ?? '',
        inviteCode: _s(j['invite_code']) ?? '',
        motto: _s(j['motto']),
        coverUrl: _s(j['cover_url']),
        ownerId: _s(j['owner_id']) ?? '',
        memberCount: _i(j['member_count']),
        albumCount: _i(j['album_count']),
        photoCount: _i(j['photo_count']),
      );
}

class Member {
  final String id;
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final String? roleName;
  final String role;
  final DateTime? joinedAt;

  Member({
    required this.id,
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    this.roleName,
    required this.role,
    this.joinedAt,
  });

  bool get isOwner => role == 'owner';

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: j['id'] as String,
        userId: _s(j['user_id']) ?? '',
        nickname: _s(j['nickname']) ?? '家人',
        avatarUrl: _s(j['avatar_url']),
        roleName: _s(j['role_name']),
        role: _s(j['role']) ?? 'member',
        joinedAt: _dt(j['joined_at']),
      );
}

class Album {
  final String id;
  final String title;
  final String? description;
  final String? coverUrl;
  final String category;
  final DateTime? eventDate;
  final String createdBy;
  final String? creatorName;
  final int photoCount;
  final DateTime? createdAt;

  Album({
    required this.id,
    required this.title,
    this.description,
    this.coverUrl,
    required this.category,
    this.eventDate,
    required this.createdBy,
    this.creatorName,
    this.photoCount = 0,
    this.createdAt,
  });

  factory Album.fromJson(Map<String, dynamic> j) => Album(
        id: j['id'] as String,
        title: _s(j['title']) ?? '',
        description: _s(j['description']),
        coverUrl: _s(j['cover_url']),
        category: _s(j['category']) ?? '日常',
        eventDate: _dt(j['event_date']),
        createdBy: _s(j['created_by']) ?? '',
        creatorName: _s(j['creator_name']),
        photoCount: _i(j['photo_count']),
        createdAt: _dt(j['created_at']),
      );
}

class Comment {
  final String id;
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final String content;
  final DateTime? createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    required this.content,
    this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        id: j['id'] as String,
        userId: _s(j['user_id']) ?? '',
        nickname: _s(j['nickname']) ?? '家人',
        avatarUrl: _s(j['avatar_url']),
        content: _s(j['content']) ?? '',
        createdAt: _dt(j['created_at']),
      );
}

class Photo {
  final String id;
  final String albumId;
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final String mediaType;
  final DateTime? takenAt;
  final String uploadedBy;
  final String? uploaderName;
  final int likes;
  final List<Comment> comments;
  final DateTime? createdAt;

  Photo({
    required this.id,
    required this.albumId,
    required this.url,
    this.thumbnailUrl,
    this.caption,
    this.mediaType = 'image',
    this.takenAt,
    required this.uploadedBy,
    this.uploaderName,
    this.likes = 0,
    this.comments = const [],
    this.createdAt,
  });

  String get thumb => thumbnailUrl ?? url;

  factory Photo.fromJson(Map<String, dynamic> j) => Photo(
        id: j['id'] as String,
        albumId: _s(j['album_id']) ?? '',
        url: _s(j['url']) ?? '',
        thumbnailUrl: _s(j['thumbnail_url']),
        caption: _s(j['caption']),
        mediaType: _s(j['media_type']) ?? 'image',
        takenAt: _dt(j['taken_at']),
        uploadedBy: _s(j['uploaded_by']) ?? '',
        uploaderName: _s(j['uploader_name']),
        likes: _i(j['likes']),
        comments: (j['comments'] as List? ?? [])
            .map((c) => Comment.fromJson(c as Map<String, dynamic>))
            .toList(),
        createdAt: _dt(j['created_at']),
      );
}

class TimelineEvent {
  final String id;
  final DateTime eventDate;
  final String title;
  final String? description;
  final String? imageUrl;

  TimelineEvent({
    required this.id,
    required this.eventDate,
    required this.title,
    this.description,
    this.imageUrl,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> j) => TimelineEvent(
        id: j['id'] as String,
        eventDate: _dt(j['event_date']) ?? DateTime.now(),
        title: _s(j['title']) ?? '',
        description: _s(j['description']),
        imageUrl: _s(j['image_url']),
      );
}

class Blessing {
  final String id;
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final String? roleName;
  final String? content;
  final String? audioUrl;
  final int audioDuration;
  final String blessingType;
  final int likes;
  final DateTime? createdAt;

  Blessing({
    required this.id,
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    this.roleName,
    this.content,
    this.audioUrl,
    this.audioDuration = 0,
    this.blessingType = 'text',
    this.likes = 0,
    this.createdAt,
  });

  bool get isVoice => blessingType == 'voice';

  factory Blessing.fromJson(Map<String, dynamic> j) => Blessing(
        id: j['id'] as String,
        userId: _s(j['user_id']) ?? '',
        nickname: _s(j['nickname']) ?? '家人',
        avatarUrl: _s(j['avatar_url']),
        roleName: _s(j['role_name']),
        content: _s(j['content']),
        audioUrl: _s(j['audio_url']),
        audioDuration: _i(j['audio_duration']),
        blessingType: _s(j['blessing_type']) ?? 'text',
        likes: _i(j['likes']),
        createdAt: _dt(j['created_at']),
      );
}

class Anniversary {
  final String id;
  final String title;
  final String husbandName;
  final String wifeName;
  final DateTime weddingDate;
  final DateTime? celebrationDate;
  final String? story;
  final String? coverUrl;
  final int yearsTogether;
  final int daysTogether;
  final int? daysUntilCelebration;
  final int blessingCount;
  final List<TimelineEvent> timeline;
  final List<Blessing> blessings;

  Anniversary({
    required this.id,
    required this.title,
    required this.husbandName,
    required this.wifeName,
    required this.weddingDate,
    this.celebrationDate,
    this.story,
    this.coverUrl,
    this.yearsTogether = 0,
    this.daysTogether = 0,
    this.daysUntilCelebration,
    this.blessingCount = 0,
    this.timeline = const [],
    this.blessings = const [],
  });

  factory Anniversary.fromJson(Map<String, dynamic> j) => Anniversary(
        id: j['id'] as String,
        title: _s(j['title']) ?? '金婚纪念',
        husbandName: _s(j['husband_name']) ?? '',
        wifeName: _s(j['wife_name']) ?? '',
        weddingDate: _dt(j['wedding_date']) ?? DateTime.now(),
        celebrationDate: _dt(j['celebration_date']),
        story: _s(j['story']),
        coverUrl: _s(j['cover_url']),
        yearsTogether: _i(j['years_together']),
        daysTogether: _i(j['days_together']),
        daysUntilCelebration: j['days_until_celebration'] == null ? null : _i(j['days_until_celebration']),
        blessingCount: _i(j['blessing_count']),
        timeline: (j['timeline'] as List? ?? [])
            .map((t) => TimelineEvent.fromJson(t as Map<String, dynamic>))
            .toList(),
        blessings: (j['blessings'] as List? ?? [])
            .map((b) => Blessing.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
}

class HomeSummary {
  final User user;
  final Family? family;
  final List<Member> members;
  final Anniversary? anniversary;
  final List<Album> recentAlbums;
  final List<Photo> recentPhotos;
  final Photo? memoryOfDay;

  HomeSummary({
    required this.user,
    this.family,
    this.members = const [],
    this.anniversary,
    this.recentAlbums = const [],
    this.recentPhotos = const [],
    this.memoryOfDay,
  });

  factory HomeSummary.fromJson(Map<String, dynamic> j) => HomeSummary(
        user: User.fromJson(j['user'] as Map<String, dynamic>),
        family: j['family'] == null ? null : Family.fromJson(j['family'] as Map<String, dynamic>),
        members: (j['members'] as List? ?? []).map((m) => Member.fromJson(m as Map<String, dynamic>)).toList(),
        anniversary: j['anniversary'] == null ? null : Anniversary.fromJson(j['anniversary'] as Map<String, dynamic>),
        recentAlbums: (j['recent_albums'] as List? ?? []).map((a) => Album.fromJson(a as Map<String, dynamic>)).toList(),
        recentPhotos: (j['recent_photos'] as List? ?? []).map((p) => Photo.fromJson(p as Map<String, dynamic>)).toList(),
        memoryOfDay: j['memory_of_day'] == null ? null : Photo.fromJson(j['memory_of_day'] as Map<String, dynamic>),
      );
}

class ShareLink {
  final String code;
  final String url;
  final DateTime? expiresAt;

  ShareLink({required this.code, required this.url, this.expiresAt});

  factory ShareLink.fromJson(Map<String, dynamic> j) => ShareLink(
        code: _s(j['code']) ?? '',
        url: _s(j['url']) ?? '',
        expiresAt: _dt(j['expires_at']),
      );
}
