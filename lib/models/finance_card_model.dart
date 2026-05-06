import 'package:flutter/material.dart';

class FinanceCardModel {
  final String id;
  final String title;
  final double value;
  final IconData icon;
  final List<double> history;

  FinanceCardModel({
    required this.id,
    required this.title,
    required this.value,
    required this.icon,
    required this.history,
  });
}
