import 'package:equatable/equatable.dart';

/// Model representing a player's added friend
class Friend extends Equatable {
  final String id;
  final String displayName;
  final String email;
  final DateTime addedAt;
  final bool isOnline;

  const Friend({
    required this.id,
    required this.displayName,
    required this.email,
    required this.addedAt,
    this.isOnline = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        'addedAt': addedAt.toIso8601String(),
      };

  factory Friend.fromJson(Map<String, dynamic> json, {bool isOnline = false}) {
    return Friend(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? 'Player',
      email: json['email'] as String? ?? '',
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isOnline: isOnline,
    );
  }

  Friend copyWith({
    String? id,
    String? displayName,
    String? email,
    DateTime? addedAt,
    bool? isOnline,
  }) {
    return Friend(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      addedAt: addedAt ?? this.addedAt,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [id, displayName, email, addedAt, isOnline];
}
