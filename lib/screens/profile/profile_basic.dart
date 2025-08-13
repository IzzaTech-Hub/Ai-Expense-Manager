import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../../providers/profile_provider.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<ProfileProvider>(context, listen: false).loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final profileProvider = Provider.of<ProfileProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 🧑 Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.yellow.shade200),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 44,
                        backgroundImage: AssetImage(
                          'assets/images/user_placeholder.png',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profileProvider.name.isNotEmpty ? profileProvider.name : 'Your Name',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        profileProvider.email.isNotEmpty ? profileProvider.email : 'your@email.com',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/editProfile');
                        },
                        icon: const Icon(Icons.edit, size: 18, color: Color(0xFF3B82F6)),
                        label: const Text("Edit Profile"),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ⚙️ Account Settings Section
                _sectionCard(
                  context,
                  title: "Account Settings",
                  children: [
                    _listTile(
                      icon: Icons.lock_outline,
                      title: "Change Password",
                      onTap: () {
                        Navigator.pushNamed(context, '/changePassword');
                      },
                    ),
                    _listTile(
                      icon: Icons.subscriptions_outlined,
                      title: "Manage Subscription",
                      onTap: () {
                        // TODO: Navigate to subscription screen
                      },
                    ),
                    _listTile(
                      icon: Icons.notifications_none,
                      title: "Notification Preferences",
                      onTap: () {
                        Navigator.pushNamed(context, '/notificationPreferences');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // 📱 App Info Section
                _sectionCard(
                  context,
                  title: "App Info",
                  children: [
                    _listTile(icon: Icons.info_outline, title: "About App", onTap: () {
                      Navigator.pushNamed(context, '/aboutApp');
                    }),
                    _listTile(
                      icon: Icons.privacy_tip_outlined,
                      title: "Privacy Policy",
                      onTap: () {
                        Navigator.pushNamed(context, '/privacyPolicy');
                      },
                    ),
                    _listTile(
                      icon: Icons.article_outlined,
                      title: "Terms of Service",
                      onTap: () {
                        Navigator.pushNamed(context, '/termsOfService');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 🚪 Logout Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await AuthService().signOut();
                      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 4),
    );
  }

  Widget _sectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.shade200),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _listTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        leading: Icon(icon, color: Color(0xFF3B82F6)),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 15)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
        onTap: onTap,
      ),
    );
  }
}
