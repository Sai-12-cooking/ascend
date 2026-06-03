import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final bool isMandatory;
  final bool isCompleted;
  final int xpReward;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    this.isMandatory = true,
    this.isCompleted = false,
    this.xpReward = 10,
    DateTime? createdAt,
  }) : createdAt = _truncateDate(createdAt ?? DateTime.now());

  static DateTime _truncateDate(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Creates a copy of this [TaskModel] but with the given fields replaced.
  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? category,
    bool? isMandatory,
    bool? isCompleted,
    int? xpReward,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      isMandatory: isMandatory ?? this.isMandatory,
      isCompleted: isCompleted ?? this.isCompleted,
      xpReward: xpReward ?? this.xpReward,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this [TaskModel] to a Map suitable for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'category': category,
      'isMandatory': isMandatory,
      'isCompleted': isCompleted,
      'xpReward': xpReward,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a [TaskModel] from a Map retrieved from Firestore.
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['createdAt'];
    DateTime parsedDate;
    
    if (rawCreatedAt is Timestamp) {
      parsedDate = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedDate = DateTime.parse(rawCreatedAt);
    } else if (rawCreatedAt is DateTime) {
      parsedDate = rawCreatedAt;
    } else {
      parsedDate = DateTime.now();
    }

    return TaskModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      isMandatory: map['isMandatory'] as bool? ?? true,
      isCompleted: map['isCompleted'] as bool? ?? false,
      xpReward: (map['xpReward'] as num? ?? 10).toInt(),
      createdAt: parsedDate,
    );
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, userId: $userId, title: $title, category: $category, isMandatory: $isMandatory, isCompleted: $isCompleted, xpReward: $xpReward, createdAt: $createdAt)';
  }
}
