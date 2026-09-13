import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/user.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController dobController;
  late TextEditingController courseController;
  late TextEditingController yearController;

  String? selectedGender;
  String? selectedQualification;
  String? selectedCategory;
  String? selectedState;
  String? selectedDistrict;

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
  void initState() {
    super.initState();
    final user = appState.currentUser;
    nameController = TextEditingController(text: user?.name ?? '');
    emailController = TextEditingController(text: user?.email ?? '');
    dobController = TextEditingController(text: user?.dob ?? '');
    courseController = TextEditingController(text: user?.course ?? '');
    yearController = TextEditingController(text: user?.yearOfPassing ?? '');

    selectedGender = user?.gender ?? 'Male';
    selectedQualification = user?.qualification ?? 'Degree';
    selectedCategory = user?.category ?? 'General';
    selectedState = user?.state ?? 'Kerala';
    selectedDistrict = user?.district ?? 'Ernakulam';
  }

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

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = appState.currentUser;
    final updatedUser = (currentUser ??
            const User(
              id: 'user_001',
              name: '',
              phone: '7012823414',
              email: '',
              dob: '',
              gender: 'Male',
              qualification: 'Degree',
              course: '',
              yearOfPassing: '',
              category: 'General',
              state: 'Kerala',
              district: 'Ernakulam',
            ))
        .copyWith(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      dob: dobController.text.trim(),
      gender: selectedGender,
      qualification: selectedQualification,
      course: courseController.text.trim(),
      yearOfPassing: yearController.text.trim(),
      category: selectedCategory,
      state: selectedState,
      district: selectedDistrict,
    );

    appState.updateProfile(updatedUser);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final availableDistricts = _stateDistricts[selectedState] ?? ['General'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: nameController,
                label: 'Full Name',
                required: true,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: emailController,
                label: 'Email Address',
                keyboardType: TextInputType.emailAddress,
                hint: 'name@example.com',
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Enter a valid email';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: dobController,
                label: 'Date of Birth',
                required: true,
                readOnly: true,
                onTap: _selectDateOfBirth,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'DOB is required' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Gender',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedGender,
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) => setState(() => selectedGender = val),
              ),
              const SizedBox(height: 16),

              const Text(
                'Highest Qualification',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedQualification,
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'Degree', child: Text('Degree / Graduation')),
                  DropdownMenuItem(value: 'Post Graduate', child: Text('Post Graduate / Master\'s')),
                  DropdownMenuItem(value: 'Plus Two / 12th', child: Text('Plus Two / 12th')),
                  DropdownMenuItem(value: 'SSLC / 10th Pass', child: Text('SSLC / 10th Pass')),
                  DropdownMenuItem(value: 'Diploma', child: Text('Polytechnic / Diploma')),
                ],
                onChanged: (val) => setState(() => selectedQualification = val),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: courseController,
                label: 'Course / Discipline',
                required: true,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Course is required' : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: yearController,
                label: 'Year of Passing',
                required: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Year is required' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'General', child: Text('General')),
                  DropdownMenuItem(value: 'OBC', child: Text('OBC')),
                  DropdownMenuItem(value: 'SC', child: Text('SC')),
                  DropdownMenuItem(value: 'ST', child: Text('ST')),
                  DropdownMenuItem(value: 'EWS', child: Text('EWS')),
                ],
                onChanged: (val) => setState(() => selectedCategory = val),
              ),
              const SizedBox(height: 16),

              const Text(
                'State',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
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

              const Text(
                'District',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
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
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      type: ButtonType.outlined,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Save Changes',
                      onPressed: _saveProfile,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
