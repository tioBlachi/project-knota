import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:frontend/pages/registation_page.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/services/user_services.dart';
import 'package:frontend/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formGlobalKey = GlobalKey<FormState>();
  bool _hidePassword = true;
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Image.network(
                  'https://fastly.picsum.photos/id/200/367/267.jpg?hmac=GFqST8d65ZPaEGEiCClMdf7MXamTdDadgB7lNZXYWP8',
                  height: 250,
                ),
        
                const SizedBox(
                  height: 15,
                ),
        
                Text(
                  "Welcome To Knota!",
                  style: TextStyle(fontSize: 30),
                ),
        
                const SizedBox(
                  height: 50,
                ),
        
                Form(
                  key: _formGlobalKey,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
        
                      // email input
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email cannot be empty';
                          }
        
                          if (!EmailValidator.validate(value)) {
                            return 'Invalid email address';
                          }
                          return null;
                        },
                        onSaved: (value) => email = value!.toLowerCase().trim(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Email',
                        ),
                      ),
        
                      // password input
                      const SizedBox(
                        height: 20,
                      ),
        
                      TextFormField(
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: _hidePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password cannot be empty';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters long';
                          }
                          return null;
                        },
                        onSaved: (value) => password = value!,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _hidePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _hidePassword = !_hidePassword;
                              });
                            },
                          ),
                        ),
                      ),
        
                      const SizedBox(
                        height: 20,
                      ),
        
                      // login button
                      FilledButton(
                        onPressed: () async {
                          if (_formGlobalKey.currentState!.validate()) {
                            _formGlobalKey.currentState!.save();
                          
                            final scaffoldMessenger = ScaffoldMessenger.of(context);

                            try {
                              final String token = await UserServices.login(email, password);
                              await StorageService.saveToken(token);
                              
                              if (!context.mounted) return;
                              
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const HomePage()),
                                (route) => false,
                              );
                            } catch (e) {
                              if (!context.mounted) return;

                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                                  backgroundColor: Colors.red,),
                              );
                            }
                          }
                        },
                        child: Text('Login'),
                      ),
        
                      // create account button
                      TextButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegistrationPage(),
                            ),
                          );
        
                          _formGlobalKey.currentState?.reset();
                        },
                        child: const Text('Create Account'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Divider(),
            Text(
              "© 2026 Knota",
              textAlign: TextAlign.center,
              textScaler: TextScaler.linear(0.75),
            ),
            SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Built with Flutter',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                  textScaler: TextScaler.linear(0.75),
                ),
                FlutterLogo(
                  size: 10,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
