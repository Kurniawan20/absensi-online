import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/device_reset/device_reset_bloc.dart';
import '../bloc/device_reset/device_reset_event.dart';
import '../bloc/device_reset/device_reset_state.dart';

class ResetDevicePage extends StatefulWidget {
  final String? initialNrk;

  const ResetDevicePage({super.key, this.initialNrk});

  @override
  State<ResetDevicePage> createState() => _ResetDevicePageState();
}

class _ResetDevicePageState extends State<ResetDevicePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController txtEditNrk = TextEditingController();
  final TextEditingController txtEditReason = TextEditingController();
  final FocusNode _nrkFocusNode = FocusNode();
  final FocusNode _reasonFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Pre-fill NRK if provided
    if (widget.initialNrk != null && widget.initialNrk!.isNotEmpty) {
      txtEditNrk.text = widget.initialNrk!;
    }
    _nrkFocusNode.addListener(() => setState(() {}));
    _reasonFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    txtEditNrk.dispose();
    txtEditReason.dispose();
    _nrkFocusNode.dispose();
    _reasonFocusNode.dispose();
    super.dispose();
  }

  void _submitResetRequest() {
    if (_formKey.currentState!.validate()) {
      context.read<DeviceResetBloc>().add(
            SubmitDeviceResetRequest(
              npp: txtEditNrk.text.trim(),
              reason: txtEditReason.text.trim(),
            ),
          );
    }
  }

  void _showSuccessBottomSheet(String message) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Success Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(1, 101, 65, 0.1),
                  borderRadius: BorderRadius.circular(35),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 40,
                  color: Color.fromRGBO(1, 101, 65, 1),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Permintaan Terkirim',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              // Additional info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Admin akan memproses permintaan Anda. Silakan coba login kembali setelah mendapat konfirmasi.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close bottom sheet
                    Navigator.of(context).pop(); // Go back to login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(1, 101, 65, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Kembali ke Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showErrorBottomSheet({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    String buttonText = 'Mengerti',
    VoidCallback? onButtonPressed,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Icon(
                  icon,
                  size: 35,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onButtonPressed?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(1, 101, 65, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeviceResetBloc, DeviceResetState>(
      listener: (context, state) {
        if (state is DeviceResetSubmitSuccess) {
          _showSuccessBottomSheet(state.message);
          // Reset form
          txtEditNrk.clear();
          txtEditReason.clear();
          // Reset bloc state
          context.read<DeviceResetBloc>().add(const ResetDeviceResetState());
        } else if (state is DeviceResetAlreadyPending) {
          _showErrorBottomSheet(
            title: 'Permintaan Sudah Ada',
            message: state.message,
            icon: Icons.pending_actions_rounded,
            iconColor: Colors.orange,
          );
          context.read<DeviceResetBloc>().add(const ResetDeviceResetState());
        } else if (state is DeviceResetUserNotFound) {
          _showErrorBottomSheet(
            title: 'NRK Tidak Ditemukan',
            message: state.message,
            icon: Icons.person_off_rounded,
            iconColor: Colors.red,
          );
          context.read<DeviceResetBloc>().add(const ResetDeviceResetState());
        } else if (state is DeviceResetSubmitFailed) {
          _showErrorBottomSheet(
            title: 'Gagal Mengirim',
            message: state.message,
            icon: Icons.error_outline_rounded,
            iconColor: Colors.red,
          );
          context.read<DeviceResetBloc>().add(const ResetDeviceResetState());
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Logo
                    Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.asset("assets/images/ic_launcher.png",
                            height: 50),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Title Text
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 30,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.2,
                        ),
                        children: [
                          TextSpan(text: 'Reset '),
                          TextSpan(
                            text: 'Device',
                            style: TextStyle(
                              color: Color.fromRGBO(1, 101, 65, 1),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajukan permintaan reset device jika Anda mengganti perangkat.',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // NRK Field
                    TextFormField(
                      controller: txtEditNrk,
                      focusNode: _nrkFocusNode,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'NRK',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(1, 101, 65, 0.3),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(1, 101, 65, 0.3),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(1, 101, 65, 1),
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 20,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 15, right: 10),
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: _nrkFocusNode.hasFocus
                                ? const Color.fromRGBO(1, 101, 65, 1)
                                : Colors.grey,
                            size: 24,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 25,
                          minHeight: 25,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'NRK tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Reason Field
                    TextFormField(
                      controller: txtEditReason,
                      focusNode: _reasonFocusNode,
                      maxLines: 4,
                      maxLength: 500,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Alasan reset device (min. 10 karakter)',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(1, 101, 65, 0.3),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(1, 101, 65, 0.3),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(1, 101, 65, 1),
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 20,
                        ),
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 15, right: 10, bottom: 60),
                          child: Icon(
                            Icons.edit_note_rounded,
                            color: _reasonFocusNode.hasFocus
                                ? const Color.fromRGBO(1, 101, 65, 1)
                                : Colors.grey,
                            size: 24,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 25,
                          minHeight: 25,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Alasan tidak boleh kosong';
                        }
                        if (value.trim().length < 10) {
                          return 'Alasan minimal 10 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Submit Button
                    BlocBuilder<DeviceResetBloc, DeviceResetState>(
                      builder: (context, state) {
                        final isLoading = state is DeviceResetLoading;
                        return SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submitResetRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(1, 101, 65, 1),
                              disabledBackgroundColor:
                                  const Color.fromRGBO(1, 101, 65, 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                              shadowColor: const Color.fromRGBO(1, 101, 65, 1)
                                  .withValues(alpha: 0.5),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Kirim Permintaan',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Info box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Informasi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoItem(
                            'Permintaan reset akan diproses oleh admin',
                          ),
                          _buildInfoItem(
                            'Anda akan menerima notifikasi setelah permintaan disetujui',
                          ),
                          _buildInfoItem(
                            'Pastikan NRK yang dimasukkan benar',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
