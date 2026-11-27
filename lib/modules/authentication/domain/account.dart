import '../../../core/network/api_response.dart';

class Account {
  const Account({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.verified,
    this.jobTitle = '',
    this.photo,
    this.theme,
    this.birthday,
    this.birthdayVisible = true,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    email: json['email'] as String,
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    verified: json['is_verified'] as bool,
    jobTitle: json['job_title'] as String? ?? '',
    photo: json['photo'] as String?,
    theme: json['theme'] as String?,
    birthday: DateTime.tryParse(json['date_of_birth'] as String? ?? ''),
    birthdayVisible: json['birthday_visibility'] != 'private',
  );

  final String id, email, firstName, lastName, jobTitle;
  final String? photo, theme;
  final DateTime? birthday;
  final bool verified, birthdayVisible;
}

class AccountWorkspace {
  AccountWorkspace.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      kind = json['kind'] as String,
      subtype = json['subtype'] as String?,
      approval = json['approval_status'] as String,
      rejectionReason = json['rejected_reason'] as String?;

  final String id, name, kind, approval;
  final String? subtype, rejectionReason;
}

class AccountFailure implements Exception {
  const AccountFailure(this.type, {this.code});

  final NetworkFailureType type;
  final String? code;

  @override
  String toString() => 'AccountFailure(${type.name})';
}

T accountPayload<T>(ApiResponse<T> response) {
  if (response.hasData) return response.data as T;
  final body = response.response?.data;
  throw AccountFailure(
    response.failureType ?? NetworkFailureType.invalidResponse,
    code: body is Map && body['code'] is String ? body['code'] as String : null,
  );
}
