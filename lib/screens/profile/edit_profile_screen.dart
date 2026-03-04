import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'utils/profile_constants.dart';
import 'utils/location_data.dart';
import 'delete_account_screen.dart'; // Keeping for navigation

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Mode
  final bool _isEditing = true; // Always editing in this screen
  bool _isLoading = true;
  bool _isSaving = false;

  // User Data & Controllers
  final _formKey = GlobalKey<FormState>();
  User? _currentUser;
  Map<String, dynamic>? _userData;

  // Personal Info
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _cnicController =
      TextEditingController(); // Read-only
  final TextEditingController _fatherCnicController =
      TextEditingController(); // Read-only
  DateTime? _cnicIssueDate;

  // Contact Info
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fullAddressController = TextEditingController();

  // Location Data
  String? _selectedCountry;
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedTehsil;
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();

  // Document URLs (View Only)
  String? _cnicFrontUrl;
  String? _cnicBackUrl;
  String? _utilityBillUrl;
  String? _passportPhotoUrl;
  String? _policeVerificationUrl;
  String? _affidavitUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- Fetch Data ---
  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (doc.exists) {
          _userData = doc.data();
          _populateFields(_userData!);
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      _showSnackbar('Error loading profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    _fullNameController.text = data['fullName'] ?? '';
    _fatherNameController.text = data['fatherName'] ?? '';
    _cnicController.text = data['cnic'] ?? '';
    _fatherCnicController.text = data['fatherCnic'] ?? '';

    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _fullAddressController.text = data['fullAddress'] ?? '';

    // Dates
    if (data['cnicIssueDate'] != null) {
      try {
        // Assuming stored as string "YYYY-MM-DD" or similar, parse it.
        // Registration screen stores it via _formatDate, we need to handle parsing.
        // If stored as Timestamp? The registration code typically stores string or Timestamp.
        // Let's assume standard format or Timestamp.
        // Checking registration: 'cnicIssueDate': _formatDate(cnicIssueDate!), where _formatDate usually returns String.
        // We'll try to parse string.
        _cnicIssueDate = DateFormat('yyyy-MM-dd').parse(data['cnicIssueDate']);
      } catch (_) {
        // If parsing fails or it's not a string matching that format
      }
    }

    // Location
    _selectedCountry = data['country'];
    _selectedProvince = data['province'];
    _selectedDistrict = data['district'];
    _selectedTehsil = data['area']; // Registration saves 'area' as tehsil

    if (data['latitude'] != null && data['longitude'] != null) {
      _selectedLocation = LatLng(
        (data['latitude'] as num).toDouble(),
        (data['longitude'] as num).toDouble(),
      );
    }

    // Documents
    _cnicFrontUrl = data['cnicFrontUrl'];
    _cnicBackUrl = data['cnicBackUrl'];
    _utilityBillUrl = data['utilityBillUrl'];
    _passportPhotoUrl = data['passportPhotoUrl'];
    _policeVerificationUrl = data['policeVerificationUrl'];
    _affidavitUrl = data['affidavitUrl'];
  }

  // --- Update Data ---
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      _showSnackbar('Please select a location', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updateData = {
        'fullName': _fullNameController.text.trim(),
        'fatherName': _fatherNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'cnicIssueDate': _cnicIssueDate != null
            ? DateFormat('yyyy-MM-dd').format(_cnicIssueDate!)
            : null,
        'country': _selectedCountry,
        'province': _selectedProvince,
        'district': _selectedDistrict,
        'area': _selectedTehsil,
        'fullAddress': _fullAddressController.text.trim(),
        'propertyAddress': _selectedCountry == "Pakistan"
            ? "$_selectedTehsil, $_selectedDistrict, $_selectedProvince"
            : "$_selectedCountry",
        'latitude': _selectedLocation?.latitude,
        'longitude': _selectedLocation?.longitude,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update(updateData);

      setState(() {
        _isSaving = false;
      });
      _showSnackbar('Profile updated successfully!', isError: false);
      if (mounted) Navigator.pop(context); // Go back to dashboard
    } catch (e) {
      debugPrint('Error updating profile: $e');
      _showSnackbar('Failed to update profile: $e', isError: true);
      setState(() => _isSaving = false);
    }
  }

  // --- UI Helpers ---
  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? coral : successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- Location Logic ---
  List<String> get _provinceList =>
      _selectedCountry == "Pakistan" ? pakistanData.keys.toList() : [];
  List<String> get _districtList => (_selectedCountry == "Pakistan" &&
          _selectedProvince != null)
      ? (pakistanData[_selectedProvince] as Map<String, dynamic>).keys.toList()
      : [];
  List<String> get _tehsilList => (_selectedCountry == "Pakistan" &&
          _selectedProvince != null &&
          _selectedDistrict != null)
      ? List<String>.from(pakistanData[_selectedProvince][_selectedDistrict])
      : [];

  Future<void> _openLocationPicker() async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation ??
                    const LatLng(30.3753, 69.3451), // Center of Pak
                initialZoom: 13,
                onTap: (_, point) {
                  Navigator.pop(context, point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.muhallah.app',
                ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on,
                            color: coral, size: 40),
                      ),
                    ],
                  ),
              ],
            ),
            Positioned(
              top: 40,
              left: 20,
              child: CircleAvatar(
                backgroundColor: deepNavy,
                child: IconButton(
                  icon: const Icon(Icons.close, color: whiteish),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: deepNavy.withOpacity(0.8),
                  child: const Text("Tap anywhere to select location",
                      style: TextStyle(color: whiteish),
                      textAlign: TextAlign.center),
                ))
          ],
        ),
      ),
    ).then((value) {
      if (value != null && value is LatLng) {
        setState(() {
          _selectedLocation = value;
        });
      }
    });
  }

  // --- Widgets ---

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 0.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          if (icon != null) ...[
            Icon(icon, color: teal, size: 20),
            const SizedBox(width: 8)
          ],
          Text(title, style: headingStyle.copyWith(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    String? Function(String?)? validator,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
    VoidCallback? onTap,
    String? hint,
  }) {
    final isLocked = !_isEditing || readOnly;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: isLocked || onTap != null,
            onTap: (!_isEditing && !readOnly) ? null : onTap,
            enabled: true, // Allow copy-paste
            style: inputTextStyle.copyWith(
                color: isLocked ? Colors.white60 : Colors.white),
            keyboardType: inputType,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              filled: true,
              fillColor: isLocked ? sectionBg.withOpacity(0.5) : inputBg,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white30),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: teal, width: 2),
              ),
              suffixIcon: isLocked && _isEditing && readOnly
                  ? const Icon(Icons.lock, color: Colors.white24, size: 16)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final isLocked = !_isEditing;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isLocked ? sectionBg.withOpacity(0.5) : inputBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.contains(value) ? value : null,
                dropdownColor: sectionBg,
                icon: Icon(Icons.arrow_drop_down,
                    color: isLocked ? Colors.white24 : teal),
                isExpanded: true,
                style: inputTextStyle.copyWith(
                    color: isLocked ? Colors.white60 : Colors.white),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: isLocked ? null : onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String title, String? url, IconData icon) {
    return Card(
      color: inputBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (url != null) {
            showDialog(
                context: context,
                builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: InteractiveViewer(child: Image.network(url)),
                    ));
          } else {
            _showSnackbar('Document not available', isError: true);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: url != null ? teal : Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: whiteish, fontSize: 12, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                url != null ? "Tap to View" : "Missing",
                style: TextStyle(
                    color: url != null ? successGreen : errorRed, fontSize: 10),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: deepNavy,
        body: Center(child: CircularProgressIndicator(color: teal)),
      );
    }

    final role = _userData?['role'] ?? 'Restricted';
    final isOwner = role == 'owner';
    final status = _userData?['status'] ?? 'pending';

    return PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: deepNavy,
          appBar: AppBar(
            backgroundColor:
                Colors.transparent, // Gradient background handles this
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: whiteish),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Edit Profile',
                style: TextStyle(fontWeight: FontWeight.bold)),
            flexibleSpace: Container(
              decoration: const BoxDecoration(gradient: primaryGradient),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel",
                    style: TextStyle(
                        color: Colors.white54, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Section
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: teal, width: 2),
                                  color: sectionBg,
                                  image: const DecorationImage(
                                    image: AssetImage(
                                        'assets/images/placeholder_avatar_2.png'),
                                    fit: BoxFit.cover,
                                  )),
                              // Showing initials if no image logic is complex with Assets
                              // We can use a Child with Text if image fails, but keeping it simple
                              child: const Center(
                                  child: Text("U",
                                      style: TextStyle(
                                          fontSize: 40,
                                          color: Colors.white30))),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: deepNavy, shape: BoxShape.circle),
                              child: Icon(
                                status == 'verified'
                                    ? Icons.verified
                                    : Icons.access_time_filled,
                                color: status == 'verified'
                                    ? successGreen
                                    : warningAmber,
                                size: 20,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _fullNameController.text.isNotEmpty
                              ? _fullNameController.text
                              : "User Name",
                          style: headingStyle,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOwner
                                ? teal.withOpacity(0.2)
                                : coral.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isOwner ? teal : coral),
                          ),
                          child: Text(
                            role.toString().toUpperCase(),
                            style: TextStyle(
                              color: isOwner ? teal : coral,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Personal Information
                  _buildSectionHeader('Personal Information',
                      icon: Icons.person),
                  _buildTextField(
                    label: 'Full Name',
                    controller: _fullNameController,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  _buildTextField(
                    label: 'Father Name',
                    controller: _fatherNameController,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  _buildTextField(
                    label: 'CNIC (Identifier)',
                    controller: _cnicController,
                    readOnly: true, // ALWAYS READ ONLY
                    hint: 'Cannot be changed',
                  ),
                  _buildTextField(
                    label: 'CNIC Issue Date',
                    controller: TextEditingController(
                      text: _cnicIssueDate != null
                          ? DateFormat('yyyy-MM-dd').format(_cnicIssueDate!)
                          : '',
                    ),
                    hint: 'YYYY-MM-DD',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _cnicIssueDate ?? DateTime(now.year - 5),
                        firstDate: DateTime(1950),
                        lastDate: now,
                        builder: (context, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: teal,
                              onPrimary: deepNavy,
                              surface: sectionBg,
                            ),
                            dialogTheme: const DialogThemeData(
                                backgroundColor: deepNavy),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() => _cnicIssueDate = picked);
                      }
                    },
                  ),
                  if (!isOwner)
                    _buildTextField(
                      label: "Father's CNIC",
                      controller: _fatherCnicController,
                      readOnly: true, // Read Only
                    ),

                  // 3. Contact Info
                  _buildSectionHeader('Contact Information',
                      icon: Icons.contact_phone),
                  _buildTextField(
                    label: 'Email Address',
                    controller: _emailController,
                    inputType: TextInputType.emailAddress,
                    validator: (v) =>
                        v != null && v.contains('@') ? null : 'Invalid Email',
                  ),
                  _buildTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    inputType: TextInputType.phone,
                    validator: (v) => v!.length >= 11 ? null : 'Invalid Phone',
                  ),

                  // 4. Location
                  _buildSectionHeader('Location Details',
                      icon: Icons.location_city),
                  _buildDropdown(
                    label: 'Country',
                    value: _selectedCountry,
                    items: allCountries,
                    onChanged: (val) {
                      setState(() {
                        _selectedCountry = val;
                        // Reset Cascading dropdowns
                        _selectedProvince = null;
                        _selectedDistrict = null;
                        _selectedTehsil = null;
                      });
                    },
                  ),
                  if (_selectedCountry == 'Pakistan') ...[
                    _buildDropdown(
                      label: 'Province',
                      value: _selectedProvince,
                      items: _provinceList,
                      onChanged: (val) => setState(() {
                        _selectedProvince = val;
                        _selectedDistrict = null;
                        _selectedTehsil = null;
                      }),
                    ),
                    _buildDropdown(
                      label: 'District',
                      value: _selectedDistrict,
                      items: _districtList,
                      onChanged: (val) => setState(() {
                        _selectedDistrict = val;
                        _selectedTehsil = null;
                      }),
                    ),
                    _buildDropdown(
                      label: 'Tehsil/Area',
                      value: _selectedTehsil,
                      items: _tehsilList,
                      onChanged: (val) => setState(() => _selectedTehsil = val),
                    ),
                  ],
                  _buildTextField(
                    label: 'Availability Address',
                    controller: _fullAddressController,
                    maxLines: 2,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _selectedLocation ??
                                  const LatLng(30.3753, 69.3451),
                              initialZoom: 13,
                              interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag
                                      .none), // Disable interaction in mini map
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.muhallah.app',
                              ),
                              if (_selectedLocation != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _selectedLocation!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(Icons.location_on,
                                          color: coral, size: 40),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: FloatingActionButton.small(
                                backgroundColor: teal,
                                onPressed: _openLocationPicker,
                                child: const Icon(Icons.edit_location_alt,
                                    color: deepNavy),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 5. Documents
                  _buildSectionHeader('Documents', icon: Icons.folder_shared),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: warningAmber.withOpacity(0.1),
                      border: Border.all(color: warningAmber.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: warningAmber, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Documents are fixed after registration. Contact support to change.",
                            style: TextStyle(color: warningAmber, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.2,
                    children: [
                      _buildDocumentCard(
                          'CNIC Front', _cnicFrontUrl, Icons.subtitles),
                      _buildDocumentCard(
                          'CNIC Back', _cnicBackUrl, Icons.subtitles),
                      _buildDocumentCard(
                          'Utility Bill', _utilityBillUrl, Icons.receipt),
                      _buildDocumentCard('Passport Photo', _passportPhotoUrl,
                          Icons.person_pin),
                      if (isOwner)
                        _buildDocumentCard('Police Verification',
                            _policeVerificationUrl, Icons.gavel),
                      if (!isOwner)
                        _buildDocumentCard(
                            'Affidavit', _affidavitUrl, Icons.description),
                    ],
                  ),

                  // 6. Account Info
                  _buildSectionHeader('Account Information', icon: Icons.info),
                  _buildTextField(
                      label: 'Account Status',
                      controller:
                          TextEditingController(text: status.toUpperCase()),
                      readOnly: true),
                  _buildTextField(
                      label: 'Registration Date',
                      controller: TextEditingController(
                          text: _userData?['registrationDate'] != null
                              ? DateFormat.yMMMd().format(
                                  (_userData!['registrationDate'] as Timestamp)
                                      .toDate())
                              : '-'),
                      readOnly: true),
                  _buildTextField(
                      label: 'User ID',
                      controller:
                          TextEditingController(text: _currentUser?.uid),
                      readOnly: true),

                  // 7. Security
                  _buildSectionHeader('Security', icon: Icons.security),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_reset, color: teal),
                    title: const Text('Change Password',
                        style: TextStyle(color: whiteish)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white24, size: 16),
                    onTap: () {
                      // Open Password Change Dialog
                      showDialog(
                          context: context,
                          builder: (context) => const ChangePasswordDialog());
                    },
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: coral),
                    title:
                        const Text('Logout', style: TextStyle(color: whiteish)),
                    onTap: () async {
                      // Confirm Logout
                      bool confirm = await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                    backgroundColor: sectionBg,
                                    title: const Text("Logout",
                                        style: TextStyle(color: whiteish)),
                                    content: const Text(
                                        "Are you sure you want to logout?",
                                        style:
                                            TextStyle(color: Colors.white70)),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text("Cancel")),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text("Logout",
                                              style: TextStyle(color: coral))),
                                    ],
                                  )) ??
                          false;

                      if (confirm) {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login', (route) => false);
                        }
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_forever, color: errorRed),
                    title: const Text('Delete Account',
                        style: TextStyle(color: errorRed)),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const DeleteAccountScreen()));
                    },
                  ),
                  const SizedBox(height: 32),

                  // 8. Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: teal.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: whiteish, strokeWidth: 2))
                            : const Text(
                                "Save Changes",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: whiteish),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ));
  }
}

// Simple Dialog for Password Change
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _passController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _loading = false;

  Future<void> _updatePassword() async {
    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Passwords do not match"), backgroundColor: coral));
      return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Re-auth first
        final cred = EmailAuthProvider.credential(
            email: user.email!, password: _passController.text);
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(_newPassController.text);

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Password changed successfully"),
            backgroundColor: successGreen));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: coral));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: sectionBg,
      title: const Text("Change Password", style: TextStyle(color: whiteish)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _passController,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: "Current Password",
                labelStyle: TextStyle(color: Colors.white54)),
            style: const TextStyle(color: Colors.white),
          ),
          TextField(
            controller: _newPassController,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: "New Password",
                labelStyle: TextStyle(color: Colors.white54)),
            style: const TextStyle(color: Colors.white),
          ),
          TextField(
            controller: _confirmPassController,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: "Confirm New Password",
                labelStyle: TextStyle(color: Colors.white54)),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        if (_loading)
          const CircularProgressIndicator()
        else
          TextButton(
              onPressed: _updatePassword,
              child: const Text("Update", style: TextStyle(color: teal))),
      ],
    );
  }
}
