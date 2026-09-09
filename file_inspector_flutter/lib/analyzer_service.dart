import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart' as xls;
import 'package:csv/csv.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'models.dart';

class AnalyzerService {
  static const _imageExt = {'png', 'jpg', 'jpeg', 'gif', 'webp'};

  static FileCategory detectCategory(String filename) {
    final ext = p.extension(filename).toLowerCase().replaceFirst('.', '');
    if (_imageExt.contains(ext)) return FileCategory.image;
    if (ext == 'pdf') return FileCategory.pdf;
    if (ext == 'docx') return FileCategory.docx;
    if (ext == 'csv') return FileCategory.csv;
    if (ext == 'xlsx' || ext == 'xls') return FileCategory.sheet;
    return FileCategory.text; // fall back to reading as plain text
  }

  static String _mediaTypeForImage(String filename) {
    final ext = p.extension(filename).toLowerCase().replaceFirst('.', '');
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/png';
    }
  }

  static String _extractDocxText(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docFile = archive.files.firstWhere(
        (f) => f.name == 'word/document.xml',
        orElse: () => throw Exception('document.xml not found'),
      );
      final xml = utf8.decode(docFile.content as List<int>);
      final withBreaks = xml.replaceAll(RegExp(r'</w:p>'), '\n');
      final noTags = withBreaks.replaceAll(RegExp(r'<[^>]+>'), '');
      return noTags.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    } catch (e) {
      return '[Could not extract text from this .docx file: $e]';
    }
  }

  static String _summarizeSheet(Uint8List bytes) {
    try {
      final excel = xls.Excel.decodeBytes(bytes);
      final buf = StringBuffer();
      var sheetCount = 0;
      for (final name in excel.tables.keys) {
        if (sheetCount >= 3) break;
        sheetCount++;
        final table = excel.tables[name]!;
        final rows = table.rows;
        if (rows.isEmpty) continue;
        final headers = rows.first.map((c) => c?.value?.toString() ?? '').join(', ');
        buf.writeln('Sheet "$name": ${rows.length - 1} data rows, columns: [$headers]');
        final sample = rows.skip(1).take(5);
        for (final row in sample) {
          buf.writeln(row.map((c) => c?.value?.toString() ?? '').toList().toString());
        }
        buf.writeln();
      }
      return buf.toString();
    } catch (e) {
      return '[Could not parse spreadsheet: $e]';
    }
  }

  static String _summarizeCsv(String text) {
    try {
      final rows = const CsvToListConverter(eol: '\n').convert(text);
      if (rows.isEmpty) return '[Empty CSV]';
      final headers = rows.first;
      final dataRows = rows.skip(1).toList();
      final sample = dataRows.take(5);
      final buf = StringBuffer();
      buf.writeln('Columns: [${headers.join(', ')}]');
      buf.writeln('Row count: ${dataRows.length}');
      buf.writeln('Sample rows:');
      for (final row in sample) {
        buf.writeln(row.toString());
      }
      return buf.toString();
    } catch (e) {
      return '[Could not parse CSV: $e]';
    }
  }

  static String _tryUtf8(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }

  static String _cap(String s) => s.length > 15000 ? s.substring(0, 15000) : s;

  /// Returns either {'kind':'text','text':...} or {'kind':'block','block': {...}}
  static Future<Map<String, dynamic>> buildContent(AnalyzedFile f) async {
    switch (f.category) {
      case FileCategory.image:
        return {
          'kind': 'block',
          'block': {
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': _mediaTypeForImage(f.name),
              'data': base64Encode(f.bytes),
            }
          }
        };
      case FileCategory.pdf:
        return {
          'kind': 'block',
          'block': {
            'type': 'document',
            'source': {
              'type': 'base64',
              'media_type': 'application/pdf',
              'data': base64Encode(f.bytes),
            }
          }
        };
      case FileCategory.docx:
        return {'kind': 'text', 'text': _cap(_extractDocxText(f.bytes))};
      case FileCategory.sheet:
        return {'kind': 'text', 'text': _cap(_summarizeSheet(f.bytes))};
      case FileCategory.csv:
        return {'kind': 'text', 'text': _cap(_summarizeCsv(_tryUtf8(f.bytes)))};
      case FileCategory.text:
      case FileCategory.unknown:
        return {'kind': 'text', 'text': _cap(_tryUtf8(f.bytes))};
    }
  }

  static const String systemPrompt = '''
You are a rigorous file and content analyzer inside a diagnostic tool called File Inspector.
Given one uploaded file's content (attached directly as an image or PDF, or provided inline as text/data), respond with ONLY a single valid JSON object. No markdown code fences, no prose before or after.

Schema (omit a key entirely if it does not apply to this file type):
{
  "summary": "2-4 sentence plain-language summary of what the file contains",
  "contentDetected": [ {"label": "short label", "value": "short value"} ],
  "extractedText": "the full readable text content of the file, transcribed/extracted as plainly as possible. Use \\n for line breaks.",
  "structure": { ...arbitrary small JSON describing the file's structure, e.g. sections, fields, or layout... },
  "recommendations": ["short actionable recommendation", ...],
  "confidence": 0-100 integer, your calibrated confidence in this analysis
}

Rules:
- contentDetected: for images/screenshots include things like title, visible text, buttons, tables. For documents include key sections/fields. For data files include columns/row count.
- extractedText: focus purely on extracting/transcribing the readable text content of the file. Do not analyze code quality or list programming issues. Keep it to at most ~500 words -- give a representative excerpt for longer files rather than a full verbatim transcription, and note in the summary that it's an excerpt.
- structure: a short JSON sketch of the file's shape.
- recommendations: 2-5 concrete, specific suggestions about the content itself.
- Never wrap the JSON in backticks. Never include commentary outside the JSON object.
- Keep the ENTIRE response compact enough to finish well within your output limit. If in doubt, shorten fields further rather than risk an incomplete JSON object.
''';

  static String _repairTruncatedJson(String text) {
    var inString = false;
    var escape = false;
    final stack = <String>[];
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (inString) {
        if (escape) {
          escape = false;
        } else if (ch == '\\') {
          escape = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
        continue;
      }
      if (ch == '{' || ch == '[') {
        stack.add(ch);
      } else if (ch == '}') {
        if (stack.isNotEmpty && stack.last == '{') stack.removeLast();
      } else if (ch == ']') {
        if (stack.isNotEmpty && stack.last == '[') stack.removeLast();
      }
    }
    var repaired = text;
    if (inString) repaired += '"';
    repaired = repaired.replaceFirst(RegExp(r',\s*$'), '');
    for (var i = stack.length - 1; i >= 0; i--) {
      repaired += stack[i] == '{' ? '}' : ']';
    }
    return repaired;
  }

  /// Calls the Anthropic Messages API directly from the device.
  static Future<AnalysisResult> analyze(AnalyzedFile f, String apiKey) async {
    final content = await buildContent(f);
    final header = 'Filename: ${f.name}\nDetected category: ${f.category.name}\n';
    final List<Map<String, dynamic>> userBlocks = [];
    if (content['kind'] == 'text') {
      userBlocks.add({
        'type': 'text',
        'text': '$header\n--- FILE CONTENT START ---\n${content['text']}\n--- FILE CONTENT END ---',
      });
    } else {
      userBlocks.add({'type': 'text', 'text': '$header\nThe file is attached below.'});
      userBlocks.add(content['block']);
    }

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'content-type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4-6',
        'max_tokens': 1024,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userBlocks}
        ],
      }),
    );

    if (response.statusCode != 200) {
      final snippet = response.body.length > 300 ? response.body.substring(0, 300) : response.body;
      throw Exception('API error ${response.statusCode}: $snippet');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final blocks = (data['content'] as List<dynamic>? ?? []);
    final text = blocks
        .where((b) => (b as Map)['type'] == 'text')
        .map((b) => (b as Map)['text'] as String)
        .join('\n')
        .trim();

    var cleaned = text
        .replaceFirst(RegExp(r'^\`\`\`json\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^\`\`\`\s*'), '')
        .replaceFirst(RegExp(r'\`\`\`\s*$'), '')
        .trim();

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      try {
        parsed = jsonDecode(_repairTruncatedJson(cleaned)) as Map<String, dynamic>;
      } catch (_) {
        throw Exception(
            'The response was cut off before it finished (the file may be too dense to fully transcribe). Try Retry, or use a smaller/simpler file.');
      }
    }
    return AnalysisResult.fromJson(parsed);
  }
}
