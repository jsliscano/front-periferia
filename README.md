# Prueba Periferia Flutter 

Aplicación cliente Flutter para gestión de tareas empresariales, integrada con backend Spring Boot (API REST + autenticación JWT).

## Resumen ejecutivo

Este frontend permite autenticar usuarios, administrar tareas (crear, consultar, filtrar, actualizar y eliminar) y recibir alertas de vencimiento. Prioriza una interfaz clara, feedback consistente y una arquitectura mantenible orientada a features.

## Objetivos

- Consumir la API REST del backend de forma confiable
- Gestionar sesión mediante token JWT
- Ofrecer un flujo operativo completo de tareas
- Notificar tareas vencidas o próximas a vencer
- Presentar errores y confirmaciones de forma uniforme

## Stack tecnológico

| Componente | Tecnología |
|---|---|
| Framework | Flutter (Dart) |
| Comunicación HTTP | http |
| Autenticación | JWT (Authorization: Bearer token) |
| Notificaciones locales | flutter_local_notifications + timezone |
| UI | Material Design |
| Arquitectura | Feature-first / Clean Architecture ligera |



### Capas por feature

- **Presentation:** pantallas, widgets y flujo de UI
- **Domain:** entidades y contratos de repositorio
- **Data:** datasources remotos, modelos y mapeo a entidades

## Alcance funcional

### Autenticación

- Registro de usuario
- Inicio de sesión
- Sesión en memoria durante el ciclo de vida de la app
- Envío de JWT en operaciones protegidas

### Gestión de tareas

- Listado paginado
- Filtrado por estado (Todas / Pendiente / Completada)
- Búsqueda local sobre la página visible
- Creación de tarea
- Edición de tarea
- Eliminación de tarea con confirmación

### Notificaciones y alertas

- Campana en AppBar con contador
- Panel centrado de tareas vencidas o con vencimiento en ≤ 1 día
- Navegación directa a la tarea seleccionada desde el panel
- Recordatorios locales (día anterior y día de vencimiento)

### Experiencia de usuario

- Diálogos de éxito, error, información y confirmación (AppDialog)
- Mensajes de feedback alineados a respuestas del backend
- Interfaz simple, funcional y consistente

## Integración con backend

### Base URL

| Entorno | URL |
|---|---|
| Web / Windows | http://localhost:8181 |
| Emulador Android | http://10.0.2.2:8181 |
| Dispositivo físico | http://IP-LAN-PC:8181 vía --dart-define=API_BASE_URL=... |

### Endpoints consumidos

| Método | Endpoint | Descripción |
|---|---|---|
| POST | /api/users/register | Registro |
| POST | /api/users/login | Autenticación |
| GET | /api/tasks | Listado (filtros y paginación) |
| POST | /api/tasks | Creación |
| PUT | /api/tasks/{id} | Actualización |
| DELETE | /api/tasks/{id} | Eliminación |

### Seguridad

Las operaciones de tareas envían:

Authorization: Bearer <token>

## Requisitos

- Flutter SDK instalado y configurado
- Backend Spring Boot disponible en el puerto 8181
- Para Android: Android SDK / Android Studio
- Misma red Wi-Fi entre PC y dispositivo físico (si se prueba con APK)

## Getting Started

### 1. Instalar dependencias

flutter pub get

### 2. Ejecutar en Chrome

flutter run -d chrome

### 3. Ejecutar en Android (emulador)

flutter run -d android

### 4. Generar APK para pruebas

flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.16:8181

Artefacto generado:

build/app/outputs/flutter-apk/app-release.apk

Nota: reemplazar 192.168.1.16 por la IP local vigente del equipo.

## Configuración Android relevante

- Permisos de Internet y notificaciones habilitados
- Tráfico HTTP permitido en ambiente de pruebas (usesCleartextTraffic=true)
- Core Library Desugaring habilitado (requerido por flutter_local_notifications) en android/app/build.gradle.kts:
  - isCoreLibraryDesugaringEnabled = true
  - dependencia com.android.tools:desugar_jdk_libs:2.1.4
  - Java 17 como source/target compatibility

## Cumplimiento de requerimientos

| Requerimiento | Estado | Evidencia |
|---|---|---|
| Pantalla de Registro/Login | Cumple | Módulo features/auth |
| Lista de tareas con filtrado por estado | Cumple | TaskListPage + consulta API |
| Crear/Editar tarea | Cumple | TaskFormPage + POST/PUT |
| Eliminar tarea | Cumple | Confirmación + DELETE |
| Consumo API REST | Cumple | ApiClient / ApiConfig |
| Manejo de token JWT | Cumple | SessionStore + header Authorization |
| Interfaz simple y funcional | Cumple | Material UI + flujos CRUD |
| Notificaciones locales | Cumple | TaskNotificationService + campana |
| Manejo de errores y feedback | Cumple | AppDialog + ApiException |

## Limitaciones conocidas (ambiente de prueba)

- La sesión JWT no persiste tras reiniciar la aplicación (almacenamiento en memoria)
- En navegador web, las notificaciones del sistema tienen soporte limitado; el panel in-app cubre la experiencia de alerta
- La generación de APK requiere recursos de memoria suficientes en el equipo de compilación

## Criterios de aceptación

1. Un usuario puede registrarse e iniciar sesión
2. Tras autenticarse, visualiza su listado de tareas
3. Puede filtrar por estado y paginar resultados
4. Puede crear, editar y eliminar tareas con confirmación/feedback
5. La campana muestra solo tareas vencidas o con vencimiento en 1 día
6. Al seleccionar una tarea desde la campana, se abre su edición
7. Ante fallos de API, la aplicación muestra mensajes claros al usuario

## Conclusión

El frontend Flutter prueba_periferia cubre de manera adecuada los requerimientos funcionales y técnicos de la prueba: autenticación JWT, integración REST, CRUD de tareas, filtrado, notificaciones locales y feedback de usuario, con una estructura preparada para mantenimiento y evolución.

