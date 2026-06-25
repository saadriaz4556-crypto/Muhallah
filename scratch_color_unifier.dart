import 'dart:io';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) {
    print('Directory lib does not exist');
    return;
  }
  
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  print('Found ${files.length} dart files.');
  
  for (final file in files) {
    final content = file.readAsStringSync();
    if (file.path.contains('login_screen.dart') || file.path.contains('registration_screen.dart')) {
      continue;
    }
    
    // Check if the file is a screen/page or contains UI
    if (!content.contains('Widget build(BuildContext') && !content.contains('class ') && !content.contains('extends ')) {
      continue;
    }
    
    // Look for occurrences of Color or Colors
    final colorMatches = RegExp(r'Color\(0xFF[0-9a-fA-F]{6}\)|Colors\.[a-zA-Z]+').allMatches(content);
    if (colorMatches.isNotEmpty) {
      print('File: ${file.path}');
      final uniqueColors = colorMatches.map((m) => m.group(0)).toSet();
      print('  Colors used: $uniqueColors');
    }
  }
}
