import 'package:flutter/material.dart';

class AchievementsPage extends StatelessWidget {
  final String currentAchievement;

  AchievementsPage({required this.currentAchievement});

  final List<Achievement> achievements = [
    Achievement(
      title: 'Explorer',
      subtitle: 'If you play between 1–5 games',
      icon: Icons.explore,
      color: Colors.orange,
    ),
    Achievement(
      title: 'Veteran',
      subtitle: 'If you play between 6–15 games',
      icon: Icons.verified,
      color: Colors.redAccent,
    ),
    Achievement(
      title: 'Invincible',
      subtitle: 'If you play between 15–30 games',
      icon: Icons.military_tech,
      color: Colors.yellow,
    ),
    Achievement(
      title: 'Future king',
      subtitle: 'If you play between 31–50 games',
      icon: Icons.emoji_events,
      color: Colors.amber,
    ),
    Achievement(
      title: 'Almost Godlike',
      subtitle: 'If you play between 50–75 games',
      icon: Icons.change_history,
      color: Colors.lightBlue,
    ),
    Achievement(
      title: 'Game Legend',
      subtitle: 'If you play between 75–100 games',
      icon: Icons.emoji_events,
      color: Colors.deepOrange,
    ),
    Achievement(
      title: 'G.O.A.T',
      subtitle: 'If you play between 100–130 games',
      icon: Icons.workspace_premium,
      color: Colors.blueAccent,
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
          "Achievements",
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
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final item = achievements[index];
          final isCurrent = item.title == currentAchievement;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + vertical line
              Container(
                width: 40,
                child: Column(
                  children: [
                    Icon(item.icon, color: item.color, size: 36),
                    if (index != achievements.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        margin: EdgeInsets.only(top: 4),
                        color: Colors.grey.shade300,
                      ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              // Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isCurrent ? Colors.green : Colors.black,
                          ),
                        ),
                        if (isCurrent)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(Icons.check_circle,
                                color: Colors.green, size: 18),
                          )
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(item.subtitle,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class Achievement {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  Achievement({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
