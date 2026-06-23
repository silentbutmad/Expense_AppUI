enum TransactionType { received, paid,loan }
enum ContextType { personal, business }
enum TransactionCategory { income, expense, loan }

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String? description;
  final ContextType contextType;
  final TransactionCategory transactionCategory;
  final double? gst;
  final String? partyId;
  final String? personName;
  final TransactionType? transactionType;
  final String? remark;
  final PaymentMode? paymentMode;
  final List<ExpenseItem> items;
  final String? email;
  final bool? isBorrow;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.description,
    this.contextType = ContextType.personal,
    this.transactionCategory = TransactionCategory.expense,
    this.gst,
    this.partyId,
    this.personName,
    this.transactionType,
    this.remark,
    this.paymentMode,
    this.items = const [],
    this.email,
    this.isBorrow,
  });

  bool get isBusinessExpense => contextType == ContextType.business;
}

enum PaymentMode { cash, online, other }

class ExpenseItem {
  final String itemId;
  final int quantity;
  final double price;
  final String? description;

  ExpenseItem({
    required this.itemId,
    required this.quantity,
    required this.price,
    this.description,
  });
}
