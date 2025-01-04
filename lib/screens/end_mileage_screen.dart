import 'package:flutter/material.dart';

class EndMileageScreen extends StatefulWidget {
  final double startMileage;

  const EndMileageScreen({
    super.key,
    required this.startMileage,
  });

  @override
  State<EndMileageScreen> createState() => _EndMileageScreenState();
}

class _EndMileageScreenState extends State<EndMileageScreen> {
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
        title: const Text('End Mileage'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Start Mileage: ${widget.startMileage}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mileageController,
              decoration: const InputDecoration(
                labelText: 'End Mileage',
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
                if (mileage <= widget.startMileage) {
                  return 'End mileage must be greater than start mileage';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Set End Mileage'),
            ),
          ],
        ),
      ),
    );
  }
}
