import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile.dart';
import '../../services/profile_service.dart';
import 'login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final nameController = TextEditingController();
  final roleController = TextEditingController();
  final interestsController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> signUpUser() async {
    final supabase = Supabase.instance.client;

    try {
      final res = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        data: {"full_name": nameController.text.trim()},
      );

      // DEBUG: print result
      debugPrint("Signup response: ${res.user}");

      if (res.user != null) {
        // Create profile with extra details
        final profile = Profile(
          id: res.user!.id,
          fullName: nameController.text.trim(),
          role: roleController.text.trim(),
          interests: interestsController.text.trim().isNotEmpty
              ? interestsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toList()
              : [],
        );

        // Save to Supabase
        await ProfileService().updateProfile(profile);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup successful. Please login.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Auth error: ${e.message}")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    roleController.dispose();
    interestsController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              const Text(
                "CREATE AN ACCOUNT",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Start Your Journey With Us ",
                style: TextStyle(fontSize: 20, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 40),

              _buildInputField(
                hintText: "Fill Name",
                icon: Icons.person_outline,
                controller: nameController,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                hintText: "Role (e.g. Student)",
                icon: Icons.work_outline,
                controller: roleController,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                hintText: "Interests (comma separated)",
                icon: Icons.favorite_border,
                controller: interestsController,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                hintText: "Email or Phone",
                icon: Icons.email_outlined,
                controller: emailController,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                hintText: "Password",
                icon: Icons.lock_outline,
                controller: passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 50),

              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF448AFF), Color(0xFF9C27B0)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF448AFF).withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2.0,
                      offset: const Offset(-4, 4),
                    ),
                    BoxShadow(
                      color: const Color(0xFF9C27B0).withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2.0,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: signUpUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade800)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Or continue with",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade800)),
                ],
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(Icons.g_mobiledata, size: 40),
                  const SizedBox(width: 20),
                  _buildSocialButton(Icons.apple, size: 30),
                  const SizedBox(width: 20),
                  _buildSocialButton(Icons.facebook, size: 30),
                ],
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2746),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(icon, color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, {double size = 30}) {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2746),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}
