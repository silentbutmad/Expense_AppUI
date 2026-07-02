import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:myapp/models/support_models.dart';
import 'package:myapp/providers/support_provider.dart';
import 'package:myapp/screens/ticket_details_screen.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/theme/app_tokens.dart';
import 'package:myapp/utils/token_manager.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedIssueType;
  String? _selectedPriority;

  final List<String> _issueTypes = [
    'PAYMENT',
    'LOGIN',
    'ACCOUNT',
    'EXPENSE',
    'BUG',
    'FEATURE_REQUEST',
    'OTHER',
  ];

  final List<String> _priorities = [
    'LOW',
    'MEDIUM',
    'HIGH',
    'CRITICAL',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final supportProvider = context.read<SupportProvider>();
    final userId = await TokenManager.getUserId();
    
    if (userId != null) {
      await supportProvider.refreshAll();
    } else {
      await supportProvider.loadPublicData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    final supportProvider = context.read<SupportProvider>();
    final success = await supportProvider.createTicket(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      issueType: _selectedIssueType!,
      priority: _selectedPriority!,
    );

    if (success && mounted) {
      _formKey.currentState!.reset();
      _selectedIssueType = null;
      _selectedPriority = null;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket Created Successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh tickets list
      await supportProvider.getUserTickets();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(supportProvider.errorMessage ?? 'Failed to create ticket'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: Consumer<SupportProvider>(
        builder: (context, supportProvider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              final userId = await TokenManager.getUserId();
              if (userId != null) {
                await supportProvider.refreshAll();
              } else {
                await supportProvider.loadPublicData();
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTokens.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildQuickContactOptions(supportProvider),
                  const SizedBox(height: 24),
                  _buildCreateTicketForm(supportProvider),
                  const SizedBox(height: 24),
                  _buildMyTicketsSection(supportProvider),
                  const SizedBox(height: 24),
                  _buildFaqSection(supportProvider),
                  const SizedBox(height: 24),
                  _buildHelpCenterInfo(supportProvider),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Help & Support',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Need assistance? We\'re here to help.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    ).animate().fadeIn(duration: AppTokens.animationMedium);
  }

  Widget _buildQuickContactOptions(SupportProvider supportProvider) {
    final helpInfo = supportProvider.helpInfo;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Contact',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ContactCard(
                icon: Icons.chat,
                iconColor: Colors.green,
                label: 'Chat on WhatsApp',
                onTap: helpInfo != null
                    ? () => _launchUrl('https://wa.me/${helpInfo.whatsapp.replaceAll('+', '')}')
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ContactCard(
                icon: Icons.phone,
                iconColor: Colors.blue,
                label: 'Call Support',
                onTap: helpInfo != null
                    ? () => _launchUrl('tel:${helpInfo.callUs}')
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ContactCard(
                icon: Icons.email,
                iconColor: Colors.orange,
                label: 'Email Support',
                onTap: helpInfo != null
                    ? () => _launchUrl('mailto:${helpInfo.email}')
                    : null,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: AppTokens.animationFast, duration: AppTokens.animationMedium);
  }

  Widget _buildCreateTicketForm(SupportProvider supportProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.padding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Support Ticket',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Brief description of the issue',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Detailed description of your issue',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedIssueType,
                decoration: const InputDecoration(
                  labelText: 'Issue Type',
                  border: OutlineInputBorder(),
                ),
                items: _issueTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(supportProvider.getIssueTypeLabel(type)),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedIssueType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select an issue type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: _priorities
                    .map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(supportProvider.getPriorityLabel(priority)),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a priority';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: supportProvider.isCreatingTicket ? null : _submitTicket,
                  child: supportProvider.isCreatingTicket
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit Ticket'),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: AppTokens.animationFast * 2, duration: AppTokens.animationMedium);
  }

  Widget _buildMyTicketsSection(SupportProvider supportProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Support Tickets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (supportProvider.tickets.isNotEmpty)
              Text(
                '${supportProvider.tickets.length} tickets',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (supportProvider.isLoadingTickets)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (supportProvider.ticketsError != null)
          _EmptyState(
            icon: Icons.cloud_off,
            message: 'Could not load tickets',
            subMessage: 'Pull down to retry',
          )
        else if (supportProvider.tickets.isEmpty)
          _EmptyState(
            icon: Icons.support_agent,
            message: 'No tickets yet',
            subMessage: 'Create a ticket to get help',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: supportProvider.tickets.length,
            itemBuilder: (context, index) {
              final ticket = supportProvider.tickets[index];
              return _TicketCard(
                ticket: ticket,
                onTap: () async {
                  // Set the selected ticket before navigating
                  supportProvider.selectedTicket = ticket;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TicketDetailsScreen(),
                    ),
                  );
                  // Don't refresh tickets on return - causes unnecessary loading
                },
              );
            },
          ),
      ],
    ).animate().fadeIn(delay: AppTokens.animationFast * 3, duration: AppTokens.animationMedium);
  }

  Widget _buildFaqSection(SupportProvider supportProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        if (supportProvider.isLoadingFaqs)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (supportProvider.faqsError != null)
          _EmptyState(
            icon: Icons.cloud_off,
            message: 'Unable to load FAQs',
            subMessage: 'Pull down to retry',
          )
        else if (supportProvider.faqs.isEmpty)
          _EmptyState(
            icon: Icons.help_outline,
            message: 'No FAQs available',
            subMessage: 'Check back later',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: supportProvider.faqs.length,
            itemBuilder: (context, index) {
              final faq = supportProvider.faqs[index];
              return _FaqTile(faq: faq);
            },
          ),
      ],
    ).animate().fadeIn(delay: AppTokens.animationFast * 4, duration: AppTokens.animationMedium);
  }

  Widget _buildHelpCenterInfo(SupportProvider supportProvider) {
    final helpInfo = supportProvider.helpInfo;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Help Center',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        if (supportProvider.isLoadingHelpInfo)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (helpInfo == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Help center information temporarily unavailable',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.padding),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.access_time,
                    label: 'Working Hours',
                    value: helpInfo.workingHours,
                  ),
                  const Divider(height: 32),
                  _InfoRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: helpInfo.email,
                    onTap: () => _launchUrl('mailto:${helpInfo.email}'),
                  ),
                  const Divider(height: 32),
                  _InfoRow(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: helpInfo.callUs,
                    onTap: () => _launchUrl('tel:${helpInfo.callUs}'),
                  ),
                  const Divider(height: 32),
                  _InfoRow(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    value: helpInfo.whatsapp,
                    onTap: () => _launchUrl('https://wa.me/${helpInfo.whatsapp.replaceAll('+', '')}'),
                  ),
                ],
              ),
            ),
          ),
      ],
    ).animate().fadeIn(delay: AppTokens.animationFast * 5, duration: AppTokens.animationMedium);
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  const _ContactCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: iconColor,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onTap;

  const _TicketCard({
    required this.ticket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final supportProvider = context.read<SupportProvider>();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: supportProvider.getStatusColor(ticket.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      supportProvider.getStatusLabel(ticket.status),
                      style: TextStyle(
                        color: supportProvider.getStatusColor(ticket.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(
                      supportProvider.getIssueTypeLabel(ticket.issueType),
                      style: const TextStyle(fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      supportProvider.getPriorityLabel(ticket.priority),
                      style: const TextStyle(fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: supportProvider.getPriorityColor(ticket.priority).withOpacity(0.2),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: ${ticket.id.substring(0, 8)}...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                  ),
                  Text(
                    supportProvider.formatDate(ticket.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final FaqModel faq;

  const _FaqTile({required this.faq});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              faq.answer,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subMessage;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.subMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                subMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}