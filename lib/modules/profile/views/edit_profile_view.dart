import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../core/utils/snackbar_utils.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final Future<File?> _savedAvatar;
  late final User? _user;
  File? _selectedAvatar;
  bool _isPickingAvatar = false;
  bool _isSaving = false;

  UserProfileService get _profileService => Get.find<UserProfileService>();

  @override
  void initState() {
    super.initState();
    _user = Get.find<AuthService>().currentUser;
    _usernameController = TextEditingController(
      text: _user?.displayName?.trim() ?? _user?.email?.split('@').first ?? '',
    );
    _savedAvatar = _user == null
        ? Future<File?>.value()
        : _profileService.localAvatarForUser(_user.uid);
  }

  Future<void> _pickAvatar() async {
    if (_isPickingAvatar || _isSaving || _user == null) return;
    setState(() => _isPickingAvatar = true);
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result.isEmpty || !mounted) return;
      final sourcePath = result.first.path;
      if (sourcePath == null) {
        throw StateError('The selected image could not be opened.');
      }
      final avatar = await _profileService.saveLocalAvatar(
        _user.uid,
        sourcePath,
      );
      if (mounted) setState(() => _selectedAvatar = avatar);
    } catch (error) {
      if (mounted) SnackbarUtils.showError('Could not update photo: $error');
    } finally {
      if (mounted) setState(() => _isPickingAvatar = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final user = _user;
    if (user == null) {
      SnackbarUtils.showError('Sign in before editing your profile.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final username = _usernameController.text.trim();
      if (username != user.displayName?.trim()) {
        await _profileService.updateUsername(user, username);
      }
      if (!mounted) return;
      SnackbarUtils.showSuccess('Profile updated.');
      Get.back(result: true);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        SnackbarUtils.showError(
          error.message ?? 'Could not update your profile.',
        );
      }
    } catch (error) {
      if (mounted) {
        SnackbarUtils.showError('Could not update your profile: $error');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _avatar(BuildContext context, File? file) {
    final palette = AppPalette.of(context);
    return CircleAvatar(
      radius: 58,
      backgroundColor: palette.surfaceVariant,
      child: ClipOval(
        child: file == null
            ? Icon(Icons.person_rounded, size: 54, color: palette.secondaryText)
            : Image.file(
                file,
                width: 116,
                height: 116,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.person_rounded,
                  size: 54,
                  color: palette.secondaryText,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final user = _user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: Center(
          child: FilledButton(
            onPressed: () => Get.offAllNamed(AppRoutes.login),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _isSaving || _isPickingAvatar ? null : _saveProfile,
            child: _isSaving || _isPickingAvatar
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => Get.focusScope?.unfocus(),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FutureBuilder<File?>(
                        future: _savedAvatar,
                        builder: (context, snapshot) => Center(
                          child: _avatar(
                            context,
                            _selectedAvatar ?? snapshot.data,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _isPickingAvatar ? null : _pickAvatar,
                        icon: _isPickingAvatar
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.photo_camera_outlined),
                        label: Text(
                          _isPickingAvatar
                              ? 'Loading photo...'
                              : 'Change photo',
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _usernameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a username.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: user.email ?? '',
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your profile photo is saved only on this device.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.secondaryText),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
