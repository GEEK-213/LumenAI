import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/components/my_button.dart';
import 'package:app/components/my_textfield.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _hidePassword = true;

  //text editing controller
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  //sign User In method
  void signUserIn() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 60),

            Container(
              padding: EdgeInsets.all(30),

              //lets sign you in
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: const [
                  Text(
                    r"Let's Sign you In.",
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 10),

                  //welcome back you have been missed
                  Text(
                    "Welcome back. \nYou have been missed!",
                    style: TextStyle(fontSize: 26),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            //username text field
            MyTextfield(
              controller: usernameController,
              hintText: "Username",
              obscureText: false,
              prefixIcon: Icons.email,
            ),

            SizedBox(height: 20),

            //password textfield
            MyTextfield(
              controller: passwordController,
              hintText: "Password",
              obscureText: _hidePassword,
              prefixIcon: Icons.lock,
              suffixIcon: IconButton(
                icon: Icon(
                  _hidePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _hidePassword = !_hidePassword;
                  });
                },
              ),
            ),

            SizedBox(height: 10),

            //forgot password
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Forgot Password?",
                    style: TextStyle(color: Color(0xFF2B8CEE), fontSize: 15),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            //signin button
            MyButton(onTap: signUserIn),
            SizedBox(height: 50),

            //continue with
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(thickness: 2, color: Colors.grey[400]),
                  ),

                  Text(
                    "  Or continue with  ",
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  ),

                  Expanded(
                    child: Divider(thickness: 2, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            //google,apple,facebook login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                socialButtons(FontAwesomeIcons.google),
                SizedBox(width: 10),
                socialButtons(FontAwesomeIcons.apple),
                SizedBox(width: 10),
                socialButtons(FontAwesomeIcons.facebook),
              ],
            ),
            //dont have account, register
            const Spacer(),

            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    text: r"Don't have an account? ",

                    style: GoogleFonts.inter(color: Colors.black, fontSize: 15),
                    children: const [
                      TextSpan(
                        text: "Register",
                        style: TextStyle(
                          color: Color(0xFF2B8CEE),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget socialButtons(IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.black.withValues(alpha: .2),
            width: 1,
          ),
        ),
        child: Center(child: Icon(icon, size: 30)),
      ),
    );
  }
}
