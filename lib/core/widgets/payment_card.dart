import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

typedef VoidCallback = void Function();

class PaymentCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final String matchId;
  final bool alreadyFinal;
  final bool isMobile;
  final Set<String> loadingSet;
  final TextEditingController commentController;
  final void Function(void Function()) setState;

  const PaymentCard({
    super.key,
    required this.doc,
    required this.matchId,
    required this.alreadyFinal,
    required this.isMobile,
    required this.loadingSet,
    required this.commentController,
    required this.setState,
    required bool showProofTextInline,
  });

  Future<String?> getScreenshotUrl(String matchId, String uid) async {
    try {
      final path = 'match_screenshots/$matchId/$uid';
      print('Trying to access: $path');
      final result = await FirebaseStorage.instance.ref(path).listAll();
      if (result.items.isNotEmpty) {
        return await result.items.first.getDownloadURL();
      } else {
        print("No screenshot found at $path");
        return null;
      }
    } catch (e) {
      print("Error getting screenshot for $uid: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final uid = data['payerId'] ?? doc.id;
    final verified = data['verified'] == true;
    final rejected = data['rejected'] == true;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnapshot) {
        final userData =
            userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final username = userData['username'] ?? 'Unknown';

        return FutureBuilder<String?>(
          future: getScreenshotUrl(matchId, uid),
          builder: (context, snapshot) {
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: verified
                      ? Colors.green.shade400
                      : rejected
                          ? Colors.red.shade300
                          : Colors.grey.shade300,
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.person, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      username,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting)
                                    const Text(
                                      "Loading...",
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    )
                                  else if (snapshot.data == null)
                                    const Text(
                                      "No payment proof",
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.redAccent,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  else
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            contentPadding:
                                                const EdgeInsets.all(6),
                                            content: InteractiveViewer(
                                              child:
                                                  Image.network(snapshot.data!),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "View payment screenshot",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (verified || rejected)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Chip(
                                    label: Text(
                                      verified ? "Verified ✅" : "Rejected ❌",
                                      style: TextStyle(
                                        color: verified
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                      ),
                                    ),
                                    backgroundColor: verified
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!alreadyFinal)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (loadingSet.contains(uid))
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else ...[
                            Tooltip(
                              message: "Verify Payment",
                              child: InkWell(
                                onTap: () async {
                                  setState(() => loadingSet.add(uid));
                                  await FirebaseFirestore.instance
                                      .collection('matches')
                                      .doc(matchId)
                                      .collection('payments')
                                      .doc(uid)
                                      .update({
                                    'verified': true,
                                    'rejected': false,
                                  });
                                  setState(() => loadingSet.remove(uid));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Payment verified."),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(6),
                                hoverColor: Colors.green.withOpacity(0.2),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.check,
                                      size: 18, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: "Reject Payment",
                              child: InkWell(
                                onTap: () async {
                                  String comment = '';
                                  commentController.clear();
                                  await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Reason for Rejection"),
                                      content: TextField(
                                        controller: commentController,
                                        decoration: const InputDecoration(
                                            hintText: "Enter reason"),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            comment =
                                                commentController.text.trim();
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Submit"),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (comment.isNotEmpty) {
                                    setState(() => loadingSet.add(uid));
                                    await FirebaseFirestore.instance
                                        .collection('matches')
                                        .doc(matchId)
                                        .collection('payments')
                                        .doc(uid)
                                        .update({
                                      'verified': false,
                                      'rejected': true,
                                      'adminComment': comment,
                                    });
                                    await FirebaseFirestore.instance
                                        .collection('matches')
                                        .doc(matchId)
                                        .collection('groupChats')
                                        .doc(matchId)
                                        .update({
                                      'members': FieldValue.arrayRemove([uid])
                                    });
                                    setState(() => loadingSet.remove(uid));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Payment rejected."),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(6),
                                hoverColor: Colors.red.withOpacity(0.2),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 18, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
