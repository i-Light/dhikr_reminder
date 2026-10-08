import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/requests/data/proof_of_work.dart';
import 'package:dhikr_reminder/features/requests/domain/dhikr_request.dart';
import 'package:dhikr_reminder/features/requests/domain/request_rules.dart';
import 'package:flutter_test/flutter_test.dart';

DhikrRequest _request(String text, {RequestStatus status = RequestStatus.pending}) =>
    DhikrRequest(
      localId: 'r$text',
      text: text,
      createdAt: DateTime(2026, 10, 8),
      status: status,
    );

void main() {
  group('cleanRequestText', () {
    test('takes out control and direction characters and tidies spacing', () {
      final dirty = 'اللهم${String.fromCharCode(0x202E)}  إني\u0000 أسألك${String.fromCharCode(0x200F)} علما\r\n\r\n\r\n\r\nنافعا';
      expect(cleanRequestText(dirty), 'اللهم إني أسألك علما\n\nنافعا');
    });
  });

  group('checkRequestText', () {
    test('accepts a dhikr, bare or vowelled', () {
      expect(checkRequestText('اللهم إني أسألك علما نافعا'), isNull);
      expect(
        checkRequestText('اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا'),
        isNull,
      );
    });

    test('says why not', () {
      expect(checkRequestText('اللهم'), RequestTextProblem.tooShort);
      expect(checkRequestText('اللهم ' * 120), RequestTextProblem.tooLong);
      expect(checkRequestText('\n' * 13 + 'اللهم اغفر لي ذنبي'),
          RequestTextProblem.tooLong);
      expect(checkRequestText('please add this to the library'),
          RequestTextProblem.notArabic);
      expect(checkRequestText('اللهم اغفر لي https://x.example'),
          RequestTextProblem.hasLink);
      expect(checkRequestText('اللهم <b>اغفر</b> لي ذنبي'),
          RequestTextProblem.hasLink);
      expect(checkRequestText('اللهم ااااااااا اغفر لي'),
          RequestTextProblem.repeated);
    });

    test('long vowelled text is judged by its words, not its marks', () {
      // 200 letters with a vowel on each is 400 characters.
      final vowelled = 'اَللّٰهُ ' * 25;
      expect(checkRequestText(vowelled), isNull);
    });
  });

  group('cleanRequestSource', () {
    test('is null for nothing and one line otherwise', () {
      expect(cleanRequestSource('   '), isNull);
      expect(cleanRequestSource('رواه\nمسلم'), 'رواه مسلم');
      expect(cleanRequestSource('ا' * 300)!.length, requestSourceMax);
    });

    test('a link in the source is a problem', () {
      expect(requestSourceHasLink('انظر https://x.example'), isTrue);
      expect(requestSourceHasLink('رواه مسلم'), isFalse);
      expect(requestSourceHasLink(null), isFalse);
    });
  });

  group('findInLibrary', () {
    test('finds a dhikr the library has, however it is spelled', () {
      final item = dhikrLibrary.firstWhere((i) => i.text.length > 30);
      expect(findInLibrary(item.text)?.id, item.id);
      expect(findInLibrary(item.text.replaceAll('ة', 'ه'))?.id, item.id);
    });

    test('finds a request that is part of a longer entry', () {
      final item = dhikrLibrary.firstWhere((i) => i.text.length > 120);
      final part = item.text.substring(10, 70);
      expect(findInLibrary(part), isNotNull);
    });

    test('finds nothing for a short phrase that is only part of an entry', () {
      expect(findInLibrary('اللهم اغفر'), isNull);
    });

    test('finds nothing for words the library does not have', () {
      expect(findInLibrary('كلمات لا وجود لها في الأذكار أبدا قطعا'), isNull);
    });
  });

  group('findOwnRequest', () {
    test('matches the same words and ignores a declined request', () {
      final mine = [
        _request('اللهم إني أسألك علما نافعا'),
        _request('ربنا آتنا في الدنيا حسنة', status: RequestStatus.declined),
      ];
      expect(findOwnRequest('اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا', mine),
          mine.first);
      expect(findOwnRequest('ربنا آتنا في الدنيا حسنة', mine), isNull);
      expect(findOwnRequest('شيء آخر تماما', mine), isNull);
    });
  });

  group('proof of work', () {
    test('holds when the hash has enough leading zero bits', () {
      var counter = 0;
      while (!proofHolds('challenge', 'install', counter, 10)) {
        counter++;
      }
      expect(proofHolds('challenge', 'install', counter, 10), isTrue);
      expect(proofHolds('challenge', 'someone else', counter, 10), isFalse,
          reason: 'a solution belongs to one install');
      expect(proofHolds('challenge', 'install', counter, 0), isTrue);
    });

    test('solveProofOfWork finds a counter that holds', () async {
      final counter = await solveProofOfWork(
        challenge: '1800000000.abcdefghijklmnop.sig',
        install: 'i' * 43,
        bits: 8,
      );
      expect(
        proofHolds('1800000000.abcdefghijklmnop.sig', 'i' * 43, counter, 8),
        isTrue,
      );
    });
  });

  group('DhikrRequest', () {
    test('survives a JSON round trip', () {
      final request = DhikrRequest(
        localId: 'r1',
        serverId: 'abc',
        text: 'اللهم اغفر لي',
        source: 'رواه مسلم',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1800000000000),
        status: RequestStatus.declined,
        reason: DeclineReason.unclear,
        libraryId: 'd123',
        shippedIn: '0.1.4',
        votes: 3,
        unseen: true,
      );
      expect(DhikrRequest.tryFromJson(request.toJson()), request);
    });

    test('a damaged entry reads as null instead of breaking the list', () {
      expect(DhikrRequest.tryFromJson(null), isNull);
      expect(DhikrRequest.tryFromJson({'localId': 5}), isNull);
      expect(
        DhikrRequest.tryFromJson({'localId': 'a', 'text': 'b', 'createdAt': 1})
            ?.status,
        RequestStatus.pending,
      );
    });

    test('open and finished statuses', () {
      expect(RequestStatus.queued.isOpen, isTrue);
      expect(RequestStatus.inProgress.isOpen, isTrue);
      expect(RequestStatus.done.isFinished, isTrue);
      expect(RequestStatus.declined.isFinished, isTrue);
    });
  });
}
