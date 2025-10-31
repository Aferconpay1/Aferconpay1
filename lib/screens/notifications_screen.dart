import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../widgets/gradient_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const GradientAppBar(
        title: Text('Notificações'),
      ),
      body: currentUser == null
          ? const Center(child: Text('Por favor, faça login para ver as notificações.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Ocorreu um erro ao carregar as notificações.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 20),
                        const Text('Não tem notificações.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ).animate().fadeIn(duration: 500.ms),
                  );
                }

                final notifications = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final notification = notifications[index].data() as Map<String, dynamic>;
                    final timestamp = (notification['timestamp'] as Timestamp).toDate();
                    final formattedDate = DateFormat('dd MMM, HH:mm').format(timestamp);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        child: Icon(
                          Icons.notifications_active,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      title: Text(notification['title'] ?? 'Sem Título', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text(notification['body'] ?? 'Sem Corpo', style: theme.textTheme.bodyMedium),
                      trailing: Text(formattedDate, style: theme.textTheme.bodySmall),
                    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: -0.2);
                  },
                );
              },
            ),
    );
  }
}
