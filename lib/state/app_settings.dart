import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idiomas destino que el usuario puede elegir en la configuración.
class TranslationLanguage {
  const TranslationLanguage(this.code, this.label);

  /// Código ISO que entiende Google Translate (`tl`), p. ej. `es`.
  final String code;

  /// Nombre mostrado en el desplegable (en inglés, como la interfaz).
  final String label;
}

/// Idiomas a los que se puede traducir la palabra o el texto consultado.
///
/// No controlan el idioma de la app (siempre en inglés): solo a qué idioma se
/// traduce lo que el usuario toca o selecciona.
const List<TranslationLanguage> kTranslationLanguages = <TranslationLanguage>[
  TranslationLanguage('en', 'English'),
  TranslationLanguage('es', 'Spanish'),
  TranslationLanguage('fr', 'French'),
  TranslationLanguage('de', 'German'),
  TranslationLanguage('it', 'Italian'),
  TranslationLanguage('pt', 'Portuguese'),
  TranslationLanguage('ru', 'Russian'),
  TranslationLanguage('ja', 'Japanese'),
  TranslationLanguage('ko', 'Korean'),
  TranslationLanguage('zh-CN', 'Chinese (Simplified)'),
  TranslationLanguage('ar', 'Arabic'),
  TranslationLanguage('hi', 'Hindi'),
];

/// Etiqueta legible de un código de idioma destino.
String translationLanguageLabel(String code) {
  for (final language in kTranslationLanguages) {
    if (language.code == code) return language.label;
  }
  return code;
}

/// Definición de un ajuste: su clave, valor por defecto y normalizador.
class SettingDef<T> {
  const SettingDef({
    required this.key,
    required this.defaultValue,
    this.persist = true,
    this.normalize,
  });

  final String key;
  final T defaultValue;
  final bool persist;
  final T Function(T value)? normalize;

  T clean(T value) => normalize?.call(value) ?? value;
}

/// Acota el tamaño de fuente a un rango legible en pantalla.
double _clampFontSize(double size) => size.clamp(12.0, 48.0);

/// Catálogo de ajustes de MDLector.
///
/// Son exactamente los tres del lector de referencia: tamaño de letra, tema
/// oscuro y traductor (idioma destino).
abstract final class Settings {
  static const SettingDef<double> fontSize = SettingDef<double>(
    key: 'ui.fontSize',
    defaultValue: 18,
    normalize: _clampFontSize,
  );

  static const SettingDef<bool> themeIsDark = SettingDef<bool>(
    key: 'ui.themeIsDark',
    defaultValue: false,
  );

  /// Código del idioma al que se traduce la palabra o el texto consultado.
  static const SettingDef<String> translationTarget = SettingDef<String>(
    key: 'ui.translationTarget',
    defaultValue: 'es',
  );

  static const List<SettingDef<dynamic>> all = <SettingDef<dynamic>>[
    fontSize,
    themeIsDark,
    translationTarget,
  ];
}

/// Valores actuales de los ajustes (inmutable).
class AppSettings {
  const AppSettings(this._values);

  final Map<String, Object?> _values;

  T get<T>(SettingDef<T> def) => (_values[def.key] as T?) ?? def.defaultValue;

  AppSettings withValue<T>(SettingDef<T> def, T value) =>
      AppSettings({..._values, def.key: value});
}

/// Ajustes de interfaz persistidos entre sesiones.
final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);

/// Preferencias persistentes (`shared_preferences`). Se sobreescribe en
/// `main` con la instancia ya cargada.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main().',
  ),
);

/// Carga, aplica y persiste los ajustes.
class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final values = <String, Object?>{};
    for (final def in Settings.all) {
      final raw = prefs.get(def.key);
      if (raw != null) values[def.key] = raw;
    }
    return AppSettings(values);
  }

  /// Cambia un ajuste y, si es persistente, lo guarda.
  void set<T>(SettingDef<T> def, T value) {
    final next = def.clean(value);
    state = state.withValue(def, next);
    if (def.persist) _persist(def.key, next);
  }

  /// Devuelve un ajuste a su valor por defecto.
  void reset<T>(SettingDef<T> def) => set(def, def.defaultValue);

  void _persist(String key, Object? value) {
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = switch (value) {
      final bool v => prefs.setBool(key, v),
      final double v => prefs.setDouble(key, v),
      final int v => prefs.setInt(key, v),
      final String v => prefs.setString(key, v),
      _ => Future<bool>.value(false),
    };
    saved.ignore();
  }
}
