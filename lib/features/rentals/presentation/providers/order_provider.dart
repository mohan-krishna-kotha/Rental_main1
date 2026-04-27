import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/order_models.dart'; // Use new comprehensive models
import '../../../../core/models/booking_request_model.dart';
import '../../../../core/providers/items_provider.dart'; // For firestoreServiceProvider
import '../../../../core/providers/auth_provider.dart';

final userOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  if (user == null) return Stream.value([]);

  return firestoreService.getUserOrders(user.uid);
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userBookingRequestsProvider = StreamProvider<List<BookingRequestModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  if (user == null) return Stream.value([]);

  return firestoreService.getUserBookingRequests(user.uid);
});

final ownerBookingRequestsProvider =
    StreamProvider.family<List<BookingRequestModel>, String>((ref, ownerId) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.getOwnerBookingRequests(ownerId);
    });

final ownerPendingRequestsCountProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  final asyncList = ref.watch(ownerBookingRequestsProvider(user.uid));
  return asyncList.maybeWhen(data: (list) => list.length, orElse: () => 0);
});
