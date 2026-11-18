import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import 'notification_service.dart';

class UserProfileService extends GetxService {
  UserProfileService({
    required this.notificationService,
    FirebaseFirestore? firestore,
  }) : _firestoreOverride = firestore;

  final NotificationService notificationService;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  String? _activeUserId;
  String? _storedFcmToken;

  Future<void> syncUser(User? user) async {
    final previousUserId = _activeUserId;
    final previousToken = _storedFcmToken;
    _activeUserId = user?.uid;
    if (previousUserId != user?.uid) _storedFcmToken = null;

    if (previousUserId != null &&
        previousUserId != user?.uid &&
        previousToken != null) {
      try {
        await _deviceDocument(previousUserId, previousToken).delete();
      } catch (error, stackTrace) {
        developer.log(
          'Could not remove the previous account token record.',
          name: 'UserProfileService',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    if (user == null) return;

    await _writeUserProfile(user);

    var token = notificationService.fcmToken;
    if (token == null || token.isEmpty) {
      try {
        token = await notificationService.requestDeviceToken();
      } catch (error, stackTrace) {
        developer.log(
          'Could not obtain an FCM token for the signed-in user.',
          name: 'UserProfileService',
          error: error,
          stackTrace: stackTrace,
        );
        return;
      }
    }
    await syncFcmToken(token);
  }

  Future<void> _writeUserProfile(User user, {String? username}) async {
    final userDocument = _firestore.collection('users').doc(user.uid);
    final existing = await userDocument.get();
    final displayName = username ?? user.displayName?.trim();
    final fields = <String, Object?>{
      'username': displayName == null || displayName.isEmpty
          ? user.email?.split('@').first ?? 'user'
          : displayName,
      'email': user.email ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!existing.exists) {
      fields['createdAt'] = FieldValue.serverTimestamp();
    }
    await userDocument.set(fields, SetOptions(merge: true));
  }

  Future<void> syncFcmToken(String token) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) return;
    final userId = _activeUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final previousToken = _storedFcmToken;
    if (previousToken != null && previousToken != cleanToken) {
      await _deviceDocument(userId, previousToken).delete();
    }
    await _deviceDocument(userId, cleanToken).set({
      'fcmToken': cleanToken,
      'platform': _platformName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _activeUserId = userId;
    _storedFcmToken = cleanToken;
  }

  Future<void> updateUsername(User user, String username) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty) {
      throw ArgumentError.value(username, 'username', 'Must not be empty.');
    }

    await user.updateDisplayName(cleanUsername);
    await user.reload();
    await _writeUserProfile(
      FirebaseAuth.instance.currentUser ?? user,
      username: cleanUsername,
    );
  }

  Future<File?> localAvatarForUser(String userId) async {
    final directory = await _avatarDirectory();
    if (!await directory.exists()) return null;

    final prefix = '${_avatarFilePrefix(userId)}.';
    final files = await directory
        .list()
        .where(
          (entity) =>
              entity is File && entity.uri.pathSegments.last.startsWith(prefix),
        )
        .cast<File>()
        .toList();
    return files.isEmpty ? null : files.first;
  }

  Future<File> saveLocalAvatar(String userId, String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException(
        'The selected profile image is unavailable.',
        sourcePath,
      );
    }

    final fileName = source.uri.pathSegments.last;
    final extension = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.')).toLowerCase()
        : '';
    if (!const ['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
      throw FormatException('Choose a JPG, PNG, or WebP image.');
    }

    final directory = await _avatarDirectory();
    await directory.create(recursive: true);
    final prefix = '${_avatarFilePrefix(userId)}.';
    final targetPath =
        '${directory.path}${Platform.pathSeparator}${prefix.substring(0, prefix.length - 1)}$extension';
    final savedFile = source.absolute.path == targetPath
        ? source
        : await source.copy(targetPath);
    final previousFiles = await directory
        .list()
        .where(
          (entity) =>
              entity is File && entity.uri.pathSegments.last.startsWith(prefix),
        )
        .cast<File>()
        .toList();
    for (final previousFile in previousFiles) {
      if (previousFile.path != savedFile.path) await previousFile.delete();
    }
    return savedFile;
  }

  Future<Directory> _avatarDirectory() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return Directory(
      '${supportDirectory.path}${Platform.pathSeparator}profile_avatars',
    );
  }

  String _avatarFilePrefix(String userId) =>
      sha256.convert(utf8.encode(userId)).toString();

  DocumentReference<Map<String, dynamic>> _deviceDocument(
    String userId,
    String token,
  ) {
    final tokenId = sha256.convert(utf8.encode(token)).toString();
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(tokenId);
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'other',
    };
  }
}
