import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  final List<FAQItem> faqs = [
    FAQItem(
      question: "What is PlayPal?",
      answer:
          "PlayPal is a mobile app that helps you create, find, and join local football matches easily with built-in payments, chats, and player ratings.",
    ),
    FAQItem(
      question: "How do I join a match?",
      answer:
          "Go to the homepage, browse the list of available matches, and tap 'Join'. If the match is open and you pay your part of the fees, you're in!",
    ),
    FAQItem(
      question: "How is the payment handled?",
      answer:
          "Match fee is paid in advance to the Jazzcash account/Bank account of the admin. The admin will review your screenshot for confirming the dues paid.",
    ),
    FAQItem(
      question: "What happens if a match gets canceled?",
      answer:
          "If the match is cancelled for whatever reason, players will get their fees refunded.",
    ),
    FAQItem(
      question: "Can I chat with teammates?",
      answer:
          "Yes, you can chat with your teammates in real-time once you're part of a match.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          "FAQs",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text(
              faqs[index].question,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(faqs[index].answer),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
