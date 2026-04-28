import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:aptos/aptos.dart';
import 'package:aptos/coin_client.dart';

class AptosNetwork {
  final String name;
  final String fullnode;
  
  AptosNetwork(this.name, this.fullnode);
  
  static final mainnet = AptosNetwork('mainnet', 'https://fullnode.mainnet.aptoslabs.com/v1');
  static final testnet = AptosNetwork('testnet', 'https://fullnode.testnet.aptoslabs.com/v1');
  
  static AptosNetwork fromName(String name) {
    return name.toLowerCase() == 'mainnet' ? mainnet : testnet;
  }
}

void main() async {
  final serverInfo = Implementation(
    name: 'aptos_pro_tools',
    version: '4.0.0',
  );

  final server = McpServer(
    serverInfo,
    options: McpServerOptions(
      capabilities: ServerCapabilities(
        tools: ServerCapabilitiesTools(),
        resources: ServerCapabilitiesResources(),
        prompts: ServerCapabilitiesPrompts(),
        extensions: withMcpUiExtension(), // Habilitamos soporte para MCP Apps UI
      ),
    ),
  );

  const dashboardUri = 'ui://aptos/dashboard.html';

  // --- MCP APPS UI RESOURCES ---

  registerAppResource(
    server,
    'Aptos Wallet Dashboard',
    dashboardUri,
    const McpUiAppResourceConfig(
      description: 'Interfaz visual para el monitoreo de la wallet de Aptos',
      meta: {
        'ui': {
          'prefersBorder': true,
        },
      },
    ),
    (uri, [extra]) async {
      final client = AptosClient("https://fullnode.testnet.aptoslabs.com/v1");
      final info = await client.getLedgerInfo();
      
      return ReadResourceResult(
        contents: [
          TextResourceContents(
            uri: uri.toString(),
            mimeType: mcpUiResourceMimeType,
            text: '''
<!doctype html>
<html>
<head>
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 0; margin: 0; background: #0f172a; color: #f8fafc; }
    .container { max-width: 600px; margin: 20px auto; padding: 20px; }
    .card { background: #1e293b; border: 1px solid #334155; padding: 24px; border-radius: 16px; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.5); }
    .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
    .badge { background: #0ea5e9; color: white; padding: 4px 12px; border-radius: 9999px; font-size: 12px; font-weight: bold; text-transform: uppercase; }
    .label { color: #94a3b8; font-size: 14px; margin-bottom: 4px; }
    .value { font-size: 18px; font-weight: 600; color: #e2e8f0; }
    .balance-main { font-size: 48px; font-weight: 800; color: #38bdf8; margin: 12px 0; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 24px; border-top: 1px solid #334155; padding-top: 24px; }
    .footer { margin-top: 20px; text-align: center; color: #64748b; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="card">
      <div class="header">
        <div class="badge">Aptos Testnet</div>
        <div style="color: #22c55e; font-size: 12px;">● Connected</div>
      </div>
      
      <div class="label">Total Balance</div>
      <div class="balance-main">0.00 APT</div>
      
      <div class="grid">
        <div>
          <div class="label">Ledger Version</div>
          <div class="value">${info['ledger_version']}</div>
        </div>
        <div>
          <div class="label">Chain ID</div>
          <div class="value">${info['chain_id']}</div>
        </div>
        <div>
          <div class="label">Block Height</div>
          <div class="value">${info['block_height']}</div>
        </div>
        <div>
          <div class="label">Epoch</div>
          <div class="value">${info['epoch']}</div>
        </div>
      </div>
      
      <div class="footer">
        Dilexit Wallet v4.0.0 • Updated via MCP Tools
      </div>
    </div>
  </div>
</body>
</html>
''',
            meta: const McpUiResourceMeta(prefersBorder: true).toMeta(),
          ),
        ],
      );
    },
  );

  // --- TOOLS ---

  registerAppTool(
    server,
    'aptos_view_dashboard',
    McpUiAppToolConfig(
      description: 'Muestra un dashboard visual e interactivo de la wallet de Aptos.',
      meta: const {
        'ui': {
          'resourceUri': dashboardUri,
          'visibility': ['model', 'app'],
        },
      },
    ),
    (args, [extra]) async {
      return const CallToolResult(
        content: [
          TextContent(text: 'Abriendo el dashboard visual de Aptos...'),
          ResourceLink(
            uri: dashboardUri,
            name: 'Aptos Wallet Dashboard',
            mimeType: mcpUiResourceMimeType,
          ),
        ],
      );
    },
  );

  // Helper para obtener cliente según red
  AptosClient getClient(String network) => AptosClient(AptosNetwork.fromName(network).fullnode);

  // --- TOOLS ---

  server.registerTool(
    'aptos_get_balance',
    description: 'Obtiene el balance de APT de una dirección en Mainnet o Testnet.',
    inputSchema: ToolInputSchema(
      properties: {
        'address': JsonSchema.string(description: '0x...'),
        'network': JsonSchema.string(
          description: 'Red a consultar',
          enumValues: ['mainnet', 'testnet'],
          defaultValue: 'testnet',
        ),
      },
      required: ['address'],
    ),
    callback: (args, [extra]) async {
      try {
        final network = args['network'] as String? ?? 'testnet';
        final client = getClient(network);
        final balance = await CoinClient(client).checkBalance(args['address'] as String);
        final apt = balance / BigInt.from(100000000);
        return CallToolResult(
          content: [TextContent(text: 'Balance en $network: $apt APT ($balance octas)')],
        );
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Error: $e')]);
      }
    },
  );

  server.registerTool(
    'aptos_generate_keypair',
    description: 'Genera una nueva cuenta (Mnemónica, Privada, Pública, Dirección).',
    inputSchema: ToolInputSchema(properties: {}),
    callback: (args, [extra]) async {
      final mnemonic = AptosAccount.generateMnemonic();
      final account = AptosAccount.generateAccount(mnemonic);
      return CallToolResult(
        content: [
          TextContent(text: '--- NUEVA CUENTA APTOS ---\n'
                           'Dirección: ${account.address}\n'
                           'Mnemónica: $mnemonic\n'
                           'Llave Privada: ${account.privateKey}\n'
                           'Llave Pública: ${account.pubKey}')
        ],
      );
    },
  );

  // Herramienta de tarea larga con reporte de progreso
  server.registerTool(
    'long-task',
    description: 'Demuestra el reporte de progreso para tareas largas.',
    inputSchema: ToolInputSchema(properties: {}),
    callback: (args, [extra]) async {
      if (extra == null) {
        return const CallToolResult(
          isError: true,
          content: [TextContent(text: 'Error: Contexto extra no disponible para progreso.')],
        );
      }
      for (var i = 0; i < 100; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        await extra.sendProgress(
          i.toDouble(),
          total: 100,
          message: 'Procesando paso $i de 100...',
        );
      }
      return const CallToolResult(
        content: [TextContent(text: '¡Tarea larga completada con éxito!')],
      );
    },
  );

  // Herramienta de búsqueda compleja (Patrón Search-Database)
  server.registerTool(
    'aptos_search_events',
    description: 'Busca eventos específicos en la blockchain (transferencias, depósitos) con filtros avanzados.',
    inputSchema: ToolInputSchema(
      properties: {
        'address': JsonSchema.string(description: 'Dirección a investigar'),
        'event_type': JsonSchema.string(
          description: 'Tipo de evento (ej: 0x1::coin::DepositEvent)',
          defaultValue: '0x1::coin::WithdrawEvent',
        ),
        'filters': JsonSchema.object(
          properties: {
            'min_amount': JsonSchema.number(description: 'Monto mínimo en octas'),
            'network': JsonSchema.string(enumValues: ['mainnet', 'testnet']),
          },
        ),
        'limit': JsonSchema.integer(
          description: 'Cantidad máxima de resultados',
          minimum: 1,
          maximum: 100,
          defaultValue: 10,
        ),
      },
      required: ['address'],
    ),
    callback: (args, [extra]) async {
      final address = args['address'] as String;
      final limit = args['limit'] as int? ?? 10;
      final filters = args['filters'] as Map<String, dynamic>?;
      final network = filters?['network'] as String? ?? 'testnet';
      
      final client = getClient(network);
      
      // Aquí iría la lógica de consulta a la API de eventos de Aptos
      // Por ahora devolvemos un log estructurado del intento de búsqueda
      return CallToolResult(
        content: [
          TextContent(text: 'Buscando $limit eventos de tipo ${args['event_type']} para $address en $network...'),
          TextContent(text: 'Filtros aplicados: ${jsonEncode(filters)}'),
        ],
      );
    },
  );

  // --- RESOURCES ---

  // Estado de la red dinámico: aptos://mainnet/status o aptos://testnet/status
  server.registerResourceTemplate(
    'Network Status',
    ResourceTemplateRegistration('aptos://{network}/status', listCallback: null),
    null,
    (uri, vars, [extra]) async {
      final client = getClient(vars['network'] as String);
      final info = await client.getLedgerInfo();
      return ReadResourceResult(
        contents: [
          TextResourceContents(
            uri: uri.toString(),
            mimeType: 'application/json',
            text: jsonEncode(info),
          ),
        ],
      );
    },
  );

  // Info de cuenta dinámico: aptos://testnet/account/0x123...
  server.registerResourceTemplate(
    'Account Details',
    ResourceTemplateRegistration('aptos://{network}/account/{address}', listCallback: null),
    null,
    (uri, vars, [extra]) async {
      final client = getClient(vars['network'] as String);
      final account = await client.getAccount(vars['address'] as String);
      return ReadResourceResult(
        contents: [
          TextResourceContents(
            uri: uri.toString(),
            mimeType: 'application/json',
            text: jsonEncode(account),
          ),
        ],
      );
    },
  );

  // --- PROMPTS ---

  server.registerPrompt(
    'review-code',
    description: 'Genera una revisión de código profesional buscando calidad y bugs.',
    callback: (args, [extra]) async {
      return GetPromptResult(
        description: 'Review code for quality and best practices',
        messages: [
          PromptMessage(
            role: PromptMessageRole.user,
            content: TextContent(
              text: 'Por favor, revisa el siguiente código buscando:\n'
                    '- Calidad de código y legibilidad\n'
                    '- Mejores prácticas de Flutter/Dart o Move\n'
                    '- Posibles bugs o errores lógicos\n'
                    '- Problemas de seguridad',
            ),
          ),
        ],
      );
    },
  );

  server.registerPrompt(
    'audit-move-code',
    description: 'Analiza código Move para detectar vulnerabilidades comunes.',
    argsSchema: {
      'code': PromptArgumentDefinition(type: String, description: 'Código Move a auditar', required: true),
    },
    callback: (args, [extra]) async {
      return GetPromptResult(
        messages: [
          PromptMessage(
            role: PromptMessageRole.user,
            content: TextContent(text: 'Por favor, audita este código Move de Aptos buscando errores de reentrancia, gestión de recursos o vulnerabilidades de seguridad:\n\n${args['code']}'),
          ),
        ],
      );
    },
  );

  server.registerPrompt(
    'translate',
    description: 'Genera un prompt de traducción con tono específico.',
    argsSchema: {
      'target_language': PromptArgumentDefinition(
        type: String,
        description: 'Idioma al que traducir',
        required: true,
      ),
      'formality': PromptArgumentDefinition(
        type: String,
        description: 'Nivel de formalidad (casual, formal)',
        required: false,
      ),
    },
    callback: (args, [extra]) async {
      final language = args['target_language'] as String;
      final formality = args['formality'] as String? ?? 'neutral';

      return GetPromptResult(
        description: 'Traducción de texto a $language',
        messages: [
          PromptMessage(
            role: PromptMessageRole.user,
            content: TextContent(
              text: 'Traduce el siguiente texto al idioma $language '
                  'con un tono $formality:',
            ),
          ),
        ],
      );
    },
  );

  server.registerPrompt(
    'brainstorm',
    description: 'Inicia una sesión de lluvia de ideas sobre un tema.',
    argsSchema: {
      'topic': PromptArgumentDefinition(
        type: String,
        description: 'Tema sobre el que hacer brainstorm',
        required: true,
      ),
    },
    callback: (args, [extra]) async {
      final topic = args['topic'] as String;

      return GetPromptResult(
        messages: [
          PromptMessage(
            role: PromptMessageRole.user,
            content: TextContent(
              text: 'Generemos ideas creativas sobre: $topic',
            ),
          ),
          PromptMessage(
            role: PromptMessageRole.assistant,
            content: TextContent(
              text: '¡Excelente! Te ayudaré con el brainstorm. ¿Qué aspecto de $topic te interesa más?',
            ),
          ),
          PromptMessage(
            role: PromptMessageRole.user,
            content: TextContent(
              text: 'Me interesan particularmente las aplicaciones prácticas y la facilidad de uso.',
            ),
          ),
        ],
      );
    },
  );

  server.registerPrompt(
    'analyze-file',
    description: 'Analiza un archivo en profundidad.',
    argsSchema: {
      'file_uri': PromptArgumentDefinition(
        type: String,
        description: 'URI del archivo a analizar',
        required: true,
      ),
    },
    callback: (args, [extra]) async {
      final fileUri = args['file_uri'] as String;

      return GetPromptResult(
        messages: [
          PromptMessage(
            role: PromptMessageRole.user,
            content: EmbeddedResource(
              resource: ResourceReference(
                uri: fileUri,
                type: 'resource',
              ),
            ),
          ),
          PromptMessage(
            role: PromptMessageRole.user,
            content: TextContent(
              text: 'Por favor, analiza este archivo buscando:\n'
                  '- Estructura lógica\n'
                  '- Calidad del contenido y legibilidad\n'
                  '- Posibles mejoras y optimizaciones',
            ),
          ),
        ],
      );
    },
  );

  final transport = StdioServerTransport();
  await server.connect(transport);
}
