import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';

import 'login.dart';

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  final ProfileService _profileService = ProfileService();
  final SupabaseClient _supabase = Supabase.instance.client;

  Profile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final fetchedProfile = await _profileService.getProfile(user.id);
      // If profile doesn't exist (new user), create a default local instance
      final profile = fetchedProfile ?? Profile(id: user.id);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  bool _isPickingImage = false;

  Future<void> _pickAndUploadImage() async {
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null && _profile != null) {
        // Show loading state while uploading
        setState(() => _isLoading = true);

        final userId = _supabase.auth.currentUser!.id;
        final newUrl = await _profileService.uploadAvatar(
          userId,
          pickedFile.path,
        );

        if (newUrl != null && mounted) {
          setState(() {
            _profile = Profile(
              id: _profile!.id,
              fullName: _profile!.fullName,
              avatarUrl: newUrl,
              role: _profile!.role,
              interests: _profile!.interests,
              stats: _profile!.stats,
            );
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
          _isLoading = false;
        });
      }
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _profile?.fullName);
    final roleController = TextEditingController(text: _profile?.role);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E2746),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                labelStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: roleController,
              decoration: const InputDecoration(
                labelText: "Role (e.g. Student)",
                labelStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_profile != null) {
                final updatedProfile = Profile(
                  id: _profile!.id,
                  fullName: nameController.text,
                  role: roleController.text,
                  avatarUrl: _profile!.avatarUrl,
                  interests: _profile!.interests,
                  stats: _profile!.stats,
                );
                final success = await _profileService.updateProfile(
                  updatedProfile,
                );
                if (mounted) {
                  if (success) {
                    setState(() {
                      _profile = updatedProfile;
                    });
                    // Check if dialog is still mounted before popping
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Failed to update profile. Please try again.",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showAddInterestDialog() {
    final interestController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E2746),
        title: const Text(
          "Add Interest",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: interestController,
          decoration: const InputDecoration(
            labelText: "Interest",
            labelStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_profile != null && interestController.text.isNotEmpty) {
                final newInterests = List<String>.from(_profile!.interests)
                  ..add(interestController.text);
                final success = await _profileService.updateInterests(
                  _profile!.id,
                  newInterests,
                );
                if (mounted) {
                  if (success) {
                    setState(() {
                      _profile = Profile(
                        id: _profile!.id,
                        fullName: _profile!.fullName,
                        role: _profile!.role,
                        avatarUrl: _profile!.avatarUrl,
                        interests: newInterests,
                        stats: _profile!.stats,
                      );
                    });
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Failed to add interest. Please try again.",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _removeInterest(String interest) async {
    if (_profile != null) {
      final newInterests = List<String>.from(_profile!.interests)
        ..remove(interest);
      await _profileService.updateInterests(_profile!.id, newInterests);
      if (mounted) {
        setState(() {
          _profile = Profile(
            id: _profile!.id,
            fullName: _profile!.fullName,
            role: _profile!.role,
            avatarUrl: _profile!.avatarUrl,
            interests: newInterests,
            stats: _profile!.stats,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFF1E2746),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2746),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Profile Header
                  _buildProfileHeader(),

                  const SizedBox(height: 25),

                  // Overview Section
                  _buildSectionHeader("Overview", actionText: "View All"),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.local_fire_department,
                          iconColor: Colors.orange,
                          value: _profile?.stats['streak']?.toString() ?? "0",
                          label: "Day Streak",
                          badge: "+2", // Placeholder logic
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.menu_book_rounded,
                          iconColor: Colors.teal,
                          value:
                              _profile?.stats['notes_scribed']?.toString() ??
                              "0",
                          label: "Notes Scribed",
                          badge: "+15%",
                          isPercentage: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildWideStatCard(),

                  const SizedBox(height: 25),

                  // Interests Section
                  _buildSectionHeader("Interests"),
                  const SizedBox(height: 15),
                  _buildInterestsSection(),

                  const SizedBox(height: 25),

                  // Settings Section
                  _buildSectionHeader("Settings"),
                  const SizedBox(height: 10),
                  _buildSettingsTile(Icons.person, "Account Details"),
                  _buildSettingsTile(
                    Icons.notifications,
                    "Notifications",
                    badgeCount: 2,
                  ),
                  _buildSettingsTile(Icons.tune, "AI Preferences"),
                  _buildSettingsTile(Icons.lock, "Privacy & Security"),
                  _buildSettingsTile(Icons.help_outline, "Help & Support"),

                  const SizedBox(height: 25),

                  // Logout Button
                  GestureDetector(
                    onTap: _signOut,
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.red.withOpacity(0.05),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text(
                              "Log Out",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Lumen AI v1.0.0",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 80), // Space for Bottom Nav
                ],
              ),
            ),
      // bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // WIDGETS

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101628),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Avatar with Glow & Camera Icon
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundImage: _profile?.avatarUrl != null
                      ? NetworkImage(_profile!.avatarUrl!)
                      : const NetworkImage(
                          'https://avatar.iran.liara.run/public/boy?username=User',
                        ), // Fallback
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _profile?.fullName ?? "User",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_profile?.role != null) ...[
                _buildTag(_profile!.role!),
                const SizedBox(width: 8),
                const Text("•", style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
              ],
              const Text(
                "Computer Science",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text("Edit Profile"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2746),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text("Share"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2746),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? actionText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (actionText != null)
          Text(
            actionText,
            style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String badge,
    bool isPercentage = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101628),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F291F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWideStatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101628),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.purpleAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile?.stats['ai_generations']?.toString() ?? "3,240",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "AI Generations",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _profile?.stats['level'] ?? "Level 8",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: 80,
                child: LinearProgressIndicator(
                  value: 0.7,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.purpleAccent,
                  ),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    List<String> interests = _profile?.interests.isNotEmpty == true
        ? _profile!.interests
        : ["Machine Learning", "Data Structures", "UX Design", "Python"];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...interests.map((interest) => _buildInterestChip(interest)),
        _buildAddInterestButton(),
      ],
    );
  }

  Widget _buildInterestChip(String label) {
    return GestureDetector(
      onLongPress: () => _removeInterest(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2235), // Dark background for chip
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildAddInterestButton() {
    return GestureDetector(
      onTap: _showAddInterestDialog,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          color: Colors.transparent,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {int badgeCount = 0}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF101628),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFF1A2235),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blueAccent, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 20),
          ],
        ),
      ),
    );
  }
}
