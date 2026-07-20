String getVideoId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return '';
  if (uri.host.contains('youtube.com')) {
    return uri.queryParameters['v'] ?? '';
  }
  if (uri.host == 'youtu.be') {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
  }
  return '';
}
