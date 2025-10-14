class LoginDto {
  final String email;
  final String password;

  LoginDto({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class RegisterDto {
  final String email;
  final String password;

  RegisterDto({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class RefreshTokenDto {
  final String refreshToken;

  RefreshTokenDto({required this.refreshToken});

  Map<String, dynamic> toJson() => {
        'refreshToken': refreshToken,
      };
}

class SwipeDto {
  final String receiverId;

  SwipeDto({required this.receiverId});

  Map<String, dynamic> toJson() => {
        'receiverId': receiverId,
      };
}

class SendMessageDto {
  final String receiverId;
  final String content;

  SendMessageDto({required this.receiverId, required this.content});

  Map<String, dynamic> toJson() => {
        'receiverId': receiverId,
        'content': content,
      };
}

class UpdateUserProfileDto {
  final String name;
  final String description;
  final int birthYear;
  final String city;
  final String country;

  UpdateUserProfileDto({required this.name, required this.description, required this.birthYear, required this.city, required this.country});

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'birthYear': birthYear,
        'city': city,
        'country': country,
      };
}

class PasswordDto {
  final String password;

  PasswordDto({required this.password});

  Map<String, dynamic> toJson() => {
        'password': password,
      };
}

class ChangePasswordDto {
  final String oldPassword;
  final String newPassword;

  ChangePasswordDto({required this.oldPassword, required this.newPassword});

  Map<String, dynamic> toJson() => {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      };
}
