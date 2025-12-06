import 'package:flutter_test/flutter_test.dart';
import 'package:soundmates/api/models.dart';

void main() {
  group('LoginDto', () {
    test('should serialize to JSON correctly', () {
      final dto = LoginDto(email: 'test@example.com', password: 'password123');
      final json = dto.toJson();

      expect(json['email'], equals('test@example.com'));
      expect(json['password'], equals('password123'));
    });
  });

  group('RegisterDto', () {
    test('should serialize to JSON correctly', () {
      final dto = RegisterDto(email: 'new@example.com', password: 'SecurePass123!');
      final json = dto.toJson();

      expect(json['email'], equals('new@example.com'));
      expect(json['password'], equals('SecurePass123!'));
    });
  });

  group('RefreshTokenDto', () {
    test('should serialize to JSON correctly', () {
      final dto = RefreshTokenDto(refreshToken: 'refresh_token_xyz');
      final json = dto.toJson();

      expect(json['refreshToken'], equals('refresh_token_xyz'));
    });
  });

  group('SwipeDto', () {
    test('should serialize to JSON correctly', () {
      final dto = SwipeDto(receiverId: 'user-123');
      final json = dto.toJson();

      expect(json['receiverId'], equals('user-123'));
    });
  });

  group('SendMessageDto', () {
    test('should serialize to JSON correctly', () {
      final dto = SendMessageDto(receiverId: 'user-456', content: 'Hello!');
      final json = dto.toJson();

      expect(json['receiverId'], equals('user-456'));
      expect(json['content'], equals('Hello!'));
    });
  });

  group('PasswordDto', () {
    test('should serialize to JSON correctly', () {
      final dto = PasswordDto(password: 'MyPassword123!');
      final json = dto.toJson();

      expect(json['password'], equals('MyPassword123!'));
    });
  });

  group('ChangePasswordDto', () {
    test('should serialize to JSON correctly', () {
      final dto = ChangePasswordDto(
        oldPassword: 'OldPass123!',
        newPassword: 'NewPass456!',
      );
      final json = dto.toJson();

      expect(json['oldPassword'], equals('OldPass123!'));
      expect(json['newPassword'], equals('NewPass456!'));
    });
  });

  group('ProfilePictureDto', () {
    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'pic-123',
        'fileUrl': '/uploads/profile.jpg',
      };
      final dto = ProfilePictureDto.fromJson(json);

      expect(dto.id, equals('pic-123'));
      expect(dto.fileUrl, equals('/uploads/profile.jpg'));
    });

    test('should serialize to JSON correctly', () {
      final dto = ProfilePictureDto(id: 'pic-456', fileUrl: '/uploads/avatar.jpg');
      final json = dto.toJson();

      expect(json['id'], equals('pic-456'));
      expect(json['fileUrl'], equals('/uploads/avatar.jpg'));
    });

    test('getAbsoluteUrl should handle relative URLs', () {
      final dto = ProfilePictureDto(id: 'pic-1', fileUrl: '/uploads/image.jpg');
      final absoluteUrl = dto.getAbsoluteUrl('http://localhost:5000');

      expect(absoluteUrl, equals('http://localhost:5000/uploads/image.jpg'));
    });

    test('getAbsoluteUrl should handle base URL with trailing slash', () {
      final dto = ProfilePictureDto(id: 'pic-2', fileUrl: '/uploads/image.jpg');
      final absoluteUrl = dto.getAbsoluteUrl('http://localhost:5000/');

      expect(absoluteUrl, equals('http://localhost:5000/uploads/image.jpg'));
    });

    test('getAbsoluteUrl should return URL unchanged if already absolute', () {
      final dto = ProfilePictureDto(id: 'pic-3', fileUrl: 'https://cdn.example.com/image.jpg');
      final absoluteUrl = dto.getAbsoluteUrl('http://localhost:5000');

      expect(absoluteUrl, equals('https://cdn.example.com/image.jpg'));
    });
  });

  group('MusicSampleDto', () {
    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'sample-123',
        'fileUrl': '/uploads/music.mp3',
      };
      final dto = MusicSampleDto.fromJson(json);

      expect(dto.id, equals('sample-123'));
      expect(dto.fileUrl, equals('/uploads/music.mp3'));
    });

    test('should serialize to JSON correctly', () {
      final dto = MusicSampleDto(id: 'sample-456', fileUrl: '/uploads/song.mp3');
      final json = dto.toJson();

      expect(json['id'], equals('sample-456'));
      expect(json['fileUrl'], equals('/uploads/song.mp3'));
    });

    test('getAbsoluteUrl should handle relative URLs', () {
      final dto = MusicSampleDto(id: 'sample-1', fileUrl: '/uploads/track.mp3');
      final absoluteUrl = dto.getAbsoluteUrl('http://localhost:5000');

      expect(absoluteUrl, equals('http://localhost:5000/uploads/track.mp3'));
    });

    test('getAbsoluteUrl should return URL unchanged if already absolute', () {
      final dto = MusicSampleDto(id: 'sample-2', fileUrl: 'https://cdn.example.com/track.mp3');
      final absoluteUrl = dto.getAbsoluteUrl('http://localhost:5000');

      expect(absoluteUrl, equals('https://cdn.example.com/track.mp3'));
    });
  });

  group('UpdateUserProfileDto', () {
    test('should serialize artist profile to JSON correctly', () {
      final dto = UpdateUserProfileDto(
        isBand: false,
        name: 'John Doe',
        description: 'Musician',
        countryId: 'country-1',
        cityId: 'city-1',
        birthDate: DateTime(1990, 5, 15),
        genderId: 'gender-1',
        tagsIds: ['tag-1', 'tag-2'],
        musicSamplesOrder: ['sample-1', 'sample-2'],
        profilePicturesOrder: ['pic-1', 'pic-2'],
      );
      final json = dto.toJson();

      expect(json['userType'], equals('artist'));
      expect(json['name'], equals('John Doe'));
      expect(json['description'], equals('Musician'));
      expect(json['countryId'], equals('country-1'));
      expect(json['cityId'], equals('city-1'));
      expect(json['birthDate'], equals('1990-05-15'));
      expect(json['genderId'], equals('gender-1'));
      expect(json['tagsIds'], equals(['tag-1', 'tag-2']));
      expect(json['musicSamplesOrder'], equals(['sample-1', 'sample-2']));
      expect(json['profilePicturesOrder'], equals(['pic-1', 'pic-2']));
    });

    test('should serialize band profile to JSON correctly', () {
      final dto = UpdateUserProfileDto(
        isBand: true,
        name: 'The Band',
        description: 'Rock band',
        countryId: 'country-2',
        cityId: 'city-2',
      );
      final json = dto.toJson();

      expect(json['userType'], equals('band'));
      expect(json['name'], equals('The Band'));
      expect(json['description'], equals('Rock band'));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'userType': 'artist',
        'name': 'Jane Doe',
        'description': 'Singer',
        'countryId': 'country-3',
        'cityId': 'city-3',
        'birthDate': '1995-03-20',
        'genderId': 'gender-2',
        'tagsIds': ['tag-3', 'tag-4'],
        'musicSamplesOrder': ['sample-3'],
        'profilePicturesOrder': ['pic-3'],
      };
      final dto = UpdateUserProfileDto.fromJson(json);

      expect(dto.isBand, equals(false));
      expect(dto.name, equals('Jane Doe'));
      expect(dto.description, equals('Singer'));
      expect(dto.countryId, equals('country-3'));
      expect(dto.cityId, equals('city-3'));
      expect(dto.birthDate, equals(DateTime(1995, 3, 20)));
      expect(dto.genderId, equals('gender-2'));
      expect(dto.tagsIds, equals(['tag-3', 'tag-4']));
      expect(dto.musicSamplesOrder, equals(['sample-3']));
      expect(dto.profilePicturesOrder, equals(['pic-3']));
    });
  });

  group('UpdateArtistProfile', () {
    test('should serialize to JSON correctly', () {
      final dto = UpdateArtistProfile(
        name: 'Artist Name',
        description: 'Artist description',
        countryId: 'country-id',
        cityId: 'city-id',
        birthDate: DateTime(1985, 12, 25),
        genderId: 'gender-id',
        tagsIds: ['tag-a', 'tag-b'],
        musicSamplesOrder: ['music-1'],
        profilePicturesOrder: ['pic-1'],
      );
      final json = dto.toJson();

      expect(json['userType'], equals('artist'));
      expect(json['name'], equals('Artist Name'));
      expect(json['birthDate'], equals('1985-12-25'));
    });
  });

  group('UpdateBandProfile', () {
    test('should serialize to JSON correctly with band members', () {
      final dto = UpdateBandProfile(
        isBand: true,
        name: 'Band Name',
        description: 'Band description',
        countryId: 'country-id',
        cityId: 'city-id',
        tagsIds: ['tag-x', 'tag-y'],
        musicSamplesOrder: ['music-2'],
        profilePicturesOrder: ['pic-2'],
      );
      final json = dto.toJson();

      expect(json['userType'], equals('band'));
      expect(json['name'], equals('Band Name'));
      expect(json['description'], equals('Band description'));
      expect(json['bandMembers'], isA<List>());
    });
  });
}
