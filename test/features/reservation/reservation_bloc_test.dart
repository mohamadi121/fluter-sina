import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/reservation/blocs/reservation_bloc.dart';
import 'package:asood/features/reservation/data/reservation_api_service.dart';

class _FakeReservationApi implements ReservationApiService {
  dynamic servicesRes;
  dynamic specialistsRes;
  dynamic reserveTimesRes;
  dynamic createRes;
  dynamic mineRes;
  Map<String, dynamic>? lastCreate;

  @override
  Future services(String marketId) async => servicesRes;

  @override
  Future reserveTimes(String serviceId) async => reserveTimesRes;

  @override
  Future myReservations() async => mineRes;

  @override
  Future createReservation({
    required String reserveTimeId,
    required String specialistId,
  }) async {
    lastCreate = {'reserve': reserveTimeId, 'specialist': specialistId};
    return createRes;
  }

  @override
  Future specialists(String serviceId) async => specialistsRes;

  @override
  DioClient get dioClient => throw UnimplementedError();
}

void main() {
  late _FakeReservationApi api;
  late ReservationBloc bloc;

  setUp(() {
    api = _FakeReservationApi();
    bloc = ReservationBloc(api: api);
  });

  tearDown(() => bloc.close());

  test('LoadServices maps services and clears reserve-times', () async {
    api.servicesRes = Success(
      code: 200,
      response: [
        {'id': 's1', 'name': 'اصلاح'},
      ],
    );

    bloc.add(const LoadServices('m1'));
    await bloc.stream.firstWhere((s) => s.status == ReservationStatus.loaded);

    expect(bloc.state.services.single['name'], 'اصلاح');
  });

  test('LoadReserveTimes maps times', () async {
    api.reserveTimesRes = Success(
      code: 200,
      response: [
        {'id': 't1', 'day': 'شنبه', 'start': '10:00'},
      ],
    );

    bloc.add(const LoadReserveTimes('s1'));
    await bloc.stream.firstWhere((s) => s.status == ReservationStatus.loaded);

    expect(bloc.state.reserveTimes.single['id'], 't1');
  });

  test('LoadSpecialists maps specialists and clears reserve-times', () async {
    api.reserveTimesRes = Success(
      code: 200,
      response: [
        {'id': 'old-time'},
      ],
    );
    bloc.add(const LoadReserveTimes('s1'));
    await bloc.stream.firstWhere(
      (s) => s.status == ReservationStatus.loaded && s.reserveTimes.isNotEmpty,
    );

    api.specialistsRes = Success(
      code: 200,
      response: [
        {'id': 'sp1', 'name': 'متخصص اول'},
      ],
    );

    bloc.add(const LoadSpecialists('s1'));
    await bloc.stream.firstWhere((s) => s.status == ReservationStatus.loaded);

    expect(bloc.state.specialists.single['id'], 'sp1');
    expect(bloc.state.reserveTimes, isEmpty);
  });

  test('CreateReservation sends reserve id and reaches booked', () async {
    api.createRes = Success(code: 201, response: {'id': 'r1'});

    bloc.add(const CreateReservation(reserveTimeId: 't1', specialistId: 'sp1'));
    await bloc.stream.firstWhere((s) => s.status == ReservationStatus.booked);

    expect(api.lastCreate, {'reserve': 't1', 'specialist': 'sp1'});
  });

  test('failure surfaces backend detail', () async {
    api.servicesRes = Failure(
      code: 400,
      errorResponse: 'Market Not Provided',
      kind: FailureKind.validation,
    );

    bloc.add(const LoadServices('m1'));
    await bloc.stream.firstWhere((s) => s.status == ReservationStatus.failure);

    expect(bloc.state.error, 'Market Not Provided');
  });
}
