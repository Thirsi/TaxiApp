import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'export_screen.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsScreen({
    super.key,
    required this.settingsService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _mileageRateController;
  late TextEditingController _shiftChargeController;

  @override
  void initState() {
    super.initState();
    _mileageRateController = TextEditingController(
      text: widget.settingsService.mileageRate.toString(),
    );
    _shiftChargeController = TextEditingController(
      text: widget.settingsService.shiftCharge.toString(),
    );
  }

  @override
  void dispose() {
    _mileageRateController.dispose();
    _shiftChargeController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      await widget.settingsService.setMileageRate(
        double.parse(_mileageRateController.text),
      );
      await widget.settingsService.setShiftCharge(
        double.parse(_shiftChargeController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
        Navigator.pop(context, true); // true indicates settings were changed
      }
    }
  }

  Future<void> _resetToDefaults() async {
    await widget.settingsService.resetToDefaults();
    setState(() {
      _mileageRateController.text =
          SettingsService.defaultMileageRate.toString();
      _shiftChargeController.text =
          SettingsService.defaultShiftCharge.toString();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings reset to defaults')),
      );
    }
  }

  Future<void> _clearDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Database'),
        content: const Text(
          'Are you sure you want to clear all jobs? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.settingsService.clearDatabase();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database cleared successfully')),
          );
          Navigator.pop(context, true); // Reload the main screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing database: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetToDefaults,
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _mileageRateController,
              decoration: const InputDecoration(
                labelText: 'Mileage Rate (£)',
                helperText: 'Amount per mile (default: £0.85)',
                prefixText: '£',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a rate';
                }
                final rate = double.tryParse(value);
                if (rate == null) {
                  return 'Please enter a valid number';
                }
                if (rate <= 0) {
                  return 'Rate must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _shiftChargeController,
              decoration: const InputDecoration(
                labelText: 'Shift Charge (£)',
                helperText: 'Base amount per job (default: £5.00)',
                prefixText: '£',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a charge';
                }
                final charge = double.tryParse(value);
                if (charge == null) {
                  return 'Please enter a valid number';
                }
                if (charge < 0) {
                  return 'Charge cannot be negative';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExportScreen(settingsService: widget.settingsService),
                  ),
                );
              },
              child: const Text('Export Data'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearDatabase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Database'),
            ),
          ],
        ),
      ),
    );
  }
}
