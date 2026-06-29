import 'package:flutter/material.dart';

class SearchablePickerItem<T> {
  final T value;
  final String displayName;
  final String? subtitle;
  final Widget? leading;

  const SearchablePickerItem({
    required this.value,
    required this.displayName,
    this.subtitle,
    this.leading,
  });
}

class SearchablePicker {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<SearchablePickerItem<T>> items,
    T? selected,
    String searchHint = 'Search...',
    String emptyText = 'No items found',
    bool showClearButton = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SearchablePickerSheet(
        title: title,
        items: items,
        selected: selected,
        searchHint: searchHint,
        emptyText: emptyText,
        showClearButton: showClearButton,
      ),
    );
  }
}

class _SearchablePickerSheet<T> extends StatefulWidget {
  final String title;
  final List<SearchablePickerItem<T>> items;
  final T? selected;
  final String searchHint;
  final String emptyText;
  final bool showClearButton;

  const _SearchablePickerSheet({
    required this.title,
    required this.items,
    this.selected,
    required this.searchHint,
    required this.emptyText,
    required this.showClearButton,
  });

  @override
  State<_SearchablePickerSheet<T>> createState() => _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T> extends State<_SearchablePickerSheet<T>> {
  late List<SearchablePickerItem<T>> _filteredItems;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        final q = query.toLowerCase();
        _filteredItems = widget.items.where((item) =>
          item.displayName.toLowerCase().contains(q) ||
          (item.subtitle?.toLowerCase().contains(q) ?? false)
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.title,
                          style: t.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.showClearButton)
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Clear'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _filter,
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _filteredItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              widget.emptyText,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _filteredItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = item.value == widget.selected;

                        return ListTile(
                          leading: item.leading,
                          title: Text(
                            item.displayName,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: t.colorScheme.primary)
                              : null,
                          onTap: () => Navigator.pop(context, item.value),
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}
