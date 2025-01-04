import '../services/settings_service.dart';

class Job {
  final int? id;
  final DateTime date;
  final double startMileage;
  final double? endMileage;
  final double price;
  final String paymentType; // 'cash', 'credit', or 'account'
  final String? notes;

  Job({
    this.id,
    required this.date,
    required this.startMileage,
    this.endMileage,
    required this.price,
    required this.paymentType,
    this.notes,
  });

  double? get distance => endMileage != null ? endMileage! - startMileage : null;

  double? calculatedPrice(SettingsService settings) {
    if (distance == null) return null;
    return distance! * settings.mileageRate + settings.shiftCharge;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'startMileage': startMileage,
      'endMileage': endMileage,
      'price': price,
      'paymentType': paymentType,
      'notes': notes,
    };
  }

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['id'],
      date: DateTime.parse(map['date']),
      startMileage: map['startMileage'],
      endMileage: map['endMileage'],
      price: map['price'],
      paymentType: map['paymentType'],
      notes: map['notes'],
    );
  }

  List<String> toCsvRow(SettingsService settings) {
    final calculatedPriceStr = calculatedPrice(settings) != null && paymentType != 'account'
        ? ' (calc: £${calculatedPrice(settings)!.toStringAsFixed(2)})'
        : '';
    
    return [
      date.toIso8601String(),
      startMileage.toString(),
      endMileage?.toString() ?? '',
      distance?.toStringAsFixed(1) ?? '',
      '£${price.toStringAsFixed(2)}$calculatedPriceStr',
      paymentType,
      notes ?? '',
    ];
  }

  static List<String> csvHeaders() {
    return [
      'Date',
      'Start Mileage',
      'End Mileage',
      'Distance',
      'Price (GBP)',
      'Payment Type',
      'Notes',
    ];
  }
}

class DailySummary {
  final DateTime date;
  final double accountTotal;
  final double? totalMiles;
  final List<Job> jobs;
  final double? mileageOnlyTotal;

  DailySummary({
    required this.date,
    required this.accountTotal,
    this.totalMiles,
    required this.jobs,
    this.mileageOnlyTotal,
  });

  double? get calculatedTotal => mileageOnlyTotal != null 
      ? mileageOnlyTotal! + accountTotal 
      : null;

  factory DailySummary.fromJobs(List<Job> dayJobs, SettingsService settings) {
    var account = 0.0;
    double? miles;
    double? mileageOnlyTotal;

    // Calculate account total
    for (final job in dayJobs) {
      if (job.paymentType == 'account') {
        account += job.price;
      }
    }

    // Calculate total miles if all jobs have end mileage
    if (dayJobs.isNotEmpty && dayJobs.every((job) => job.endMileage != null)) {
      final firstJob = dayJobs.first;
      final lastJob = dayJobs.last;
      miles = lastJob.endMileage! - firstJob.startMileage;

      // Calculate mileage-only total (even if no jobs)
      mileageOnlyTotal = miles * settings.mileageRate + settings.shiftCharge;
    }

    return DailySummary(
      date: dayJobs.first.date,
      accountTotal: account,
      totalMiles: miles,
      jobs: dayJobs,
      mileageOnlyTotal: mileageOnlyTotal,
    );
  }
}
