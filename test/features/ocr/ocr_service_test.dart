// test/features/ocr/ocr_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_floating_assistant/features/ocr/domain/ocr_service.dart';
import 'dart:io';

void main() {
  group('OcrService Tests', () {
    test('extractText returns non-empty string for valid image', () async {
      // Gunakan gambar test yang berisi teks
      final testImage = File('test/assets/test_image_with_text.jpg');
      
      if (!testImage.existsSync()) {
        markTestSkipped('Test image not found');
        return;
      }
      
      final result = await OcrService.extractText(testImage);
      expect(result, isNotEmpty);
      expect(result, isNot('Tidak ada teks yang ditemukan di layar'));
    });
    
    test('extractText handles non-existent file gracefully', () async {
      final fakeFile = File('non_existent.jpg');
      final result = await OcrService.extractText(fakeFile);
      expect(result, contains('Gagal'));
    });
  });
}