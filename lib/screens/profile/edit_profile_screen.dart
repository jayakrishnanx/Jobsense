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
  late TextEditingController otherCourseController;
  late TextEditingController yearController;

  String? selectedGender;
  String? selectedQualification;
  String? selectedCourse;
  String? selectedCategory;
  String? selectedState;
  String? selectedDistrict;

  static const Map<String, List<String>> qualificationCourses = {
    'Post Graduate': [
      'MCA (Master of Computer Applications)',
      'M.Tech / M.E (Computer Science / IT)',
      'M.Tech / M.E (Civil / Mechanical / Electrical / EC)',
      'MBA (Master of Business Administration)',
      'M.Sc Computer Science / Data Science / IT',
      'M.Sc Mathematics / Statistics',
      'M.Sc Physics / Chemistry',
      'M.Sc Botany / Zoology / Life Sciences',
      'M.Com (Finance / Taxation / Banking)',
      'M.A Economics / English / History / Public Admin',
      'MSW (Master of Social Work)',
      'LL.M (Master of Laws)',
      'MD / MS (Medical Postgraduate)',
      'Other',
    ],
    'Degree': [
      'BCA (Bachelor of Computer Applications)',
      'B.Tech / B.E (Computer Science & Engineering)',
      'B.Tech / B.E (Civil Engineering)',
      'B.Tech / B.E (Mechanical Engineering)',
      'B.Tech / B.E (Electrical & Electronics)',
      'B.Tech / B.E (Electronics & Communication)',
      'B.Sc Computer Science / IT / AI',
      'B.Sc Mathematics / Statistics',
      'B.Sc Physics / Chemistry',
      'B.Sc Botany / Zoology / Agriculture',
      'B.Sc Nursing',
      'B.Com (Finance / Computer Applications / General)',
      'BBA / BBM (Business Administration)',
      'B.A Economics / Political Science / History',
      'B.A English / Literature / Languages',
      'B.Ed (Bachelor of Education)',
      'LL.B (Bachelor of Laws)',
      'MBBS / BDS / BAMS / BHMS',
      'B.Pharm (Bachelor of Pharmacy)',
      'B.Voc (Vocational Studies)',
      'Other',
    ],
    'Diploma': [
      'Diploma in Computer Engineering / IT',
      'Diploma in Civil Engineering',
      'Diploma in Mechanical Engineering',
      'Diploma in Electrical & Electronics',
      'Diploma in Electronics & Communication',
      'Diploma in Automobile Engineering',
      'Diploma in Pharmacy (D.Pharm)',
      'Diploma in General Nursing & Midwifery (GNM)',
      'Diploma in Medical Laboratory Technology (DMLT)',
      'Diploma in Commercial Practice / Secretarial',
      'Other',
    ],
    'Plus Two / 12th': [
      'Higher Secondary - Science (Bio-Maths / PCMB)',
      'Higher Secondary - Science (Computer Science)',
      'Higher Secondary - Commerce (with Computer Applications / Maths)',
      'Higher Secondary - Commerce (Cooperation)',
      'Higher Secondary - Humanities / Arts',
      'VHSE / Technical Higher Secondary',
      'Other',
    ],
    'SSLC / 10th Pass': [
      'General 10th Standard / SSLC Pass',
      'CBSE Class 10 (Secondary School)',
      'ICSE Class 10 (Secondary School)',
      'ITI / Trade Certificate (Electrician, Fitter, Welder, COPA)',
      'Other',
    ],
  };

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
    yearController = TextEditingController(text: user?.yearOfPassing ?? '');

    selectedGender = user?.gender ?? 'Male';
    selectedQualification = user?.qualification ?? 'Degree';
    selectedCategory = user?.category ?? 'General';
    selectedState = user?.state ?? 'Kerala';
    selectedDistrict = user?.district ?? 'Ernakulam';

    final courses = qualificationCourses[selectedQualification] ?? ['Other'];
    final userCourse = user?.course ?? '';

    if (courses.contains(userCourse)) {
      selectedCourse = userCourse;
      otherCourseController = TextEditingController();
    } else if (userCourse.isNotEmpty) {
      selectedCourse = 'Other';
      otherCourseController = TextEditingController(text: userCourse);
    } else {
      selectedCourse = courses.first;
      otherCourseController = TextEditingController();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    dobController.dispose();
    otherCourseController.dispose();
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

    final effectiveCourse = selectedCourse == 'Other'
        ? otherCourseController.text.trim()
        : (selectedCourse ?? '');

    final currentUser = appState.currentUser;
    final updatedUser = (currentUser ??
            const User(
              id: 'user_001',
              name: '',
              phone: '',
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
      course: effectiveCourse,
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
    final theme = Theme.of(context);
    final availableDistricts = _stateDistricts[selectedState] ?? ['General'];
    final availableCourses = qualificationCourses[selectedQualification] ?? ['General', 'Other'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                  required: true,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email is required';
                    if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email';
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
                  suffixIcon: const Icon(Icons.calendar_month),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Date of birth is required' : null,
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
                  'Highest Educational Qualification',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedQualification,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'Post Graduate', child: Text('Post Graduate / Master\'s')),
                    DropdownMenuItem(value: 'Degree', child: Text('Degree / Graduation')),
                    DropdownMenuItem(value: 'Diploma', child: Text('Polytechnic / Diploma')),
                    DropdownMenuItem(value: 'Plus Two / 12th', child: Text('Plus Two / 12th Pass')),
                    DropdownMenuItem(value: 'SSLC / 10th Pass', child: Text('SSLC / 10th Pass')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedQualification = val;
                      final courses = qualificationCourses[val] ?? ['Other'];
                      selectedCourse = courses.contains(selectedCourse) ? selectedCourse : courses.first;
                    });
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  'Course / Degree Discipline',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: availableCourses.contains(selectedCourse) ? selectedCourse : availableCourses.first,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  isExpanded: true,
                  items: availableCourses.map((c) {
                    return DropdownMenuItem<String>(
                      value: c,
                      child: Text(
                        c,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: c == 'Other' ? FontWeight.bold : FontWeight.normal,
                          color: c == 'Other' ? theme.colorScheme.primary : null,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedCourse = val;
                    });
                  },
                ),

                // Additional Text Field if "Other" is selected
                if (selectedCourse == 'Other') ...[
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: otherCourseController,
                    label: 'Specify Your Course / Degree',
                    hint: 'e.g. B.Tech Artificial Intelligence, B.Sc Forensic Science',
                    required: true,
                    prefixIcon: const Icon(Icons.edit_note_outlined),
                    validator: (val) {
                      if (selectedCourse == 'Other' && (val == null || val.trim().isEmpty)) {
                        return 'Please enter your course/degree name';
                      }
                      return null;
                    },
                  ),
                ],

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
                    DropdownMenuItem(value: 'General', child: Text('General / Unreserved')),
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
                const SizedBox(height: 32),

                CustomButton(
                  text: 'Save Changes',
                  onPressed: _saveProfile,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
