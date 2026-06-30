// ============================================================
// BUSINESS MODELS
// ============================================================

/// Represents a business entity
class BusinessModel {
  final String business_id;
  final String business_name;
  final String? phone;
  final String? email;
  final String? gstin;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessModel({
    required this.business_id,
    required this.business_name,
    this.phone,
    this.email,
    this.gstin,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      business_id: json['business_id'] ?? '',
      business_name: json['name'] ?? json['business_name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      gstin: json['gstin'],
      address: json['address'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': business_name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (gstin != null) 'gstin': gstin,
      if (address != null) 'address': address,
    };
  }
}

/// Represents a party (Customer or Supplier)
class PartyModel {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? email;
  final String partyType; // CUSTOMER or SUPPLIER
  final String? gstin;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  PartyModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.email,
    required this.partyType,
    this.gstin,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PartyModel.fromJson(Map<String, dynamic> json) {
    return PartyModel(
      id: json['party_id'] ?? json['id'] ?? '',
      businessId: json['business_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      partyType: json['party_type'] ?? json['partyType'] ?? 'CUSTOMER',
      gstin: json['gstin'],
      address: json['address'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'party_type': partyType,
      'business_id': businessId,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (gstin != null) 'gstin': gstin,
      if (address != null) 'address': address,
    };
  }
}

/// Represents a business transaction
class BusinessTransactionModel {
  final String transactionId;
  final String transactionNumber;
  final String businessId;
  final String? partyId;
  final String? userId;
  final String? title;
  final String? description;
  final String transactionType;
  final DateTime transactionDate;
  final String? transactionTime;
  final DateTime? dueDate;
  final double subtotalAmount;
  final double totalGstAmount;
  final double totalAmount;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? lastModifiedAt;
  final PartyModel? party;
  final List<TransactionItemModel> items;

  BusinessTransactionModel({
    required this.transactionId,
    required this.transactionNumber,
    required this.businessId,
    this.partyId,
    this.userId,
    this.title,
    this.description,
    required this.transactionType,
    required this.transactionDate,
    this.transactionTime,
    this.dueDate,
    required this.subtotalAmount,
    required this.totalGstAmount,
    required this.totalAmount,
    required this.isDeleted,
    required this.createdAt,
    this.lastModifiedAt,
    this.party,
    this.items = const [],
  });

  factory BusinessTransactionModel.fromJson(Map<String, dynamic> json) {
    return BusinessTransactionModel(
      transactionId: json['transaction_id'] ?? json['id'] ?? '',
      transactionNumber: json['transaction_number'] ?? '',
      businessId: json['business_id'] ?? '',
      partyId: json['party_id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      transactionType: json['transaction_type'] ?? '',
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'])
          : DateTime.now(),
      transactionTime: json['transaction_time'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      subtotalAmount: (json['subtotal_amount'] is num) ? (json['subtotal_amount'] as num).toDouble() : 0.0,
      totalGstAmount: (json['total_gst_amount'] is num) ? (json['total_gst_amount'] as num).toDouble() : 0.0,
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : 0.0,
      isDeleted: json['is_deleted'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      lastModifiedAt: json['last_modified_at'] != null ? DateTime.parse(json['last_modified_at']) : null,
      party: json['party'] != null ? PartyModel.fromJson(json['party']) : null,
      items: json['items'] != null
          ? (json['items'] as List).map((item) => TransactionItemModel.fromJson(item)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'transaction_number': transactionNumber,
      'business_id': businessId,
      if (partyId != null) 'party_id': partyId,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      'transaction_type': transactionType,
      'transaction_date': transactionDate.toIso8601String(),
      if (transactionTime != null) 'transaction_time': transactionTime,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      'subtotal_amount': subtotalAmount,
      'total_gst_amount': totalGstAmount,
      'total_amount': totalAmount,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt!.toIso8601String(),
      if (party != null) 'party': party!.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class TransactionItemModel {
  final String id;
  final String transactionId;
  final String? itemId;
  final String? description;
  final int quantity;
  final double price;
  final CatalogItemModel? item;

  TransactionItemModel({
    required this.id,
    required this.transactionId,
    this.itemId,
    this.description,
    required this.quantity,
    required this.price,
    this.item,
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    return TransactionItemModel(
      id: json['id'] ?? json['transaction_item_id'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      itemId: json['item_id'],
      description: json['description'],
      quantity: json['quantity'] ?? 0,
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      item: json['item'] != null ? CatalogItemModel.fromJson(json['item']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      if (itemId != null) 'item_id': itemId,
      if (description != null) 'description': description,
      'quantity': quantity,
      'price': price,
      if (item != null) 'item': item!.toJson(),
    };
  }

  double get total => quantity * price;
}

/// Represents a catalog item for a business
class CatalogItemModel {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final double price;
  final String? unit;
  final String? hsnCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  CatalogItemModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    required this.price,
    this.unit,
    this.hsnCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CatalogItemModel.fromJson(Map<String, dynamic> json) {
    // Debug logging
    final priceValue = json['price'];
    final priceType = priceValue?.runtimeType.toString() ?? 'null';
    final isNum = priceValue is num;
    final parsedPrice = isNum
        ? (priceValue as num).toDouble()
        : (priceValue is String ? double.tryParse(priceValue) ?? 0.0 : 0.0);

    print('CatalogItemModel parsing:');
    print('  Raw price value: $priceValue');
    print('  Price type: $priceType');
    print('  Is num: $isNum');
    print('  Parsed price: $parsedPrice');

    return CatalogItemModel(
      id: json['item_id'] ?? json['id'] ?? '',
      businessId: json['business_id'] ?? '',
      name: json['name'] ?? json['item_name'] ?? '',
      description: json['description'],
      price: parsedPrice,
      unit: json['unit'],
      hsnCode: json['hsn_code'] ?? json['hsnCode'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'business_id': businessId,
      if (description != null) 'description': description,
      if (unit != null) 'unit': unit,
      if (hsnCode != null) 'hsn_code': hsnCode,
    };
  }
}
