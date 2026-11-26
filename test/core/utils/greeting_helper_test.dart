import 'package:book_inventory_apps/core/utils/greeting_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GreetingHelper (BR-04 & A-02)', () {
    test('Returns "Selamat Pagi" for 04:00 to 10:59', () {
      expect(
        GreetingHelper.getGreeting(DateTime(2026, 11, 25, 4, 0)),
        'Selamat Pagi',
      );
      expect(
        GreetingHelper.getGreeting(DateTime(2026, 11, 25, 8, 30)),
        'Selamat Pagi',
      );
      expect(
        GreetingHelper.getGreeting(DateTime(2026, 11, 25, 10, 59)),
        'Selamat Pagi',
      );
    });

    test('Returns "Selamat Siang" for 11:00 to 14:59', () {
      expect(
        GreetingHelper.getGreeting(DateTime(2026, 11, 25, 11, 0)),
        'Selamat Siang',
      );
      expect(
        GreetingHelper.getGreeting(DateTime(2026, 11, 25, 13, 15)),
        'Selamat Siang',
      );
      expect(
        GreetingHelper.getGreeting(DateTime(2026, 11, 25, 14, 59)),
        'Selamat Siang',
      );
    });

    test('Returns "Selamat Sore" for 15:00 to 18:29', () {
      expect(
        GreetingHelper.getGreeting(DateTime(2026, 11, 25, 15, 0)),
        'Selamat Sore',
      );
      expect(
        GreetingHelper.getGreeting(DateTime(2026, 11, 25, 16, 40)),
        'Selamat Sore',
      );
      expect(
        GreetingHelper.getGreeting(DateTime(2026, 11, 25, 18, 29)),
        'Selamat Sore',
      );
    });

    test('Returns "Selamat Malam" for 18:30 to 03:59', () {
      expect(
        GreetingHelper.getGreeting(DateTime(2026, 11, 25, 18, 30)),
        'Selamat Malam',
      );
      expect(
        GreetingHelper.getGreeting(DateTime(2026, 11, 25, 23, 59)),
        'Selamat Malam',
      );
      expect(
        GreetingHelper.getGreeting(DateTime(2026, 11, 25, 0, 0)),
        'Selamat Malam',
      );
      expect(
        GreetingHelper.getGreeting(DateTime(2026, 11, 25, 3, 59)),
        'Selamat Malam',
      );
    });
  });
}
