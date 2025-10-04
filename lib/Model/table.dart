class TableModel {
  final String id; // Firestore document id
  final String tableNo; // e.g. "101"
  final String type; // e.g. "VIP", "Rooftop", "Standing"

  TableModel({
    required this.id,
    required this.tableNo,
    required this.type,
  });

  // Convert Firestore map → Dart object
  factory TableModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TableModel(
      id: documentId,
      tableNo: data['tableNo'] ?? '',
      type: data['type'] ?? '',
    );
  }

  // Convert Dart object → Firestore map
  Map<String, dynamic> toMap() {
    return {
      'tableNo': tableNo,
      'type': type,
    };
  }
}
