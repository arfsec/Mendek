import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/schedule.dart';
import '../services/db_service.dart';
import '../services/notif_service.dart';
import '../services/url_helper.dart';

class AddEditScreen extends StatefulWidget {
  final Schedule? schedule;
  const AddEditScreen({super.key, this.schedule});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;

  TimeOfDay _startTime = const TimeOfDay(hour: 5, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 0);
  final Set<int> _selectedDays = {1, 2, 3, 4, 5, 6, 7};
  bool _isActive = true;
  UrlParseResult? _parsedResult;

  @override
  void initState() {
    super.initState();
    final existing = widget.schedule;
    if (existing != null) {
      _nameController = TextEditingController(text: existing.name);
      _urlController = TextEditingController(text: existing.url);
      _startTime = TimeOfDay(hour: existing.startHour, minute: existing.startMinute);
      _endTime = TimeOfDay(hour: existing.endHour, minute: existing.endMinute);
      _selectedDays.clear();
      _selectedDays.addAll(existing.daysOfWeek);
      _isActive = existing.isActive;
      _parsedResult = UrlHelper.parse(existing.url);
    } else {
      _nameController = TextEditingController();
      _urlController = TextEditingController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schedule == null ? 'Tambah Jadwal' : 'Ubah Jadwal'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Masteran / Burung'),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'URL Video YouTube / TikTok'),
              onChanged: (val) {
                setState(() {
                  _parsedResult = UrlHelper.parse(val);
                });
              },
              validator: (v) => _parsedResult == null ? 'URL YouTube / TikTok tidak valid' : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final t = await showTimePicker(context: context, initialTime: _startTime);
                      if (t != null) setState(() => _startTime = t);
                    },
                    child: Text('Mulai: ${_startTime.format(context)}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final t = await showTimePicker(context: context, initialTime: _endTime);
                      if (t != null) setState(() => _endTime = t);
                    },
                    child: Text('Selesai: ${_endTime.format(context)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final schedule = Schedule(
                  id: widget.schedule?.id,
                  name: _nameController.text.trim(),
                  url: _urlController.text.trim(),
                  platform: _parsedResult!.platform,
                  videoId: _parsedResult!.videoId,
                  startHour: _startTime.hour,
                  startMinute: _startTime.minute,
                  endHour: _endTime.hour,
                  endMinute: _endTime.minute,
                  daysOfWeek: _selectedDays.toList()..sort(),
                  isActive: _isActive,
                );
                if (widget.schedule == null) {
                  await DbService.instance.insertSchedule(schedule);
                } else {
                  await DbService.instance.updateSchedule(schedule);
                }
                if (_isActive) {
                  await NotifService.instance.scheduleAlarm(schedule);
                }
                Navigator.pop(context, true);
              },
              child: const Text('SIMPAN JADWAL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}