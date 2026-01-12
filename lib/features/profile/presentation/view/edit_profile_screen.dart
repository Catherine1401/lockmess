import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/core/domain/entities/profile.dart';
import 'package:lockmess/features/profile/presentation/viewmodel/profile_provider.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final Profile initialProfile;

  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  String _selectedGender = '';
  DateTime? _selectedBirthday;
  List<String> _selectedHobbies = [];

  bool _isLoading = false;
  String? _usernameError;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.initialProfile.displayName,
    );
    _usernameController = TextEditingController(
      text: widget.initialProfile.username,
    );
    _phoneController = TextEditingController(text: widget.initialProfile.phone);
    _selectedGender = widget.initialProfile.gender.isEmpty
        ? 'Male'
        : widget.initialProfile.gender;
    _selectedBirthday = widget.initialProfile.birthday.isNotEmpty
        ? DateTime.tryParse(widget.initialProfile.birthday)
        : null;
    _selectedHobbies = List.from(widget.initialProfile.hobbies);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required';
    }
    if (value.trim().length < 2) {
      return 'Display name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Display name must be less than 50 characters';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    final username = value.trim();
    if (username.length < 3 || username.length > 30) {
      return 'Username must be 3-30 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return _usernameError;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    // Basic phone validation
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value.trim())) {
      return 'Invalid phone number';
    }
    return null;
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    if (username == widget.initialProfile.username) {
      setState(() => _usernameError = null);
      return;
    }

    final isAvailable = await ref
        .read(profileEditControllerProvider)
        .isUsernameAvailable(username, widget.initialProfile.id);

    setState(() {
      _usernameError = isAvailable ? null : 'Username already taken';
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() == false) {
      return;
    }

    if (_usernameError != null) {
      return;
    }

    if (_selectedHobbies.isEmpty) {
      _showError('Please select at least one hobby');
      return;
    }

    if (_selectedBirthday == null) {
      _showError('Please select your birthday');
      return;
    }

    // Validate age
    final age = DateTime.now().difference(_selectedBirthday!).inDays ~/ 365;
    if (age < 13 || age > 120) {
      _showError('Age must be between 13 and 120');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedProfile = Profile(
        id: widget.initialProfile.id,
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: _selectedGender,
        email: widget.initialProfile.email,
        avatarUrl: widget.initialProfile.avatarUrl, // Keep existing avatar
        birthday: _selectedBirthday!.toIso8601String().split('T')[0],
        hobbies: _selectedHobbies,
      );

      await ref
          .read(profileEditControllerProvider)
          .updateProfile(updatedProfile);

      if (mounted) {
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      _showError('Failed to update profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedBirthday = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white900,
      appBar: AppBar(
        backgroundColor: AppColors.white900,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.black900),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.black900,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.green500,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Display Name
            TextFormField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: _validateDisplayName,
            ),
            SizedBox(height: 16),

            // Username
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: _validateUsername,
              onChanged: (_) {
                setState(() => _usernameError = null);
              },
              onEditingComplete: _checkUsernameAvailability,
            ),
            SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone (optional)',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
            ),
            SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: _genderOptions
                  .map(
                    (gender) =>
                        DropdownMenuItem(value: gender, child: Text(gender)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedGender = value);
                }
              },
            ),
            SizedBox(height: 16),

            // Birthday
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.cake),
              title: Text('Birthday'),
              subtitle: Text(
                _selectedBirthday != null
                    ? DateFormat('dd/MM/yyyy').format(_selectedBirthday!)
                    : 'Not set',
              ),
              trailing: Icon(Icons.chevron_right),
              onTap: _selectBirthday,
            ),
            Divider(),
            SizedBox(height: 16),

            // Hobbies (from database)
            Text(
              'Hobbies',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Consumer(
              builder: (context, ref, child) {
                final hobbiesAsync = ref.watch(allHobbiesProvider);

                return hobbiesAsync.when(
                  data: (availableHobbies) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableHobbies.map((hobby) {
                        final isSelected = _selectedHobbies.contains(hobby);
                        return FilterChip(
                          label: Text(hobby),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedHobbies.add(hobby);
                              } else {
                                _selectedHobbies.remove(hobby);
                              }
                            });
                          },
                          selectedColor: AppColors.green500.withValues(
                            alpha: 0.2,
                          ),
                          checkmarkColor: AppColors.green500,
                        );
                      }).toList(),
                    );
                  },
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error loading hobbies'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
