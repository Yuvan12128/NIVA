/// Utility class for validating and normalizing URLs across NIVA profiles.
class UrlValidator {
  /// Ensures URL starts with https:// if scheme is missing.
  static String normalize(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  /// Checks if the URL format is valid. Returns true if empty (since optional).
  static bool isValidUrl(String? url) {
    if (url == null || url.trim().isEmpty) return true;
    final normalized = normalize(url);
    final uri = Uri.tryParse(normalized);
    if (uri == null) return false;
    return uri.hasScheme && uri.hasAuthority && uri.host.contains('.');
  }

  /// Form field validator for optional URLs with platform-specific checks.
  static String? validateUrl(String? value, {String? platform}) {
    if (value == null || value.trim().isEmpty) {
      return null; // All social links are optional
    }

    final normalized = normalize(value);
    final uri = Uri.tryParse(normalized);

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        !uri.host.contains('.')) {
      return 'Please enter a valid URL (e.g. https://example.com)';
    }

    final hostLower = uri.host.toLowerCase();

    if (platform == 'LinkedIn' && !hostLower.contains('linkedin.com')) {
      return 'Must be a valid LinkedIn URL (e.g. https://linkedin.com/in/username)';
    }

    if (platform == 'GitHub' && !hostLower.contains('github.com')) {
      return 'Must be a valid GitHub URL (e.g. https://github.com/username)';
    }

    return null;
  }
}
