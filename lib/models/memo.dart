import 'package:uuid/uuid.dart';

class Memo {
  final String id;
  String title;
  String content;
  DateTime createdAt;
  DateTime modifiedAt;
  int colorIndex;
  String folderId;

  Memo({
    String? id,
    this.title = '',
    this.content = '',
    DateTime? createdAt,
    DateTime? modifiedAt,
    this.colorIndex = 0,
    this.folderId = '',
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'colorIndex': colorIndex,
      'folderId': folderId,
    };
  }

  factory Memo.fromMap(Map<String, dynamic> map) {
    return Memo(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      modifiedAt: DateTime.parse(map['modifiedAt']),
      colorIndex: map['colorIndex'],
      folderId: map['folderId'] ?? '',
    );
  }

  Memo copyWith({
    String? title,
    String? content,
    int? colorIndex,
    String? folderId,
  }) {
    return Memo(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      modifiedAt: DateTime.now(),
      colorIndex: colorIndex ?? this.colorIndex,
      folderId: folderId ?? this.folderId,
    );
  }
} 