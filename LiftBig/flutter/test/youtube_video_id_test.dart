import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/utils/youtube_video_id.dart';

void main() {
  test('extracts ids from watch, Shorts, embed, live, and youtu.be URLs', () {
    expect(
      youtubeVideoIdFromUrl('https://www.youtube.com/shorts/hWbUlkb5Ms4'),
      'hWbUlkb5Ms4',
    );
    expect(
      youtubeVideoIdFromUrl(
        'https://www.youtube.com/shorts/hWbUlkb5Ms4?feature=share',
      ),
      'hWbUlkb5Ms4',
    );
    expect(
      youtubeVideoIdFromUrl('https://www.youtube.com/watch?v=gl8H4QLXKTo'),
      'gl8H4QLXKTo',
    );
    expect(
      youtubeVideoIdFromUrl(
        'https://www.youtube.com/watch?v=gl8H4QLXKTo&t=12s',
      ),
      'gl8H4QLXKTo',
    );
    expect(
      youtubeVideoIdFromUrl('https://m.youtube.com/watch?v=gl8H4QLXKTo'),
      'gl8H4QLXKTo',
    );
    expect(
      youtubeVideoIdFromUrl('https://youtu.be/gl8H4QLXKTo'),
      'gl8H4QLXKTo',
    );
    expect(
      youtubeVideoIdFromUrl('https://www.youtube.com/embed/gl8H4QLXKTo'),
      'gl8H4QLXKTo',
    );
    expect(
      youtubeVideoIdFromUrl('https://www.youtube.com/live/gl8H4QLXKTo'),
      'gl8H4QLXKTo',
    );
  });

  test('returns null when the URL has no YouTube video id', () {
    expect(youtubeVideoIdFromUrl(''), isNull);
    expect(youtubeVideoIdFromUrl('   '), isNull);
    expect(youtubeVideoIdFromUrl('not a url'), isNull);
    expect(
      youtubeVideoIdFromUrl('https://example.com/watch?v=gl8H4QLXKTo'),
      isNull,
    );
    expect(
      youtubeVideoIdFromUrl('https://www.youtube.com/watch?v=short'),
      isNull,
    );
    expect(youtubeVideoIdFromUrl('https://www.youtube.com/feed/library'), isNull);
  });
}
