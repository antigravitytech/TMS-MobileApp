import '../../domain/profile.dart';

/// The translation key for a status, shared by Profile and More.
String presenceLabelKey(Presence presence) => switch (presence) {
  Presence.available => 'profile.available',
  Presence.meeting => 'profile.in_a_meeting',
  Presence.focusing => 'profile.focusing',
  Presence.away => 'profile.out_of_office',
};
