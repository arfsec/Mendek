import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/db_service.dart';
import '../services/notif_service.dart';
import 'add_edit_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Schedule> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    final list = await DbService.instance.getAllSchedules();
    setState(() {
      _schedules = list;
      _isLoading = false;
    });
  }

  Future<void> _toggleSchedule(Schedule schedule, bool value) async {
    final updated = schedule.copyWith(isActive: value);
    await DbService.instance.toggleScheduleActive(schedule.id, value);

    if (value) {
      await NotifService.instance.scheduleAlarm(updated);
    } else {
      await NotifService.instance.cancelSchedule(schedule);
    }

    setState(() {
      final index = _schedules.indexWhere((s) => s.id == schedule.id);
      if (index != -1) _schedules[index] = updated;
    });
  }

  Future<void> _deleteSchedule(Schedule schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal?'),
        content: Text('Yakin ingin menghapus jadwal "${schedule.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('BATAL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('HAPUS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DbService.instance.deleteSchedule(schedule.id);
      await NotifService.instance.cancelSchedule(schedule);
      _loadSchedules();
    }
  }

  void _openPlayer(Schedule schedule) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerScreen(
          scheduleId: schedule.id,
          scheduleTitle: schedule.name,
          rawUrl: schedule.url,
          endHour: schedule.endHour,
          endMinute: schedule.endMinute,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: const Text('Mendek Arena Masteran', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : RefreshIndicator(
              onRefresh: _loadSchedules,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ..._schedules.map((schedule) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Chip(
                                    label: Text(schedule.platform.toUpperCase(),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      schedule.name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Switch(
                                    value: schedule.isActive,
                                    activeColor: const Color(0xFF1B5E20),
                                    onChanged: (val) => _toggleSchedule(schedule, val),
                                  ),
                                ],
                              ),
                              Text(
                                '${schedule.formattedStartTime} - ${schedule.formattedEndTime}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              Text('Hari: ${schedule.formattedDaysSummary}'),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('Tes Putar'),
                                      onPressed: () => _openPlayer(schedule),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () async {
                                      final res = await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => AddEditScreen(schedule: schedule)),
                                      );
                                      if (res == true) _loadSchedules();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteSchedule(schedule),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('TAMBAH JADWAL'),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditScreen()),
          );
          if (res == true) _loadSchedules();
        },
      ),
    );
  }
}