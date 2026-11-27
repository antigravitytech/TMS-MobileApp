enum NotificationKind { review, mention, birthday }

enum NotificationDay { today, yesterday }

typedef NotificationPreview = ({
  int id,
  NotificationKind kind,
  NotificationDay day,
  String initials,
  String message,
  int? ageMinutes,
});

const notificationPreviews = <NotificationPreview>[
  (
    id: 0,
    kind: NotificationKind.review,
    day: NotificationDay.today,
    initials: 'TB',
    message: 'tunde_resubmitted',
    ageMinutes: null,
  ),
  (
    id: 1,
    kind: NotificationKind.review,
    day: NotificationDay.today,
    initials: 'AE',
    message: 'amaka_submitted',
    ageMinutes: null,
  ),
  (
    id: 2,
    kind: NotificationKind.birthday,
    day: NotificationDay.today,
    initials: 'MB',
    message: 'mama_bisi_birthday',
    ageMinutes: 5,
  ),
  (
    id: 3,
    kind: NotificationKind.birthday,
    day: NotificationDay.today,
    initials: 'TB',
    message: 'tunde_birthday',
    ageMinutes: 5,
  ),
  (
    id: 4,
    kind: NotificationKind.mention,
    day: NotificationDay.yesterday,
    initials: 'DM',
    message: 'david_mentioned',
    ageMinutes: 720,
  ),
  (
    id: 5,
    kind: NotificationKind.review,
    day: NotificationDay.yesterday,
    initials: 'SJ',
    message: 'sarah_submitted',
    ageMinutes: 1140,
  ),
];
