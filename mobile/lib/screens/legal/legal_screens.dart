import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

/// About Trabab Screen
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('About Trabab', style: AppTypography.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Logo
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.gavel, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text('Trabab', style: AppTypography.displaySmall),
            Text('Your Town. Your Auctions.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
            const SizedBox(height: 8),
            Text('Version 1.0.2', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
            const SizedBox(height: 32),
            // Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Our Mission', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Trabab connects communities through local auctions. We believe in the power of neighborhood commerce - buying and selling from people you can trust, right in your own town.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Features
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Key Features', style: AppTypography.titleMedium),
                  const SizedBox(height: 16),
                  _Feature(icon: Icons.location_on, title: 'Town-First', desc: 'Sell in your town, buy anywhere'),
                  _Feature(icon: Icons.gavel, title: 'Fair Slots', desc: 'Equal visibility for all sellers'),
                  _Feature(icon: Icons.security, title: 'Safe', desc: 'Verified users and secure transactions'),
                  _Feature(icon: Icons.flash_on, title: 'Real-Time', desc: 'Live bidding updates'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Team
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Made with ❤️ in Zimbabwe', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  Text('Built by a team passionate about community commerce and local economies.', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Social links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialButton(icon: Icons.language, onTap: () {}),
                const SizedBox(width: 16),
                _SocialButton(icon: Icons.facebook, onTap: () {}),
                const SizedBox(width: 16),
                _SocialButton(icon: Icons.camera_alt, onTap: () {}),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _Feature({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTypography.titleSmall),
          Text(desc, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
        ])),
      ]),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.borderLight)),
        child: Icon(icon, color: AppColors.textSecondaryLight),
      ),
    );
  }
}

/// Privacy Policy Screen
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Privacy Policy', style: AppTypography.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last updated: December 2024', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
            const SizedBox(height: 24),
            _Section(title: '1. Information We Collect', content: 'We collect information you provide directly, such as your name, email, phone number, and location. We also collect data about your activity on our platform, including auctions viewed, bids placed, and items sold.'),
            _Section(title: '2. How We Use Your Information', content: 'We use your information to provide and improve our services, process transactions, communicate with you, and ensure the security of our platform.'),
            _Section(title: '3. Information Sharing', content: 'We may share your information with other users as necessary for transactions, with service providers who assist our operations, and as required by law.'),
            _Section(title: '4. Data Security', content: 'We implement appropriate security measures to protect your personal information. However, no method of transmission over the internet is 100% secure.'),
            _Section(title: '5. Your Rights', content: 'You have the right to access, correct, or delete your personal information. Contact us at privacy@trabab.com for any requests.'),
            _Section(title: '6. Changes to This Policy', content: 'We may update this policy from time to time. We will notify you of any material changes through the app or via email.'),
            const SizedBox(height: 24),
            Text('Contact Us', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text('If you have questions about this policy, please contact us at privacy@trabab.com', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTypography.titleMedium),
        const SizedBox(height: 8),
        Text(content, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight, height: 1.6)),
      ]),
    );
  }
}

/// Terms of Service Screen
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Terms of Service', style: AppTypography.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Effective: December 2024', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
            const SizedBox(height: 24),
            _Section(title: '1. Acceptance of Terms', content: 'By accessing or using Trabab, you agree to be bound by these Terms of Service and all applicable laws and regulations.'),
            _Section(title: '2. User Accounts', content: 'You must create an account to use certain features. You are responsible for maintaining the confidentiality of your account and password.'),
            _Section(title: '3. Auction Rules', content: 'All bids are binding. Sellers must accurately describe items. Buyers must complete payment for won auctions. Trabab is not responsible for the quality of items sold.'),
            _Section(title: '4. Prohibited Activities', content: 'You may not use Trabab for illegal activities, fraud, or to sell prohibited items. Violations may result in account suspension.'),
            _Section(title: '5. Fees and Payments', content: 'Trabab may charge fees for certain services. Payment terms and any applicable fees will be clearly disclosed before you incur them.'),
            _Section(title: '6. Limitation of Liability', content: 'Trabab is provided "as is" without warranties. We are not liable for any damages arising from your use of the platform.'),
            _Section(title: '7. Dispute Resolution', content: 'Any disputes will be resolved through arbitration in accordance with Zimbabwe law.'),
          ],
        ),
      ),
    );
  }
}

/// Help & Support Screen
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {'q': 'How do I create an auction?', 'a': 'Tap the + button on the home screen, add photos, fill in details, and publish. Your auction will be live for 7 days.'},
      {'q': 'How do I bid on an item?', 'a': 'Go to the auction detail page and enter your bid amount in the footer. Your bid must be higher than the current bid plus the bid increment.'},
      {'q': 'What happens when I win?', 'a': 'You\'ll receive a notification and can contact the seller to arrange payment and pickup.'},
      {'q': 'Can I change my home town?', 'a': 'Yes, but you can only change it once every 30 days. Go to Settings > Profile to make changes.'},
      {'q': 'How does the waiting list work?', 'a': 'When a category is full, you can join the waiting list. You\'ll be notified when a slot opens up.'},
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Help & Support', style: AppTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact options
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('Need Help?', style: AppTypography.headlineMedium.copyWith(color: Colors.white)),
                const SizedBox(height: 8),
                Text('We\'re here to assist you', style: AppTypography.bodyMedium.copyWith(color: Colors.white70)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _ContactButton(icon: Icons.email, label: 'Email', onTap: () {})),
                  const SizedBox(width: 12),
                  Expanded(child: _ContactButton(icon: Icons.chat, label: 'Live Chat', onTap: () {})),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // FAQs
          Text('Frequently Asked Questions', style: AppTypography.headlineSmall),
          const SizedBox(height: 16),
          ...faqs.map((f) => _FAQItem(question: f['q']!, answer: f['a']!)),
          const SizedBox(height: 24),
          // Report bug
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.bug_report, color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Report a Bug', style: AppTypography.titleSmall),
                Text('Found something wrong? Let us know.', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
              ])),
              Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.labelMedium.copyWith(color: Colors.white)),
        ]),
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FAQItem({required this.question, required this.answer});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.question, style: AppTypography.titleSmall),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(widget.answer, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
          ),
        ],
      ),
    );
  }
}
