class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String? description;
  final bool isBusinessExpense;
  final double? gst;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.description,
    this.isBusinessExpense = false,
    this.gst,
  });
}
