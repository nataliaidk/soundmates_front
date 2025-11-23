import 'package:flutter/material.dart';
import '../theme/app_design_system.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLightPurple,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryAlt),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: AppColors.textPrimaryAlt,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.darkPurpleGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'AGREEMENT',
                  style: TextStyle(
                    color: AppColors.textWhite70,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Terms of Service',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Last Updated: October 18, 2025',
                  style: TextStyle(color: AppColors.textWhite70, fontSize: 12),
                ),
                SizedBox(height: 18),
                _Paragraph(
                  number: '1.',
                  title: 'Your Account & Eligibility',
                  body:
                      'You must be 18+ to use Soundmates. Keep your login details safe; you are responsible for your account activity. Provide accurate registration info and confirm your email. You can create a personal or band profile.',
                ),
                _Paragraph(
                  number: '2.',
                  title: 'The Service',
                  body:
                      'Soundmates connects musicians for collaboration via profiles, matching, and chat between matches.',
                ),
                _Paragraph(
                  number: '3.',
                  title: 'Your Content & Conduct',
                  body:
                      'You own the content you upload (photos, music, text). You grant us a license to use it only to operate and promote the Service. Do not misuse the Service (spam, harassment, impersonation, illegal acts). Only chat with users you have matched with.',
                ),
                _Paragraph(
                  number: '4.',
                  title: 'Disclaimers & Liability Limitation',
                  body:
                      'The Service is provided “as is” without warranties of any kind. We do not guarantee you will find suitable collaborators or that interactions between users will be to your satisfaction. To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising out of your use of the Service.',
                ),
                _Paragraph(
                  number: '5.',
                  title: 'Termination',
                  body:
                      'You can deactivate your account at any time through the app settings. We reserve the right to suspend or terminate your account if you violate these terms or engage in behavior harmful to the Service or other users.',
                ),
                _Paragraph(
                  number: '6.',
                  title: 'Privacy',
                  body:
                      'We process data as described in our Privacy Policy (coming soon). Do not share personal data of others without consent.',
                ),
                _Paragraph(
                  number: '7.',
                  title: 'Changes',
                  body:
                      'We may update these Terms. Continued use after changes means you accept the revised Terms.',
                ),
                SizedBox(height: 24),
                Text(
                  'By continuing to use Soundmates you agree to these Terms.',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  const _Paragraph({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number $title',
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textWhite70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
