# Dilexit: Flutter Aptos Wallet 🚀

Dilexit es una wallet avanzada para la blockchain de Aptos desarrollada en Flutter, diseñada con una arquitectura limpia y potenciada por Inteligencia Artificial Generativa. Es un proyecto de código abierto enfocado en la seguridad, la extensibilidad y la facilidad de uso, preparado para su distribución en **F-Droid**.

## 🧠 Dilexit AI Assistant (Agentic UI)

Dilexit integra un asistente de IA de última generación basado en el **GenUI SDK** y **Gemini 1.5 Flash**. A diferencia de los chatbots tradicionales, Dilexit AI es un **Agente Activo** que puede razonar e interactuar con la wallet en tiempo real.

### 🛠️ Capacidades del Agente (Agentic Loop)
El asistente utiliza un "Agentic Loop" con **Tool Calling** para realizar tareas complejas:
*   **Consulta de Balances:** El agente puede verificar tus saldos de APT y Fungible Assets (tokens) directamente en la blockchain.
*   **Análisis de Actividad:** Puede leer tus transacciones recientes y explicarte qué sucedió en lenguaje natural.
*   **Gestión de Dirección:** Sabe quién eres y puede mostrarte tu dirección pública cuando la necesites.
*   **UI Generativa (GenUI):** El agente puede responder generando widgets dinámicos (tarjetas de balance, formularios, listas) que se renderizan de forma nativa en la app.

### 🔐 Seguridad y Privacidad
*   **Variables de Entorno:** Las llaves de API se gestionan de forma segura mediante `flutter_dotenv`.
*   **Privacidad:** El asistente solo accede a los datos de la wallet cuando el usuario lo solicita explícitamente durante la sesión.

## 🛠️ Ecosistema MCP (Herramientas de Desarrollo)

Este proyecto utiliza el **Model Context Protocol (MCP)** para acelerar el desarrollo:
1.  **Dart MCP Server:** Servidor oficial de Flutter/Dart para análisis profundo de código.
2.  **Aptos Pro Tools:** Servidor personalizado en `tool/aptos_mcp_server.dart` que permite a los agentes de IA auditar contratos Move, consultar el ledger y generar keypairs de prueba.

## 📦 Estándares de F-Droid (FOSS Ready)
El proyecto ha sido optimizado para cumplir con los estándares de **F-Droid**:
*   **100% Código Abierto:** Licencia MIT.
*   **Sin Blobs Propietarios:** No depende de servicios de Google Play o Firebase nativo. Utiliza el SDK puro de Dart para IA.
*   **Identidad Única:** Package name configurado como `com.dilexit.wallet`.
*   **Reproducibilidad:** Documentación clara y archivo `.env.example` para compilaciones locales.

## 📂 Estructura del Proyecto
*   `lib/domain`: Entidades y casos de uso (Arquitectura Limpia).
*   `lib/data`: Repositorios y clientes blockchain (Aptos RPC & Indexer).
*   `lib/presentation`: 
    *   `providers/`: Gestión de estado con Provider.
    *   `screens/`: Pantallas de la app, incluyendo la nueva `ai_assistant_screen.dart`.
*   `tool/`: Herramientas de automatización y servidores MCP.

## 🚀 Configuración de Desarrollo

### Requisitos
*   Flutter SDK ^3.11.4
*   Dart SDK ^3.11.4
*   Gemini API Key ([Obtenla aquí](https://aistudio.google.com/app/apikey))

### Instalación
1.  Clona el repositorio.
2.  Copia el archivo de ejemplo de variables de entorno:
    ```bash
    cp .env.example .env
    ```
3.  Edita `.env` y pega tu `GEMINI_API_KEY`.
4.  Instala las dependencias:
    ```bash
    flutter pub get
    ```
5.  Ejecuta la aplicación:
    ```bash
    flutter run
    ```

## 📜 Licencia
Este proyecto está bajo la Licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.

---
*Desarrollado con ❤️ para el ecosistema Aptos y la comunidad de software libre.*
