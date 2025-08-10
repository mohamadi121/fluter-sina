import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/ui/ui_status.dart';
import '../../data/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository repository;
  SettingsBloc(this.repository) : super(const SettingsState()) {
    on<LoadSettingsEvent>(_onLoad);
    on<ChangeThemeModeEvent>(_onChangeTheme);
    on<ChangeLocaleEvent>(_onChangeLocale);
    on<ChangeEnvironmentEvent>(_onChangeEnvironment);
  }

  Future<void> _onLoad(LoadSettingsEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    try {
      final theme = await repository.loadThemeMode();
      final locale = await repository.loadLocale();
      final env = await repository.loadEnvironment();
      emit(state.copyWith(
        status: const UiSuccess(),
        themeMode: theme ?? 'system',
        locale: locale ?? 'fa',
        environment: env ?? 'dev',
      ));
    } catch (e) {
      emit(state.copyWith(status: UiError(e.toString())));
    }
  }

  Future<void> _onChangeTheme(ChangeThemeModeEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    try {
      await repository.saveThemeMode(event.mode);
      emit(state.copyWith(status: const UiSuccess(), themeMode: event.mode));
    } catch (e) { emit(state.copyWith(status: UiError(e.toString()))); }
  }

  Future<void> _onChangeLocale(ChangeLocaleEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    try {
      await repository.saveLocale(event.locale);
      emit(state.copyWith(status: const UiSuccess(), locale: event.locale));
    } catch (e) { emit(state.copyWith(status: UiError(e.toString()))); }
  }

  Future<void> _onChangeEnvironment(ChangeEnvironmentEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    try {
      await repository.saveEnvironment(event.environment);
      // TODO: trigger re-init of networking layer / locator with new environment
      emit(state.copyWith(status: const UiSuccess(), environment: event.environment));
    } catch (e) { emit(state.copyWith(status: UiError(e.toString()))); }
  }
}
