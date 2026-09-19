import 'package:flutter/material.dart';
import 'package:beranibicara/core/utils/url_utils.dart';

class LinkableText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const LinkableText(this.text, {super.key, this.style});

  static final _urlPattern = RegExp(
    r'(https?:\/\/[^\s]+)|(www\.[^\s]+)',
    caseSensitive: false,
  );

  static String _trimTrailingPunctuation(String value) {
    return value.replaceAll(RegExp(r'[.,;:!?)]+$'), '');
  }

  static Future<void> _open(String raw) async {
    final trimmed = _trimTrailingPunctuation(raw);
    final href = trimmed.toLowerCase().startsWith('http')
        ? trimmed
        : 'https://$trimmed';
    await openExternalUrl(href);
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final linkStyle = baseStyle.copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in _urlPattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      final raw = match.group(0)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => _open(raw),
            child: Text(raw, style: linkStyle),
          ),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}
