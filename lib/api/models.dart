

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
  final bool? isBand;
  final String name;
  final String description;
  // prefer sending IDs as backend expects UUIDs
  final String? countryId;
  final String? cityId;
  // artist-only fields
  final DateTime? birthDate; // send as ISO date yyyy-MM-dd expected by DateOnly on server
  final String? genderId;

  // tagsIds - list of tag UUIDs
  final List<String>? tagsIds;
  // orders - lists of music sample ids and profile picture ids
  final List<String> musicSamplesOrder;
  final List<String> profilePicturesOrder;

  UpdateUserProfileDto({this.isBand, required this.name, required this.description, this.countryId, this.cityId, this.birthDate, this.genderId, this.tagsIds, List<String>? musicSamplesOrder, List<String>? profilePicturesOrder}) :
    musicSamplesOrder = musicSamplesOrder ?? const [],
    profilePicturesOrder = profilePicturesOrder ?? const [];

  Map<String, dynamic> toJson() {
    // Always include discriminator required by server polymorphic DTO
    // Put it first in the map so it appears earliest in serialized JSON.
    final m = <String, dynamic>{
      'userType': (isBand == true) ? 'band' : 'artist',
      'name': name,
      'description': description,
    };
    if (countryId != null && countryId!.isNotEmpty) m['countryId'] = countryId;
    if (cityId != null && cityId!.isNotEmpty) m['cityId'] = cityId;
    // artist-only properties
    if (birthDate != null) {
      // send only the date portion in ISO format yyyy-MM-dd
      final iso = birthDate!.toIso8601String().split('T').first;
      m['birthDate'] = iso;
    }
    if (genderId != null && genderId!.isNotEmpty) m['genderId'] = genderId;
    if (tagsIds != null) m['tagsIds'] = tagsIds;
    // include orders (server expects these lists)
    m['musicSamplesOrder'] = musicSamplesOrder;
    m['profilePicturesOrder'] = profilePicturesOrder;
    return m;
  }

  factory UpdateUserProfileDto.fromJson(Map<String, dynamic> json) => UpdateUserProfileDto(
        isBand: json.containsKey('userType') ? (json['userType']?.toString() == 'band') : null,
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        countryId: json['countryId']?.toString() ?? json['country_id']?.toString(),
        cityId: json['cityId']?.toString() ?? json['city_id']?.toString(),
        birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'].toString()) : null,
        genderId: json['genderId']?.toString() ?? json['gender_id']?.toString(),
        tagsIds: (json['tagsIds'] is List) ? List<String>.from(json['tagsIds'].map((e) => e.toString())) : null,
        musicSamplesOrder: (json['musicSamplesOrder'] is List) ? List<String>.from(json['musicSamplesOrder'].map((e) => e.toString())) : const [],
        profilePicturesOrder: (json['profilePicturesOrder'] is List) ? List<String>.from(json['profilePicturesOrder'].map((e) => e.toString())) : const [],
      );
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

class ProfilePictureDto {
  final String id;
  final String url;
  final int displayOrder;

  ProfilePictureDto({required this.id, required this.url, required this.displayOrder});

  factory ProfilePictureDto.fromJson(Map<String, dynamic> json) => ProfilePictureDto(
        id: json['id']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
        displayOrder: (json['displayOrder'] is int) ? json['displayOrder'] as int : int.tryParse('${json['displayOrder'] ?? ''}') ?? 0,
      );
}

class UserDto {
  final String id;
  final String email;
  final String passwordHash;
  final bool? isBand;
  final String? name;
  final String description;
  final DateTime createdAt;
  final bool isActive;
  final bool isFirstLogin;
  final bool isEmailConfirmed;
  final bool isLoggedOut;
  final String? countryId;
  final String? cityId;
  final List<String> tags;

  UserDto({
    required this.id,
    required this.email,
    required this.passwordHash,
    this.isBand,
    this.name,
    required this.description,
    required this.createdAt,
    required this.isActive,
    required this.isFirstLogin,
    required this.isEmailConfirmed,
    required this.isLoggedOut,
    this.countryId,
    this.cityId,
    required this.tags,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    final tagList = <String>[];
    if (json['tags'] is List) {
      for (final t in json['tags']) {
        tagList.add(t?.toString() ?? '');
      }
    }

    DateTime parseDate(dynamic v) {
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return UserDto(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      passwordHash: json['passwordHash']?.toString() ?? json['password_hash']?.toString() ?? '',
      isBand: json.containsKey('isBand') ? (json['isBand'] == null ? null : (json['isBand'] is bool ? json['isBand'] as bool : (json['isBand'].toString().toLowerCase() == 'true'))) : null,
      name: json['name']?.toString(),
      description: json['description']?.toString() ?? '',
      createdAt: parseDate(json['createdAt'] ?? json['created_at'] ?? DateTime.fromMillisecondsSinceEpoch(0)),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : (json['isActive'] != null ? json['isActive'].toString().toLowerCase() == 'true' : false),
      isFirstLogin: json['isFirstLogin'] is bool ? json['isFirstLogin'] as bool : (json['isFirstLogin'] != null ? json['isFirstLogin'].toString().toLowerCase() == 'true' : false),
      isEmailConfirmed: json['isEmailConfirmed'] is bool ? json['isEmailConfirmed'] as bool : (json['isEmailConfirmed'] != null ? json['isEmailConfirmed'].toString().toLowerCase() == 'true' : false),
      isLoggedOut: json['isLoggedOut'] is bool ? json['isLoggedOut'] as bool : (json['isLoggedOut'] != null ? json['isLoggedOut'].toString().toLowerCase() == 'true' : false),
      countryId: json['countryId']?.toString() ?? json['country_id']?.toString(),
      cityId: json['cityId']?.toString() ?? json['city_id']?.toString(),
      tags: tagList,
    );
  }
}


class CountryDto {
  final String id;
  final String name;

  CountryDto({required this.id, required this.name});

  factory CountryDto.fromJson(Map<String, dynamic> json) => CountryDto(
        id: json['id']?.toString() ?? json['value']?.toString() ?? '',
        name: json['name']?.toString() ?? json['label']?.toString() ?? json['text']?.toString() ?? json['value']?.toString() ?? '',
      );
}

class CityDto {
  final String id;
  final String name;
  final String? countryId;

  CityDto({required this.id, required this.name, this.countryId});

  factory CityDto.fromJson(Map<String, dynamic> json) => CityDto(
        id: json['id']?.toString() ?? json['value']?.toString() ?? '',
        name: json['name']?.toString() ?? json['label']?.toString() ?? json['text']?.toString() ?? json['value']?.toString() ?? '',
        countryId: json['countryId']?.toString() ?? json['country_id']?.toString(),
      );
}

class TagCategoryDto {
  final String id;
  final String name;
  final bool isForBand;

  TagCategoryDto({required this.id, required this.name, required this.isForBand});

  factory TagCategoryDto.fromJson(Map<String, dynamic> json) => TagCategoryDto(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    isForBand: json['isForBand'] is bool ? json['isForBand'] as bool : (json['isForBand']?.toString().toLowerCase() == 'true'),
  );
}

class TagDto {
  final String id;
  final String name;
  final String? tagCategoryId;

  TagDto({required this.id, required this.name, this.tagCategoryId});

  factory TagDto.fromJson(Map<String, dynamic> json) => TagDto(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    tagCategoryId: json['tagCategoryId']?.toString() ?? json['tag_category_id']?.toString(),
  );
}

class GenderDto {
  final String id;
  final String name;

  GenderDto({required this.id, required this.name});

  factory GenderDto.fromJson(Map<String, dynamic> json) => GenderDto(
    id: json['id']?.toString() ?? json['value']?.toString() ?? '',
    name: json['name']?.toString() ?? json['label']?.toString() ?? json['value']?.toString() ?? '',
  );
}
