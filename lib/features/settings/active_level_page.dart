import 'package:flutter/material.dart';

class ActiveLevelPage extends StatelessWidget {
  final String currentActiveLevel;
  ActiveLevelPage({required this.currentActiveLevel});

  final List<ActiveLevel> levels = [
    ActiveLevel(
        title: 'Getting Started',
        subtitle: '+1 Games in a month',
        icon: Icons.play_circle_fill,
        color: Colors.green),
    ActiveLevel(
        title: 'Warming Up',
        subtitle: '+2 Games in a month',
        icon: Icons.thermostat,
        color: Colors.red),
    ActiveLevel(
        title: 'Almost There',
        subtitle: '+4 Games in a month',
        icon: Icons.flash_on,
        color: Colors.purple),
    ActiveLevel(
        title: 'On Fire',
        subtitle: '+6 Games in a month',
        icon: Icons.local_fire_department,
        color: Colors.orange),
    ActiveLevel(
        title: 'Unstoppable',
        subtitle: '+8 Games in a month',
        icon: Icons.rocket_launch,
        color: Colors.blue),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          "Active Level",
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
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final item = levels[index];
          final isCurrent = item.title == currentActiveLevel;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    Icon(item.icon, color: item.color, size: 44),
                    if (index != levels.length - 1)
                      Container(
                        width: 2,
                        height: 50,
                        margin: EdgeInsets.only(top: 4),
                        color: Colors.grey.shade300,
                      ),
                  ],
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                    SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style:
                          TextStyle(fontSize: 15, color: Colors.grey.shade700),
                    ),
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

class ActiveLevel {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  ActiveLevel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
