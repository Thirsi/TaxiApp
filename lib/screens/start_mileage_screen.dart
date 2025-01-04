import 'package:flutter/material.dart';

class StartMileageScreen extends StatefulWidget {
  const StartMileageScreen({super.key});

  @override
  State<StartMileageScreen> createState() => _StartMileageScreenState();
}

class _StartMileageScreenState extends State<StartMileageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mileageController = TextEditingController();

  @override
  void dispose() {
    _mileageController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, double.parse(_mileageController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Mileage'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _mileageController,
              decoration: const InputDecoration(
                labelText: 'Start Mileage',
                hintText: 'Enter the current mileage',
                suffixText: 'miles',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the mileage';
                }
                final mileage = double.tryParse(value);
                if (mileage == null) {
                  return 'Please enter a valid number';
                }
                if (mileage < 0) {
                  return 'Mileage cannot be negative';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Set Start Mileage'),
            ),
          ],
        ),
      ),
    );
  }
}
