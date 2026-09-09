import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';

class ReportView extends StatelessWidget {
  final AnalyzedFile file;
  final VoidCallback? onRetry;
  const ReportView({super.key, required this.file, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(file.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${file.category.name.toUpperCase()} · ${_fmtSize(file.sizeBytes)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
              _statusChip(file.status),
            ],
          ),
          const SizedBox(height: 16),
          if (file.status == AnalysisStatus.working) const LinearProgressIndicator(minHeight: 2),
          if (file.status == AnalysisStatus.error) _errorBox(),
          if (file.result != null) ..._buildSections(context, file.result!),
          if (file.status == AnalysisStatus.error && onRetry != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ),
        ],
      ),
    );
  }

  Widget _errorBox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(file.error ?? 'Something went wrong.', style: const TextStyle(color: Colors.redAccent)),
    );
  }

  static Widget _statusChip(AnalysisStatus status) {
    Color color;
    String label;
    switch (status) {
      case AnalysisStatus.working:
        color = Colors.amber;
        label = 'analyzing…';
        break;
      case AnalysisStatus.done:
        color = Colors.teal;
        label = 'completed';
        break;
      case AnalysisStatus.error:
        color = Colors.redAccent;
        label = 'failed';
        break;
      case AnalysisStatus.queued:
        color = Colors.grey;
        label = 'queued';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontFamily: 'monospace')),
    );
  }

  List<Widget> _buildSections(BuildContext context, AnalysisResult r) {
    final widgets = <Widget>[];
    if (r.summary != null) {
      widgets.add(_section('Summary', Text(r.summary!)));
    }
    if (r.contentDetected.isNotEmpty) {
      widgets.add(_section(
        'Content Detected',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: r.contentDetected
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: RichText(
                      text: TextSpan(style: DefaultTextStyle.of(context).style, children: [
                        TextSpan(text: '${c.label}: ', style: const TextStyle(color: Colors.grey)),
                        TextSpan(text: c.value),
                      ]),
                    ),
                  ))
              .toList(),
        ),
      ));
    }
    if (r.extractedText != null && r.extractedText!.isNotEmpty) {
      widgets.add(_section('Extracted Text', _codeBox(r.extractedText!)));
    }
    if (r.structure != null) {
      widgets.add(_section('Structure', _codeBox(_prettyJson(r.structure!))));
    }
    if (r.recommendations.isNotEmpty) {
      widgets.add(_section(
        'Recommendations',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: r.recommendations.map((rec) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('•  $rec'))).toList(),
        ),
      ));
    }
    if (r.confidence != null) {
      widgets.add(_section(
        'Confidence',
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: r.confidence! / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  color: Colors.teal,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('${r.confidence}%', style: const TextStyle(fontFamily: 'monospace', color: Colors.teal)),
          ],
        ),
      ));
      widgets.add(Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => Clipboard.setData(ClipboardData(text: _toMarkdown(r))),
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy as Markdown'),
        ),
      ));
    }
    return widgets;
  }

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 0.6, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _codeBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(4)),
      child: SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5)),
    );
  }

  static String _prettyJson(Map<String, dynamic> m) => const JsonEncoder.withIndent('  ').convert(m);

  static String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  static String _toMarkdown(AnalysisResult r) {
    final buf = StringBuffer();
    if (r.summary != null) buf.writeln('## Summary\n${r.summary}\n');
    if (r.contentDetected.isNotEmpty) {
      buf.writeln('## Content Detected');
      for (final c in r.contentDetected) {
        buf.writeln('- **${c.label}:** ${c.value}');
      }
      buf.writeln();
    }
    if (r.extractedText != null) buf.writeln('## Extracted Text\n```\n${r.extractedText}\n```\n');
    if (r.structure != null) buf.writeln('## Structure\n```json\n${_prettyJson(r.structure!)}\n```\n');
    if (r.recommendations.isNotEmpty) {
      buf.writeln('## Recommendations');
      for (final rec in r.recommendations) {
        buf.writeln('- $rec');
      }
      buf.writeln();
    }
    if (r.confidence != null) buf.writeln('## Confidence\n${r.confidence}%');
    return buf.toString();
  }
}
