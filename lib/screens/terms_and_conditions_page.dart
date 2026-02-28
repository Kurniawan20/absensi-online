import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(1, 101, 65, 1),
        elevation: 0,
        title: const Text(
          'Syarat dan Ketentuan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('1. Ketentuan Umum'),
            _buildParagraph(
              'Aplikasi HABA (Hadir Bank Aceh) adalah aplikasi absensi digital resmi milik PT Bank Aceh Syariah. '
              'Dengan menggunakan aplikasi ini, Anda setuju untuk mematuhi semua syarat dan ketentuan yang berlaku.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('2. Penggunaan Aplikasi'),
            _buildParagraph(
              'Aplikasi ini hanya diperuntukkan bagi karyawan PT Bank Aceh Syariah yang terdaftar. '
              'Setiap pengguna bertanggung jawab atas keamanan akun dan data pribadi mereka.',
            ),
            _buildBulletPoint(
                'Pengguna wajib menggunakan data yang valid dan akurat.'),
            _buildBulletPoint(
                'Pengguna dilarang membagikan akun kepada pihak lain.'),
            _buildBulletPoint('Pengguna wajib menjaga kerahasiaan kata sandi.'),
            const SizedBox(height: 20),
            _buildSectionTitle('3. Keamanan dan Privasi'),
            _buildParagraph(
              'Kami berkomitmen untuk menjaga keamanan data Anda. Aplikasi ini menggunakan enkripsi dan '
              'langkah-langkah keamanan lainnya untuk melindungi informasi pribadi Anda.',
            ),
            _buildBulletPoint(
                'Data lokasi hanya digunakan untuk keperluan absensi.'),
            _buildBulletPoint(
                'Data biometrik disimpan secara lokal dan terenkripsi.'),
            _buildBulletPoint(
                'Kami tidak membagikan data pribadi kepada pihak ketiga.'),
            const SizedBox(height: 20),
            _buildSectionTitle('4. Fitur Biometrik'),
            _buildParagraph(
              'Fitur login biometrik memungkinkan Anda untuk masuk dengan sidik jari atau pengenalan wajah. '
              'Dengan mengaktifkan fitur ini:',
            ),
            _buildBulletPoint(
                'Kredensial Anda akan disimpan secara aman di perangkat.'),
            _buildBulletPoint('Anda dapat login dengan lebih cepat dan mudah.'),
            _buildBulletPoint(
                'Anda dapat menonaktifkan fitur ini kapan saja melalui pengaturan.'),
            const SizedBox(height: 20),
            _buildSectionTitle('5. Tanggung Jawab Pengguna'),
            _buildParagraph(
              'Pengguna bertanggung jawab untuk:',
            ),
            _buildBulletPoint(
                'Memastikan perangkat dalam kondisi aman (tidak di-root/jailbreak).'),
            _buildBulletPoint('Melakukan absensi dari lokasi yang sah.'),
            _buildBulletPoint('Melaporkan jika terjadi penyalahgunaan akun.'),
            const SizedBox(height: 20),
            _buildSectionTitle('6. Pembatasan'),
            _buildParagraph(
              'Aplikasi tidak dapat digunakan pada:',
            ),
            _buildBulletPoint('Perangkat yang sudah di-root atau jailbreak.'),
            _buildBulletPoint('Emulator atau simulator.'),
            _buildBulletPoint('Perangkat dengan mode pengembang aktif.'),
            const SizedBox(height: 20),
            _buildSectionTitle('7. Perubahan Ketentuan'),
            _buildParagraph(
              'PT Bank Aceh Syariah berhak mengubah syarat dan ketentuan ini sewaktu-waktu. '
              'Pengguna akan diberitahu mengenai perubahan penting melalui aplikasi.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('8. Kontak'),
            _buildParagraph(
              'Untuk pertanyaan atau bantuan, silakan hubungi:',
            ),
            _buildContactInfo(FluentIcons.building_24_regular,
                'Kantor Pusat Bank Aceh Syariah'),
            _buildContactInfo(
                FluentIcons.mail_24_regular, 'support@bankaceh.co.id'),
            _buildContactInfo(FluentIcons.call_24_regular, '(0651) 123456'),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2024 PT Bank Aceh Syariah\nSemua Hak Dilindungi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color.fromRGBO(1, 101, 65, 1),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[800],
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(1, 101, 65, 1),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color.fromRGBO(1, 101, 65, 1),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
