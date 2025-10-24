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

class BandMemberDto {
  final String id;
  final String name;
  final int age;
  final String bandRoleId;

  BandMemberDto({required this.id, required this.name, required this.age, required this.bandRoleId});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'bandRoleId': bandRoleId,
      };
}

class UpdateUserProfileDto {
  // discriminator: "artist" or "band"
  final String userType;

  // common / artist fields
  final String? birthDate; // ISO date yyyy-MM-dd
  final String? genderId;
  final bool? isBand;
  final String? name;
  final String? description;
  final String? countryId;
  final String? cityId;
  final List<String>? tagsIds;
  final List<String>? musicSamplesOrder;
  final List<String>? profilePicturesOrder;

  // band-specific
  final List<BandMemberDto>? bandMembers;

  UpdateUserProfileDto({
    required this.userType,
    this.birthDate,
    this.genderId,
    this.isBand,
    this.name,
    this.description,
    this.countryId,
    this.cityId,
    this.tagsIds,
    this.musicSamplesOrder,
    this.profilePicturesOrder,
    this.bandMembers,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> m = {'userType': userType};
    if (birthDate != null) m['birthDate'] = birthDate;
    if (genderId != null) m['genderId'] = genderId;
    if (isBand != null) m['isBand'] = isBand;
    if (name != null) m['name'] = name;
    if (description != null) m['description'] = description;
    if (countryId != null) m['countryId'] = countryId;
    if (cityId != null) m['cityId'] = cityId;
    if (tagsIds != null) m['tagsIds'] = tagsIds;
    if (musicSamplesOrder != null) m['musicSamplesOrder'] = musicSamplesOrder;
    if (profilePicturesOrder != null) m['profilePicturesOrder'] = profilePicturesOrder;
    if (bandMembers != null) m['bandMembers'] = bandMembers!.map((b) => b.toJson()).toList();
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
  final List<String>? filterTagsIds;

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
    this.filterTagsIds,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> m = {
      'showArtists': showArtists,
      'showBands': showBands,
    };
    if (maxDistance != null) m['maxDistance'] = maxDistance;
    if (countryId != null) m['countryId'] = countryId;
    if (cityId != null) m['cityId'] = cityId;
    if (artistMinAge != null) m['artistMinAge'] = artistMinAge;
    if (artistMaxAge != null) m['artistMaxAge'] = artistMaxAge;
    if (artistGenderId != null) m['artistGenderId'] = artistGenderId;
    if (bandMinMembersCount != null) m['bandMinMembersCount'] = bandMinMembersCount;
    if (bandMaxMembersCount != null) m['bandMaxMembersCount'] = bandMaxMembersCount;
    if (filterTagsIds != null) m['filterTagsIds'] = filterTagsIds;
    return m;
  }
}
