part of 'dio_repository.dart';

final dioRepositoryProvider = Provider<DioRepository>((ref) {
  final environment = ref.watch(environmentProvider);
  final repository = DioRepositoryImpl(
    baseUrl: environment.isLive ? environment.apiBaseUrl : null,
  );
  ref.onDispose(repository.close);
  return repository;
});
