class UrlHelper {
  static UrlParseResult? parse(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    final ytId = extractYouTubeId(trimmed);
    if (ytId != null && ytId.isNotEmpty) {
      return UrlParseResult(
        platform: 'youtube',
        videoId: ytId,
        embedUrl: buildYouTubeEmbedUrl(ytId),
        canonicalUrl: 'https://www.youtube.com/watch?v=$ytId',
      );
    }

    final ttId = extractTikTokId(trimmed);
    if (ttId != null && ttId.isNotEmpty) {
      return UrlParseResult(
        platform: 'tiktok',
        videoId: ttId,
        embedUrl: buildTikTokEmbedUrl(ttId),
        canonicalUrl: 'https://www.tiktok.com/embed/v2/$ttId',
      );
    }

    return null;
  }

  static String? extractYouTubeId(String url) {
    final cleanUrl = url.trim();

    final shortRegExp = RegExp(r'youtu\.be\/([a-zA-Z0-9_-]{11})', caseSensitive: false);
    final shortMatch = shortRegExp.firstMatch(cleanUrl);
    if (shortMatch != null) return shortMatch.group(1);

    final watchRegExp = RegExp(r'youtube\.com\/watch\?.*v=([a-zA-Z0-9_-]{11})', caseSensitive: false);
    final watchMatch = watchRegExp.firstMatch(cleanUrl);
    if (watchMatch != null) return watchMatch.group(1);

    final shortsRegExp = RegExp(r'youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})', caseSensitive: false);
    final shortsMatch = shortsRegExp.firstMatch(cleanUrl);
    if (shortsMatch != null) return shortsMatch.group(1);

    final embedRegExp = RegExp(r'youtube\.com\/embed\/([a-zA-Z0-9_-]{11})', caseSensitive: false);
    final embedMatch = embedRegExp.firstMatch(cleanUrl);
    if (embedMatch != null) return embedMatch.group(1);

    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(cleanUrl)) return cleanUrl;

    return null;
  }

  static String? extractTikTokId(String url) {
    final cleanUrl = url.trim();

    final standardRegExp = RegExp(r'tiktok\.com\/@[^\/]+\/video\/(\d+)', caseSensitive: false);
    final standardMatch = standardRegExp.firstMatch(cleanUrl);
    if (standardMatch != null) return standardMatch.group(1);

    final vRegExp = RegExp(r'tiktok\.com\/v\/(\d+)', caseSensitive: false);
    final vMatch = vRegExp.firstMatch(cleanUrl);
    if (vMatch != null) return vMatch.group(1);

    if (RegExp(r'^\d{15,22}$').hasMatch(cleanUrl)) return cleanUrl;

    return null;
  }

  static String buildYouTubeEmbedUrl(String videoId) {
    return 'https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1&controls=0&loop=1&playlist=$videoId&rel=0&enablejsapi=1';
  }

  static String buildTikTokEmbedUrl(String videoId) {
    return 'https://www.tiktok.com/embed/v2/$videoId?autoplay=1';
  }
}

class UrlParseResult {
  final String platform;
  final String videoId;
  final String embedUrl;
  final String canonicalUrl;

  UrlParseResult({
    required this.platform,
    required this.videoId,
    required this.embedUrl,
    required this.canonicalUrl,
  });
}