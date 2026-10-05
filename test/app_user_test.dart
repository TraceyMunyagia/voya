import 'package:flutter_test/flutter_test.dart';
import 'package:voya/data/models/app_user.dart';

void main() {
  test('parses a profile row', () {
    final u = AppUser.fromJson({
      'id': 'u1',
      'username': 'jane_d',
      'display_name': 'Jane Doe',
      'photo_url': 'https://example.com/a.jpg',
      'city': 'Nairobi',
      'followers_count': 12,
      'onboarding_completed': true,
    });
    expect(u.username, 'jane_d');
    expect(u.initials, 'JD');
    expect(u.shownName, 'Jane Doe');
    expect(u.followersCount, 12);
    expect(u.onboardingCompleted, isTrue);
  });

  test('a bare row defaults to not onboarded', () {
    final u = AppUser.fromJson({'id': 'u1'});
    expect(u.onboardingCompleted, isFalse);
    expect(u.bio, '');
    expect(u.tripsCount, 0);
  });

  test('initials and shown name fall back gracefully', () {
    expect(const AppUser(id: 'u', displayName: 'Tracey').initials, 'T');
    expect(const AppUser(id: 'u', username: 'jane_d').initials, 'J');
    expect(const AppUser(id: 'u', username: 'jane_d').shownName, '@jane_d');
    expect(const AppUser(id: 'u').initials, '?');
    expect(const AppUser(id: 'u').shownName, 'Traveller');
  });
}
