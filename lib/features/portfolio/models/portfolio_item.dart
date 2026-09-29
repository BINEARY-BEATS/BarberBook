import '../../../core/constants/firestore_keys.dart';

class PortfolioItem {
  const PortfolioItem({
    required this.id,
    required this.barberId,
    required this.imageUrl,
    required this.style,
  });

  final String id;
  final String barberId;
  final String imageUrl;
  final String style;

  factory PortfolioItem.fromMap(Map<String, dynamic> map, {required String id}) {
    return PortfolioItem(
      id: id,
      barberId: map[FirestoreKeys.portfolioBarberId] as String? ?? '',
      imageUrl: map[FirestoreKeys.portfolioImageUrl] as String? ?? '',
      style: map[FirestoreKeys.portfolioStyle] as String? ?? '',
    );
  }
}
