part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable { const SettingsEvent(); @override List<Object?> get props => []; }
class LoadSettingsEvent extends SettingsEvent { const LoadSettingsEvent(); }
class ChangeThemeModeEvent extends SettingsEvent { final String mode; const ChangeThemeModeEvent(this.mode); @override List<Object?> get props => [mode]; }
class ChangeLocaleEvent extends SettingsEvent { final String locale; const ChangeLocaleEvent(this.locale); @override List<Object?> get props => [locale]; }
class ChangeEnvironmentEvent extends SettingsEvent { final String environment; const ChangeEnvironmentEvent(this.environment); @override List<Object?> get props => [environment]; }
