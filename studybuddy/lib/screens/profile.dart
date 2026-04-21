import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studybuddy/shared/app_palette.dart';
import 'package:studybuddy/shared/taskbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late final Box profileBox;
  final ImagePicker picker = ImagePicker();

  bool isEditing = false;
  String? profilePhotoBase64;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController schoolController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController joinedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    profileBox = Hive.box('profileBox');
    _loadProfile();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    nameController.dispose();
    roleController.dispose();
    idController.dispose();
    emailController.dispose();
    schoolController.dispose();
    courseController.dispose();
    joinedController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    nameController.text = (profileBox.get('name') as String?) ?? 'Rai';
    roleController.text =
        (profileBox.get('role') as String?) ?? 'StudyBuddy User';
    idController.text = (profileBox.get('studentId') as String?) ?? 'SB-2026-001';
    emailController.text =
        (profileBox.get('email') as String?) ?? 'rai@student.com';
    schoolController.text =
        (profileBox.get('school') as String?) ?? 'StudyBuddy Academy';
    courseController.text =
        (profileBox.get('course') as String?) ?? 'Computer Science';
    joinedController.text =
        (profileBox.get('joined') as String?) ?? 'April 2026';

    profilePhotoBase64 = profileBox.get('profilePhotoBase64') as String?;
  }

  Future<void> _saveProfile() async {
    await profileBox.put('name', nameController.text.trim());
    await profileBox.put('role', roleController.text.trim());
    await profileBox.put('studentId', idController.text.trim());
    await profileBox.put('email', emailController.text.trim());
    await profileBox.put('school', schoolController.text.trim());
    await profileBox.put('course', courseController.text.trim());
    await profileBox.put('joined', joinedController.text.trim());
    await profileBox.put('profilePhotoBase64', profilePhotoBase64);
  }

  Future<void> _pickProfilePhoto() async {
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 800,
    );

    if (file == null) return;

    final Uint8List bytes = await file.readAsBytes();
    final String encoded = base64Encode(bytes);

    await profileBox.put('profilePhotoBase64', encoded);

    setState(() {
      profilePhotoBase64 = encoded;
    });
  }

  Uint8List? _profilePhotoBytes() {
    if (profilePhotoBase64 == null || profilePhotoBase64!.isEmpty) {
      return null;
    }

    try {
      return base64Decode(profilePhotoBase64!);
    } catch (_) {
      return null;
    }
  }

  String _initials() {
    final String name = nameController.text.trim();
    if (name.isEmpty) return 'SB';

    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppPalette.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppPalette.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                isEditing
                    ? TextField(
                        controller: controller,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black26),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                      )
                    : Text(
                        controller.text,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? photoBytes = _profilePhotoBytes();

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'PROFILE',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isEditing
                ? TextButton.icon(
                    key: const ValueKey('save'),
                    onPressed: () async {
                      await _saveProfile();
                      setState(() {
                        isEditing = false;
                      });
                    },
                    icon: const Icon(Icons.check, color: AppPalette.primary),
                    label: const Text(
                      'Save',
                      style: TextStyle(
                        color: AppPalette.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : TextButton.icon(
                    key: const ValueKey('edit'),
                    onPressed: () {
                      setState(() {
                        isEditing = true;
                      });
                    },
                    icon: const Icon(Icons.edit, color: Colors.black),
                    label: const Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomAppBar(child: TaskBar()),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Container(
              width: 420,
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppPalette.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.black, width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: isEditing ? _pickProfilePhoto : null,
                          child: Hero(
                            tag: 'profilePhoto',
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppPalette.primarySoft,
                                border: Border.all(color: Colors.black, width: 2.5),
                                image: photoBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(photoBytes),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: photoBytes == null
                                  ? Center(
                                      child: Text(
                                        _initials(),
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        if (isEditing)
                          GestureDetector(
                            onTap: _pickProfilePhoto,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppPalette.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    isEditing
                        ? TextField(
                            controller: nameController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: UnderlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 20),
                            ),
                          )
                        : Text(
                            nameController.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                    const SizedBox(height: 6),
                    isEditing
                        ? TextField(
                            controller: roleController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: UnderlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 20),
                            ),
                          )
                        : Text(
                            roleController.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppPalette.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'STUDENT INFORMATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppPalette.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoField(
                      label: 'STUDENT ID',
                      controller: idController,
                      icon: Icons.badge_outlined,
                    ),
                    _buildInfoField(
                      label: 'EMAIL',
                      controller: emailController,
                      icon: Icons.email_outlined,
                    ),
                    _buildInfoField(
                      label: 'SCHOOL',
                      controller: schoolController,
                      icon: Icons.school_outlined,
                    ),
                    _buildInfoField(
                      label: 'COURSE',
                      controller: courseController,
                      icon: Icons.book_outlined,
                    ),
                    _buildInfoField(
                      label: 'JOINED',
                      controller: joinedController,
                      icon: Icons.calendar_today_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}