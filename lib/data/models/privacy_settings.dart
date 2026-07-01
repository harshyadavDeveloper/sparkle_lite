class PrivacySettings {
  final String userId;
  final bool hideSensitiveDashboardDetails;
  final bool useGenericNotificationText; // true by default — IMPORTANT
  final bool requireConfirmationBeforeSharing;
  final bool familyProfileAccessEnabled;
  final DateTime updatedAt;

  PrivacySettings({
    required this.userId,
    this.hideSensitiveDashboardDetails = false,
    this.useGenericNotificationText = true, // default ON per PDF
    this.requireConfirmationBeforeSharing = true,
    this.familyProfileAccessEnabled = false,
    required this.updatedAt,
  });

  factory PrivacySettings.fromMap(Map<String, dynamic> map) => PrivacySettings(
    userId: map['userId'] ?? '',
    hideSensitiveDashboardDetails:
        map['hideSensitiveDashboardDetails'] ?? false,
    useGenericNotificationText: map['useGenericNotificationText'] ?? true,
    requireConfirmationBeforeSharing:
        map['requireConfirmationBeforeSharing'] ?? true,
    familyProfileAccessEnabled: map['familyProfileAccessEnabled'] ?? false,
    updatedAt: DateTime.parse(map['updatedAt']),
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'hideSensitiveDashboardDetails': hideSensitiveDashboardDetails,
    'useGenericNotificationText': useGenericNotificationText,
    'requireConfirmationBeforeSharing': requireConfirmationBeforeSharing,
    'familyProfileAccessEnabled': familyProfileAccessEnabled,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
