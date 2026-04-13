
class AppSettings {
  String bookingType; // '1' or '2'

  AppSettings({
    this.bookingType = '1',
  });

  Map<String, dynamic> toJson() => {
    'bookingType': bookingType,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    bookingType: json['bookingType'] ?? '1',
  );
}