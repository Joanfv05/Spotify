# Spotify Flutter Project

Este proyecto es una aplicación Flutter que replica características de Spotify, diseñada para funcionar con versiones modernas de las herramientas de desarrollo Android.

## 📋 Requisitos previos

Antes de comenzar, asegúrate de tener instalado:

- **Flutter** (última versión estable)
  ```bash
  flutter --version
  ```
  Recomendado: 3.22.0 o superior

- **Java 17 JDK**
  ```bash
  java -version
  ```
  Debe mostrar: `openjdk version "17.x.x"`

- **Android Studio** (recomendado) o Visual Studio Code
- **Android SDK** con API 34 (Android 14) o superior
- **Dispositivo Android** o emulador configurado

## 🚀 Configuración inicial

### 1. Clonar el repositorio
```bash
git clone <url-del-repositorio>
cd spotify-flutter
```

### 2. Verificar configuración de Flutter
```bash
flutter doctor
```
Asegúrate de que todas las comprobaciones muestren ✅ (especialmente Android toolchain).

### 3. Instalar dependencias
```bash
flutter pub get
```

### 4. Configurar variables de entorno (si es necesario)
Asegúrate de que `JAVA_HOME` apunte a tu instalación de Java 17:
- **Windows:**
  ```bash
  setx JAVA_HOME "C:\Program Files\Java\jdk-17"
  ```
- **macOS/Linux:**
  ```bash
  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
  ```

## 🔧 Configuración de Android

### Estructura de versiones actual:
- **Gradle Wrapper:** 8.7
- **Android Gradle Plugin (AGP):** 8.6.0
- **Kotlin:** 2.1.0
- **Compile SDK:** 34
- **Min SDK:** 24

### Si necesitas actualizar:

#### 1. Actualizar Gradle Wrapper:
Edita `android/gradle/wrapper/gradle-wrapper.properties`:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-all.zip
```

#### 2. Actualizar AGP y Kotlin:
Edita `android/build.gradle`:
```gradle
buildscript {
    ext.kotlin_version = '2.1.0'
    dependencies {
        classpath 'com.android.tools.build:gradle:8.6.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

#### 3. Actualizar configuración del proyecto:
Edita `android/app/build.gradle`:
```gradle
android {
    compileSdk 34
    
    defaultConfig {
        minSdk 24
        targetSdk 34
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = '17'
    }
}
```

## 🏃 Ejecutar la aplicación

### En modo desarrollo:
```bash
# Ejecutar en dispositivo conectado
flutter run

# Ejecutar en emulador específico
flutter run -d emulator-5554

# Ejecutar con hot reload
flutter run --hot
```

### Si encuentras advertencias de dependencias:
```bash
# Opción temporal para ignorar validaciones de build
flutter run --android-skip-build-dependency-validation
```

### Build para producción:
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

## 📁 Estructura del proyecto
```
spotify-flutter/
├── android/              # Configuración específica de Android
├── ios/                  # Configuración específica de iOS
├── lib/                  # Código fuente principal
│   ├── main.dart        # Punto de entrada
│   ├── screens/         # Pantallas de la aplicación
│   ├── widgets/         # Widgets reutilizables
│   ├── models/          # Modelos de datos
│   ├── services/        # Servicios y APIs
│   └── utils/           # Utilidades y helpers
├── assets/              # Recursos (imágenes, fuentes, etc.)
├── test/                # Tests unitarios y de widget
└── pubspec.yaml         # Dependencias y configuración del proyecto
```

## 📦 Dependencias principales
- **http:** Para peticiones a APIs
- **provider:** Para gestión de estado
- **audioplayers:** Para reproducción de audio
- **cached_network_image:** Para caché de imágenes
- **shared_preferences:** Para almacenamiento local
- **flutter_dotenv:** Para variables de entorno

## 🧪 Testing
```bash
# Ejecutar tests unitarios
flutter test

# Ejecutar tests de integración
flutter test integration_test/

# Generar cobertura de código
flutter test --coverage
```

## 🔍 Troubleshooting

### Problema: Error de versión de Java
```
> Failed to apply plugin 'com.android.internal.application'.
> Android Gradle plugin requires Java 17 to run. You are currently using Java 11.
```
**Solución:**
1. Verifica tu versión de Java: `java -version`
2. Configura `JAVA_HOME` para que apunte a JDK 17
3. En Android Studio: File → Settings → Build, Execution, Deployment → Build Tools → Gradle → Gradle JDK → Selecciona JDK 17

### Problema: Gradle no compatible
```
Minimum supported Gradle version is X.X. Current version is Y.Y
```
**Solución:**
Actualiza Gradle Wrapper:
```bash
cd android
./gradlew wrapper --gradle-version 8.7
```

### Problema: Emulador lento
```bash
# Habilita aceleración por hardware
flutter emulators --launch <nombre_emulador> --enable-software-rendering
```

## 📚 Recursos útiles

- [Documentación oficial de Flutter](https://flutter.dev/docs)
- [Flutter Cookbook](https://flutter.dev/docs/cookbook)
- [Pub.dev - Paquetes Flutter](https://pub.dev)
- [Dart Documentation](https://dart.dev/guides)

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## ✉️ Contacto

Joan - [@joaanferre](https://www.instagram.com/joaanferre) - joanferre123@email.com

Link del proyecto: [https://github.com/Joanfv05/Spotify.git](https://github.com/Joanfv05/Spotify.git)

---

## ⚠️ Notas importantes

- Este proyecto requiere **Java 17** específicamente
- Las advertencias sobre versiones de Gradle/AGP son preventivas y no bloquean la compilación
- Mantén las dependencias actualizadas regularmente
- Para producción, asegúrate de usar `--release` en los builds

## 🔄 Actualizaciones futuras

Para mantener el proyecto actualizado con Flutter:

```bash
# Actualizar Flutter
flutter upgrade

# Actualizar dependencias
flutter pub upgrade

# Actualizar paquetes a última versión
flutter pub outdated
flutter pub upgrade --major-versions
```

---

**¡Listo para comenzar!** 🎵🎧

Si encuentras algún problema, consulta la sección de Troubleshooting o abre un issue en el repositorio.