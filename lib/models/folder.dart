import 'package:uuid/uuid.dart';

class Folder {
  final String id;
  String name;
  DateTime createdAt;

  Folder({
    String? id,
    required this.name,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Folder copyWith({
    String? name,
  }) {
    return Folder(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
    );
  }
} 