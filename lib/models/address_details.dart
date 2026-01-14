/// Model for geocoded address data.
/// This stores cached reverse geocoding results to avoid repeated API calls.
class AddressDetails {
  final int id; // References AvesEntry.contentId
  final String? addressLine; // Full formatted address
  final String? countryCode; // ISO country code (e.g., "US")
  final String? countryName; // Full country name (e.g., "United States")
  final String? adminArea; // State/province
  final String? locality; // City/town

  AddressDetails({
    required this.id,
    this.addressLine,
    this.countryCode,
    this.countryName,
    this.adminArea,
    this.locality,
  });

  factory AddressDetails.fromMap(Map<String, dynamic> map) {
    return AddressDetails(
      id: map['id'] as int,
      addressLine: map['addressLine'] as String?,
      countryCode: map['countryCode'] as String?,
      countryName: map['countryName'] as String?,
      adminArea: map['adminArea'] as String?,
      locality: map['locality'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'addressLine': addressLine,
      'countryCode': countryCode,
      'countryName': countryName,
      'adminArea': adminArea,
      'locality': locality,
    };
  }

  /// Gets a short location string (City, Country)
  String get shortLocation {
    if (locality != null && countryName != null) {
      return '$locality, $countryName';
    } else if (countryName != null) {
      return countryName!;
    } else if (adminArea != null) {
      return adminArea!;
    }
    return addressLine ?? 'Unknown';
  }

  /// Gets a full location string
  String get fullLocation => addressLine ?? shortLocation;
}
