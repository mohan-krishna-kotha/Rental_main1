import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/support_faq_model.dart';
import '../models/support_ticket_model.dart';
import 'auth_provider.dart';
import 'items_provider.dart';

final supportFaqsProvider = StreamProvider<List<SupportFaqModel>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getSupportFaqs();
});

final userSupportTicketsProvider =
    StreamProvider.autoDispose<List<SupportTicketModel>>((ref) {
      final currentUser = ref.watch(currentUserProvider);
      if (currentUser == null) {
        return const Stream<List<SupportTicketModel>>.empty();
      }

      final service = ref.watch(firestoreServiceProvider);
      return service.getSupportTicketsForUser(currentUser.uid);
    });
