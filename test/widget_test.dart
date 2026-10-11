import 'package:flutter_test/flutter_test.dart';
import 'package:family_album/models/models.dart';

void main() {
  test('User.fromJson parses correctly', () {
    final u = User.fromJson({'id': 'u1', 'phone': '138', 'nickname': '王建国', 'elder_mode': true});
    expect(u.nickname, '王建国');
    expect(u.elderMode, true);
  });
}
