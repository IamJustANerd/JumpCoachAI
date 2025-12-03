import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. Import Firestore

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Get the current logged-in user
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Helper to update data in Firestore
  Future<void> _updateUserData(String field, String value) async {
    if (currentUser == null) return;

    // Reference to the database: collection "users" -> document "USER_ID"
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid);

    // Update the specific field (merge: true creates the doc if it's missing)
    await userDoc.set({field: value}, SetOptions(merge: true));
  }

  // Helper to show the Edit Dialog
  void _showEditDialog(String title, String fieldKey, String currentValue) {
    TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            "Edit $title",
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter new $title",
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00FFFF)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00FFFF)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                _updateUserData(fieldKey, controller.text);
                Navigator.pop(context);
              },
              child: const Text(
                "Save",
                style: TextStyle(color: Color(0xFF00FFFF)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("No user logged in")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Listen to the user's document in Firestore live
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          // Defaults if data is loading or doesn't exist yet
          String username = "Not set";
          String email = currentUser!.email ?? "No Email";
          String height = "Not set";
          String weight = "Not set";

          // If we have data from Firestore, overwrite the defaults
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            // Use '??' to fallback if the specific field is missing
            username = data['username'] ?? username;
            email = data['email'] ?? email;
            height = data['height'] ?? height;
            weight = data['weight'] ?? weight;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Avatar
                const Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF1E1E1E),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xFF00FFFF),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // --- Profile Items ---
                _buildProfileItem("Username", "username", username),
                _buildProfileItem("Email", "email", email),
                _buildProfileItem("Height", "height", height),
                _buildProfileItem("Weight", "weight", weight),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget to build a single row
  Widget _buildProfileItem(String title, String fieldKey, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LexendMega',
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF00FFFF)),
            onPressed: () => _showEditDialog(title, fieldKey, value),
          ),
        ],
      ),
    );
  }
}
