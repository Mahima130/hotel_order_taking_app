import 'package:flutter/material.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';
import 'package:hotel_order_taking_app/Widget/Common/custom_app_bar.dart';
import 'package:hotel_order_taking_app/Widget/Common/background_container.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty) {
      _showSnackBar('Please enter current password', isError: true);
      return;
    }
    if (_newPasswordController.text.isEmpty) {
      _showSnackBar('Please enter new password', isError: true);
      return;
    }
    if (_confirmPasswordController.text.isEmpty) {
      _showSnackBar('Please confirm new password', isError: true);
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('New passwords do not match', isError: true);
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    _showSnackBar('Password changed successfully!');

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // ← Changed to Colors.transparent
      body: BackgroundContainer(
        child: Column(
          children: [
            CustomAppBar(
              title: 'CHANGE PASSWORD',
              showBack: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spaceXL),
                  child: Column(
                    children: [
                      SizedBox(height: AppSizes.spaceXL),

                      // Lock Icon - Made semi-transparent
                      Container(
                        padding: const EdgeInsets.all(AppSizes.spaceXL),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold
                              .withOpacity(0.15), // ← Reduced opacity
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 60,
                          color: AppColors.primaryGold,
                        ),
                      ),

                      SizedBox(height: AppSizes.spaceXL * 1.5),

                      _buildPasswordField(
                        controller: _currentPasswordController,
                        label: 'Current Password',
                        hint: 'Enter current password',
                        icon: Icons.lock,
                        obscureText: _obscureCurrentPassword,
                        onToggle: () => setState(() =>
                            _obscureCurrentPassword = !_obscureCurrentPassword),
                      ),

                      SizedBox(height: AppSizes.spaceXL),

                      _buildPasswordField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        hint: 'Enter new password',
                        icon: Icons.lock_reset,
                        obscureText: _obscureNewPassword,
                        onToggle: () => setState(
                            () => _obscureNewPassword = !_obscureNewPassword),
                      ),

                      SizedBox(height: AppSizes.spaceXL),

                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: 'Confirm New Password',
                        hint: 'Re-enter new password',
                        icon: Icons.lock_clock,
                        obscureText: _obscureConfirmPassword,
                        onToggle: () => setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),

                      SizedBox(height: AppSizes.spaceXL * 1.5),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBackground,
                          minimumSize: const Size(
                              double.infinity, AppSizes.buttonHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMedium),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'CHANGE PASSWORD',
                          style: TextStyle(
                            color: AppColors.buttonText,
                            fontWeight: FontWeight.w600,
                            fontSize: AppSizes.fontL,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryGold),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide:
              const BorderSide(color: AppColors.buttonBackground, width: 2),
        ),
        filled: true,
        fillColor: AppColors.white
            .withOpacity(0.9), // ← KEY CHANGE: Made semi-transparent
      ),
    );
  }
}
