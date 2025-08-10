part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final UiStatus status;
  final String themeMode; // system | light | dark
  final String locale; // fa | en
  final String environment; // dev | prod
  const SettingsState({this.status = const UiIdle(), this.themeMode = 'system', this.locale = 'fa', this.environment = 'dev'});

  SettingsState copyWith({UiStatus? status, String? themeMode, String? locale, String? environment}) => SettingsState(
    status: status ?? this.status,
    themeMode: themeMode ?? this.themeMode,
    locale: locale ?? this.locale,
    environment: environment ?? this.environment,
  );

  @override
  List<Object?> get props => [status, themeMode, locale, environment];
}
