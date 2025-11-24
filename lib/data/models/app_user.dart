import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String id;
  final String email;

  const AppUser({
    required this.id,
    required this.email,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
    );
  }

  @override
  List<Object?> get props => [id, email];
}
