import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('LogMask', () {
    test('token: last 4 chars, fallback for short', () {
      expect(LogMask.token('eyJhbGciOiJIUzI1NiJ9.abc.x9kQ'), '****x9kQ');
      expect(LogMask.token('abc'), '****');
      expect(LogMask.token(null), '****');
    });

    test('uid: first 3 + last 3, fallback for short', () {
      expect(LogMask.uid('Xk29aBcdef'), 'Xk2***def');
      expect(LogMask.uid('K8nbEOGW0ZOs98eqxgogGauqGjD2'), 'K8n***jD2');
      expect(LogMask.uid('short'), '***');
      expect(LogMask.uid(null), '***');
    });

    test('email: domain only', () {
      expect(LogMask.email('dk@wtf.fit'), '**@wtf.fit');
      expect(LogMask.email('aarav@wtf.fit'), '**@wtf.fit');
      expect(LogMask.email('no-at-sign'), '****');
      expect(LogMask.email(null), '****');
    });

    test('secret: always masked', () {
      expect(LogMask.secret('Wtf@1234'), '****');
      expect(LogMask.secret(null), '****');
    });

    test('url: hides query params, keeps path', () {
      expect(
        LogMask.url('GET', '/hms-token?roomId=abc&role=member'),
        'GET /hms-token [params hidden]',
      );
      expect(LogMask.url('POST', '/auth/login'), 'POST /auth/login');
    });
  });
}
