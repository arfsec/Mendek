import 'package:uuid/uuid.dart';

class Schedule {
  final String id;
  final String name;
  final String url;
  final String platform; // 'youtube' or 'tiktok'
  final String videoId;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final List<int> daysOfWeek; // 1 = Senin, ..., 7 = Minggu
  final bool isActive;

  Schedule({
    String? id,
    required this.name,
    required this.url,
    required this.platform,
    required this.videoId,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.daysOfWeek,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'platform': platform,
      'videoId': videoId,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'daysOfWeek': daysOfWeek.join(','),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    List<int> parsedDays = [];
    if (map['daysOfWeek'] != null && map['daysOfWeek'].toString().isNotEmpty) {
      parsedDays = map['daysOfWeek']
          .toString()
          .split(',')
          .map((e) => int.tryParse(e.trim()) ?? 1)
          .toList();
    }

    return Schedule(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      platform: map['platform'] as String,
      videoId: map['videoId'] as String,
      startHour: map['startHour'] as int,
      startMinute: map['startMinute'] as int,
      endHour: map['endHour'] as int,
      endMinute: map['endMinute'] as int,
      daysOfWeek: parsedDays,
      isActive: (map['isActive'] as int) == 1,
    );
  }

  Schedule copyWith({
    String? id,
    String? name,
    String? url,
    String? platform,
    String? videoId,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    List<int>? daysOfWeek,
    bool? isActive,
  }) {
    return Schedule(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      platform: platform ?? this.platform,
      videoId: videoId ?? this.videoId,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
    );
  }

  String get formattedStartTime =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

  String get formattedEndTime =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  String get formattedTimeRange => '$formattedStartTime - $formattedEndTime';

  String get formattedDaysSummary {
    if (daysOfWeek.length == 7) return 'Setiap Hari';
    if (daysOfWeek.length == 5 &&
        daysOfWeek.contains(1) &&
        daysOfWeek.contains(2) &&
        daysOfWeek.contains(3) &&
        daysOfWeek.contains(4) &&
        daysOfWeek.contains(5)) {
      return 'Senin - Jumat';
    }
    if (daysOfWeek.length == 2 &&
        daysOfWeek.contains(6) &&
        daysOfWeek.contains(7)) {
      return 'Sabtu & Minggu';
    }

    const dayNames = {
      1: 'Sen',
      2: 'Sel',
      3: 'Rab',
      4: 'Kam',
      5: 'Jum',
      6: 'Sab',
      7: 'Min',
    };

    final sorted = List<int>.from(daysOfWeek)..sort();
    return sorted.map((d) => dayNames[d] ?? '').join(', ');
  }
}