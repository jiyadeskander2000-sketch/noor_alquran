class AzkarItem {
  final String text;
  final int count;
  int currentCount;
  final String? fadl;
  final String? source;
  final String? meaning;

  AzkarItem({
    required this.text,
    required this.count,
    this.currentCount = 0,
    this.fadl,
    this.source,
    this.meaning,
  });

  factory AzkarItem.fromJson(Map<String, dynamic> json) {
    return AzkarItem(
      text: json['text'] as String,
      count: json['count'] as int? ?? 1,
      currentCount: 0,
      fadl: json['fadl'] as String?,
      source: json['source'] as String?,
      meaning: json['meaning'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'count': count,
      if (fadl != null) 'fadl': fadl,
      if (source != null) 'source': source,
      if (meaning != null) 'meaning': meaning,
    };
  }
}

class AzkarCategory {
  final String category;
  final List<AzkarItem> items;

  AzkarCategory({
    required this.category,
    required this.items,
  });

  factory AzkarCategory.fromJson(Map<String, dynamic> json) {
    var itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((i) => AzkarItem.fromJson(i as Map<String, dynamic>))
        .toList();
    return AzkarCategory(
      category: json['category'] as String,
      items: itemsList,
    );
  }
}
