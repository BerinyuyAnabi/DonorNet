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

  /// Normalizes any blood type string to its short code.
  /// Handles formats like "A Positive (A+)", "A Positive", "A+", "a+".
  static String normalize(String input) {
    final trimmed = input.trim();

    // If it's already a short code, return uppercase
    for (final t in allTypes) {
      if (trimmed.toUpperCase() == t) return t;
    }

    // Try to extract short code from parentheses, e.g. "A Positive (A+)"
    final parenMatch = RegExp(r'\(([ABO]{1,2}[+-])\)').firstMatch(trimmed);
    if (parenMatch != null) return parenMatch.group(1)!;

    // Try to match label format like "A Positive", "AB Negative"
    final labelMap = {
      'A Positive': 'A+',
      'A Negative': 'A-',
      'B Positive': 'B+',
      'B Negative': 'B-',
      'AB Positive': 'AB+',
      'AB Negative': 'AB-',
      'O Positive': 'O+',
      'O Negative': 'O-',
    };
    for (final entry in labelMap.entries) {
      if (trimmed.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    return trimmed;
  }

  /// Checks if a donor can give blood to a recipient.
  /// Normalizes both types so "A Positive (A+)" and "A+" both work.
  static bool canDonate({required String from, required String to}) {
    return compatibleDonors(normalize(to)).contains(normalize(from));
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
    return labels[normalize(type)] ?? type;
  }

  /// All blood types.
  static const List<String> allTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];
}
