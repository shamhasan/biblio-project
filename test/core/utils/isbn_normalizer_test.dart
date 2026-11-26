import 'package:book_inventory_apps/core/utils/isbn_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IsbnNormalizer (BR-01)', () {
    test('Removes hyphens, spaces, and uppercases x checksum', () {
      expect(IsbnNormalizer.normalize('978-979-224-861-6'), '9789792248616');
      expect(IsbnNormalizer.normalize(' 978 602 063 317 6 '), '9786020633176');
      expect(IsbnNormalizer.normalize('0-306-40615-x'), '030640615X');
      expect(IsbnNormalizer.normalize(''), '');
      expect(IsbnNormalizer.normalize(null), '');
    });

    test('Validates ISBN-10 and ISBN-13 patterns accurately', () {
      expect(IsbnNormalizer.isValid('978-979-224-861-6'), isTrue);
      expect(IsbnNormalizer.isValid('0-306-40615-x'), isTrue);
      expect(IsbnNormalizer.isValid('0306406152'), isTrue);

      expect(IsbnNormalizer.isValid(''), isFalse);
      expect(IsbnNormalizer.isValid('12345'), isFalse);
      expect(IsbnNormalizer.isValid('978979224861X'), isFalse);
    });

    test('Compares two ISBNs after normalization (isSameIsbn)', () {
      expect(
        IsbnNormalizer.isSameIsbn('9789792248616', '978-979-224-861-6'),
        isTrue,
      );
      expect(
        IsbnNormalizer.isSameIsbn('0-306-40615-x', '030640615X'),
        isTrue,
      );
      expect(
        IsbnNormalizer.isSameIsbn('', ''),
        isFalse,
      );
      expect(
        IsbnNormalizer.isSameIsbn('9789792248616', ''),
        isFalse,
      );
      expect(
        IsbnNormalizer.isSameIsbn('9789792248616', '9786020633176'),
        isFalse,
      );
    });
  });
}
