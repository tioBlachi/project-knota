import 'package:flutter/material.dart';
import 'package:frontend/models/user_models.dart';
import 'package:frontend/pages/edit_profile.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/services/user_services.dart';
import 'package:intl/intl.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  UserPublic? _currentUser;
  bool _isLoading = true;
  bool _didUpdate = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = await UserServices.getUserProfile();
      if (!mounted) return;

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context, _didUpdate);
    }
  }

  Future<void> _openEditProfile() async {
    final user = _currentUser;
    if (user == null) return;

    final bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(user: user),
      ),
    );

    if (updated == true) {
      _didUpdate = true;
      await _fetchProfile();
    }
  }

  Future<void> _confirmDelete() async {
    final user = _currentUser;
    if (user == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'All your appointments and mileage data will be permanently lost. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await UserServices.deleteAccount(user.id);
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _popWithResult() {
    Navigator.pop(context, _didUpdate);
  }

  String _displayValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'Not provided' : trimmed;
  }

  String _formatJoinDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    return DateFormat('MMMM d, y').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _popWithResult,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
          ? const Center(child: Text('Unable to load profile'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ProfileSection(
                  title: 'Business',
                  children: [
                    _ProfileRow(
                      label: 'Display Name',
                      value: _currentUser!.displayName,
                    ),
                    _ProfileRow(
                      label: 'Company Name',
                      value: _displayValue(_currentUser!.companyName),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Personal',
                  children: [
                    _ProfileRow(
                      label: 'First Name',
                      value: _currentUser!.firstName,
                    ),
                    _ProfileRow(
                      label: 'Last Name',
                      value: _currentUser!.lastName,
                    ),
                    _ProfileRow(
                      label: 'Email',
                      value: _currentUser!.email,
                    ),
                    _ProfileRow(
                      label: 'Address',
                      value: _currentUser!.address,
                    ),
                    _ProfileRow(
                      label: 'Member Since',
                      value: _formatJoinDate(_currentUser!.joinDate),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _openEditProfile,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Eventually figure out how to email validate a password'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Change Password'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _confirmDelete,
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
