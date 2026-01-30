import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/features/chats/presentation/viewmodel/chat_provider.dart';

class CreateChannelScreen extends ConsumerStatefulWidget {
  const CreateChannelScreen({super.key});

  @override
  ConsumerState<CreateChannelScreen> createState() =>
      _CreateChannelScreenState();
}

class _CreateChannelScreenState extends ConsumerState<CreateChannelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _channelNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedHobbyIds = {};
  bool _isCreating = false;

  @override
  void dispose() {
    _channelNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateChannelName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Channel name is required';
    }
    if (value.trim().length < 3) {
      return 'Channel name must be at least 3 characters';
    }
    return null;
  }

  Future<void> _createChannel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final conversation = await ref
          .read(groupControllerProvider)
          .createChannel(
            name: _channelNameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            hobbyIds: _selectedHobbyIds.toList(),
          );

      if (mounted) {
        context.pop(conversation);
      }
    } catch (e) {
      _showError('Failed to create channel: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showError(String message) {
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

  Widget build(BuildContext context) {
    final hobbiesAsync = ref.watch(hobbiesListProvider);

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
          'Create Channel',
          style: TextStyle(
            color: AppColors.black900,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createChannel,
            child: _isCreating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Create',
                    style: TextStyle(
                      color: AppColors.green500,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Channel info section
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _channelNameController,
                      decoration: InputDecoration(
                        labelText: 'Channel Name',
                        prefixIcon: Icon(Icons.tag),
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateChannelName,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),

                    // Hobbies Section
                    Container(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Hobbies',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black900,
                            ),
                          ),
                          SizedBox(height: 8),
                          hobbiesAsync.when(
                            data: (hobbies) {
                              if (hobbies.isEmpty)
                                return Text('No hobbies found');
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: hobbies.map((hobby) {
                                  // Hobbies ID might be int (bigint), convert to string for Set
                                  final hobbyId = hobby['id'].toString();
                                  final isSelected = _selectedHobbyIds.contains(
                                    hobbyId,
                                  );

                                  return FilterChip(
                                    label: Text(hobby['name']),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedHobbyIds.add(hobbyId);
                                        } else {
                                          _selectedHobbyIds.remove(hobbyId);
                                        }
                                      });
                                    },
                                    backgroundColor: AppColors.gray100,
                                    selectedColor: AppColors.green500
                                        .withOpacity(0.2),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? AppColors.green500
                                          : AppColors.black900,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected
                                            ? AppColors.green500
                                            : AppColors.gray200,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                            loading: () =>
                                Center(child: CircularProgressIndicator()),
                            error: (e, _) => Text('Error loading hobbies: $e'),
                          ),
                        ],
                      ),
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
