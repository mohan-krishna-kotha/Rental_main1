import 'package:flutter/material.dart';

/// Shared booking and checkout policy helpers used by UI flows and tests.
class BookingPolicy {
  static bool isDateBooked(DateTime day, List<DateTimeRange> bookedRanges) {
    for (final range in bookedRanges) {
      if (day.isAfter(range.start.subtract(const Duration(days: 1))) &&
          day.isBefore(range.end.add(const Duration(days: 1)))) {
        return true;
      }
    }
    return false;
  }

  static bool hasDateRangeOverlap(
    DateTimeRange selectedRange,
    List<DateTimeRange> bookedRanges,
  ) {
    for (final range in bookedRanges) {
      if (selectedRange.start.isBefore(range.end) &&
          selectedRange.end.isAfter(range.start)) {
        return true;
      }
    }
    return false;
  }

  static bool canUnlockContact({
    required int usedThisMonth,
    required int monthlyLimit,
  }) {
    return usedThisMonth < monthlyLimit;
  }

  static bool canCancelPendingRental({
    required String orderStatus,
    required DateTime rentalStart,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    return orderStatus.toLowerCase() == 'pending' &&
        rentalStart.isAfter(reference);
  }

  static bool canCancelPendingRequest({
    required DateTime requestStart,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    return requestStart.isAfter(reference);
  }
}
