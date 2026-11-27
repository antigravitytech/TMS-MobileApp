part of 'visitors_repository.dart';

/// The prototype's guests: Folake waiting at reception, Bayo expected.
class MockVisitorsRepository implements VisitorsRepository {
  var _next = 42;

  late final List<VisitPass> _passes = () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      VisitPass(
        id: 'mock-folake',
        code: 'GEN-F4AD',
        guest: 'Folake Adebayo',
        purpose: 'Interview · Backend engineer role',
        validOn: today,
        status: 'waiting',
        arrivedAt: now.subtract(const Duration(minutes: 2)),
        canAnswer: true,
      ),
      VisitPass(
        id: 'mock-bayo',
        code: 'B2X-81P',
        guest: 'Bayo Ogunleye',
        purpose: '14:00 · Supplier visit',
        validOn: today,
        status: 'expected',
        canAnswer: true,
      ),
    ];
  }();

  @override
  Duration? get polling => null;

  @override
  Future<List<VisitPass>> passes() async => List.of(_passes);

  @override
  Future<VisitPass> invite(GuestInvite invite) async {
    final pass = VisitPass(
      id: 'mock-${_next++}',
      code: 'K7Q-${_next}M',
      guest: invite.name,
      purpose: invite.purpose,
      validOn: invite.day,
      status: 'expected',
      canAnswer: true,
    );
    _passes.insert(0, pass);
    return pass;
  }

  @override
  Future<VisitPass> answer(VisitPass pass, GuestAnswer answer) async {
    final updated = VisitPass(
      id: pass.id,
      code: pass.code,
      guest: pass.guest,
      purpose: pass.purpose,
      validOn: pass.validOn,
      arrivedAt: pass.arrivedAt,
      canAnswer: pass.canAnswer,
      status: switch (answer) {
        GuestAnswer.admit => 'admitted',
        GuestAnswer.hold => 'on_hold',
        GuestAnswer.decline => 'declined',
      },
    );
    final i = _passes.indexWhere((p) => p.id == pass.id);
    if (i >= 0) _passes[i] = updated;
    return updated;
  }
}
