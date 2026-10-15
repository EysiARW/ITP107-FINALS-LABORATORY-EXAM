class Post {
  final int id;
  final String title;
  final String body;
  final String note;

  const Post({
    required this.id,
    required this.title,
    required this.body,
    this.note = '',
  });

  bool get hasNote => note.trim().isNotEmpty;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }

  factory Post.fromMap(Map<dynamic, dynamic> map) {
    return Post(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'note': note,
    };
  }

  Post copyWith({
    int? id,
    String? title,
    String? body,
    String? note,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Post &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          body == other.body &&
          note == other.note;

  @override
  int get hashCode => Object.hash(id, title, body, note);
}
