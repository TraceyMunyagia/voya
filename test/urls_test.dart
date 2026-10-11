import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/utils/urls.dart';
import 'package:voya/core/utils/validators.dart';

void main() {
  group('Urls.normalise', () {
    test('adds https when the scheme is missing', () {
      expect(Urls.normalise('diani.com/book'), 'https://diani.com/book');
      expect(Urls.normalise('  www.example.co.ke  '), 'https://www.example.co.ke');
    });

    test('keeps http and https addresses', () {
      expect(Urls.normalise('http://a.com'), 'http://a.com');
      expect(Urls.normalise('https://a.com/x?y=1'), 'https://a.com/x?y=1');
    });

    test('rejects things that are not web addresses', () {
      expect(Urls.normalise(''), isNull);
      expect(Urls.normalise('hello'), isNull);
      expect(Urls.normalise('javascript:alert(1)'), isNull);
      expect(Urls.normalise('ftp://files.example.com'), isNull);
      expect(Urls.normalise('mailto:me@example.com'), isNull);
      expect(Urls.normalise('https://user:pw@example.com'), isNull);
    });
  });

  group('Validators', () {
    test('optionalUrl accepts empty and valid, rejects the rest', () {
      expect(Validators.optionalUrl(''), isNull);
      expect(Validators.optionalUrl('diani.com'), isNull);
      expect(Validators.optionalUrl('nope'), isNotNull);
    });

    test('amount accepts empty and numbers with separators', () {
      expect(Validators.amount(''), isNull);
      expect(Validators.amount('1,500'), isNull);
      expect(Validators.amount('1 500.50'), isNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount('-5'), isNotNull);
    });
  });
}