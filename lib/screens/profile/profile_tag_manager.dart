import '../../api/models.dart';

/// Helper class for managing tag selection and display
class ProfileTagManager {
  // Map categoryId -> [TagDto]
  final Map<String, List<TagDto>> tagGroups = {};
  
  // Map categoryId -> categoryName
  final Map<String, String> categoryNames = {};
  
  // User's selected tag IDs
  List<String> userTagIds = [];
  
  // For edit mode: categoryName -> set of selected values
  final Map<String, Set<dynamic>> selected = {};

  void initialize({
    required List<TagCategoryDto> categories,
    required List<TagDto> tags,
    bool? filterForBand,
  }) {
    tagGroups.clear();
    categoryNames.clear();
    
    // Filter categories based on isBand value
    final filteredCats = categories.where((c) {
      if (filterForBand == null) return true;
      return c.isForBand == filterForBand;
    }).toList();
    
    for (final c in filteredCats) {
      final ctTags = tags.where((t) => t.tagCategoryId == c.id).toList();
      tagGroups[c.id] = ctTags;
      categoryNames[c.id] = c.name;
    }
  }

  void setUserTags(List<String> tagIds) {
    userTagIds = tagIds;
  }

  void populateSelectedForEdit() {
    selected.clear();
    
    for (final tagId in userTagIds) {
      for (final entry in tagGroups.entries) {
        final tag = entry.value.firstWhere(
          (t) => t.id == tagId,
          orElse: () => TagDto(id: '', name: '', tagCategoryId: ''),
        );
        
        if (tag.id.isNotEmpty) {
          final categoryName = categoryNames[entry.key];
          if (categoryName != null) {
            selected.putIfAbsent(categoryName, () => {});
            selected[categoryName]!.add(tagId);
          }
          break;
        }
      }
    }
  }

  Map<String, List<String>> groupUserTagsForDisplay() {
    if (userTagIds.isEmpty || tagGroups.isEmpty) {
      return {};
    }

    final Map<String, List<String>> grouped = {};

    for (final tagId in userTagIds) {
      String? categoryId;
      String? tagName;

      for (final entry in tagGroups.entries) {
        final tag = entry.value.firstWhere(
          (t) => t.id == tagId,
          orElse: () => TagDto(id: '', name: '', tagCategoryId: ''),
        );
        if (tag.id.isNotEmpty) {
          categoryId = entry.key;
          tagName = tag.name;
          break;
        }
      }

      if (categoryId != null && tagName != null) {
        final categoryName = categoryNames[categoryId] ?? 'Other';
        grouped.putIfAbsent(categoryName, () => []);
        grouped[categoryName]!.add(tagName);
      }
    }

    return grouped;
  }

  List<String> getAllSelectedTagIds() {
    return selected.values.expand((s) => s).map((v) => v.toString()).toList();
  }

  Map<String, List<Map<String, dynamic>>> buildOptionsForEdit() {
    final Map<String, List<Map<String, dynamic>>> options = {};
    
    for (final entry in tagGroups.entries) {
      final categoryName = categoryNames[entry.key];
      if (categoryName != null) {
        final opts = <Map<String, dynamic>>[];
        for (final tag in entry.value) {
          opts.add({'value': tag.id, 'label': tag.name});
        }
        if (opts.isNotEmpty) {
          options[categoryName] = opts;
        }
      }
    }
    
    return options;
  }
}
