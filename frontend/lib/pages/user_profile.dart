import 'package:flutter/material.dart';
import 'package:frontend/models/user_models.dart';
import 'package:frontend/services/user_services.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/widgets/address_autocomplete.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _companyController;
  late TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();

  UserPublic? _currentUser;
  String? _newAddress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = await UserServices.getUserProfile();
      setState(() {
        _currentUser = user;
        _firstNameController = TextEditingController(text: user.firstName);
        _lastNameController = TextEditingController(text: user.lastName);
        _companyController = TextEditingController(text: user.companyName);
        _emailController = TextEditingController(text: user.email);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Account Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: "First Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: "Last Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              // Use your existing AddressAutocomplete (Optional mode)
              AddressAutocomplete(
                isRequired: false, 
                onSelected: (addr) => _newAddress = addr,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: "Company Name (Optional)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "New Password (Leave blank to keep current)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _updateProfile,
                  child: const Text("Save Changes"),
                ),
              ),
              const Divider(height: 60),
              TextButton(
                onPressed: _confirmDelete,
                child: const Text("Delete Account", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate() && _currentUser != null) {
      
      String? addressUpdate;
      if (_newAddress != null && 
          _newAddress!.trim().isNotEmpty && 
          _newAddress!.trim() != _currentUser!.address) {
        addressUpdate = _newAddress!.trim();
      } else {
        addressUpdate = null; 
      }

      final update = UserUpdate(
        firstName: _firstNameController.text.trim() != _currentUser!.firstName ? _firstNameController.text.trim() : null,
        lastName: _lastNameController.text.trim() != _currentUser!.lastName ? _lastNameController.text.trim() : null,
        companyName: _companyController.text.trim() != _currentUser!.companyName ? _companyController.text.trim() : null,
        address: addressUpdate, // Use our guarded variable
        email: _emailController.text.trim().toLowerCase() != _currentUser!.email ? _emailController.text.trim() : null,
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      );

      // 2. Guard: Don't hit the API if nothing valid changed
      if (update.firstName == null && 
          update.lastName == null && 
          update.companyName == null && 
          update.address == null && 
          update.email == null && 
          update.password == null) {
        Navigator.pop(context);
        return;
      }

      try {
        await UserServices.updateUser(_currentUser!.id, update);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
          Navigator.pop(context, true); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red)
          );
        }
      }
    }
  }



  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("All your appointments and mileage data will be permanently lost. This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    try {
    if (confirm == true) {
      await UserServices.deleteAccount(_currentUser!.id);
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const LoginPage()), 
        (route) => false
      );
    } } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'), backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
