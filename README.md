# Dilexit: Flutter Aptos Wallet 🚀

Dilexit is an advanced wallet for the Aptos blockchain developed in Flutter, designed with clean architecture and powered by Generative Artificial Intelligence. It is an open-source project focused on security, extensibility, and ease of use, ready for distribution on **F-Droid**.

## 🧠 Dilexit AI Assistant (Agentic UI)

Dilexit integrates a state-of-the-art AI assistant based on the **GenUI SDK** and **Gemini 1.5 Flash**. Unlike traditional chatbots, Dilexit AI is an **Active Agent** that can reason and interact with the wallet in real-time.

### 🛠️ Agent Capabilities (Agentic Loop)
The assistant uses an "Agentic Loop" with **Tool Calling** to perform complex tasks:
*   **Balance Inquiries:** The agent can check your APT and Fungible Assets (tokens) balances directly on the blockchain.
*   **Activity Analysis:** It can read your recent transactions and explain what happened in natural language.
*   **Address Management:** It knows who you are and can show your public address whenever you need it.
*   **Generative UI (GenUI):** The agent can respond by generating dynamic widgets (balance cards, forms, lists) that are rendered natively in the app.

### 🔐 Security and Privacy
*   **Environment Variables:** API keys are securely managed using `flutter_dotenv`.
*   **Privacy:** The assistant only accesses wallet data when explicitly requested by the user during the session.

## 🛠️ MCP Ecosystem (Development Tools)

This project uses the **Model Context Protocol (MCP)** to accelerate development:
1.  **Dart MCP Server:** Official Flutter/Dart server for deep code analysis.
2.  **Aptos Pro Tools:** Custom server in `tool/aptos_mcp_server.dart` that allows AI agents to audit Move contracts, query the ledger, and generate test keypairs.

## 📦 F-Droid Standards (FOSS Ready)
The project has been optimized to comply with **F-Droid** standards:
*   **100% Open Source:** MIT License.
*   **No Proprietary Blobs:** Does not depend on Google Play services or native Firebase. Uses the pure Dart SDK for AI.
*   **Unique Identity:** Package name configured as `com.dilexit.wallet`.
*   **Reproducibility:** Clear documentation and `.env.example` file for local builds.

## 📂 Project Structure
*   `lib/domain`: Entities and use cases (Clean Architecture).
*   `lib/data`: Repositories and blockchain clients (Aptos RPC & Indexer).
*   `lib/presentation`: 
    *   `providers/`: State management with Provider.
    *   `screens/`: App screens, including the new `ai_assistant_screen.dart`.
*   `tool/`: Automation tools and MCP servers.

## 🚀 Development Setup

### Requirements
*   Flutter SDK ^3.11.4
*   Dart SDK ^3.11.4
*   Gemini API Key ([Get it here](https://aistudio.google.com/app/apikey))

### Installation
1.  Clone the repository.
2.  Copy the environment variables example file:
    ```bash
    cp .env.example .env
    ```
3.  Edit `.env` and paste your `GEMINI_API_KEY`.
4.  Install dependencies:
    ```bash
    flutter pub get
    ```
5.  Run the application:
    ```bash
    flutter run
    ```

## 📜 License
This project is under the MIT License. See the [LICENSE](LICENSE) file for more details.

---
*Developed with ❤️ for the Aptos ecosystem and the free software community.*
