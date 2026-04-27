import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rental_app/core/utils/booking_policy.dart';

void main() {
  group('BookingPolicy date checks', () {
    final bookedRanges = <DateTimeRange>[
      DateTimeRange(start: DateTime(2026, 4, 10), end: DateTime(2026, 4, 15)),
    ];

    test('isDateBooked returns true for in-range day', () {
      expect(
        BookingPolicy.isDateBooked(DateTime(2026, 4, 12), bookedRanges),
        isTrue,
      );
    });

    test('isDateBooked returns false for out-of-range day', () {
      expect(
        BookingPolicy.isDateBooked(DateTime(2026, 4, 20), bookedRanges),
        isFalse,
      );
    });

    test('hasDateRangeOverlap returns true when selected range intersects', () {
      final selected = DateTimeRange(
        start: DateTime(2026, 4, 14),
        end: DateTime(2026, 4, 18),
      );
      expect(BookingPolicy.hasDateRangeOverlap(selected, bookedRanges), isTrue);
    });

    test(
      'hasDateRangeOverlap returns false when selected range does not intersect',
      () {
        final selected = DateTimeRange(
          start: DateTime(2026, 4, 16),
          end: DateTime(2026, 4, 18),
        );
        expect(
          BookingPolicy.hasDateRangeOverlap(selected, bookedRanges),
          isFalse,
        );
      },
    );
  });

  group('BookingPolicy checkout unlock limit', () {
    test('canUnlockContact allows unlock when usage is below limit', () {
      expect(
        BookingPolicy.canUnlockContact(usedThisMonth: 1, monthlyLimit: 2),
        isTrue,
      );
    });

    test('canUnlockContact blocks unlock when usage reaches limit', () {
      expect(
        BookingPolicy.canUnlockContact(usedThisMonth: 2, monthlyLimit: 2),
        isFalse,
      );
    });
  });

  group('BookingPolicy cancellation eligibility', () {
    final now = DateTime(2026, 4, 27, 10, 0);

    test('canCancelPendingRental allows pending rental before start', () {
      expect(
        BookingPolicy.canCancelPendingRental(
          orderStatus: 'pending',
          rentalStart: now.add(const Duration(hours: 1)),
          now: now,
        ),
        isTrue,
      );
    });

    test('canCancelPendingRental blocks non-pending status', () {
      expect(
        BookingPolicy.canCancelPendingRental(
          orderStatus: 'active',
          rentalStart: now.add(const Duration(hours: 1)),
          now: now,
        ),
        isFalse,
      );
    });

    test('canCancelPendingRental blocks pending rental at or after start', () {
      expect(
        BookingPolicy.canCancelPendingRental(
          orderStatus: 'pending',
          rentalStart: now.subtract(const Duration(minutes: 1)),
          now: now,
        ),
        isFalse,
      );
    });

    test('canCancelPendingRequest allows cancellation before start', () {
      expect(
        BookingPolicy.canCancelPendingRequest(
          requestStart: now.add(const Duration(days: 1)),
          now: now,
        ),
        isTrue,
      );
    });

    test('canCancelPendingRequest blocks cancellation after start', () {
      expect(
        BookingPolicy.canCancelPendingRequest(
          requestStart: now.subtract(const Duration(days: 1)),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
