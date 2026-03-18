class AIService {
  static Map<String, String> analyzeComplaint(String text) {
    text = text.toLowerCase();

    if (text.contains("water") || text.contains("leak")) {
      return {
        "category": "Plumbing",
        "priority": "Medium",
        "reason": "Detected keywords: water/leak",
      };
    } else if (text.contains("electric") || text.contains("spark")) {
      return {
        "category": "Electrical",
        "priority": "High",
        "reason": "Detected keywords: electric/spark",
      };
    } else if (text.contains("internet") || text.contains("wifi")) {
      return {
        "category": "Network",
        "priority": "Medium",
        "reason": "Detected keywords: wifi/internet",
      };
    } else {
      return {
        "category": "General",
        "priority": "Low",
        "reason": "No strong keywords detected",
      };
    }
  }
}
