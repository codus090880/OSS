// TestUploadScreen: A simple form to input RunSummary values and submit to /upload_course/
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:prunners/model/auth_service.dart';

class TestUploadScreen extends StatefulWidget {
  const TestUploadScreen({Key? key}) : super(key: key);

  @override
  _TestUploadScreenState createState() => _TestUploadScreenState();
}

class _TestUploadScreenState extends State<TestUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _elapsedTimeController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _avgSpeedController = TextEditingController();
  final TextEditingController _cadenceController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController(text: DateTime.now().toIso8601String());
  final TextEditingController _routeController = TextEditingController(text: '[]');

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RunSummary Test Upload')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _distanceController,
                  decoration: const InputDecoration(labelText: 'Distance (km)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _elapsedTimeController,
                  decoration: const InputDecoration(labelText: 'Elapsed Time (HH:MM:SS)'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(labelText: 'Calories'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _avgSpeedController,
                  decoration: const InputDecoration(labelText: 'Avg Speed (km/h)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _cadenceController,
                  decoration: const InputDecoration(labelText: 'Cadence (spm)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _dateTimeController,
                  decoration: const InputDecoration(labelText: 'DateTime (ISO8601)'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _routeController,
                  decoration: const InputDecoration(labelText: 'Route JSON (e.g. [{"lat":0.0,"lng":0.0}])'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final distanceKm = double.parse(_distanceController.text);
      final elapsedTime = _elapsedTimeController.text;
      final calories = double.parse(_caloriesController.text);
      final avgSpeed = double.parse(_avgSpeedController.text);
      final cadence = double.parse(_cadenceController.text);
      DateTime dateTime;
      try {
        dateTime = DateTime.parse(_dateTimeController.text);
      } catch (_) {
        dateTime = DateTime.now();
      }
      List<dynamic> parsedRoute;
      try {
        parsedRoute = jsonDecode(_routeController.text) as List<dynamic>;
      } catch (_) {
        parsedRoute = [];
      }
      final data = {
        'distance_km': distanceKm,
        'elapsed_time': elapsedTime,
        'calories': calories,
        'avg_speed_kmh': avgSpeed,
        'cadence_spm': cadence,
        'date_time': dateTime.toIso8601String(),
        'route': parsedRoute,
      };

      final token = await AuthService.storage.read(key: 'ACCESS_TOKEN');
      final resp = await AuthService.dio.post(
        '/upload_course/',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload successful!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
}
