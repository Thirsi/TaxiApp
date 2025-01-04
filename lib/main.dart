import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/job.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';
import 'screens/start_mileage_screen.dart';
import 'screens/end_mileage_screen.dart';
import 'screens/add_job_screen.dart';
import 'screens/export_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/edit_job_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsService.create();
  runApp(MyApp(settings: settings));
}

class MyApp extends StatelessWidget {
  final SettingsService settings;

  const MyApp({
    super.key,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxi Log',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: HomePage(settings: settings),
    );
  }
}

class HomePage extends StatefulWidget {
  final SettingsService settings;

  const HomePage({
    super.key,
    required this.settings,
  });

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late final DatabaseService _databaseService;
  List<DailySummary> _summaries = [];
  bool _isMenuOpen = false;
  double? _startMileage;
  double? _endMileage;
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService(widget.settings);
    _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    try {
      final summaries = await _databaseService.getDailySummaries();
      setState(() {
        _summaries = summaries;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading jobs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(settingsService: widget.settings),
      ),
    );

    if (updated == true) {
      _loadSummaries(); // Reload to update calculations with new rates
    }
  }

  Future<void> _addStartMileage() async {
    final startMileage = await Navigator.push<double>(
      context,
      MaterialPageRoute(builder: (context) => const StartMileageScreen()),
    );
    if (startMileage != null) {
      setState(() {
        _startMileage = startMileage;
        _startTime = DateTime.now();
        // Reset end values if start is being reset
        if (_endMileage != null) {
          _endMileage = null;
          _endTime = null;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Start mileage set to: $startMileage'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _addEndMileage() async {
    if (_startMileage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set start mileage first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final endMileage = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (context) => EndMileageScreen(startMileage: _startMileage!),
      ),
    );
    if (endMileage != null) {
      setState(() {
        _endMileage = endMileage;
        _endTime = DateTime.now();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('End mileage set to: $endMileage'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _loadSummaries(); // Reload summaries to update totals
    }
  }

  Future<void> _addJobDetails() async {
    if (_startMileage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set start mileage first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_endMileage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add jobs after end mileage is set'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final jobDetails = await Navigator.push<Job>(
      context,
      MaterialPageRoute(builder: (context) => const AddJobScreen()),
    );

    if (jobDetails != null) {
      try {
        final job = Job(
          date: _startTime ?? DateTime.now(),
          startMileage: _startMileage!,
          endMileage: null, // Each job doesn't need end mileage
          price: jobDetails.price,
          paymentType: jobDetails.paymentType,
          notes: jobDetails.notes,
        );

        await _databaseService.insertJob(job);
        await _loadSummaries();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job saved successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving job: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editJob(Job job) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => EditJobScreen(job: job),
      ),
    );

    if (result == 'DELETE') {
      if (job.id != null) {
        try {
          await _databaseService.deleteJob(job.id!);
          await _loadSummaries();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Job deleted successfully')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error deleting job: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } else if (result is Job) {
      try {
        await _databaseService.updateJob(result);
        await _loadSummaries();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating job: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _exportData() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExportScreen(settingsService: widget.settings),
      ),
    );
  }

  Widget _buildDailySummaryCard(DailySummary summary) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(summary.date),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Daily Summary Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Daily Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Jobs:'),
                            Text(
                              '${summary.jobs.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (summary.totalMiles != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Miles:'),
                              Text(
                                '${summary.totalMiles!.toStringAsFixed(1)} miles',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Mileage Total (£${widget.settings.mileageRate}/mile + £${widget.settings.shiftCharge}):'),
                              Text(
                                '£${summary.mileageOnlyTotal!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (summary.accountTotal > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Account Jobs:'),
                              Text(
                                '£${summary.accountTotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        if (summary.calculatedTotal != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Earnings:'),
                              Text(
                                '£${summary.calculatedTotal!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Jobs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...summary.jobs.map((job) => InkWell(
                  onTap: () => _editJob(job),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('HH:mm').format(job.date),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                  'Mileage: ${job.startMileage}${job.endMileage != null ? ' - ${job.endMileage}' : ''}'),
                              if (job.distance != null)
                                Text('Distance: ${job.distance!.toStringAsFixed(1)} miles'),
                              if (job.calculatedPrice(widget.settings) != null && job.paymentType != 'account')
                                Text(
                                  'Calculated: £${job.calculatedPrice(widget.settings)!.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              if (job.notes?.isNotEmpty == true)
                                Text('Notes: ${job.notes}'),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '£${job.price.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(job.paymentType),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taxi Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isMenuOpen) ...[
            Tooltip(
              message: 'Add Job Details (${DateFormat('HH:mm').format(DateTime.now())})',
              child: FloatingActionButton.small(
                heroTag: 'add_job',
                onPressed: _addJobDetails,
                child: const Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 8),
            Tooltip(
              message: 'End Mileage (${DateFormat('HH:mm').format(DateTime.now())})',
              child: FloatingActionButton.small(
                heroTag: 'end_mileage',
                onPressed: _addEndMileage,
                child: const Icon(Icons.flag),
              ),
            ),
            const SizedBox(height: 8),
            Tooltip(
              message: 'Start Mileage (${DateFormat('HH:mm').format(DateTime.now())})',
              child: FloatingActionButton.small(
                heroTag: 'start_mileage',
                onPressed: _addStartMileage,
                child: const Icon(Icons.play_arrow),
              ),
            ),
            const SizedBox(height: 8),
          ],
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isMenuOpen = !_isMenuOpen;
              });
            },
            child: Icon(_isMenuOpen ? Icons.close : Icons.menu),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          if (_startMileage != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withOpacity(0.1),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Start Mileage',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _startMileage.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (_startTime != null)
                            Text(
                              DateFormat('HH:mm').format(_startTime!),
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      if (_endMileage != null)
                        Column(
                          children: [
                            const Text(
                              'End Mileage',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _endMileage.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_endTime != null)
                              Text(
                                DateFormat('HH:mm').format(_endTime!),
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                    ],
                  ),
                  if (_startMileage != null && _endMileage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          Text(
                            'Distance: ${(_endMileage! - _startMileage!).toStringAsFixed(1)} miles',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            'Calculated: £${((_endMileage! - _startMileage!) * widget.settings.mileageRate + widget.settings.shiftCharge).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _summaries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.directions_car,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No jobs yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap the menu button to get started',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _summaries.length,
                    itemBuilder: (context, index) {
                      return _buildDailySummaryCard(_summaries[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
