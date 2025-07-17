class Scan {
  final String activity;
  final String date;
  final String location;
  final String srStatus;
  final String srStatusLabel;
  final String status;

  Scan({
    required this.activity,
    required this.date,
    required this.location,
    required this.srStatus,
    required this.srStatusLabel,
    required this.status,
  });

  factory Scan.fromJson(Map<String, dynamic> json) {
    return Scan(
      activity: json['activity'] as String,
      date: json['date'] as String,
      location: json['location'] as String,
      srStatus: json['sr-status'] as String,
      srStatusLabel: json['sr-status-label'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity': activity,
      'date': date,
      'location': location,
      'sr-status': srStatus,
      'sr-status-label': srStatusLabel,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'Scan(activity: $activity, date: $date, location: $location, status: $status)';
  }
}