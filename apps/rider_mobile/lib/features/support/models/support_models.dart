// lib/features/support/models/support_models.dart

enum SupportCategoryType {
  tripIssue,
  paymentIssue,
  accountIssue,
  lostItem,
  technicalIssue,
  safetyIssue,
  other,
}

extension SupportCategoryTypeExtension on SupportCategoryType {
  String get code {
    switch (this) {
      case SupportCategoryType.tripIssue:
        return 'TRIP_ISSUE';
      case SupportCategoryType.paymentIssue:
        return 'PAYMENT_ISSUE';
      case SupportCategoryType.accountIssue:
        return 'ACCOUNT';
      case SupportCategoryType.lostItem:
        return 'LOST_ITEM';
      case SupportCategoryType.technicalIssue:
        return 'TECHNICAL';
      case SupportCategoryType.safetyIssue:
        return 'SAFETY';
      case SupportCategoryType.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case SupportCategoryType.tripIssue:
        return 'Trip & Rides';
      case SupportCategoryType.paymentIssue:
        return 'Billing & Payments';
      case SupportCategoryType.accountIssue:
        return 'Account & Login';
      case SupportCategoryType.lostItem:
        return 'Lost Item';
      case SupportCategoryType.technicalIssue:
        return 'Technical Problem';
      case SupportCategoryType.safetyIssue:
        return 'Safety & Emergency';
      case SupportCategoryType.other:
        return 'Other Inquiries';
    }
  }

  String get emoji {
    switch (this) {
      case SupportCategoryType.tripIssue:
        return '🚗';
      case SupportCategoryType.paymentIssue:
        return '💳';
      case SupportCategoryType.accountIssue:
        return '🛡️';
      case SupportCategoryType.lostItem:
        return '🎒';
      case SupportCategoryType.technicalIssue:
        return '⚙️';
      case SupportCategoryType.safetyIssue:
        return '🚨';
      case SupportCategoryType.other:
        return '💬';
    }
  }
}

class FaqModel {
  final String id;
  final String category;
  final String question;
  final String answer;

  const FaqModel({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }
}

class SupportAvailabilityModel {
  final bool isChatAvailable;
  final int activeAgentsCount;
  final int estimatedWaitSeconds;
  final bool isCallAvailable;
  final String callPhoneNumber;
  final String callOperatingHours;
  final bool isCallbackAvailable;
  final String emailResponseWindow;

  const SupportAvailabilityModel({
    required this.isChatAvailable,
    required this.activeAgentsCount,
    required this.estimatedWaitSeconds,
    required this.isCallAvailable,
    required this.callPhoneNumber,
    required this.callOperatingHours,
    required this.isCallbackAvailable,
    required this.emailResponseWindow,
  });

  factory SupportAvailabilityModel.fallback() {
    return const SupportAvailabilityModel(
      isChatAvailable: true,
      activeAgentsCount: 3,
      estimatedWaitSeconds: 60,
      isCallAvailable: true,
      callPhoneNumber: '+91 1800 419 2244',
      callOperatingHours: '24/7 Priority Support',
      isCallbackAvailable: true,
      emailResponseWindow: 'Within 4-8 hours',
    );
  }

  factory SupportAvailabilityModel.fromJson(Map<String, dynamic> json) {
    final chat = json['chat'] as Map<String, dynamic>? ?? {};
    final call = json['call'] as Map<String, dynamic>? ?? {};
    final email = json['email'] as Map<String, dynamic>? ?? {};

    return SupportAvailabilityModel(
      isChatAvailable: chat['isAvailable'] as bool? ?? true,
      activeAgentsCount: (chat['activeAgentsCount'] as num?)?.toInt() ?? 1,
      estimatedWaitSeconds: (chat['estimatedWaitSeconds'] as num?)?.toInt() ?? 60,
      isCallAvailable: call['isAvailable'] as bool? ?? true,
      callPhoneNumber: call['phoneNumber'] as String? ?? '+91 1800 419 2244',
      callOperatingHours: call['operatingHours'] as String? ?? '24/7 Priority Support',
      isCallbackAvailable: call['callbackAvailable'] as bool? ?? true,
      emailResponseWindow: email['responseTimeWindow'] as String? ?? 'Within 4-8 hours',
    );
  }
}

enum ChatMessageSender { customer, agent, system }

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final ChatMessageSender sender;
  final String type; // TEXT, IMAGE, SYSTEM
  final String content;
  final String? attachmentUrl;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.sender,
    required this.type,
    required this.content,
    this.attachmentUrl,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['senderRole'] as String? ?? 'CUSTOMER').toUpperCase();
    final sender = roleStr == 'AGENT'
        ? ChatMessageSender.agent
        : roleStr == 'SYSTEM'
            ? ChatMessageSender.system
            : ChatMessageSender.customer;

    return ChatMessageModel(
      id: json['id'] as String? ?? 'msg-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      sender: sender,
      type: json['type'] as String? ?? 'TEXT',
      content: json['content'] as String? ?? '',
      attachmentUrl: json['attachmentUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SupportCaseResult {
  final String id;
  final String ticketNumber;
  final String subject;
  final String category;
  final String channel;

  const SupportCaseResult({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.category,
    required this.channel,
  });
}
