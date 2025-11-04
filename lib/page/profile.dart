import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:wstore/page/onboarding.dart';
import 'package:wstore/services/auth.dart';
import 'package:wstore/services/shared_pref.dart';
import 'package:wstore/widget/support_widget.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? image, name, email;
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;

  getSharedPref() async {
    image = await SharedPreferenceHelper().getUserImage();
    name = await SharedPreferenceHelper().getUserName();
    email = await SharedPreferenceHelper().getUserEmail();
    setState(() {});
  }

  Future getImage() async {
    var picked = await _picker.pickImage(source: ImageSource.gallery);
    selectedImage = File(picked!.path);
    uploadItem();
    setState(() {});
  }

  uploadItem() async {
    if (selectedImage != null) {
      String addId = randomAlphaNumeric(10);
      Reference ref =
          FirebaseStorage.instance.ref().child("profileImages").child(addId);

      final UploadTask task = ref.putFile(selectedImage!);
      var downloadUrl = await (await task).ref.getDownloadURL();
      await SharedPreferenceHelper().saveUserImage(downloadUrl);
    }
  }

  @override
  void initState() {
    getSharedPref();
    super.initState();
  }

  Widget profileInfoCard(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0288D1), size: 30),
        title: Text(title, style: AppWidget.lightTextFieldStyle()),
        subtitle: Text(value, style: AppWidget.semiBoldTextStyle()),
      ),
    );
  }

  Widget actionCard(IconData icon, String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: color, size: 30),
          title: Text(
            text,
            style: AppWidget.semiBoldTextStyle().copyWith(color: color),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: name == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF64B5F6)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: getImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.white,
                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage!)
                              : NetworkImage(image!) as ImageProvider,
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF64B5F6),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.edit, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    name ?? "",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email ?? "",
                    style: const TextStyle(color: Colors.blueGrey, fontSize: 15),
                  ),
                  const SizedBox(height: 25),

                  profileInfoCard(Icons.person_outline, "Name", name ?? ""),
                  profileInfoCard(Icons.email_outlined, "Email", email ?? ""),

                  const SizedBox(height: 10),

                  actionCard(
                    Icons.logout,
                    "Logout",
                    Colors.orangeAccent,
                    () async {
                      await AuthMethod().SignOut().then((value) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const Onboarding()),
                        );
                      });
                    },
                  ),
                  actionCard(
                    Icons.delete_outline,
                    "Delete Account",
                    Colors.redAccent,
                    () async {
                      await AuthMethod().deleteUser().then((value) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const Onboarding()),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
