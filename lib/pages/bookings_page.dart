import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  final List<String> statuses = [
    'pending-payment',
    'confirmed',
    'completed',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statuses.length, vsync: this);
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {}); // force UI rebuild
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: statuses
              .map((status) => Tab(text: status.toUpperCase()))
              .toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: TabBarView(
          controller: _tabController,
          children: statuses.map((status) {
            return _buildBookingList(status);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBookingList(String selectedStatus) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('members', arrayContains: currentUser!.uid)
          .where('status', isEqualTo: selectedStatus)
          .orderBy('matchDateTime')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allMatches = snapshot.data!.docs;

        if (allMatches.isEmpty) {
          return const Center(
            child: Text('No bookings found for this status.',
                style: TextStyle(fontSize: 16)),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: allMatches.length,
          itemBuilder: (context, index) {
            final doc = allMatches[index];
            final data = doc.data() as Map<String, dynamic>;

            final matchId = doc.id;
            final matchDateTime = (data['matchDateTime'] as Timestamp).toDate();
            final title = data['matchTitle'] ?? 'Match';
            final location = data['matchLocation'] ?? 'Unknown';
            final status = data['status'] ?? 'pending-payment';
            final uid = currentUser?.uid;
            final isCreator = data['creatorId'] == uid;
            final players = data['players'] ?? '6v6';
            final fees = data['matchFees'] ?? 'N/A';
            final members = List<String>.from(data['members'] ?? []);
            final maxPlayers = players == '6v6'
                ? 12
                : players == '7v7'
                    ? 14
                    : 16;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black12),
              ),
              color: Colors.amber.shade100,
              child: ListTile(
                title: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCreator)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Created by Me",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Text(
                        "Date: ${DateFormat('EEE, MMM d • hh:mm a').format(matchDateTime)}"),
                    Text("Location: $location"),
                    Text("Players: ${members.length} / $maxPlayers"),
                    const SizedBox(height: 4),
                    _statusTag(status),
                    Text("Total Fee: Rs $fees"),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/matchDetails',
                      arguments: matchId);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusTag(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'confirmed':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        break;
      case 'cancelled':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        break;
      case 'completed':
        bg = Colors.grey.shade300;
        fg = Colors.black87;
        break;
      default:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: fg,
          fontSize: 12,
        ),
      ),
    );
  }
}
