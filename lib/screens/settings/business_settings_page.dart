import 'package:flutter/material.dart';

import '../../db/database_helper.dart';

import 'package:file_picker/file_picker.dart';

import 'dart:io';

class BusinessSettingsPage extends StatefulWidget {
  const BusinessSettingsPage({super.key});

  @override
  State<BusinessSettingsPage> createState() => _BusinessSettingsPageState();
}

class _BusinessSettingsPageState extends State<BusinessSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _logoPath;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.getBusinessSettings();

    if (!mounted) return;

    if (settings != null) {
      _businessNameController.text =
          settings['business_name']?.toString() ?? '';

      _phoneController.text = settings['phone']?.toString() ?? '';

      _emailController.text = settings['email']?.toString() ?? '';

      _addressController.text = settings['address']?.toString() ?? '';
    }
    _logoPath = settings?['logo_path']?.toString();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await DatabaseHelper.saveBusinessSettings({
        'business_name': _businessNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'logo_path': _logoPath,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      setState(() {
        _hasChanges = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business settings saved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (!_hasChanges) {
              Navigator.pop(context);
              return;
            }

            final shouldLeave = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Unsaved Changes'),
                  content: const Text(
                    'You have unsaved changes. Do you want to leave without saving?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: const Text('Stay'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      child: const Text('Leave'),
                    ),
                  ],
                );
              },
            );

            if (shouldLeave == true && mounted) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Business Information',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'These details can be used on invoices and PDF documents.',
                          style: TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(height: 30),

                        TextFormField(
                          controller: _businessNameController,
                          decoration: const InputDecoration(
                            labelText: 'Business Name',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _hasChanges = true;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Business name is required.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _hasChanges = true;
                            });
                          },
                          validator: (value) {
                            final phone = value?.trim() ?? '';

                            if (phone.isEmpty) {
                              return null;
                            }

                            if (!RegExp(r'^07\d{8}$').hasMatch(phone)) {
                              return 'Enter a valid Sri Lankan mobile number.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _hasChanges = true;
                            });
                          },
                          validator: (value) {
                            final email = value?.trim() ?? '';

                            if (email.isEmpty) {
                              return null;
                            }

                            if (!email.contains('@') || !email.contains('.')) {
                              return 'Enter a valid email address.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Business Address',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _hasChanges = true;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Business Logo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 6),

                              const Text(
                                'Select a logo image to use on invoices and PDF documents.',
                                style: TextStyle(color: Colors.grey),
                              ),

                              const SizedBox(height: 12),

                              if (_logoPath != null && _logoPath!.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_logoPath!),
                                        width: 140,
                                        height: 100,
                                        fit: BoxFit.contain,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      _logoPath!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),

                              const SizedBox(height: 10),

                              OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await FilePicker.platform
                                      .pickFiles(type: FileType.image);

                                  if (result != null &&
                                      result.files.single.path != null) {
                                    setState(() {
                                      _logoPath = result.files.single.path;
                                      _hasChanges = true;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.upload),
                                label: const Text('Select Logo'),
                              ),

                              if (_logoPath != null &&
                                  _logoPath!.isNotEmpty) ...[
                                const SizedBox(height: 8),

                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _logoPath = null;
                                      _hasChanges = true;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Remove Logo',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: (_isSaving || !_hasChanges)
                                ? null
                                : _saveSettings,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              _isSaving
                                  ? 'Saving...'
                                  : 'Save Business Settings',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
