import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
// import 'package:file_picker/file_picker.dart'; // Disabled - akan diaktifkan setelah integrasi API
import '../../bloc/leave/leave_bloc.dart';
import '../../bloc/leave/leave_event.dart';
import '../../bloc/leave/leave_state.dart';
import '../../models/leave_type.dart';
import '../../constants/leave_constants.dart';

/// Halaman form pengajuan izin/cuti
class LeaveRequestForm extends StatefulWidget {
  final LeaveType leaveType;

  const LeaveRequestForm({
    Key? key,
    required this.leaveType,
  }) : super(key: key);

  @override
  State<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends State<LeaveRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _reasonFocusNode = FocusNode();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _attachmentPath;
  String? _attachmentName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _reasonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Unfocus when tapping outside of text fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(),
        body: BlocListener<LeaveBloc, LeaveState>(
          listener: (context, state) {
            if (state is LeaveSubmitting) {
              setState(() => _isSubmitting = true);
            } else if (state is LeaveSubmitSuccess) {
              setState(() => _isSubmitting = false);
              _showSuccessDialog(state.message);
            } else if (state is LeaveError) {
              setState(() => _isSubmitting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leave Type Info Card
                    _buildLeaveTypeCard(),
                    const SizedBox(height: 24),

                    // Date Selection
                    _buildDateSection(),
                    const SizedBox(height: 24),

                    // Reason Field
                    _buildReasonField(),
                    const SizedBox(height: 24),

                    // Attachment Field
                    _buildAttachmentField(),
                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(),
                    const SizedBox(height: 16),

                    // Extra space for keyboard
                    SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom > 0
                            ? 100
                            : 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF016541),
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 64,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Pengajuan ${widget.leaveType.name}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildLeaveTypeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.leaveType.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.leaveType.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.leaveType.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.leaveType.icon,
              color: widget.leaveType.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.leaveType.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.leaveType.color,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Maksimal ${widget.leaveType.maxDays} hari',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Periode Cuti',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Tanggal Mulai',
                value: _startDate,
                onTap: () => _selectDate(isStartDate: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                label: 'Tanggal Selesai',
                value: _endDate,
                onTap: () => _selectDate(isStartDate: false),
              ),
            ),
          ],
        ),
        if (_startDate != null && _endDate != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF016541).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF016541),
                ),
                const SizedBox(width: 8),
                Text(
                  'Total: ${_endDate!.difference(_startDate!).inDays + 1} hari',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF016541),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: value != null
                      ? const Color(0xFF016541)
                      : Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value != null ? dateFormat.format(value) : 'Pilih tanggal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: value != null ? Colors.black87 : Colors.grey[400],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alasan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 120,
          ),
          child: TextFormField(
            controller: _reasonController,
            focusNode: _reasonFocusNode,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onTapOutside: (event) {
              // Unfocus when tapping outside to prevent platform views bug
              _reasonFocusNode.unfocus();
            },
            decoration: InputDecoration(
              hintText: LeaveConstants.labelReasonHint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontFamily: 'Poppins',
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF016541)),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Alasan wajib diisi';
              }
              if (value.length < 10) {
                return 'Alasan minimal 10 karakter';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentField() {
    final isRequired = widget.leaveType.requiresDocument;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Lampiran (Opsional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (_attachmentName != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF016541).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF016541).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.insert_drive_file,
                  color: Color(0xFF016541),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _attachmentName!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _attachmentName = null;
                      _attachmentPath = null;
                    });
                  },
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: const Color(0xFF016541),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Klik untuk upload lampiran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF016541),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Format: JPG, PNG, PDF (Max. 5MB)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF016541),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Ajukan Izin',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
      ),
    );
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final now = DateTime.now();
    final initialDate = isStartDate
        ? (_startDate ?? now.add(const Duration(days: 1)))
        : (_endDate ?? _startDate ?? now.add(const Duration(days: 1)));

    final firstDate = isStartDate
        ? (widget.leaveType == LeaveType.izinSakit
            ? now.subtract(const Duration(days: 7))
            : now)
        : (_startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF016541),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Reset end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Mock file picker functionality
  void _pickFile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih File (Simulasi)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            _buildMockFileOption(
              icon: Icons.image_outlined,
              label: 'Foto Kamera.jpg',
              size: '2.4 MB',
              onTap: () {
                setState(() {
                  _attachmentName = 'Foto_Kamera_2024.jpg';
                  _attachmentPath =
                      '/storage/emulated/0/DCIM/Camera/IMG_2024.jpg';
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _buildMockFileOption(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Surat_Dokter.pdf',
              size: '450 KB',
              onTap: () {
                setState(() {
                  _attachmentName = 'Surat_Dokter_Klinik_Sehat.pdf';
                  _attachmentPath =
                      '/storage/emulated/0/Documents/Surat_Dokter.pdf';
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _buildMockFileOption(
              icon: Icons.insert_drive_file_outlined,
              label: 'Dokumen_Lainnya.pdf',
              size: '1.2 MB',
              onTap: () {
                setState(() {
                  _attachmentName = 'Dokumen_Pendukung.pdf';
                  _attachmentPath = '/storage/emulated/0/Documents/Dokumen.pdf';
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate dates
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal mulai dan selesai wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate attachment if required
    if (widget.leaveType.requiresDocument && _attachmentName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lampirkan dokumen pendukung'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Submit request
    HapticFeedback.mediumImpact();
    context.read<LeaveBloc>().add(
          SubmitLeaveRequest(
            type: widget.leaveType,
            startDate: _startDate!,
            endDate: _endDate!,
            reason: _reasonController.text.trim(),
            attachmentPath: _attachmentPath,
            attachmentName: _attachmentName,
          ),
        );
  }

  Widget _buildMockFileOption({
    required IconData icon,
    required String label,
    required String size,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF016541).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: const Color(0xFF016541), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    size,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF016541).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF016541),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Berhasil!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to main page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF016541),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
