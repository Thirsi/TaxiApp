import 'package:flutter/material.dart';
import '../services/settings_service.dart';

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
          ],
        ),
      ),
    );
  }
}
