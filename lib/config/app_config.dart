/// Configuration globale de l'application.
class AppConfig {
  AppConfig._();

  /// Active la carte NATIVE Google Maps (vraie 3D / tilt) sur Android & iOS.
  ///
  /// Tant que c'est `false`, l'app utilise flutter_map partout (web + mobile),
  /// donc aucune cle n'est requise et rien ne casse.
  ///
  /// POUR ACTIVER LA 3D NATIVE :
  /// 1. Obtenir une cle "Maps SDK for Android" et/ou "Maps SDK for iOS"
  ///    sur https://console.cloud.google.com (activer le billing).
  /// 2. Coller la cle :
  ///    - Android : android/app/src/main/AndroidManifest.xml
  ///      <meta-data android:name="com.google.android.geo.API_KEY"
  ///                 android:value="VOTRE_CLE_ANDROID"/>
  ///    - iOS : ios/Runner/AppDelegate.swift
  ///      GMSServices.provideAPIKey("VOTRE_CLE_IOS")
  /// 3. Passer ce flag a `true` et relancer l'app sur un device/emulateur.
  ///
  /// NB : sur le Web, on garde flutter_map (la 3D Google Maps n'existe pas sur
  /// web) ; ce flag n'a donc d'effet que sur mobile.
  static const bool useNativeGoogleMaps = false;
}
