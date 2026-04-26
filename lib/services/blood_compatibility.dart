/// Blood type compatibility logic.
///
/// Compatibility chart:
///   O- can donate to everyone (universal donor)
///   AB+ can receive from everyone (universal recipient)
class BloodCompatibility {
  /// Returns all blood types that CAN DONATE TO the given type.
  static List<String> compatibleDonors(String recipientType) {
    switch (recipientType) {
      case 'A+':
        return ['A+', 'A-', 'O+', 'O-'];
      case 'A-':
        return ['A-', 'O-'];
      case 'B+':
        return ['B+', 'B-', 'O+', 'O-'];
      case 'B-':
        return ['B-', 'O-'];
      case 'AB+':
        return ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
      case 'AB-':
        return ['A-', 'B-', 'AB-', 'O-'];
      case 'O+':
        return ['O+', 'O-'];
      case 'O-':
        return ['O-'];
      default:
        return [];
    }
  }

  /// Returns all blood types the given type CAN DONATE TO.
  static List<String> canDonateTo(String donorType) {
    switch (donorType) {
      case 'A+':
        return ['A+', 'AB+'];
      case 'A-':
        return ['A+', 'A-', 'AB+', 'AB-'];
      case 'B+':
        return ['B+', 'AB+'];
      case 'B-':
        return ['B+', 'B-', 'AB+', 'AB-'];
      case 'AB+':
        return ['AB+'];
      case 'AB-':
        return ['AB+', 'AB-'];
      case 'O+':
        return ['A+', 'B+', 'AB+', 'O+'];
      case 'O-':
        return ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
      default:
        return [];
    }
  }

  /// Checks if a donor can give blood to a recipient.
  static bool canDonate({required String from, required String to}) {
    return compatibleDonors(to).contains(from);
  }

  /// Returns a human-friendly label for blood type.
  static String label(String type) {
    const labels = {
      'A+': 'A Positive',
      'A-': 'A Negative',
      'B+': 'B Positive',
      'B-': 'B Negative',
      'AB+': 'AB Positive',
      'AB-': 'AB Negative',
      'O+': 'O Positive',
      'O-': 'O Negative',
    };
    return labels[type] ?? type;
  }

  /// All blood types.
  static const List<String> allTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];
}
