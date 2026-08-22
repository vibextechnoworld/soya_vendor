String titleCase(String? value) {
  if (value == null || value.trim().isEmpty) return value ?? '';
  return value
      .trim()
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String titleCaseOr(String? value, String fallback) {
  if (value == null || value.trim().isEmpty) return fallback;
  return titleCase(value);
}
