import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String category;
  final bool isMandatory;
  final bool isCompleted;
  final int xpReward;
  final DateTime createdAt;
  final DateTime? deadline;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    this.isMandatory = true,
    this.isCompleted = false,
    this.xpReward = 10,
    DateTime? createdAt,
    this.deadline,
  }) : createdAt = _truncateDate(createdAt ?? DateTime.now());

  static DateTime _truncateDate(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Creates a copy of this [TaskModel] but with the given fields replaced.
  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    bool? isMandatory,
    bool? isCompleted,
    int? xpReward,
    DateTime? createdAt,
    DateTime? deadline,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isMandatory: isMandatory ?? this.isMandatory,
      isCompleted: isCompleted ?? this.isCompleted,
      xpReward: xpReward ?? this.xpReward,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
    );
  }

  /// Converts this [TaskModel] to a Map suitable for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'isMandatory': isMandatory,
      'isCompleted': isCompleted,
      'xpReward': xpReward,
      'createdAt': Timestamp.fromDate(createdAt),
      if (deadline != null) 'deadline': Timestamp.fromDate(deadline!),
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

    final rawDeadline = map['deadline'];
    DateTime? parsedDeadline;
    if (rawDeadline is Timestamp) {
      parsedDeadline = rawDeadline.toDate().toUtc();
    } else if (rawDeadline is String) {
      parsedDeadline = DateTime.tryParse(rawDeadline)?.toUtc();
    } else if (rawDeadline is DateTime) {
      parsedDeadline = rawDeadline.toUtc();
    }

    if (parsedDeadline == null) {
      final nowUtc = DateTime.now().toUtc();
      parsedDeadline = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    }

    return TaskModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: map['category'] as String,
      isMandatory: map['isMandatory'] as bool? ?? true,
      isCompleted: map['isCompleted'] as bool? ?? false,
      xpReward: (map['xpReward'] as num? ?? 10).toInt(),
      createdAt: parsedDate,
      deadline: parsedDeadline,
    );
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, userId: $userId, title: $title, description: $description, category: $category, isMandatory: $isMandatory, isCompleted: $isCompleted, xpReward: $xpReward, createdAt: $createdAt, deadline: $deadline)';
  }
}
