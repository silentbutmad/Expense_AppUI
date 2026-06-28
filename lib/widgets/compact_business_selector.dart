import 'package:flutter/material.dart';
import 'package:myapp/models/business_models.dart';
import 'package:myapp/providers/business_provider.dart';

class CompactBusinessSelector extends StatelessWidget {
  final BusinessModel? selectedBusiness;
  final VoidCallback onTap;
  final VoidCallback onCreateBusiness;

  const CompactBusinessSelector({
    super.key,
    required this.selectedBusiness,
    required this.onTap,
    required this.onCreateBusiness,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedBusiness?.business_name ?? 'Select Business',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: selectedBusiness != null ? null : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.blue),
            onPressed: onCreateBusiness,
            tooltip: 'Create Business',
          ),
        ],
      ),
    );
  }
}

void showBusinessPickerBottomSheet(BuildContext context, BusinessProvider provider) {
  final theme = Theme.of(context);
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Business',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: provider.businesses.length,
                itemBuilder: (context, index) {
                  final biz = provider.businesses[index];
                  final isSelected = provider.selectedBusiness?.business_id == biz.business_id;
                  return ListTile(
                    leading: const Icon(Icons.business),
                    title: Text(biz.business_name),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                        : null,
                    selected: isSelected,
                    onTap: () {
                      provider.selectBusiness(biz);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}