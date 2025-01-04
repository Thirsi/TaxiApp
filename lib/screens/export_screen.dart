import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

class ExportScreen extends StatefulWidget {
  final SettingsService settingsService;

  const ExportScreen({
    super.key,
    required this.settingsService,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isExporting = false;
  String? _exportPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _exportData();
  }

  Future<void> _exportData() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
      _error = null;
    });

    try {
      final databaseService = DatabaseService(widget.settingsService);
      final path = await databaseService.exportToCsv();
      
      if (mounted) {
        setState(() {
          _exportPath = path;
          _isExporting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _shareFile() async {
    if (_exportPath == null) return;

    try {
      await Share.shareXFiles(
        [XFile(_exportPath!)],
        subject: 'Taxi Jobs Export',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isExporting) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Exporting data...',
                textAlign: TextAlign.center,
              ),
            ] else if (_error != null) ...[
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Export failed: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _exportData,
                child: const Text('Try Again'),
              ),
            ] else if (_exportPath != null) ...[
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Export completed successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'File saved to:\n$_exportPath',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _shareFile,
                icon: const Icon(Icons.share),
                label: const Text('Share File'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
