import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:frontend/widgets/required_label.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formGlobalKey = GlobalKey<FormState>();
  bool _hidePassword = true;
  String? _selectedAddress;

  final List<String> _allSuggestions = [
  '16318 NW 18TH ST, PEMBROKE PINES, FL 33028',
  '16318 SW 10TH ST, PEMBROKE PINES, FL 33027',
  '16318 OAKMONT DR, DELRAY BEACH, FL 33446',
  '320 SE 2ND AVE, DEERFIELD BEACH, FL 33441',
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Registration Page"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Register for a Knota account",
                style: TextStyle(fontSize: 30),
                textAlign: TextAlign.center,
              ),

              const SizedBox(
                height: 30,
              ),

              Form(
                key: _formGlobalKey,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),

                    // first name input
                    TextFormField(
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

                    const SizedBox(
                      height: 20,
                    ),

                    // last name input
                    TextFormField(
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
                    ///////////////////////// Autocomplete test area
                    const SizedBox(height: 20),

                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }

                        final query = textEditingValue.text.toUpperCase();

                        return _allSuggestions.where((address) => address.startsWith(query));
                      },
                      onSelected: (String selection) {
                        setState(() {
                          _selectedAddress = selection;
                        });
                      },
                      fieldViewBuilder: (
                        context,
                        textEditingController,
                        focusNode,
                        onFieldSubmitted,
                      ) {
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.streetAddress,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Address is required';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            label: RequiredLabel(label: 'Origin Address'),
                          ),
                        );
                      },
                    ),
                    /////////////////////////
                    const SizedBox(
                      height: 20,
                    ),

                    // company name input
                    TextFormField(
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

                    const SizedBox(
                      height: 20,
                    ),

                    // email input
                    TextFormField(
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

                    // password input
                    const SizedBox(
                      height: 20,
                    ),

                    TextFormField(
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

                    const SizedBox(
                      height: 50,
                    ),

                    // login button
                    FilledButton(
                      onPressed: () {
                        if (_formGlobalKey.currentState!.validate()) {
                          debugPrint(
                            'All registration values pass!\nAdd to database',
                          );
                        } else {
                          debugPrint(
                            'Something is wrong! Cannot add to database',
                          );
                        }
                      },
                      child: Text('Register'),
                    ),

                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
