import 'package:flutter/material.dart';
import 'package:frontend/models/user_models.dart';
import 'package:frontend/services/user_services.dart';
import 'package:frontend/widgets/address_autocomplete.dart';

class EditProfilePage extends StatefulWidget {
  final UserPublic user;

  const EditProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _newAddress;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.user.firstName;
    _lastNameController.text = widget.user.lastName;
    _companyController.text = widget.user.companyName ?? '';
    _emailController.text = widget.user.email;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    String? addressUpdate;
    if (_newAddress != null &&
        _newAddress!.trim().isNotEmpty &&
        _newAddress!.trim() != widget.user.address) {
      addressUpdate = _newAddress!.trim();
    }

    final companyText = _companyController.text.trim();
    final currentCompany = widget.user.companyName?.trim() ?? '';

    final update = UserUpdate(
      firstName: _firstNameController.text.trim() != widget.user.firstName
          ? _firstNameController.text.trim()
          : null,
      lastName: _lastNameController.text.trim() != widget.user.lastName
          ? _lastNameController.text.trim()
          : null,
      companyName: companyText != currentCompany ? companyText : null,
      address: addressUpdate,
      email: _emailController.text.trim().toLowerCase() != widget.user.email
          ? _emailController.text.trim()
          : null,
    );

    if (update.firstName == null &&
        update.lastName == null &&
        update.companyName == null &&
        update.address == null &&
        update.email == null) {
      Navigator.pop(context);
      return;
    }

    try {
      await UserServices.updateUser(widget.user.id, update);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              AddressAutocomplete(
                isRequired: false,
                onSelected: (addr) => _newAddress = addr,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Current address: ${widget.user.address.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company Name (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _updateProfile,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
