import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:myapp/models/support_models.dart';
import 'package:myapp/providers/support_provider.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/theme/app_tokens.dart';
import 'package:myapp/utils/token_manager.dart';
import 'package:provider/provider.dart';

class TicketDetailsScreen extends StatefulWidget {
  const TicketDetailsScreen({super.key});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  final _commentController = TextEditingController();
  String? _ticketId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTicketDetails();
    });
  }

  Future<void> _loadTicketDetails() async {
    final supportProvider = context.read<SupportProvider>();
    final ticket = supportProvider.selectedTicket;
    
    if (ticket != null) {
      setState(() {
        _ticketId = ticket.id;
      });
      await supportProvider.getComments(ticket.id);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final supportProvider = context.read<SupportProvider>();
    final success = await supportProvider.addComment(
      _ticketId!,
      _commentController.text.trim(),
    );

    if (success && mounted) {
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(supportProvider.errorMessage ?? 'Failed to add comment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Details'),
      ),
      body: Consumer<SupportProvider>(
        builder: (context, supportProvider, child) {
          final ticket = supportProvider.selectedTicket;

          if (supportProvider.isLoadingTicketDetails) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (ticket == null) {
            return const Center(
              child: Text('Ticket not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTicketInfo(ticket, supportProvider),
                const SizedBox(height: 24),
                _buildCommentsSection(supportProvider),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketInfo(TicketModel ticket, SupportProvider supportProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.description,
              label: 'Description',
              value: ticket.description,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.category,
              label: 'Issue Type',
              value: supportProvider.getIssueTypeLabel(ticket.issueType),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.flag,
              label: 'Priority',
              value: supportProvider.getPriorityLabel(ticket.priority),
              valueColor: supportProvider.getPriorityColor(ticket.priority),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.info,
              label: 'Status',
              value: supportProvider.getStatusLabel(ticket.status),
              valueColor: supportProvider.getStatusColor(ticket.status),
            ),
            const SizedBox(height: 16),
            if (ticket.assignedAgent != null)
              _InfoRow(
                icon: Icons.person,
                label: 'Assigned Agent',
                value: ticket.assignedAgent!,
              ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Created',
              value: _formatDateTime(ticket.createdAt),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.update,
              label: 'Last Updated',
              value: _formatDateTime(ticket.updatedAt),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppTokens.animationMedium);
  }

  Widget _buildCommentsSection(SupportProvider supportProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        if (supportProvider.isLoadingComments)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (supportProvider.comments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'No comments yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: supportProvider.comments.length,
            itemBuilder: (context, index) {
              final comment = supportProvider.comments[index];
              return _CommentCard(comment: comment);
            },
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.padding),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: supportProvider.isAddingComment ? null : _submitComment,
                  icon: supportProvider.isAddingComment
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: AppTokens.animationFast, duration: AppTokens.animationMedium);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: valueColor,
                      fontWeight: valueColor != null ? FontWeight.bold : null,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  final CommentModel comment;

  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    comment.userName ?? 'User',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  _formatDate(comment.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppTokens.animationFast);
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}