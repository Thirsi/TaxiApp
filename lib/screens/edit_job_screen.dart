import 'package:flutter/material.dart';
import '../models/job.dart';

class EditJobScreen extends StatefulWidget {
  final Job job;

  const EditJobScreen({
    super.key,
    required this.job,
  });

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  late String _paymentType;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.job.price.toString());
    _notesController = TextEditingController(text: widget.job.notes ?? '');
    _paymentType = widget.job.paymentType;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final updatedJob = Job(
        id: widget.job.id,
        date: widget.job.date,
        startMileage: widget.job.startMileage,
        endMileage: widget.job.endMileage,
        price: double.parse(_priceController.text),
        paymentType: _paymentType,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      Navigator.pop(context, updatedJob);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Job'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Job'),
                  content: const Text(
                    'Are you sure you want to delete this job? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ).then((confirmed) {
                if (confirmed == true) {
                  Navigator.pop(context, 'DELETE'); // Special return value for deletion
                }
              });
            },
            tooltip: 'Delete Job',
          ),
        ],
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
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
