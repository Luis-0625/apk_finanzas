# Inicio rápido

## Opción A: con Flutter instalado (VS Code)
1. Descomprime y abre la carpeta `finanzas_cop` en VS Code.
2. Terminal integrada:
   flutter create --org com.luis --project-name finanzas_cop .
   flutter pub get
3. Conecta el celular (depuración USB) y presiona F5, o:
   flutter run --release
4. APK: flutter build apk --release --split-per-abi
   -> build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

## Opción B: sin instalar nada (APK en la nube con GitHub)
1. Crea un repositorio en github.com y sube el contenido de esta carpeta (rama main).
2. Pestaña Actions -> "Build APK" -> Run workflow (o se ejecuta solo al subir).
3. Al terminar (5-10 min), entra a la ejecución y descarga el artefacto "finanzas-cop-apk".
4. Pasa el .apk (app-arm64-v8a-release.apk) al celular e instálalo.
