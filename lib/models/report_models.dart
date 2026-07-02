class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      hasNextPage: json['has_next_page'] == true,
      hasPreviousPage: json['has_previous_page'] == true,
    );
  }
}

class PersonalTransactionReport {
  final String transactionId;
  final String transactionType;
  final double amount;
  final String? name;
  final String? email;
  final String? category;
  final String? remark;
  final String? paymentMode;
  final String? loanType;
  final String? transactionDate;
  final String? dueDate;
  final String? createdAt;

  PersonalTransactionReport({
    required this.transactionId,
    required this.transactionType,
    required this.amount,
    this.name,
    this.email,
    this.category,
    this.remark,
    this.paymentMode,
    this.loanType,
    this.transactionDate,
    this.dueDate,
    this.createdAt,
  });

  factory PersonalTransactionReport.fromJson(Map<String, dynamic> json) {
    return PersonalTransactionReport(
      transactionId: json['transaction_id'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      name: json['name'],
      email: json['email'],
      category: json['category'],
      remark: json['remark'],
      paymentMode: json['payment_mode'],
      loanType: json['loan_type'],
      transactionDate: json['transaction_date'],
      dueDate: json['due_date'],
      createdAt: json['created_at'],
    );
  }
}

class CategoryReport {
  final String category;
  final double totalAmount;
  final int transactionCount;

  CategoryReport({
    required this.category,
    required this.totalAmount,
    required this.transactionCount,
  });

  factory CategoryReport.fromJson(Map<String, dynamic> json) {
    return CategoryReport(
      category: json['category'] ?? '',
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : 0.0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class PaymentModeReport {
  final String paymentMode;
  final double totalAmount;
  final int transactionCount;

  PaymentModeReport({
    required this.paymentMode,
    required this.totalAmount,
    required this.transactionCount,
  });

  factory PaymentModeReport.fromJson(Map<String, dynamic> json) {
    return PaymentModeReport(
      paymentMode: json['payment_mode'] ?? '',
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : 0.0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class BusinessTransactionReport {
  final String transactionId;
  final String? transactionNumber;
  final String? title;
  final String? businessId;
  final String? partyId;
  final String? partyName;
  final String? partyType;
  final String transactionType;
  final String? transactionDate;
  final String? dueDate;
  final double subtotalAmount;
  final double totalGstAmount;
  final double totalAmount;
  final String? createdAt;

  BusinessTransactionReport({
    required this.transactionId,
    this.transactionNumber,
    this.title,
    this.businessId,
    this.partyId,
    this.partyName,
    this.partyType,
    required this.transactionType,
    this.transactionDate,
    this.dueDate,
    required this.subtotalAmount,
    required this.totalGstAmount,
    required this.totalAmount,
    this.createdAt,
  });

  factory BusinessTransactionReport.fromJson(Map<String, dynamic> json) {
    return BusinessTransactionReport(
      transactionId: json['transaction_id'] ?? '',
      transactionNumber: json['transaction_number'],
      title: json['title'],
      businessId: json['business_id'],
      partyId: json['party_id'],
      partyName: json['party_name'],
      partyType: json['party_type'],
      transactionType: json['transaction_type'] ?? '',
      transactionDate: json['transaction_date'],
      dueDate: json['due_date'],
      subtotalAmount: (json['subtotal_amount'] is num) ? (json['subtotal_amount'] as num).toDouble() : 0.0,
      totalGstAmount: (json['total_gst_amount'] is num) ? (json['total_gst_amount'] as num).toDouble() : 0.0,
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : 0.0,
      createdAt: json['created_at'],
    );
  }
}

class SaleReport {
  final String transactionId;
  final String? transactionNumber;
  final String? partyName;
  final String? partyType;
  final double totalAmount;
  final String? transactionDate;
  final int itemsCount;

  SaleReport({
    required this.transactionId,
    this.transactionNumber,
    this.partyName,
    this.partyType,
    required this.totalAmount,
    this.transactionDate,
    required this.itemsCount,
  });

  factory SaleReport.fromJson(Map<String, dynamic> json) {
    return SaleReport(
      transactionId: json['transaction_id'] ?? '',
      transactionNumber: json['transaction_number'],
      partyName: json['party_name'],
      partyType: json['party_type'],
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : 0.0,
      transactionDate: json['transaction_date'],
      itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class PurchaseReport {
  final String transactionId;
  final String? transactionNumber;
  final String? partyName;
  final double totalAmount;
  final String? transactionDate;
  final List<PurchaseItem> items;

  PurchaseReport({
    required this.transactionId,
    this.transactionNumber,
    this.partyName,
    required this.totalAmount,
    this.transactionDate,
    this.items = const [],
  });

  factory PurchaseReport.fromJson(Map<String, dynamic> json) {
    return PurchaseReport(
      transactionId: json['transaction_id'] ?? '',
      transactionNumber: json['transaction_number'],
      partyName: json['party_name'],
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : 0.0,
      transactionDate: json['transaction_date'],
      items: (json['items'] as List?)?.map((i) => PurchaseItem.fromJson(i)).toList() ?? [],
    );
  }
}

class PurchaseItem {
  final String? itemName;
  final int quantity;
  final double price;

  PurchaseItem({this.itemName, required this.quantity, required this.price});

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      itemName: json['item_name'],
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
    );
  }
}

class ExpenseReport {
  final String transactionId;
  final String? transactionNumber;
  final String? title;
  final double totalAmount;
  final String? transactionDate;
  final List<ExpenseReportItem> items;

  ExpenseReport({
    required this.transactionId,
    this.transactionNumber,
    this.title,
    required this.totalAmount,
    this.transactionDate,
    this.items = const [],
  });

  factory ExpenseReport.fromJson(Map<String, dynamic> json) {
    return ExpenseReport(
      transactionId: json['transaction_id'] ?? '',
      transactionNumber: json['transaction_number'],
      title: json['title'],
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : 0.0,
      transactionDate: json['transaction_date'],
      items: (json['items'] as List?)?.map((i) => ExpenseReportItem.fromJson(i)).toList() ?? [],
    );
  }
}

class ExpenseReportItem {
  final String? itemName;
  final String? description;
  final int quantity;
  final double price;

  ExpenseReportItem({this.itemName, this.description, required this.quantity, required this.price});

  factory ExpenseReportItem.fromJson(Map<String, dynamic> json) {
    return ExpenseReportItem(
      itemName: json['item_name'],
      description: json['description'],
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
    );
  }
}

class PartySummary {
  final String partyId;
  final String partyName;
  final String? phone;
  final String partyType;
  final int totalTransactions;
  final double totalSales;
  final double totalPurchase;
  final double totalAmount;

  PartySummary({
    required this.partyId,
    required this.partyName,
    this.phone,
    required this.partyType,
    required this.totalTransactions,
    required this.totalSales,
    required this.totalPurchase,
    required this.totalAmount,
  });

  factory PartySummary.fromJson(Map<String, dynamic> json) {
    return PartySummary(
      partyId: json['party_id'] ?? '',
      partyName: json['party_name'] ?? '',
      phone: json['phone'],
      partyType: json['party_type'] ?? '',
      totalTransactions: (json['total_transactions'] as num?)?.toInt() ?? 0,
      totalSales: (json['total_sales'] is num) ? (json['total_sales'] as num).toDouble() : 0.0,
      totalPurchase: (json['total_purchase'] is num) ? (json['total_purchase'] as num).toDouble() : 0.0,
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : 0.0,
    );
  }
}

class TopCustomer {
  final String partyId;
  final String partyName;
  final String? phone;
  final double totalSales;
  final int transactionCount;

  TopCustomer({
    required this.partyId,
    required this.partyName,
    this.phone,
    required this.totalSales,
    required this.transactionCount,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      partyId: json['party_id'] ?? '',
      partyName: json['party_name'] ?? '',
      phone: json['phone'],
      totalSales: (json['total_sales'] is num) ? (json['total_sales'] as num).toDouble() : 0.0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TopSupplier {
  final String partyId;
  final String partyName;
  final String? phone;
  final double totalPurchase;
  final int transactionCount;

  TopSupplier({
    required this.partyId,
    required this.partyName,
    this.phone,
    required this.totalPurchase,
    required this.transactionCount,
  });

  factory TopSupplier.fromJson(Map<String, dynamic> json) {
    return TopSupplier(
      partyId: json['party_id'] ?? '',
      partyName: json['party_name'] ?? '',
      phone: json['phone'],
      totalPurchase: (json['total_purchase'] is num) ? (json['total_purchase'] as num).toDouble() : 0.0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ItemSaleReport {
  final String itemId;
  final String itemName;
  final String categoryName;
  final int totalQuantitySold;
  final double totalRevenue;
  final double gstRate;

  ItemSaleReport({
    required this.itemId,
    required this.itemName,
    required this.categoryName,
    required this.totalQuantitySold,
    required this.totalRevenue,
    required this.gstRate,
  });

  factory ItemSaleReport.fromJson(Map<String, dynamic> json) {
    return ItemSaleReport(
      itemId: json['item_id'] ?? '',
      itemName: json['item_name'] ?? '',
      categoryName: json['category_name'] ?? '',
      totalQuantitySold: (json['total_quantity_sold'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] is num) ? (json['total_revenue'] as num).toDouble() : 0.0,
      gstRate: (json['gst_rate'] is num) ? (json['gst_rate'] as num).toDouble() : 0.0,
    );
  }
}

class ItemPurchaseReport {
  final String itemId;
  final String itemName;
  final String categoryName;
  final int totalQuantityPurchased;
  final double totalCost;

  ItemPurchaseReport({
    required this.itemId,
    required this.itemName,
    required this.categoryName,
    required this.totalQuantityPurchased,
    required this.totalCost,
  });

  factory ItemPurchaseReport.fromJson(Map<String, dynamic> json) {
    return ItemPurchaseReport(
      itemId: json['item_id'] ?? '',
      itemName: json['item_name'] ?? '',
      categoryName: json['category_name'] ?? '',
      totalQuantityPurchased: (json['total_quantity_purchased'] as num?)?.toInt() ?? 0,
      totalCost: (json['total_cost'] is num) ? (json['total_cost'] as num).toDouble() : 0.0,
    );
  }
}

class InventoryReport {
  final String itemId;
  final String itemName;
  final String categoryName;
  final double price;
  final double gstRate;
  final String? hsnCode;
  final int totalSold;
  final int totalPurchased;

  InventoryReport({
    required this.itemId,
    required this.itemName,
    required this.categoryName,
    required this.price,
    required this.gstRate,
    this.hsnCode,
    required this.totalSold,
    required this.totalPurchased,
  });

  int get stockInHand => totalPurchased - totalSold;

  factory InventoryReport.fromJson(Map<String, dynamic> json) {
    return InventoryReport(
      itemId: json['item_id'] ?? '',
      itemName: json['item_name'] ?? '',
      categoryName: json['category_name'] ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      gstRate: (json['gst_rate'] is num) ? (json['gst_rate'] as num).toDouble() : 0.0,
      hsnCode: json['hsn_code'],
      totalSold: (json['total_sold'] as num?)?.toInt() ?? 0,
      totalPurchased: (json['total_purchased'] as num?)?.toInt() ?? 0,
    );
  }
}

class GstSummary {
  final double totalGstCollected;
  final double totalGstPaid;
  final double netGst;

  GstSummary({
    required this.totalGstCollected,
    required this.totalGstPaid,
    required this.netGst,
  });

  factory GstSummary.fromJson(Map<String, dynamic> json) {
    return GstSummary(
      totalGstCollected: (json['total_gst_collected'] is num) ? (json['total_gst_collected'] as num).toDouble() : 0.0,
      totalGstPaid: (json['total_gst_paid'] is num) ? (json['total_gst_paid'] as num).toDouble() : 0.0,
      netGst: (json['net_gst'] is num) ? (json['net_gst'] as num).toDouble() : 0.0,
    );
  }
}

class GstDetail {
  final String? transactionNumber;
  final String transactionType;
  final String? transactionDate;
  final double subtotalAmount;
  final double totalGstAmount;
  final double totalAmount;
  final String? partyName;

  GstDetail({
    this.transactionNumber,
    required this.transactionType,
    this.transactionDate,
    required this.subtotalAmount,
    required this.totalGstAmount,
    required this.totalAmount,
    this.partyName,
  });

  factory GstDetail.fromJson(Map<String, dynamic> json) {
    return GstDetail(
      transactionNumber: json['transaction_number'],
      transactionType: json['transaction_type'] ?? '',
      transactionDate: json['transaction_date'],
      subtotalAmount: (json['subtotal_amount'] is num) ? (json['subtotal_amount'] as num).toDouble() : 0.0,
      totalGstAmount: (json['total_gst_amount'] is num) ? (json['total_gst_amount'] as num).toDouble() : 0.0,
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : 0.0,
      partyName: json['party_name'],
    );
  }
}

class ProfitLossReport {
  final double totalSales;
  final double totalPurchase;
  final double totalExpenses;
  final double grossProfit;
  final double netProfit;

  ProfitLossReport({
    required this.totalSales,
    required this.totalPurchase,
    required this.totalExpenses,
    required this.grossProfit,
    required this.netProfit,
  });

  factory ProfitLossReport.fromJson(Map<String, dynamic> json) {
    return ProfitLossReport(
      totalSales: (json['total_sales'] is num) ? (json['total_sales'] as num).toDouble() : 0.0,
      totalPurchase: (json['total_purchase'] is num) ? (json['total_purchase'] as num).toDouble() : 0.0,
      totalExpenses: (json['total_expenses'] is num) ? (json['total_expenses'] as num).toDouble() : 0.0,
      grossProfit: (json['gross_profit'] is num) ? (json['gross_profit'] as num).toDouble() : 0.0,
      netProfit: (json['net_profit'] is num) ? (json['net_profit'] as num).toDouble() : 0.0,
    );
  }
}

class CashFlowEntry {
  final String? date;
  final String transactionType;
  final String contextType;
  final double amountIn;
  final double amountOut;
  final double balance;

  CashFlowEntry({
    this.date,
    required this.transactionType,
    required this.contextType,
    required this.amountIn,
    required this.amountOut,
    required this.balance,
  });

  factory CashFlowEntry.fromJson(Map<String, dynamic> json) {
    return CashFlowEntry(
      date: json['date'],
      transactionType: json['transaction_type'] ?? '',
      contextType: json['context_type'] ?? '',
      amountIn: (json['amount_in'] is num) ? (json['amount_in'] as num).toDouble() : 0.0,
      amountOut: (json['amount_out'] is num) ? (json['amount_out'] as num).toDouble() : 0.0,
      balance: (json['balance'] is num) ? (json['balance'] as num).toDouble() : 0.0,
    );
  }
}

class MonthlyTrend {
  final String month;
  final double totalSales;
  final double totalPurchase;
  final double totalExpenses;
  final double netProfit;

  MonthlyTrend({
    required this.month,
    required this.totalSales,
    required this.totalPurchase,
    required this.totalExpenses,
    required this.netProfit,
  });

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      month: json['month'] ?? '',
      totalSales: (json['total_sales'] is num) ? (json['total_sales'] as num).toDouble() : 0.0,
      totalPurchase: (json['total_purchase'] is num) ? (json['total_purchase'] as num).toDouble() : 0.0,
      totalExpenses: (json['total_expenses'] is num) ? (json['total_expenses'] as num).toDouble() : 0.0,
      netProfit: (json['net_profit'] is num) ? (json['net_profit'] as num).toDouble() : 0.0,
    );
  }
}

class DashboardReport {
  final double totalSales;
  final double totalPurchase;
  final double totalExpenses;
  final int totalParties;
  final int totalItems;
  final int pendingReminders;
  final List<RecentTransaction> recentTransactions;

  DashboardReport({
    required this.totalSales,
    required this.totalPurchase,
    required this.totalExpenses,
    required this.totalParties,
    required this.totalItems,
    required this.pendingReminders,
    this.recentTransactions = const [],
  });

  factory DashboardReport.fromJson(Map<String, dynamic> json) {
    return DashboardReport(
      totalSales: (json['total_sales'] is num) ? (json['total_sales'] as num).toDouble() : 0.0,
      totalPurchase: (json['total_purchase'] is num) ? (json['total_purchase'] as num).toDouble() : 0.0,
      totalExpenses: (json['total_expenses'] is num) ? (json['total_expenses'] as num).toDouble() : 0.0,
      totalParties: (json['total_parties'] as num?)?.toInt() ?? 0,
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
      pendingReminders: (json['pending_reminders'] as num?)?.toInt() ?? 0,
      recentTransactions: (json['recent_transactions'] as List?)?.map((t) => RecentTransaction.fromJson(t)).toList() ?? [],
    );
  }
}

class RecentTransaction {
  final String transactionId;
  final String? transactionNumber;
  final String transactionType;
  final double totalAmount;
  final String? transactionDate;
  final String? partyName;

  RecentTransaction({
    required this.transactionId,
    this.transactionNumber,
    required this.transactionType,
    required this.totalAmount,
    this.transactionDate,
    this.partyName,
  });

  factory RecentTransaction.fromJson(Map<String, dynamic> json) {
    return RecentTransaction(
      transactionId: json['transaction_id'] ?? '',
      transactionNumber: json['transaction_number'],
      transactionType: json['transaction_type'] ?? '',
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : 0.0,
      transactionDate: json['transaction_date'],
      partyName: json['party_name'],
    );
  }
}

class CombinedHistoryEntry {
  final String transactionId;
  final String contextType;
  final String transactionType;
  final double amount;
  final String? transactionDate;
  final String? partyName;
  final String? description;

  CombinedHistoryEntry({
    required this.transactionId,
    required this.contextType,
    required this.transactionType,
    required this.amount,
    this.transactionDate,
    this.partyName,
    this.description,
  });

  factory CombinedHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CombinedHistoryEntry(
      transactionId: json['transaction_id'] ?? '',
      contextType: json['context_type'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      transactionDate: json['transaction_date'],
      partyName: json['party_name'],
      description: json['description'],
    );
  }
}
