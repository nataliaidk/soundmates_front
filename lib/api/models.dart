import 'package:uuid/uuid.dart';

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

class UpdateArtistProfile {
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

  UpdateArtistProfile({this.isBand, required this.name, required this.description, this.countryId, this.cityId, this.birthDate, this.genderId, this.tagsIds, List<String>? musicSamplesOrder, List<String>? profilePicturesOrder}) :
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
    return m;}


}

class UpdateBandProfile {
  final bool? isBand;
  final String name;
  final String description;
  // prefer sending IDs as backend expects UUIDs
  final String? countryId;
  final String? cityId;

  // tagsIds - list of tag UUIDs
  final List<String>? tagsIds;
  // orders - lists of music sample ids and profile picture ids
  final List<String> musicSamplesOrder;
  final List<BandMemberDto> bandMembers;
  final List<String> profilePicturesOrder;

  UpdateBandProfile({this.isBand, required this.name, required this.description, this.countryId, this.cityId, this.tagsIds, List<String>? musicSamplesOrder, List<BandMemberDto>? bandMembers, List<String>? profilePicturesOrder}) :
    bandMembers = bandMembers ?? const [],
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
    if (tagsIds != null) m['tagsIds'] = tagsIds;
    
    m['bandMembers'] = bandMembers.map((bm) => bm.toJson()).toList();
    
    // include orders (server expects these lists)
    m['musicSamplesOrder'] = musicSamplesOrder;
    m['profilePicturesOrder'] = profilePicturesOrder;
    return m;
  }
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
class ArtistDto extends UserDto {
  final DateTime? birthDate;
  final String? genderId;

  ArtistDto({
    required String id,
    required String email,
    required String passwordHash,
    required String? name,
    required String description,
    required DateTime createdAt,
    required bool isActive,
    required bool isFirstLogin,
    required bool isEmailConfirmed,
    required bool isLoggedOut,
    required String? countryId,
    required String? cityId,
    required List<String> tags,
    this.birthDate,
    this.genderId,
  }) : super(
          id: id,
          email: email,
          passwordHash: passwordHash,
          isBand: false,
          name: name,
          description: description,
          createdAt: createdAt,
          isActive: isActive,
          isFirstLogin: isFirstLogin,
          isEmailConfirmed: isEmailConfirmed,
          isLoggedOut: isLoggedOut,
          countryId: countryId,
          cityId: cityId,
          tags: tags,
        );
   Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'id': id,
      'email': email,
      'passwordHash': passwordHash,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'isFirstLogin': isFirstLogin,
      'isEmailConfirmed': isEmailConfirmed,
      'isLoggedOut': isLoggedOut,
      'countryId': countryId,
      'cityId': cityId,
      'tags': tags,
    };
    if (birthDate != null) {
      m['birthDate'] = birthDate!.toIso8601String();
    } 
    if (genderId != null) {
      m['genderId'] = genderId;
    } 
    return m;
  }
  factory ArtistDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return null;
    }

    return ArtistDto(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      passwordHash: json['passwordHash']?.toString() ?? json['password_hash']?.toString() ?? '',
      name: json['name']?.toString(),
      description: json['description']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : (json['isActive'] != null ? json['isActive'].toString().toLowerCase() == 'true' : false),
      isFirstLogin: json['isFirstLogin'] is bool ? json['isFirstLogin'] as bool : (json['isFirstLogin'] != null ? json['isFirstLogin'].toString().toLowerCase() == 'true' : false),
      isEmailConfirmed: json['isEmailConfirmed'] is bool ? json['isEmailConfirmed'] as bool : (json['isEmailConfirmed'] != null ? json['isEmailConfirmed'].toString().toLowerCase() == 'true' : false),
      isLoggedOut: json['isLoggedOut'] is bool ? json['isLoggedOut'] as bool : (json['isLoggedOut'] != null ? json['isLoggedOut'].toString().toLowerCase() == 'true' : false),
      countryId: json['countryId']?.toString() ?? json['country_id']?.toString(),
      cityId: json['cityId']?.toString() ?? json['city_id']?.toString(),
      tags: (json['tags'] is List) ? List<String>.from(json['tags'].map((e) => e.toString())) : [],
      birthDate: parseDate(json['birthDate'] ?? json['birth_date']),  
    );

  }}

  class BandDto extends UserDto {
    final BandMemberDto? bandMemberInfo;
    BandDto({ 
      required String id,
      required String email,
      required String passwordHash,
      required String? name,
      required String description,
      required DateTime createdAt,
      required bool isActive,
      required bool isFirstLogin,
      required bool isEmailConfirmed,
      required bool isLoggedOut,
      required String? countryId,
      required String? cityId,
      required List<String> tags,
      this.bandMemberInfo,
    }) : super(
          id: id,
          email: email,
          passwordHash: passwordHash,
          isBand: true,
          name: name,
          description: description,
          createdAt: createdAt,
          isActive: isActive,
          isFirstLogin: isFirstLogin,
          isEmailConfirmed: isEmailConfirmed,
          isLoggedOut: isLoggedOut,
          countryId: countryId,
          cityId: cityId,
          tags: tags,
        );  

    Map<String, dynamic> toJson() { 
      final m = <String, dynamic>{
        'id': id,
        'email': email,
        'passwordHash': passwordHash,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
        'isFirstLogin': isFirstLogin,
        'isEmailConfirmed': isEmailConfirmed,
        'isLoggedOut': isLoggedOut,
        'countryId': countryId,
        'cityId': cityId,
        'tags': tags,
      };
      if (bandMemberInfo != null) {
        m['bandMemberInfo'] = {
          'id': bandMemberInfo!.id,
          'name': bandMemberInfo!.name,
          'age': bandMemberInfo!.age,
          'displayOrder': bandMemberInfo!.displayOrder,
          'bandId': bandMemberInfo!.bandId,
          'bandRoleId': bandMemberInfo!.bandRoleId,
        };
      } 
      return m;
    }

    factory BandDto.fromJson(Map<String, dynamic> json) {
      BandMemberDto? parseBandMemberInfo(dynamic v) {
        if (v is Map<String, dynamic>) {
          return BandMemberDto.fromJson(v);
        }
        return null;
      } 
      return BandDto(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        passwordHash: json['passwordHash']?.toString() ?? json['password_hash']?.toString() ?? '',
        name: json['name']?.toString(),
        description: json['description']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        isActive: json['isActive'] is bool ? json['isActive'] as bool : (json['isActive'] != null ? json['isActive'].toString().toLowerCase() == 'true' : false),
        isFirstLogin: json['isFirstLogin'] is bool ? json['isFirstLogin'] as bool : (json['isFirstLogin'] != null ? json['isFirstLogin'].toString().toLowerCase() == 'true' : false),
        isEmailConfirmed: json['isEmailConfirmed'] is bool ? json['isEmailConfirmed'] as bool : (json['isEmailConfirmed'] != null ? json['isEmailConfirmed'].toString().toLowerCase() == 'true' : false),
        isLoggedOut: json['isLoggedOut'] is bool ? json['isLoggedOut'] as bool : (json['isLoggedOut'] != null ? json['isLoggedOut'].toString().toLowerCase() == 'true' : false),
        countryId: json['countryId']?.toString() ?? json['country_id']?.toString(),
        cityId: json['cityId']?.toString() ?? json['city_id']?.toString(),
        tags: (json['tags'] is List) ? List<String>.from(json['tags'].map((e) => e.toString())) : [],
        bandMemberInfo: parseBandMemberInfo(json['bandMemberInfo'] ?? json['band_member_info']),  
      );
    }}

class BandMemberDto {
  final String id;  
  final String name;
  final int age;
  final int displayOrder;
  final String bandId;
  final String bandRoleId;
  BandMemberDto({
    required this.id,
    required this.name,
    required this.age,
    required this.displayOrder,
    required this.bandId,
    required this.bandRoleId,
  });
  BandMemberDto copyWith({
    String? id,
    String? name,
    int? age,
    int? displayOrder,
    String? bandId,
    String? bandRoleId,
  }) {
    return BandMemberDto(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      displayOrder: displayOrder ?? this.displayOrder,
      bandId: bandId ?? this.bandId,
      bandRoleId: bandRoleId ?? this.bandRoleId,
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'displayOrder': displayOrder,
    'bandId': bandId,
    'bandRoleId': bandRoleId,
  };


  factory BandMemberDto.fromJson(Map<String, dynamic> json) {
    return BandMemberDto(
      id: json['id']?.toString() ?? const Uuid().v4(),
      name: json['name']?.toString() ?? '',
      age: (json['age'] is int) ? json['age'] as int : int.tryParse(json['age']?.toString() ?? '') ?? 0,
      displayOrder: (json['displayOrder'] is int) ? json['displayOrder'] as int : int.tryParse(json['displayOrder']?.toString() ?? '') ?? 0,
      bandId: json['bandId']?.toString() ?? '',
      bandRoleId: json['bandRoleId']?.toString() ?? '',
    );
  }
} 

  class BandRoleDto {
  final String id;  
  final String name;
  BandRoleDto({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
  
  factory BandRoleDto.fromJson(Map<String, dynamic> json) => BandRoleDto(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
  );
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

class MatchPreferenceDto {
  final bool? showArtists;
  final bool? showBands;
  final int? maxDistance;
  final int? artistMinAge;
  final int? artistMaxAge;
  final String? countryId;
  final String? cityId;
  final String? artistGenderId;
  final int? bandMinMembersCount;
  final int? bandMaxMembersCount;
  final List<String>? filterTagsIds;

  MatchPreferenceDto({
    this.showArtists,
    this.showBands,
    this.maxDistance,
    this.artistMinAge,
    this.artistMaxAge,
    this.countryId,
    this.cityId,
    this.artistGenderId,
    this.bandMinMembersCount,
    this.bandMaxMembersCount,
    this.filterTagsIds,
  });

  factory MatchPreferenceDto.fromJson(Map<String, dynamic> json) => MatchPreferenceDto(
    showArtists: json['showArtists'] as bool?,
    showBands: json['showBands'] as bool?,
    maxDistance: json['maxDistance'] as int?,
    artistMinAge: json['artistMinAge'] as int?,
    artistMaxAge: json['artistMaxAge'] as int?,
    countryId: json['countryId']?.toString(),
    cityId: json['cityId']?.toString(),
    artistGenderId: json['artistGenderId']?.toString(),
    bandMinMembersCount: json['bandMinMembersCount'] as int?,
    bandMaxMembersCount: json['bandMaxMembersCount'] as int?,
    filterTagsIds: (json['filterTagsIds'] is List)
        ? List<String>.from(json['filterTagsIds'].map((e) => e.toString()))
        : null,
  );
}


class UpdateMatchPreferenceDto {
  final bool showArtists;
  final bool showBands;
  final int? maxDistance;
  final String? countryId;
  final String? cityId;
  final int? artistMinAge;
  final int? artistMaxAge;
  final String? artistGenderId;
  final int? bandMinMembersCount;
  final int? bandMaxMembersCount;
  final List<String> filterTagsIds;

  UpdateMatchPreferenceDto({
    required this.showArtists,
    required this.showBands,
    this.maxDistance,
    this.countryId,
    this.cityId,
    this.artistMinAge,
    this.artistMaxAge,
    this.artistGenderId,
    this.bandMinMembersCount,
    this.bandMaxMembersCount,
    required this.filterTagsIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'showArtists': showArtists,
      'showBands': showBands,
      'maxDistance': maxDistance,
      'countryId': countryId,
      'cityId': cityId,
      'artistMinAge': artistMinAge,
      'artistMaxAge': artistMaxAge,
      'artistGenderId': artistGenderId,
      'bandMinMembersCount': bandMinMembersCount,
      'bandMaxMembersCount': bandMaxMembersCount,
      'filterTagsIds': filterTagsIds,
    };
  }
}
