class Tag {
  final String id;
  final String name;
  final String category; // Style, Occasion, Material, Pattern, etc.
  final String? description;
  final DateTime createdAt;
  final bool isActive;
  final int usageCount; // How many items have this tag
  final List<String> synonyms; // Alternative names for better matching

  Tag({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.createdAt,
    this.isActive = true,
    this.usageCount = 0,
    this.synonyms = const [],
  });

  factory Tag.fromMap(Map<String, dynamic> map, String id) {
    return Tag(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      usageCount: map['usageCount'] ?? 0,
      synonyms: List<String>.from(map['synonyms'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'createdAt': createdAt,
      'isActive': isActive,
      'usageCount': usageCount,
      'synonyms': synonyms,
    };
  }
}

class UserTagInteraction {
  final String id;
  final String userId;
  final String tagId;
  final String itemId;
  final InteractionType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // Additional context

  UserTagInteraction({
    required this.id,
    required this.userId,
    required this.tagId,
    required this.itemId,
    required this.type,
    required this.timestamp,
    this.metadata,
  });

  factory UserTagInteraction.fromMap(Map<String, dynamic> map, String id) {
    return UserTagInteraction(
      id: id,
      userId: map['userId'] ?? '',
      tagId: map['tagId'] ?? '',
      itemId: map['itemId'] ?? '',
      type: InteractionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InteractionType.view,
      ),
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tagId': tagId,
      'itemId': itemId,
      'type': type.name,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

enum InteractionType {
  view,        // User viewed an item with this tag
  like,        // User liked an item with this tag
  purchase,    // User purchased an item with this tag
  search,      // User searched for this tag
  filter,      // User filtered by this tag
}

class TaggedItem {
  final String itemId;
  final List<String> tagIds;
  final Map<String, double> tagRelevanceScores; // AI confidence scores
  final DateTime lastTaggedAt;

  TaggedItem({
    required this.itemId,
    required this.tagIds,
    this.tagRelevanceScores = const {},
    required this.lastTaggedAt,
  });

  factory TaggedItem.fromMap(Map<String, dynamic> map) {
    return TaggedItem(
      itemId: map['itemId'] ?? '',
      tagIds: List<String>.from(map['tagIds'] ?? []),
      tagRelevanceScores: Map<String, double>.from(map['tagRelevanceScores'] ?? {}),
      lastTaggedAt: map['lastTaggedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'tagIds': tagIds,
      'tagRelevanceScores': tagRelevanceScores,
      'lastTaggedAt': lastTaggedAt,
    };
  }
} 