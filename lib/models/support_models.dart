class TicketModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String issueType;
  final String priority;
  final String status;
  final String? assignedAgent;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.issueType,
    required this.priority,
    required this.status,
    this.assignedAgent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      issueType: json['issueType'] ?? 'OTHER',
      priority: json['priority'] ?? 'MEDIUM',
      status: json['status'] ?? 'OPEN',
      assignedAgent: json['assignedAgent'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'issueType': issueType,
      'priority': priority,
      'status': status,
      'assignedAgent': assignedAgent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CommentModel {
  final String id;
  final String ticketId;
  final String message;
  final String userId;
  final String? userName;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.ticketId,
    required this.message,
    required this.userId,
    this.userName,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      ticketId: json['ticketId'] ?? '',
      message: json['message'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['user']?['name'] ?? json['userName'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'message': message,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class FaqModel {
  final String id;
  final String question;
  final String answer;
  final String category;
  final DateTime createdAt;

  FaqModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.createdAt,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      category: json['category'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class HelpInfoModel {
  final String whatsapp;
  final String callUs;
  final String email;
  final String workingHours;
  final String? address;
  final String? website;

  HelpInfoModel({
    required this.whatsapp,
    required this.callUs,
    required this.email,
    required this.workingHours,
    this.address,
    this.website,
  });

  factory HelpInfoModel.fromJson(Map<String, dynamic> json) {
    return HelpInfoModel(
      whatsapp: json['whatsapp'] ?? '',
      callUs: json['callUs'] ?? '',
      email: json['email'] ?? '',
      workingHours: json['workingHours'] ?? '',
      address: json['address'],
      website: json['website'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'whatsapp': whatsapp,
      'callUs': callUs,
      'email': email,
      'workingHours': workingHours,
      'address': address,
      'website': website,
    };
  }
}

class TicketCreateRequest {
  final String title;
  final String description;
  final String issueType;
  final String priority;

  TicketCreateRequest({
    required this.title,
    required this.description,
    required this.issueType,
    required this.priority,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'issueType': issueType,
      'priority': priority,
    };
  }
}

class CommentCreateRequest {
  final String message;

  CommentCreateRequest({required this.message});

  Map<String, dynamic> toJson() {
    return {'message': message};
  }
}