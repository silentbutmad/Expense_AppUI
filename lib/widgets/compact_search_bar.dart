import 'package:flutter/material.dart';

typedef OnSearchChanged = void Function(String value);
typedef OnClearSearch = void Function();

class CompactSearchBar extends StatefulWidget {
  final String hintText;
  final OnSearchChanged onSearchChanged;
  final OnClearSearch? onClearSearch;
  final String initialValue;

  const CompactSearchBar({
    super.key,
    required this.hintText,
    required this.onSearchChanged,
    this.onClearSearch,
    this.initialValue = '',
  });

  @override
  State<CompactSearchBar> createState() => _CompactSearchBarState();
}

class _CompactSearchBarState extends State<CompactSearchBar> {
  late TextEditingController _controller;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _currentQuery = widget.initialValue;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _currentQuery = '';
    });
    widget.onClearSearch?.call();
    widget.onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search, size: 18),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: _currentQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: _clearSearch,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _currentQuery = value;
          });
          widget.onSearchChanged(value);
        },
      ),
    );
  }
}