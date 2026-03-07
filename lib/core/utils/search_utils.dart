/// A utility class to handle synonym-based search logic.
class SearchUtils {
  /// A curated map of synonyms for common search terms in the rental app.
  static const Map<String, List<String>> synonymMap = {
    'bike': ['motorcycle', 'motor cycle', 'bicycle', 'scooter', 'two wheeler', 'cycle'],
    'motorcycle': ['bike', 'motor cycle', 'two wheeler', 'bullet', 'scooter'],
    'motor cycle': ['bike', 'motorcycle', 'two wheeler'],
    'bicycle': ['bike', 'cycle', 'mountain bike'],
    'cycle': ['bike', 'bicycle'],
    'camera': ['dslr', 'camcoder', 'photography', 'lens', 'mirrorless'],
    'dslr': ['camera', 'photography'],
    'car': ['vehicle', 'automobile', 'four wheeler', 'suv', 'sedan'],
    'vehicle': ['car', 'bike', 'motorcycle', 'truck'],
    'laptop': ['computer', 'pc', 'notebook', 'macbook'],
    'computer': ['laptop', 'pc', 'desktop'],
    'phone': ['mobile', 'smartphone', 'iphone', 'android'],
    'mobile': ['phone', 'smartphone'],
    'tv': ['television', 'monitor', 'display', 'screen'],
    'clothing': ['dress', 'shirt', 'pants', 'apparel', 'outfit'],
    'dress': ['clothing', 'outfit', 'garment'],
    'furniture': ['chair', 'table', 'sofa', 'bed', 'couch'],
    'sofa': ['couch', 'furniture', 'seating'],
    'tools': ['drill', 'hammer', 'construction', 'equipment'],
    'gaming': ['playstation', 'ps5', 'xbox', 'nintendo', 'console'],
    'console': ['gaming', 'playstation', 'xbox'],
  };

  /// Returns a set of terms to search for based on the input query.
  /// This includes the original query and any recognized synonyms.
  static Set<String> getSearchTerms(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return {};
    
    final terms = <String>{normalizedQuery};
    
    // 1. Check if the full query has synonyms (e.g., "motor cycle")
    if (synonymMap.containsKey(normalizedQuery)) {
      terms.addAll(synonymMap[normalizedQuery]!);
    }
    
    // 2. Split the query into individual words to handle synonyms for parts
    final words = normalizedQuery.split(RegExp(r'\s+'));
    
    if (words.length > 1) {
      for (final word in words) {
        if (word.length < 3) continue; // Skip very short words like "a", "of"
        
        // Add synonyms for each word
        if (synonymMap.containsKey(word)) {
          terms.addAll(synonymMap[word]!);
        }
      }
    }
    
    return terms;
  }

  /// Checks if a text matches the query or any of its synonyms.
  static bool matches(String text, String query) {
    if (query.isEmpty) return true;
    
    final lowerText = text.toLowerCase();
    final searchTerms = getSearchTerms(query);
    
    // If any search term is contained in the text, it's a match
    return searchTerms.any((term) => lowerText.contains(term));
  }
}
