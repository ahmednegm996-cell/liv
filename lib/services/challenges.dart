class Challenge {
  final String id;
  final String titleEn;
  final String titleAr;
  final int points;
  final String category;

  const Challenge({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    this.points = 15,
    this.category = 'daily',
  });
}

const kDailyChallenges = [
  Challenge(id: 'water', titleEn: 'Drink 8 glasses of water', titleAr: 'اشرب 8 أكواب ماء', points: 10),
  Challenge(id: 'walk', titleEn: 'Walk 5000 steps', titleAr: 'امشِ 5000 خطوة', points: 20),
  Challenge(id: 'read', titleEn: 'Read 10 pages', titleAr: 'اقرأ 10 صفحات', points: 15),
  Challenge(id: 'meditate', titleEn: 'Meditate 5 minutes', titleAr: 'تأمل 5 دقائق', points: 15),
  Challenge(id: 'gratitude', titleEn: 'Write 3 things you are grateful for', titleAr: 'اكتب 3 أمور تشكر عليها', points: 10),
];
