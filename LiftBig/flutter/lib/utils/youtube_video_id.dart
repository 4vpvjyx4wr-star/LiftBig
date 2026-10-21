final RegExp _youtubeIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// YouTube video id from a watch, Shorts, embed, live, or youtu.be URL.
String? youtubeVideoIdFromUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return null;
  final host = uri.host.toLowerCase();
  if (host == 'youtu.be') {
    return _firstValidSegment(uri.pathSegments);
  }
  if (!_isYoutubeHost(host)) return null;

  final watchId = uri.queryParameters['v'];
  if (watchId != null) {
    final valid = _validId(watchId);
    if (valid != null) return valid;
  }

  const heads = {'shorts', 'embed', 'live', 'v'};
  final segments = uri.pathSegments;
  for (var i = 0; i < segments.length - 1; i++) {
    if (!heads.contains(segments[i])) continue;
    final valid = _validId(segments[i + 1]);
    if (valid != null) return valid;
  }
  return null;
}

bool _isYoutubeHost(String host) {
  return host == 'youtube.com' ||
      host.endsWith('.youtube.com') ||
      host == 'youtube-nocookie.com' ||
      host.endsWith('.youtube-nocookie.com');
}

String? _firstValidSegment(List<String> segments) {
  for (final segment in segments) {
    final valid = _validId(segment);
    if (valid != null) return valid;
  }
  return null;
}

String? _validId(String raw) {
  final id = raw.trim();
  if (!_youtubeIdPattern.hasMatch(id)) return null;
  return id;
}
