import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Firebase Imports (Registration logic ke liye zaroori)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
// import 'package:countries_list/countries_list.dart'; // Removed
import 'family_member_flow.dart';

// End Firebase Imports
const Color deepNavy = Color(0xFF252A34);
const Color sectionBg = Color(0xFF2A303C);
const Color inputBg = Color(0xFF3A4250);
const Color teal = Color(0xFF08D9D6);
const Color coral = Color(0xFFFF2E63);
const Color whiteish = Color(0xFFEAEAEA);
const Color successGreen = Color(0xFF10B981);
const Color warningAmber = Color(0xFFF59E0B);

// Enhanced color palette with gradients
const LinearGradient primaryGradient = LinearGradient(
  colors: [Color(0xFF08D9D6), Color(0xFF00B4B2)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient secondaryGradient = LinearGradient(
  colors: [Color(0xFFFF2E63), Color(0xFFE01E5A)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient cardGradient = LinearGradient(
  colors: [Color(0xFF2A303C), Color(0xFF363D4C)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class RegistrationFlow extends StatefulWidget {
  const RegistrationFlow({super.key});

  @override
  State<RegistrationFlow> createState() => _RegistrationFlowState();
}

class _RegistrationFlowState extends State<RegistrationFlow> {
  String? selectedRole;

  // Common controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController =
      TextEditingController(); // Added Phone Controller
  final TextEditingController cnicController = TextEditingController();
  final TextEditingController fatherCnicController = TextEditingController();

  // ... (existing code)

  // Page Controller for Wizard
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Country List - Offline Fallback
  final List<String> allCountries = [
    "Pakistan",
    "Afghanistan",
    "India",
    "United States",
    "United Kingdom",
    "Canada",
    "Australia",
    "Other"
  ];

  // Pakistan Data Map
  final Map<String, dynamic> pakistanData = {
    // Provinces / Regions with important districts and tehsils (comprehensive)
    "Punjab": {
      "Lahore": [
        "Lahore Cantonment",
        "Gulberg",
        "Iqbal Town",
        "Data Gunj Bakhsh"
      ],
      "Faisalabad": ["Faisalabad City", "Jaranwala", "Tandlianwala"],
      "Rawalpindi": ["Rawalpindi Tehsil", "Gujar Khan", "Murree"],
      "Gujranwala": ["Gujranwala City", "Nowshera Virkan"],
      "Gujrat": ["Gujrat City", "Kharian"],
      "Sialkot": ["Sialkot City", "Daska"],
      "Multan": ["Multan City", "Musa Pak Shaheed"],
      "Bahawalpur": ["Bahawalpur City", "Hasilpur"],
      "Sargodha": ["Sargodha City", "Bhalwal"],
      "Sahiwal": ["Sahiwal City", "Chichawatni"],
      "Dera Ghazi Khan": ["Dera Ghazi Khan City", "Taunsa"],
      "Sheikhupura": ["Sheikhupura City", "Ferozewala"],
      "Kasur": ["Kasur City", "Pattoki"],
      "Khanewal": ["Khanewal City", "Jahanian"],
      "Vehari": ["Vehari City", "Burewala"],
      "Rahim Yar Khan": ["Rahim Yar Khan City", "Khanpur"],
      "Muzaffargarh": ["Muzaffargarh City", "Alipur"],
      "Okara": ["Okara City", "Renala Khurd"],
      "Pakpattan": ["Pakpattan City", "Arifwala"],
      "Lodhran": ["Lodhran City"],
      "Bhakkar": ["Bhakkar City"],
      "Jhang": ["Jhang City", "Shorkot"],
      "Mianwali": ["Mianwali City"],
      "Toba Tek Singh": ["Toba Tek Singh City"],
      "Hafizabad": ["Hafizabad City"],
      "Chiniot": ["Chiniot City"],
      "Narowal": ["Narowal City"],
      "Nankana Sahib": ["Nankana Sahib City"],
      "Attock": ["Attock City", "Jand"],
      "Chakwal": ["Chakwal City"],
      "Jhelum": ["Jhelum City"],
      "Khushab": ["Khushab City"],
      "Layyah": ["Layyah City"],
      "Rajanpur": ["Rajanpur City"],
      "Mandi Bahauddin": ["Mandi Bahauddin City"]
    },
    "Sindh": {
      "Karachi": ["Korangi", "Malir", "Gulshan", "Orangi", "Lyari"],
      "Hyderabad": ["Latifabad", "Qasimabad"],
      "Sukkur": ["Sukkur City"],
      "Larkana": ["Larkana City"],
      "Benazirabad": ["Nawabshah"],
      "Dadu": ["Dadu City"],
      "Khairpur": ["Khairpur City"]
    },
    "Khyber Pakhtunkhwa": {
      "Peshawar": ["Peshawar City", "Hayatabad", "Tehkal"],
      "Mardan": ["Mardan City"],
      "Swat": ["Mingora", "Kabal"],
      "Abbottabad": ["Abbottabad City"],
      "Kohat": ["Kohat City"],
      "Bannu": ["Bannu City"]
    },
    "Balochistan": {
      "Quetta": ["Quetta City", "Sariab"],
      "Gwadar": ["Gwadar City", "Pasni"],
      "Kalat": ["Kalat City"],
      "Sibi": ["Sibi City"]
    },
    "Islamabad": {
      "Islamabad": ["F-6", "F-7", "G-10", "G-11", "I-8", "I-10"]
    },
    "Azad Kashmir": {
      "Muzaffarabad": ["Muzaffarabad City"],
      "Mirpur": ["Dadyal"]
    },
    "Gilgit-Baltistan": {
      "Gilgit": ["Gilgit City"],
      "Skardu": ["Skardu City"]
    }
  };

  // Location State Variables
  String? selectedCountry;
  String? selectedProvince; // used only when country == "Pakistan"
  String? selectedDistrict;
  String? selectedTehsil;
  TextEditingController fullAddressController = TextEditingController();

  // Location Getters
  List<String> get countryList => allCountries;

  List<String> get provinceList =>
      selectedCountry == "Pakistan" ? pakistanData.keys.toList() : [];

  List<String> get districtList =>
      selectedCountry == "Pakistan" && selectedProvince != null
          ? pakistanData[selectedProvince]!.keys.toList()
          : [];

  List<String> get tehsilList => selectedCountry == "Pakistan" &&
          selectedProvince != null &&
          selectedDistrict != null
      ? List<String>.from(pakistanData[selectedProvince]![selectedDistrict])
      : [];

  // CNIC issue date
  DateTime? cnicIssueDate;

  // Location
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  bool _gettingLocation = false;

  // File placeholders (for display)
  String? cnicFrontFileName;
  String? cnicBackFileName;
  String? utilityBillFileName;
  String? passportPhotoFileName;
  String? policeVerificationFileName;
  String? affidavitFileName;

  // Local files for upload (Changed to XFile for Web support)
  XFile? cnicFrontFile;
  XFile? cnicBackFile;
  XFile? utilityBillFile;
  XFile? passportPhotoFile;
  XFile? policeVerificationFile;
  XFile? affidavitFile;

  // Cloudinary Upload Helper
  Future<String?> _uploadToCloudinary(XFile file) async {
    const cloudName = 'drposqmf0';
    const uploadPreset = 'flutter_uploads';

    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;
    request.headers['X-Requested-With'] = 'XMLHttpRequest';

    // Universally use bytes for upload (Works on Web & Mobile)
    final bytes = await file.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: file.name,
    ));

    try {
      debugPrint('Starting Cloudinary upload for ${file.name}...');
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200) {
        final secureUrl = jsonResponse['secure_url'];
        debugPrint('Cloudinary Upload Success: $secureUrl');
        return secureUrl;
      } else {
        debugPrint(
            'Cloudinary Upload Failed: ${response.statusCode} - $responseString');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary Upload Error: $e');
      return null;
    }
  }

  // Firebase Storage URLs (to save in Firestore)
  String? cnicFrontFileUrl;
  String? cnicBackFileUrl;
  String? utilityBillFileUrl;
  String? passportPhotoFileUrl;
  String? policeVerificationFileUrl;
  String? affidavitFileUrl;

  // Password fields
  String _password = '';
  String _confirmPassword = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool sameAsPermanent = false;

  @override
  void dispose() {
    fullNameController.dispose();
    fatherNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    cnicController.dispose();
    fatherCnicController.dispose();
    fullAddressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // --- helpers ---
  void _selectRole(String role) {
    setState(() {
      selectedRole = role;
      _clearForm();
    });
  }

  void _handleBackToRole() {
    setState(() {
      selectedRole = null;
      _clearForm();
    });
  }

  void _clearForm() {
    fullNameController.clear();
    fatherNameController.clear();
    emailController.clear();
    cnicController.clear();
    fatherCnicController.clear();
    // propertyController.clear(); // Removed
    cnicIssueDate = null;

    // Reset Location Selection
    selectedCountry = null;
    selectedProvince = null;
    selectedDistrict = null;
    selectedTehsil = null;
    fullAddressController.clear();
    _currentStep = 0; // Reset Step
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    cnicIssueDate = null;

    // Clear all file placeholders and paths
    cnicFrontFileName = null;
    cnicFrontFile = null;
    cnicFrontFileUrl = null;

    cnicBackFileName = null;
    cnicBackFile = null;
    cnicBackFileUrl = null;

    utilityBillFileName = null;
    utilityBillFile = null;
    utilityBillFileUrl = null;

    passportPhotoFileName = null;
    passportPhotoFile = null;
    passportPhotoFileUrl = null;

    policeVerificationFileName = null;
    policeVerificationFile = null;
    policeVerificationFileUrl = null;

    affidavitFileName = null;
    affidavitFile = null;
    affidavitFileUrl = null;

    _password = '';
    _confirmPassword = '';
    _obscurePassword = true;
    _obscureConfirmPassword = true;
    sameAsPermanent = false;
  }

  // Password rules (same as forgot password)
  Map<String, bool> _passwordRules(String pass) {
    return {
      'length': pass.length >= 8,
      'uppercase': RegExp(r'[A-Z]').hasMatch(pass),
      'lowercase': RegExp(r'[a-z]').hasMatch(pass),
      'number': RegExp(r'[0-9]').hasMatch(pass),
      'special': RegExp(r'[!@#$%^&*]').hasMatch(pass),
    };
  }

  // Replaced FilePicker with ImagePicker as requested
  Future<void> _pickImage(String key) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          switch (key) {
            case 'cnic_front':
              cnicFrontFileName = image.name;
              cnicFrontFile = image;
              break;
            case 'cnic_back':
              cnicBackFileName = image.name;
              cnicBackFile = image;
              break;
            case 'utility_bill':
              utilityBillFileName = image.name;
              utilityBillFile = image;
              break;
            case 'passport_photo':
              passportPhotoFileName = image.name;
              passportPhotoFile = image;
              break;
            case 'police_verification':
              policeVerificationFileName = image.name;
              policeVerificationFile = image;
              break;
            case 'affidavit':
              affidavitFileName = image.name;
              affidavitFile = image;
              break;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected: ${image.name}'),
            backgroundColor: teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      _showAlert('Image Picker Error', 'Error picking image: $e');
    }
  }

  // Firebase Storage Uploader
  // Put this helper inside the same class or file where you handle registration.

  Future<void> _pickCnicIssueDate() async {
    final now = DateTime.now();
    final initial = cnicIssueDate ?? DateTime(now.year - 5);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: teal,
            onPrimary: deepNavy,
            surface: sectionBg,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: deepNavy),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => cnicIssueDate = picked);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      if (kIsWeb) {
        // On web, directly call getCurrentPosition without permission checks
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _mapController.move(_selectedLocation!, 15);
          _gettingLocation = false;
        });
      } else {
        // Mobile permission check code
        bool serviceEnabled;
        LocationPermission permission;

        // Test if location services are enabled.
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _showAlert('Location Error', 'Location services are disabled.');
          setState(() => _gettingLocation = false);
          return;
        }

        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            _showAlert('Location Error', 'Location permissions are denied');
            setState(() => _gettingLocation = false);
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          _showAlert('Location Error',
              'Location permissions are permanently denied, we cannot request permissions.');
          setState(() => _gettingLocation = false);
          return;
        }

        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _mapController.move(_selectedLocation!, 15);
          _gettingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      _showAlert('Location Error', 'Could not get current location: $e');
      setState(() => _gettingLocation = false);
    }
  }

  void _validateAndNext() {
    if (_currentStep == 0) {
      // Step 1 - Personal Info validation
      if (fullNameController.text.trim().isEmpty) {
        _showAlert('Required', 'Please enter your Full Name.');
        return;
      }
      if (fatherNameController.text.trim().isEmpty) {
        _showAlert('Required', 'Please enter your Father Name.');
        return;
      }
      if (emailController.text.trim().isEmpty ||
          !RegExp(r'^[\w.-]+@[\w.-]+\.\w+$')
              .hasMatch(emailController.text.trim())) {
        _showAlert('Required', 'Please enter a valid Email Address.');
        return;
      }
      if (phoneController.text.trim().isEmpty ||
          phoneController.text.replaceAll(RegExp(r'\D'), '').length < 11) {
        _showAlert('Required', 'Please enter a valid 11-digit Phone Number.');
        return;
      }
      final cnicDigits = cnicController.text.replaceAll(RegExp(r'\D'), '');
      if (!RegExp(r'^\d{13}$').hasMatch(cnicDigits)) {
        _showAlert('Required', 'Please enter a valid 13-digit CNIC Number.');
        return;
      }
      if (cnicIssueDate == null) {
        _showAlert('Required', 'Please select CNIC Date of Issue.');
        return;
      }
      if (selectedRole == 'renter') {
        final fatherCnicDigits =
            fatherCnicController.text.replaceAll(RegExp(r'\D'), '');
        if (!RegExp(r'^\d{13}$').hasMatch(fatherCnicDigits)) {
          _showAlert(
              'Required', "Please enter a valid 13-digit Father's CNIC.");
          return;
        }
      }
    } else if (_currentStep == 1) {
      // Step 2 - Location validation
      if (selectedCountry == null) {
        _showAlert('Required', 'Please select a Country.');
        return;
      }
      if (selectedCountry == 'Pakistan') {
        if (selectedProvince == null) {
          _showAlert('Required', 'Please select a Province / Region.');
          return;
        }
        if (selectedDistrict == null) {
          _showAlert('Required', 'Please select a District.');
          return;
        }
        if (selectedTehsil == null) {
          _showAlert('Required', 'Please select a Tehsil / Town.');
          return;
        }
      }
      if (fullAddressController.text.trim().isEmpty) {
        _showAlert('Required', 'Please enter your Full Address.');
        return;
      }
      if (_selectedLocation == null) {
        _showAlert('Required', 'Please select your location on the map.');
        return;
      }
    }

    // All good — move to next step
    setState(() {
      _currentStep++;
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });
  }

  // Firebase Registration and Firestore Logic
  Future<void> _handleSubmit() async {
    final role = selectedRole;
    if (role == null) return;

    // --- Validation Checks ---
    if (fullNameController.text.trim().isEmpty ||
        fatherNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      _showAlert('Error', 'Please fill all required personal details.');
      return;
    }

    bool isPakistan = selectedCountry == "Pakistan";
    if (selectedCountry == null) {
      _showAlert('Error', 'Please select a Country.');
      return;
    }
    if (isPakistan) {
      if (isPakistan) {
        if (selectedProvince == null ||
            selectedDistrict == null ||
            selectedTehsil == null) {
          _showAlert('Error',
              'Please select your full address (Province, District, Tehsil/Town).');
          return;
        }
      }

      if (fullAddressController.text.trim().isEmpty) {
        _showAlert(
            'Error', 'Please enter your full address (House, Street, Area).');
        return;
      }
    }

    if (_selectedLocation == null) {
      _showAlert('Error', 'Please select your location on the map.');
      return;
    }

    final cnicTextRaw = cnicController.text.trim();
    final cnicText = cnicTextRaw.replaceAll(RegExp(r'\D'), '');

    if (cnicText.isEmpty || !RegExp(r'^\d{13}$').hasMatch(cnicText)) {
      _showAlert('Error', 'Please enter a valid 13-digit CNIC number.');
      return;
    }
    if (cnicIssueDate == null) {
      _showAlert('Error', 'Please pick CNIC Date of Issue.');
      return;
    }

    // File check using File variables
    if (cnicFrontFile == null ||
        cnicBackFile == null ||
        utilityBillFile == null ||
        passportPhotoFile == null) {
      _showAlert(
        'Error',
        'Please upload all common required documents (CNIC Front/Back, Utility Bill, Passport Photo).',
      );
      return;
    }

    // Role-specific checks
    if (role == 'owner') {
      if (policeVerificationFile == null) {
        _showAlert(
          'Error',
          'As an Owner, please upload the Police Verification document.',
        );
        return;
      }
    } else if (role == 'renter') {
      final fatherCnicTextRaw = fatherCnicController.text.trim();
      final fatherCnicText = fatherCnicTextRaw.replaceAll(RegExp(r'\D'), '');
      if (fatherCnicText.isEmpty ||
          !RegExp(r'^\d{13}$').hasMatch(fatherCnicText)) {
        _showAlert('Error', "Please enter a valid 13-digit Father's CNIC.");
        return;
      }
      if (affidavitFile == null) {
        _showAlert(
          'Error',
          'As a Renter, please upload the Affidavit document.',
        );
        return;
      }
    }

    // Password validations
    final passwordRules = _passwordRules(_password);
    if (_password.isEmpty ||
        _password != _confirmPassword ||
        passwordRules.values.where((v) => v).length < 4) {
      _showAlert(
        'Error',
        'Please ensure both passwords match and meet at least 4 of the password requirements.',
      );
      return;
    }
    // --- End Validation Checks ---

    setState(() {
      // Logic for saving state could be added here if needed for UI
    });

    final email = '$cnicText@muhallah.com'; // Consistent pseudo-email
    final firestore = FirebaseFirestore.instance;

    try {
      // 1. Create User in Firebase Authentication
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: _password);
      final userId = userCredential.user!.uid;

      // 2. Upload Documents to CLOUDINARY
      // We will upload available files and get their URLs

      // Helper to upload with timeout
      Future<String?> uploadWithTimeout(XFile file) async {
        try {
          return await _uploadToCloudinary(file)
              .timeout(const Duration(seconds: 30));
        } catch (e) {
          debugPrint("Upload timed out or failed: $e");
          return null;
        }
      }

      cnicFrontFileUrl = await uploadWithTimeout(cnicFrontFile!);
      cnicBackFileUrl = await uploadWithTimeout(cnicBackFile!);
      utilityBillFileUrl = await uploadWithTimeout(utilityBillFile!);
      passportPhotoFileUrl = await uploadWithTimeout(passportPhotoFile!);

      if (role == 'owner' && policeVerificationFile != null) {
        policeVerificationFileUrl =
            await uploadWithTimeout(policeVerificationFile!);
      } else if (role == 'renter' && affidavitFile != null) {
        affidavitFileUrl = await uploadWithTimeout(affidavitFile!);
      }

      // 3. Prepare and Save user data to Firestore
      final userData = {
        'uid': userId,
        'role': role,
        'fullName': fullNameController.text.trim(),
        'fatherName': fatherNameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(), // Save Phone Number
        'cnic': cnicText,
        'cnicIssueDate': _formatDate(cnicIssueDate!),
        // propertyAddress constructed from dropdowns and fields
        'propertyAddress': selectedCountry == "Pakistan"
            ? "$selectedTehsil, $selectedDistrict, $selectedProvince"
            : "$selectedCountry",

        // New fields as requested
        'country': selectedCountry,
        'province': selectedProvince,
        'district': selectedDistrict,
        'area': selectedTehsil,
        'fullAddress': fullAddressController.text.trim(),

        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'cnicFrontUrl': cnicFrontFileUrl,
        'cnicBackUrl': cnicBackFileUrl,
        'utilityBillUrl': utilityBillFileUrl,
        'passportPhotoUrl': passportPhotoFileUrl,
        'registrationDate': FieldValue.serverTimestamp(),
        'status': 'pending_verification',
        'password': _password, // Storing password for Hybrid Login fallback
      };

      if (role == 'owner') {
        userData['policeVerificationUrl'] = policeVerificationFileUrl;
      } else if (role == 'renter') {
        userData['fatherCnic'] = fatherCnicController.text.trim().replaceAll(
              RegExp(r'\D'),
              '',
            );
        userData['affidavitUrl'] = affidavitFileUrl;
      }

      await firestore.collection('users').doc(userId).set(userData);

      // On successful Auth and Firestore write: show success and navigate
      if (mounted) setState(() {});

      // Check if any uploads failed to warn the user, or just success
      bool anyUploadFailed = cnicFrontFileUrl == null ||
          cnicBackFileUrl == null ||
          utilityBillFileUrl == null ||
          passportPhotoFileUrl == null ||
          (role == 'owner' && policeVerificationFileUrl == null) ||
          (role == 'renter' && affidavitFileUrl == null);

      String successMessage =
          'Your ${role == 'owner' ? 'Owner' : 'Renter'} registration has been submitted.';
      if (anyUploadFailed) {
        successMessage +=
            '\n\nNote: Some documents failed to upload due to network issues, but your account was created. Please contact admin to provide documents.';
      } else {
        successMessage += ' Please log in now.';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: sectionBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Success',
              style: TextStyle(color: whiteish, fontWeight: FontWeight.bold),
            ),
            content: Text(
              successMessage,
              style: const TextStyle(color: whiteish),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Navigating to Login Screen as requested
                  Navigator.pushReplacementNamed(
                    context,
                    '/login',
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: deepNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for this CNIC.';
      } else {
        message = 'Registration failed: ${e.message}';
      }
      if (mounted) {
        _showAlert('Registration Error', message);
        setState(() {});
      }
    } catch (e) {
      // Critical error (Firestore write failed?)
      debugPrint("CRITICAL ERROR DURING REGISTRATION: $e");

      // Rollback Auth if Firestore failed
      try {
        await FirebaseAuth.instance.currentUser?.delete();
        debugPrint("Rollback successful: User deleted from Auth.");
      } catch (deleteError) {
        debugPrint("Rollback failed: Could not delete user. $deleteError");
      }

      final message = e.toString();
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content:
                Text('Registration failed (Database Error). Details: $message'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'))
            ],
          ),
        );
        setState(() {});
      }
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: sectionBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: whiteish)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: teal)),
          ),
        ],
      ),
    );
  }

  // --- UI build ---
  @override
  Widget build(BuildContext context) {
    // Role selection screen - clean professional design
    if (selectedRole == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1923),
        appBar: AppBar(
          title: const Text('Select Role'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildRoleSelection(),
          ),
        ),
      );
    }

    // Registration form screen - existing design
    return Scaffold(
      backgroundColor: deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced AppBar with gradient
            Container(
              decoration: const BoxDecoration(
                gradient: primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  'Complete Your ${selectedRole == 'owner' ? 'Owner' : 'Renter'} Profile',
                  style: const TextStyle(
                    color: deepNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: deepNavy),
                  onPressed: _handleBackToRole,
                ),
                centerTitle: true,
              ),
            ),
            // Main content with proper constraints
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildFormForRole(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 32),

          // ── Top Icon + Title ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF08D9D6), Color(0xFF00B4B2)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF08D9D6).withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),

          const SizedBox(height: 24),

          // ── Heading ──
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF08D9D6), Color(0xFFFF2E63)],
            ).createShader(bounds),
            child: const Text(
              'Register as',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Choose your role to join your\nneighborhood community',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 48),

          // ── OWNER CARD ──
          GestureDetector(
            onTap: () => _selectRole('owner'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E1B4B), Color(0xFF2D1B69)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFF2E63).withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2E63).withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon Box
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF2E63), Color(0xFFE01E5A)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF2E63).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Owner',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Register as Owner in your community',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Tag badges
                        Wrap(
                          spacing: 8,
                          children: [
                            _roleBadge(
                                'Property Owner', const Color(0xFFFF2E63)),
                            _roleBadge('Verified', const Color(0xFFFF2E63)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2E63).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFFFF2E63),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── OR DIVIDER ──
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── RENTER CARD ──
          GestureDetector(
            onTap: () => _selectRole('renter'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F2A2A), Color(0xFF0D3333)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF08D9D6).withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF08D9D6).withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon Box
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF08D9D6), Color(0xFF00B4B2)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF08D9D6).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Renter',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Register as Renter in your community',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            _roleBadge('Tenant', const Color(0xFF08D9D6)),
                            _roleBadge('Verified', const Color(0xFF08D9D6)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF08D9D6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF08D9D6),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── OR DIVIDER ──
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── FAMILY MEMBER CARD ──
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FamilyMemberTypeScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A0F3E), Color(0xFF2D1B69)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon Box
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.family_restroom_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Family Member',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Register as a family member in your community',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            _roleBadge('Family', const Color(0xFF7C3AED)),
                            _roleBadge('Linked', const Color(0xFF7C3AED)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF7C3AED),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _roleBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFormForRole() {
    final isOwner = selectedRole == 'owner';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [teal, coral],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: Text(
              isOwner ? 'Owner Registration' : 'Renter Registration',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Simple Step Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stepHeader(0, "Personal"),
            _stepLine(0),
            _stepHeader(1, "Location"),
            _stepLine(1),
            _stepHeader(2, "Finalize"),
          ],
        ),
        const SizedBox(height: 20),

        // Wizard Pages
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (p) => setState(() => _currentStep = p),
            children: [
              _buildStep1Personal(isRenter: selectedRole == 'renter'),
              _buildStep2Location(),
              _buildStep3Finalize(
                  isOwner: isOwner, isRenter: selectedRole == 'renter'),
            ],
          ),
        ),

        // Navigation Buttons
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                      _pageController.animateToPage(_currentStep,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease);
                    });
                  },
                  child: const Text("Back", style: TextStyle(color: whiteish)),
                )
              else
                const SizedBox(),
              ElevatedButton(
                onPressed: () {
                  if (_currentStep < 2) {
                    _validateAndNext();
                  } else {
                    _handleSubmit();
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF1565C0), // professional blue shade
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: Text(_currentStep < 2 ? "Next" : "Register"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Step 1: Personal Info ---
  Widget _buildStep1Personal({required bool isRenter}) {
    return SingleChildScrollView(
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: cardGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _fieldLabel('Full Name'),
              _textInput(fullNameController, hint: 'Enter full name'),
              const SizedBox(height: 16),
              _fieldLabel('Father Name'),
              _textInput(fatherNameController, hint: 'Enter father name'),
              const SizedBox(height: 16),
              _fieldLabel('Email Address'),
              _textInput(
                emailController,
                hint: 'Enter email address (e.g., name@example.com)',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Phone Number Field
              _fieldLabel('Phone Number'),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: inputBg,
                  border: Border.all(color: Colors.white12),
                ),
                child: TextFormField(
                  controller: phoneController,
                  style: const TextStyle(color: whiteish),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                    _PakistaniPhoneFormatter(),
                  ],
                  decoration: const InputDecoration(
                    hintText: "0XXX-XXXXXXX",
                    hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: Icon(Icons.phone, color: teal),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Phone number is required";
                    }
                    if (v.length < 11) return "Enter valid phone number";
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _fieldLabel('CNIC Number'),
              _textInput(
                cnicController,
                hint: 'XXXXX-XXXXXXX-X',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(13),
                ],
                onChanged: (v) {
                  final formatted = _formatCnicDigits(v);
                  if (cnicController.text != formatted) {
                    cnicController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel('CNIC Date of Issue'),
              GestureDetector(
                onTap: _pickCnicIssueDate,
                child: AbsorbPointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: TextEditingController(
                        text: cnicIssueDate == null
                            ? ''
                            : _formatDate(cnicIssueDate!),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Pick date of issue',
                        hintStyle: const TextStyle(color: Colors.white60),
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: InputBorder.none,
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.calendar_today,
                                color: deepNavy, size: 20),
                            onPressed: _pickCnicIssueDate,
                          ),
                        ),
                      ),
                      style: const TextStyle(color: whiteish),
                    ),
                  ),
                ),
              ),
              if (isRenter) ...[
                const SizedBox(height: 16),
                _fieldLabel("Father's CNIC Number"),
                _textInput(
                  fatherCnicController,
                  hint: 'XXXXX-XXXXXXX-X (Father)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(13),
                  ],
                  onChanged: (v) {
                    final formatted = _formatCnicDigits(v);
                    if (fatherCnicController.text != formatted) {
                      fatherCnicController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 2: Location ---
  Widget _buildStep2Location() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(2.0), // small padding
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: cardGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Country Dropdown
                DropdownButtonFormField<String>(
                  value: selectedCountry,
                  decoration: const InputDecoration(
                      labelText: "Country",
                      labelStyle: TextStyle(color: Colors.white70)),
                  dropdownColor: inputBg,
                  style: const TextStyle(color: whiteish),
                  items: countryList
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedCountry = v;
                      selectedProvince = null;
                      selectedDistrict = null;
                      selectedTehsil = null;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Province Dropdown
                if (selectedCountry == "Pakistan") ...[
                  DropdownButtonFormField<String>(
                    value: selectedProvince,
                    decoration: const InputDecoration(
                        labelText: "Province / Region",
                        labelStyle: TextStyle(color: Colors.white70)),
                    dropdownColor: inputBg,
                    style: const TextStyle(color: whiteish),
                    items: provinceList
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedProvince = v;
                        selectedDistrict = null;
                        selectedTehsil = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // District Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedDistrict,
                    decoration: const InputDecoration(
                        labelText: "District",
                        labelStyle: TextStyle(color: Colors.white70)),
                    dropdownColor: inputBg,
                    style: const TextStyle(color: whiteish),
                    items: districtList
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedDistrict = v;
                        selectedTehsil = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Tehsil Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedTehsil,
                    decoration: const InputDecoration(
                        labelText: "Tehsil / Town",
                        labelStyle: TextStyle(color: Colors.white70)),
                    dropdownColor: inputBg,
                    style: const TextStyle(color: whiteish),
                    items: tehsilList
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedTehsil = v;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Info Text
                if (selectedTehsil != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "During select location you are within the Muhallah.",
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: successGreen),
                    ),
                  ),

                // Full Address Field
                TextFormField(
                  controller: fullAddressController,
                  maxLines: 3,
                  style: const TextStyle(color: whiteish),
                  decoration: const InputDecoration(
                    labelText: "Full Address (house, street, area)",
                    alignLabelWithHint: true,
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Please enter full address";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Map (Keep existing map to ensure _selectedLocation is set)
                _fieldLabel('Location (Tap to select)'),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Listener(
                          onPointerDown: (_) =>
                              FocusScope.of(context).unfocus(),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all &
                                    ~InteractiveFlag.rotate,
                              ),
                              initialCenter: const LatLng(
                                  31.5204, 74.3587), // Lahore default
                              initialZoom: 13.0,
                              onTap: (tapPosition, point) {
                                setState(() {
                                  _selectedLocation = point;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.muhallah',
                              ),
                              if (_selectedLocation != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _selectedLocation!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: coral,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: teal,
                            onPressed: _getCurrentLocation,
                            child: _gettingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: deepNavy,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.my_location,
                                    color: deepNavy),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedLocation == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Please select your location on the map',
                      style: TextStyle(color: warningAmber, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Step 3: Finalize ---
  Widget _buildStep3Finalize({required bool isOwner, required bool isRenter}) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Column(
          children: [
            // Documents Section
            Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: cardGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Required Documents',
                      style: TextStyle(
                        color: whiteish,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Please upload all required documents (PDF, JPG, PNG, DOC allowed)',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),

                    // Uploads (common)
                    _uploadSection(
                      'CNIC (Front)',
                      cnicFrontFileName,
                      () => _pickImage('cnic_front'),
                    ),
                    const SizedBox(height: 12),
                    _uploadSection(
                      'CNIC (Back)',
                      cnicBackFileName,
                      () => _pickImage('cnic_back'),
                    ),
                    const SizedBox(height: 12),
                    _uploadSection(
                      'Utility Bill',
                      utilityBillFileName,
                      () => _pickImage('utility_bill'),
                    ),
                    const SizedBox(height: 12),
                    _uploadSection(
                      'Passport Photo',
                      passportPhotoFileName,
                      () => _pickImage('passport_photo'),
                    ),

                    // Owner specific uploads
                    if (isOwner) ...[
                      const SizedBox(height: 12),
                      _uploadSection(
                        'Police Verification',
                        policeVerificationFileName,
                        () => _pickImage('police_verification'),
                      ),
                    ],
                    // Renter specific uploads
                    if (isRenter) ...[
                      const SizedBox(height: 12),
                      _uploadSection(
                        'Affidavit',
                        affidavitFileName,
                        () => _pickImage('affidavit'),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Password Section
            Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: cardGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Account Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [teal, coral],
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a strong password for your account security',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    const Text(
                      'Password',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        obscureText: _obscurePassword,
                        onChanged: (v) => setState(() => _password = v),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: teal.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: teal, width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: teal,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    const Text(
                      'Confirm Password',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        obscureText: _obscureConfirmPassword,
                        onChanged: (v) => setState(() => _confirmPassword = v),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: teal.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: teal, width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: teal,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Password Strength Indicator
                    if (_password.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildPasswordStrength(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- Wizard Helpers ---
  Widget _stepHeader(int index, String title) {
    bool isActive = _currentStep >= index;
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? teal : Colors.grey,
          child: Text('${index + 1}',
              style: const TextStyle(
                  color: deepNavy, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(title,
            style: TextStyle(
                color: isActive ? whiteish : Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _stepLine(int index) {
    return Container(
      width: 40,
      height: 2,
      color: _currentStep > index ? teal : Colors.grey,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
    );
  }

  // --- Helper Widgets (Unchanged functionality) ---

  // CNIC Formatting helper
  String _formatCnicDigits(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    final limited =
        digitsOnly.length > 13 ? digitsOnly.substring(0, 13) : digitsOnly;
    if (limited.length <= 5) return limited;
    if (limited.length <= 12) {
      return '${limited.substring(0, 5)}-${limited.substring(5)}';
    }
    return '${limited.substring(0, 5)}-${limited.substring(5, 12)}-${limited.substring(12)}';
  }

  Widget _buildPasswordStrength() {
    final rules = _passwordRules(_password);
    final strengthCount = rules.values.where((v) => v).length;
    final widthFactor = (strengthCount / rules.length).clamp(0.0, 1.0);
    Color strengthColor = Colors.red;
    if (strengthCount >= 4) {
      strengthColor = successGreen;
    } else if (strengthCount >= 2) strengthColor = warningAmber;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔒 Password Requirements:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _ruleRow(rules['length']!, 'Minimum 8 characters'),
          _ruleRow(rules['uppercase']!, 'Uppercase letter'),
          _ruleRow(rules['lowercase']!, 'Lowercase letter'),
          _ruleRow(rules['number']!, 'At least one number'),
          _ruleRow(rules['special']!, 'Special character (!@#\$%^&*)'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Password Strength',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                strengthCount == 5
                    ? 'Strong'
                    : strengthCount >= 3
                        ? 'Medium'
                        : 'Weak',
                style: TextStyle(
                  color: strengthColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [strengthColor, strengthColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: strengthColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleRow(bool ok, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: ok ? successGreen : Colors.transparent,
              border: Border.all(color: ok ? successGreen : Colors.redAccent),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ok ? Icons.check : Icons.close,
              color: ok ? Colors.white : Colors.redAccent,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: ok ? Colors.white70 : Colors.redAccent,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // Enhanced helper widgets
  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: whiteish,
            letterSpacing: 0.5,
          ),
        ),
      );

  // Updated _textInput to include formatters
  Widget _textInput(
    TextEditingController controller, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: const TextStyle(color: whiteish),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white60),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _uploadSection(
    String title,
    String? fileName,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: whiteish,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileName ?? 'No file selected',
                    style: TextStyle(
                      color: fileName != null ? teal : Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: onPressed,
                  icon: const Icon(Icons.upload, color: deepNavy, size: 20),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PakistaniPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    String formatted;
    if (limited.length <= 4) {
      formatted = limited;
    } else {
      formatted = '${limited.substring(0, 4)}-${limited.substring(4)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
