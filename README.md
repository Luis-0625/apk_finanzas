# Finanzas COP — Compilar APK

## 1. Requisitos (una sola vez)
- Flutter SDK instalado y en el PATH
- Android Studio (SDK + licencias): `flutter doctor --android-licenses`
- Verifica todo con: `flutter doctor`

## 2. Crear el proyecto y copiar el código
```bash
flutter create --org com.luis --project-name finanzas_cop finanzas_cop
cd finanzas_cop
flutter pub add provider intl shared_preferences
```
Borra `lib/main.dart` generado y copia dentro de `finanzas_cop/` la carpeta `lib/` de este paquete (reemplazándola).

## 3. Probar en el celular (USB con depuración activada)
```bash
flutter run --release
```

## 4. Generar el APK
```bash
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
```
APK listo (celulares modernos, 64 bits):
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

Un solo APK universal (más pesado):
```bash
flutter build apk --release
```
→ `build/app/outputs/flutter-apk/app-release.apk`

## 5. Instalar
```bash
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```
O pasa el .apk al celular y ábrelo (permite "instalar apps desconocidas").

## Nombre de la app en el launcher (opcional)
En `android/app/src/main/AndroidManifest.xml` cambia `android:label="finanzas_cop"` por `android:label="Finanzas COP"`.
