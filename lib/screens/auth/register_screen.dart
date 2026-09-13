import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/user.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String phoneNumber;

  const RegisterScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController yearController = TextEditingController();

  String? selectedGender = 'Male';
  String? selectedQualification = 'Degree';
  String? selectedCategory = 'General';
  String? selectedState = 'Kerala';
  String? selectedDistrict = 'Ernakulam';

  bool _isLoading = false;

  final Map<String, List<String>> _stateDistricts = {
    'Kerala': [
      'Ernakulam',
      'Thiruvananthapuram',
      'Kozhikode',
      'Kollam',
      'Thrissur',
      'Malappuram',
      'Palakkad',
      'Kannur',
      'Kottayam',
      'Alappuzha',
      'Idukki',
      'Pathanamthitta',
      'Kasaragod',
      'Wayanad',
    ],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem'],
    'Karnataka': ['Bengaluru Urban', 'Mysuru', 'Mangaluru', 'Hubballi-Dharwad', 'Belagavi'],
    'Delhi': ['New Delhi', 'Central Delhi', 'South Delhi', 'North Delhi'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Thane'],
  };

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    dobController.dispose();
    courseController.dispose();
    yearController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime(2010),
      initialDate: DateTime(2001, 6, 15),
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text =
            '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
      });
    }
  }

  void _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields properly'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final newUser = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: nameController.text.trim(),
      phone: widget.phoneNumber,
      email: emailController.text.trim(),
      dob: dobController.text.trim(),
      gender: selectedGender ?? 'Male',
      qualification: selectedQualification ?? 'Degree',
      course: courseController.text.trim(),
      yearOfPassing: yearController.text.trim(),
      category: selectedCategory ?? 'General',
      state: selectedState ?? 'Kerala',
      district: selectedDistrict ?? 'Ernakulam',
    );

    appState.registerUser(newUser);

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Account created successfully! Welcome, ${newUser.name}!'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableDistricts = _stateDistricts[selectedState] ?? ['General'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal & Education Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'JobSense analyzes these details to show notifications for jobs you are eligible for.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),

                // Phone (verified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Verified Mobile: +91 ${widget.phoneNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Full Name
                CustomTextField(
                  controller: nameController,
                  label: 'Full Name',
                  hint: 'e.g. Rahul Sharma',
                  required: true,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  controller: emailController,
                  label: 'Email Address',
                  hint: 'e.g. rahul@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty) {
                      if (!val.contains('@') || !val.contains('.')) {
                        return 'Enter a valid email address';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Date of Birth
                CustomTextField(
                  controller: dobController,
                  label: 'Date of Birth',
                  hint: 'DD/MM/YYYY',
                  required: true,
                  readOnly: true,
                  onTap: _selectDateOfBirth,
                  prefixIcon: const Icon(Icons.cake_outlined),
                  suffixIcon: const Icon(Icons.calendar_month),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please select your date of birth';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Gender Dropdown
                _buildDropdownLabel('Gender', required: true),
                DropdownButtonFormField<String>(
                  initialValue: selectedGender,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) => setState(() => selectedGender = val),
                  validator: (val) => val == null ? 'Select gender' : null,
                ),

                const SizedBox(height: 16),

                // Qualification Dropdown
                _buildDropdownLabel('Highest Educational Qualification', required: true),
                DropdownButtonFormField<String>(
                  initialValue: selectedQualification,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'Degree', child: Text('Degree / Graduation')),
                    DropdownMenuItem(value: 'Post Graduate', child: Text('Post Graduate / Master\'s')),
                    DropdownMenuItem(value: 'Plus Two / 12th', child: Text('Plus Two / 12th Pass')),
                    DropdownMenuItem(value: 'SSLC / 10th Pass', child: Text('SSLC / 10th Pass')),
                    DropdownMenuItem(value: 'Diploma', child: Text('Polytechnic / Diploma')),
                  ],
                  onChanged: (val) => setState(() => selectedQualification = val),
                ),

                const SizedBox(height: 16),

                // Course / Degree
                CustomTextField(
                  controller: courseController,
                  label: 'Course / Degree Name',
                  hint: 'e.g. BCA, B.Tech CS, B.Com, B.Sc Maths',
                  required: true,
                  prefixIcon: const Icon(Icons.school_outlined),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please specify your degree or course';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Year of Passing
                CustomTextField(
                  controller: yearController,
                  label: 'Year of Passing',
                  hint: 'e.g. 2025',
                  required: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  prefixIcon: const Icon(Icons.date_range_outlined),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter year of passing';
                    }
                    if (val.length != 4) {
                      return 'Enter a 4-digit year (e.g. 2025)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Category Dropdown
                _buildDropdownLabel('Reservation Category', required: true),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'General', child: Text('General / Unreserved (UR)')),
                    DropdownMenuItem(value: 'OBC', child: Text('OBC (Other Backward Classes)')),
                    DropdownMenuItem(value: 'SC', child: Text('SC (Scheduled Castes)')),
                    DropdownMenuItem(value: 'ST', child: Text('ST (Scheduled Tribes)')),
                    DropdownMenuItem(value: 'EWS', child: Text('EWS (Economically Weaker Section)')),
                  ],
                  onChanged: (val) => setState(() => selectedCategory = val),
                ),

                const SizedBox(height: 16),

                // State Dropdown
                _buildDropdownLabel('State of Domicile', required: true),
                DropdownButtonFormField<String>(
                  initialValue: selectedState,
                  decoration: const InputDecoration(),
                  items: _stateDistricts.keys.map((st) {
                    return DropdownMenuItem(value: st, child: Text(st));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedState = val;
                      selectedDistrict = _stateDistricts[val]?.first ?? 'General';
                    });
                  },
                ),

                const SizedBox(height: 16),

                // District Dropdown
                _buildDropdownLabel('District', required: true),
                DropdownButtonFormField<String>(
                  initialValue: availableDistricts.contains(selectedDistrict)
                      ? selectedDistrict
                      : availableDistricts.first,
                  decoration: const InputDecoration(),
                  items: availableDistricts.map((dist) {
                    return DropdownMenuItem(value: dist, child: Text(dist));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedDistrict = val),
                ),

                const SizedBox(height: 32),

                // Create Account Button
                CustomButton(
                  text: 'Create Account & Continue',
                  isLoading: _isLoading,
                  onPressed: _registerUser,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}