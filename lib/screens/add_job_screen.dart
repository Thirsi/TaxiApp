import 'package:flutter/material.dart';
import '../models/job.dart';

class AddJobScreen extends StatefulWidget {
  const AddJobScreen({super.key});

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentType = 'cash';

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final job = Job(
        date: DateTime.now(),
        startMileage: 0, // Will be set by caller
        price: double.parse(_priceController.text),
        paymentType: _paymentType,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      Navigator.pop(context, job);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Job Details'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (£)',
                prefixText: '£',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                final price = double.tryParse(value);
                if (price == null) {
                  return 'Please enter a valid number';
                }
                if (price < 0) {
                  return 'Price cannot be negative';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentType,
              decoration: const InputDecoration(
                labelText: 'Payment Type',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'cash',
                  child: Text('Cash'),
                ),
                DropdownMenuItem(
                  value: 'credit',
                  child: Text('Credit Card'),
                ),
                DropdownMenuItem(
                  value: 'account',
                  child: Text('Account'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _paymentType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any additional information',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Save Job'),
            ),
          ],
        ),
      ),
    );
  }
}
