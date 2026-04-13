import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studybuddy/shared/taskbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Box profileBox;
  final ImagePicker picker = ImagePicker();

  bool isEditing = false;
  String? profilePhotoBase64;

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
    setState(() {
      profilePhotoBase64 = base64Encode(bytes);
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

  Widget _buildIdField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(': ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: isEditing
                ? TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: UnderlineInputBorder(),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      controller.text,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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
      backgroundColor: const Color(0xFFF5F5F5),
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
          TextButton.icon(
            onPressed: () async {
              if (isEditing) {
                await _saveProfile();
              }

              setState(() {
                isEditing = !isEditing;
              });
            },
            icon: Icon(isEditing ? Icons.save : Icons.edit, color: Colors.black),
            label: Text(
              isEditing ? 'Save' : 'Edit',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomAppBar(child: TaskBar()),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            width: 420,
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.black, width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          GestureDetector(
                            onTap: isEditing ? _pickProfilePhoto : null,
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green.shade200,
                                border: Border.all(color: Colors.black, width: 2),
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
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          if (isEditing)
                            TextButton.icon(
                              onPressed: _pickProfilePhoto,
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: const Text('Change Photo'),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            isEditing
                                ? TextField(
                                    controller: nameController,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: UnderlineInputBorder(),
                                    ),
                                  )
                                : Text(
                                    nameController.text,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                  ),
                            const SizedBox(height: 4),
                            isEditing
                                ? TextField(
                                    controller: roleController,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: UnderlineInputBorder(),
                                    ),
                                  )
                                : Text(
                                    roleController.text,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(thickness: 1.2),
                  const SizedBox(height: 12),
                  _buildIdField(label: 'ID', controller: idController),
                  _buildIdField(label: 'EMAIL', controller: emailController),
                  _buildIdField(label: 'SCHOOL', controller: schoolController),
                  _buildIdField(label: 'COURSE', controller: courseController),
                  _buildIdField(label: 'JOINED', controller: joinedController),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
