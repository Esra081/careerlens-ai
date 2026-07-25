import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../core/theme/app_theme.dart';

/// Renders AI coach Markdown text in a clean, sectioned layout.
/// - Strips raw `###`, `**` syntax that used to appear as plain text.
/// - Breaks "wall of text" into visually distinct collapsible sections
///   when the content contains Markdown headings.
class CoachMarkdownView extends StatelessWidget {
  final String markdownText;

  /// Whether the widget is rendered on a dark card (gradient background).
  /// When true, text colours are forced white for legibility.
  final bool onDarkBackground;

  const CoachMarkdownView({
    super.key,
    required this.markdownText,
    this.onDarkBackground = false,
  });

  /// Splits markdown into sections by `###` or `##` headings.
  List<_Section> _parseSections(String text) {
    final lines = text.split('\n');
    final sections = <_Section>[];
    String? currentTitle;
    final buffer = StringBuffer();

    for (final line in lines) {
      final headingMatch = RegExp(r'^#{1,3}\s+(.+)').firstMatch(line.trim());
      if (headingMatch != null) {
        if (buffer.isNotEmpty || currentTitle != null) {
          sections.add(_Section(title: currentTitle, body: buffer.toString().trim()));
          buffer.clear();
        }
        currentTitle = headingMatch.group(1);
      } else {
        if (buffer.isNotEmpty || line.trim().isNotEmpty) {
          buffer.writeln(line);
        }
      }
    }
    if (buffer.isNotEmpty || currentTitle != null) {
      sections.add(_Section(title: currentTitle, body: buffer.toString().trim()));
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = onDarkBackground
        ? Colors.white.withValues(alpha: 0.95)
        : (isDark ? Colors.white : const Color(0xFF1A1A2E));
    final subTextColor = onDarkBackground
        ? Colors.white70
        : (isDark ? Colors.white60 : Colors.black54);

    final sections = _parseSections(markdownText);

    // If there are no heading-based sections, render as a single MarkdownBody
    if (sections.length <= 1 && sections.first.title == null) {
      return _buildMarkdownBody(sections.first.body, textColor, context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((s) {
        if (s.title == null) {
          // Intro paragraph – no heading
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMarkdownBody(s.body, textColor, context),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                initiallyExpanded: sections.indexOf(s) == 0,
                backgroundColor: onDarkBackground
                    ? Colors.black.withValues(alpha: 0.12)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8F9FA)),
                collapsedBackgroundColor: onDarkBackground
                    ? Colors.black.withValues(alpha: 0.08)
                    : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF3F4F6)),
                iconColor: onDarkBackground ? Colors.white70 : AppTheme.primaryColor,
                collapsedIconColor: onDarkBackground ? Colors.white54 : subTextColor,
                title: Text(
                  s.title!,
                  style: TextStyle(
                    color: onDarkBackground ? Colors.white : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                children: [
                  if (s.body.isNotEmpty)
                    _buildMarkdownBody(s.body, textColor, context),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMarkdownBody(String body, Color textColor, BuildContext context) {
    if (body.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeBackground = onDarkBackground
        ? Colors.black26
        : (isDark ? const Color(0xFF2A2D3E) : const Color(0xFFF0F0F5));

    return MarkdownBody(
      data: body,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: textColor, fontSize: 14, height: 1.65, fontWeight: FontWeight.w400),
        strong: TextStyle(color: textColor, fontWeight: FontWeight.w700),
        em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
        h1: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w800),
        h2: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700),
        h3: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
        listBullet: TextStyle(color: textColor, fontSize: 14),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: AppTheme.primaryColor, width: 3)),
          color: AppTheme.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(4),
        ),
        blockquote: TextStyle(color: textColor, fontSize: 14, fontStyle: FontStyle.italic),
        code: TextStyle(
          color: onDarkBackground ? Colors.white : AppTheme.primaryColor,
          backgroundColor: codeBackground,
          fontSize: 13,
        ),
        codeblockDecoration: BoxDecoration(
          color: codeBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.2))),
        ),
      ),
    );
  }
}

class _Section {
  final String? title;
  final String body;
  const _Section({required this.title, required this.body});
}
