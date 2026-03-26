import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/widgets/required_label.dart';
import 'package:frontend/widgets/address_autocomplete.dart';
import 'package:frontend/models/user_models.dart';
import 'package:frontend/services/user_services.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formGlobalKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _hidePassword = true;
  String? _selectedAddress;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Registration Page"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Text(
                  "Register for a Knota account",
                  style: TextStyle(fontSize: 30),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                Form(
                  key: _formGlobalKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // First Name
                      TextFormField(
                        controller: _firstNameController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.name,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }

                          if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value)) {
                            return 'Only letters, spaces, (-) and (\') allowed';
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          label: RequiredLabel(label: 'First Name'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Last Name
                      TextFormField(
                        controller: _lastNameController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.name,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }

                          if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value)) {
                            return 'Only letters, spaces, (-) and (\') allowed';
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          label: RequiredLabel(label: 'Last Name'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Address - should autocomplere
                      AddressAutocomplete(
                        onSelected: (address) {
                          _selectedAddress = address.isEmpty ? null : address;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Optional Company Name
                      // If null, first and last name will be used in the generated mileage report
                      TextFormField(
                        controller: _companyNameController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.text,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null;
                          }
                          if (!RegExp(
                            r"^[a-zA-Z0-9\s&.,'-]+$",
                          ).hasMatch(value)) {
                            return 'Invalid characters in company name';
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Company Name (Optional)',
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email cannot be empty';
                          }

                          if (!EmailValidator.validate(value)) {
                            return 'Invalid email address';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          label: RequiredLabel(label: 'Email'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Password. Will be hashed at the backend
                      TextFormField(
                        controller: _passwordController,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.visiblePassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        obscureText: _hidePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password cannot be empty';
                          }
                          if (value.length < 8) {
                            return 'Minimum 8 characters required';
                          }
                          if (!value.contains(RegExp(r'[A-Z]'))) {
                            return 'Must have an uppercase letter';
                          }
                          if (!value.contains(RegExp(r'[a-z]'))) {
                            return 'Must have a lowercase letter';
                          }
                          if (!value.contains(RegExp(r'[0-9]'))) {
                            return 'Must have a number';
                          }
                          if (!value.contains(
                            RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
                          )) {
                            return 'Must have a special character';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          label: RequiredLabel(label: 'Password'),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _hidePassword = !_hidePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      FilledButton(
                        onPressed: () async {
                          final String? companyName =
                              _companyNameController.text.trim().isEmpty
                              ? null
                              : _companyNameController.text
                                    .trim()
                                    .toUpperCase();

                          if (_formGlobalKey.currentState!.validate()) {
                            final String userFirstName = _firstNameController
                                .text
                                .trim();
                            final String userLastName = _lastNameController.text
                                .trim();
                            final String userEmail = _emailController.text
                                .trim();
                            final String userPassword =
                                _passwordController.text;

                            UserCreate user = UserCreate(
                              firstName: userFirstName.toUpperCase(),
                              lastName: userLastName.toUpperCase(),
                              companyName: companyName,
                              address: _selectedAddress.toString(),
                              email: userEmail.toUpperCase(),
                              password: userPassword,
                            );
                            try {
                              await UserServices.createUser(user);
                              await StorageService.deleteToken();

                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();

                              final snackBarController =
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.green.shade100,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      content: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green.shade900,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'User created successfully. Please Login',
                                              style: TextStyle(
                                                color: Colors.green.shade900,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                              await snackBarController.closed;

                              Navigator.pop(context);
                              
                            } catch (e) {
                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red.shade100,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.error,
                                        color: Colors.red.shade900,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Failed to create user: $e',
                                          style: TextStyle(
                                            color: Colors.red.shade900,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          } else {
                            debugPrint(
                              'Something is wrong! Cannot add to database',
                            );
                          }
                        },
                        child: Text('Register'),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
