import 'package:flutter/material.dart';

// Abstract base class for help sections (Abstraction)
abstract class HelpSection {
  String get title;
  IconData get icon;
  Color get color;
  Widget buildContent(BuildContext context);
}

// Help item model (Encapsulation)
class HelpItem {
  final String _question;
  final String _answer;
  final IconData _icon;

  const HelpItem({
    required String question,
    required String answer,
    required IconData icon,
  }) : _question = question,
       _answer = answer,
       _icon = icon;

  String get question => _question;
  String get answer => _answer;
  IconData get icon => _icon;
}

// Contact method model
class ContactMethod {
  final String _title;
  final String _subtitle;
  final IconData _icon;
  final Color _color;
  final VoidCallback _onTap;

  const ContactMethod({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) : _title = title,
       _subtitle = subtitle,
       _icon = icon,
       _color = color,
       _onTap = onTap;

  String get title => _title;
  String get subtitle => _subtitle;
  IconData get icon => _icon;
  Color get color => _color;
  VoidCallback get onTap => _onTap;
}

// Interface for help actions (Polymorphism)
mixin HelpActionMixin {
  void launchURL(String url);
  void sendEmail(String email, String subject);
  void makePhoneCall(String phoneNumber);
}

// FAQ Section (Inheritance)
class FAQSection extends HelpSection {
  @override
  String get title => 'Frequently Asked Questions';

  @override
  IconData get icon => Icons.quiz;

  @override
  Color get color => Colors.blue;

  final List<HelpItem> _faqItems = [
    const HelpItem(
      question: 'How do I book an appointment?',
      answer:
          'You can book an appointment by going to the "Doctor Consultation" section on the dashboard and selecting your preferred doctor and time slot.',
      icon: Icons.calendar_today,
    ),
    const HelpItem(
      question: 'How can I view my medical reports?',
      answer:
          'Navigate to the "Medical Reports" section to view all your lab results, prescriptions, and medical history.',
      icon: Icons.assignment,
    ),
    const HelpItem(
      question: 'Can I reschedule my appointment?',
      answer:
          'Yes, you can reschedule your appointment up to 2 hours before the scheduled time from the "Appointments" section.',
      icon: Icons.schedule,
    ),
    const HelpItem(
      question: 'How do I update my profile information?',
      answer:
          'Go to the Profile section from the navigation menu and tap the edit icon to update your personal information.',
      icon: Icons.person,
    ),
    const HelpItem(
      question: 'Is my medical data secure?',
      answer:
          'Yes, we use industry-standard encryption and follow HIPAA guidelines to protect your medical information.',
      icon: Icons.security,
    ),
    const HelpItem(
      question: 'How do I order medicines?',
      answer:
          'Use the "Order Medicine" feature to browse medications, add them to cart, and place orders for home delivery.',
      icon: Icons.medication,
    ),
  ];

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      children: _faqItems.map((item) => _buildFAQItem(item)).toList(),
    );
  }

  Widget _buildFAQItem(HelpItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(item.icon, color: color, size: 20),
        ),
        title: Text(
          item.question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              item.answer,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Contact Support Section (Inheritance)
class ContactSupportSection extends HelpSection with HelpActionMixin {
  @override
  String get title => 'Contact Support';

  @override
  IconData get icon => Icons.support_agent;

  @override
  Color get color => Colors.green;

  @override
  Widget buildContent(BuildContext context) {
    final contactMethods = [
      ContactMethod(
        title: 'Call Support',
        subtitle: '+1 (800) 123-4567',
        icon: Icons.phone,
        color: Colors.green,
        onTap: () => makePhoneCall('+18001234567'),
      ),
      ContactMethod(
        title: 'Email Support',
        subtitle: 'support@medicalcenter.com',
        icon: Icons.email,
        color: Colors.blue,
        onTap: () => sendEmail('support@medicalcenter.com', 'Support Request'),
      ),
      ContactMethod(
        title: 'Live Chat',
        subtitle: 'Chat with our support team',
        icon: Icons.chat,
        color: Colors.purple,
        onTap: () => _openLiveChat(context),
      ),
      ContactMethod(
        title: 'Emergency',
        subtitle: '24/7 Emergency Line',
        icon: Icons.emergency,
        color: Colors.red,
        onTap: () => makePhoneCall('911'),
      ),
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.support_agent, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      'Our support team is here 24/7 to assist you',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...contactMethods.map((method) => _buildContactMethod(method)).toList(),
      ],
    );
  }

  Widget _buildContactMethod(ContactMethod method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: method.color.withOpacity(0.1),
            child: Icon(method.icon, color: method.color),
          ),
          title: Text(
            method.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(method.subtitle),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.shade600,
          ),
          onTap: method.onTap,
        ),
      ),
    );
  }

  void _openLiveChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Chat'),
        content: const Text(
          'Live chat feature would be implemented here with real-time messaging.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void launchURL(String url) async {
    // URL launcher would be implemented here
    debugPrint('Would launch URL: $url');
  }

  @override
  void sendEmail(String email, String subject) async {
    // Email launcher would be implemented here
    debugPrint('Would send email to: $email with subject: $subject');
  }

  @override
  void makePhoneCall(String phoneNumber) async {
    // Phone call would be implemented here
    debugPrint('Would call: $phoneNumber');
  }
}

// Tutorials Section (Inheritance)
class TutorialsSection extends HelpSection {
  @override
  String get title => 'App Tutorials';

  @override
  IconData get icon => Icons.school;

  @override
  Color get color => Colors.orange;

  final List<TutorialItem> _tutorials = [
    const TutorialItem(
      title: 'Getting Started',
      description: 'Learn the basics of using the app',
      duration: '5 min',
      icon: Icons.play_circle,
    ),
    const TutorialItem(
      title: 'Booking Appointments',
      description: 'Step-by-step guide to book appointments',
      duration: '3 min',
      icon: Icons.calendar_today,
    ),
    const TutorialItem(
      title: 'Managing Health Records',
      description: 'How to view and manage your medical data',
      duration: '4 min',
      icon: Icons.folder_shared,
    ),
    const TutorialItem(
      title: 'Using Telemedicine',
      description: 'Guide to video consultations',
      duration: '6 min',
      icon: Icons.video_call,
    ),
  ];

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      children: _tutorials
          .map((tutorial) => _buildTutorialItem(tutorial, context))
          .toList(),
    );
  }

  Widget _buildTutorialItem(TutorialItem tutorial, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(tutorial.icon, color: color),
          ),
          title: Text(
            tutorial.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tutorial.description),
              const SizedBox(height: 4),
              Text(
                'Duration: ${tutorial.duration}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: Icon(Icons.play_arrow, color: color),
          onTap: () => _playTutorial(context, tutorial),
        ),
      ),
    );
  }

  void _playTutorial(BuildContext context, TutorialItem tutorial) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tutorial.title),
        content: Text(
          '${tutorial.description}\n\nTutorial video would play here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Tutorial item model
class TutorialItem {
  final String title;
  final String description;
  final String duration;
  final IconData icon;

  const TutorialItem({
    required this.title,
    required this.description,
    required this.duration,
    required this.icon,
  });
}

// Feedback Section (Inheritance)
class FeedbackSection extends HelpSection {
  @override
  String get title => 'Feedback & Suggestions';

  @override
  IconData get icon => Icons.feedback;

  @override
  Color get color => Colors.purple;

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade50, Colors.pink.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 48),
              const SizedBox(height: 16),
              Text(
                'We Value Your Feedback',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help us improve by sharing your thoughts and suggestions',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        _buildFeedbackOption(
          'Rate the App',
          'Share your experience on app stores',
          Icons.star,
          Colors.amber,
          () => _rateApp(context),
        ),
        _buildFeedbackOption(
          'Send Feedback',
          'Send us your suggestions and comments',
          Icons.message,
          Colors.blue,
          () => _sendFeedback(context),
        ),
        _buildFeedbackOption(
          'Report a Bug',
          'Help us fix issues you encounter',
          Icons.bug_report,
          Colors.red,
          () => _reportBug(context),
        ),
        _buildFeedbackOption(
          'Feature Request',
          'Suggest new features you\'d like to see',
          Icons.lightbulb,
          Colors.orange,
          () => _requestFeature(context),
        ),
      ],
    );
  }

  Widget _buildFeedbackOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.shade600,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  void _rateApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Our App'),
        content: const Text('Would redirect to app store for rating.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _sendFeedback(BuildContext context) {
    _showFeedbackDialog(
      context,
      'Send Feedback',
      'Share your thoughts with us...',
    );
  }

  void _reportBug(BuildContext context) {
    _showFeedbackDialog(
      context,
      'Report Bug',
      'Describe the issue you encountered...',
    );
  }

  void _requestFeature(BuildContext context) {
    _showFeedbackDialog(
      context,
      'Feature Request',
      'What feature would you like to see?',
    );
  }

  void _showFeedbackDialog(BuildContext context, String title, String hint) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          height: 150,
          child: TextField(
            controller: controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your feedback!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

// Main Help & Support Page using Composition
class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<HelpSection> _sections = [
    FAQSection(),
    ContactSupportSection(),
    TutorialsSection(),
    FeedbackSection(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sections.length, vsync: this);
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.purple.shade600,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: _sections.map((section) {
            return Tab(icon: Icon(section.icon), text: section.title);
          }).toList(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.purple.shade800],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.help_center, size: 50, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'We\'re Here to Help',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Find answers or get in touch with our support team',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _sections.map((section) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: section.buildContent(context),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
