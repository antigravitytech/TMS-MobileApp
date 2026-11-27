/// A guest's pass, from invited to gone.
class VisitPass {
  const VisitPass({
    required this.id,
    required this.code,
    required this.guest,
    required this.validOn,
    required this.status,
    this.purpose = '',
    this.arrivedAt,
    this.canAnswer = false,
  });
  final String id, code, guest, purpose;
  final DateTime validOn;

  /// The server's status: `expected`, `waiting`, `admitted`, `on_hold`,
  /// `hold_over`, `inside`, `declined`, `left`, `expired`, `cancelled`.
  final String status;
  final DateTime? arrivedAt;

  /// Whether I (as host or desk receiver) can let them in.
  final bool canAnswer;

  bool get needsAnswer =>
      canAnswer && (status == 'waiting' || status == 'hold_over');
}

/// How I answered a waiting guest.
enum GuestAnswer {
  admit('admit'),
  hold('hold'),
  decline('decline');

  const GuestAnswer(this.action);
  final String action;
}

/// A new invitation.
typedef GuestInvite = ({String name, DateTime day, String purpose});

/// The server turned an action down and said why, for example
/// "Only Finance can answer this guest."
class VisitorRefused implements Exception {
  const VisitorRefused(this.detail);
  final String detail;
  @override
  String toString() => detail;
}
