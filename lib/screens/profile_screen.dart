import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  User? _user;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _nameController.text = _user!.displayName ?? '';
      _emailController.text = _user!.email ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (_user != null) {
      String name = _nameController.text;
      String email = _emailController.text;

      // Update Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': name,
        'email': email,
      });

      // Update Firebase Auth
      await _user!.updateDisplayName(name);
      await _user!.updateEmail(email);

      // Update profile image if selected
      if (_profileImage != null) {
        String fileName = 'profile_images/${_user!.uid}.jpg';
        UploadTask uploadTask =
            _storage.ref().child(fileName).putFile(_profileImage!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        await _user!.updatePhotoURL(downloadUrl);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : NetworkImage(
                        _user?.photoURL ?? 'https://via.placeholder.com/150'),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
