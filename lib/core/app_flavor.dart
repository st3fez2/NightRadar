enum AppFlavor { prod, demo }

class AppFlavorConfig {
  static const _flavorName = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'prod',
  );

  static const _publicAppUrl = String.fromEnvironment(
    'PUBLIC_APP_URL',
    defaultValue: '',
  );

  static AppFlavor get flavor {
    return _flavorName == 'demo' ? AppFlavor.demo : AppFlavor.prod;
  }

  static bool get isDemo => flavor == AppFlavor.demo;

  static bool get allowMutations => !isDemo;

  static String get appTitle => isDemo ? 'NightRadar Demo' : 'NightRadar';

  static String get modeLabel => isDemo ? 'DEMO' : '';

  static String get defaultPublicAppUrl {
    if (_publicAppUrl.isNotEmpty) {
      return _publicAppUrl;
    }

    return isDemo
        ? 'https://st3fez2.github.io/NightRadar/demo/'
        : 'https://st3fez2.github.io/NightRadar/';
  }

  static String get alternativePublicAppUrl {
    return isDemo
        ? 'https://st3fez2.github.io/NightRadar/'
        : 'https://st3fez2.github.io/NightRadar/demo/';
  }

  static String get alternativeCtaLabel {
    return isDemo ? 'Apri la versione attiva' : 'Apri la demo guidata';
  }

  static String get readonlyMessage =>
      'Questa e una demo read-only: puoi esplorare flussi e account demo, ma per creare eventi, liste e prenotazioni usa la versione attiva.';
}
