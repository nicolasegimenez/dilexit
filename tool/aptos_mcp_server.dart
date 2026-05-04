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
        extensions: withMcpUiExtension(), // Enable support for MCP Apps UI
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
      description: 'Visual interface for Aptos wallet monitoring',
      meta: {
        'ui': {
          'prefersBorder': true,
        },
      },
    ),
    (uri, [dynamic extra]) async {
      final client = AptosClient("https://fullnode.testnet.aptoslabs.com/v1");
      final info = await client.getLedgerInfo();
      
      final ledgerVersion = info['ledger_version'];
      final chainId = info['chain_id'];
      final blockHeight = info['block_height'];
      final epoch = info['epoch'];

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
          <div class="value">$ledgerVersion</div>
        </div>
        <div>
          <div class="label">Chain ID</div>
          <div class="value">$chainId</div>
        </div>
        <div>
          <div class="label">Block Height</div>
          <div class="value">$blockHeight</div>
        </div>
        <div>
          <div class="label">Epoch</div>
          <div class="value">$epoch</div>
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
      description: 'Shows a visual and interactive dashboard of the Aptos wallet.',
      meta: const {
        'ui': {
          'resourceUri': dashboardUri,
          'visibility': ['model', 'app'],
        },
      },
    ),
    (args, [dynamic extra]) async {
      return const CallToolResult(
        content: [
          TextContent(text: 'Opening visual Aptos dashboard...'),
          ResourceLink(
            uri: dashboardUri,
            name: 'Aptos Wallet Dashboard',
            mimeType: mcpUiResourceMimeType,
          ),
        ],
      );
    },
  );

  // Helper to get client by network
  AptosClient getClient(String network) => AptosClient(AptosNetwork.fromName(network).fullnode);

  // --- TOOLS ---

  server.registerTool(
    'aptos_get_balance',
    description: 'Gets the APT balance of an address on Mainnet or Testnet.',
    inputSchema: ToolInputSchema(
      properties: {
        'address': JsonSchema.string(description: '0x...'),
        'network': JsonSchema.string(
          description: 'Network to query',
          enumValues: ['mainnet', 'testnet'],
          defaultValue: 'testnet',
        ),
      },
      required: ['address'],
    ),
    callback: (args, [dynamic extra]) async {
      try {
        final network = args?['network'] as String? ?? 'testnet';
        final client = getClient(network);
        final balance = await CoinClient(client).checkBalance(args?['address'] as String);
        final apt = balance / BigInt.from(100000000);
        return CallToolResult(
          content: [TextContent(text: 'Balance on $network: $apt APT ($balance octas)')],
        );
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Error: $e')]);
      }
    },
  );

  server.registerTool(
    'aptos_generate_keypair',
    description: 'Generates a new account (Mnemonic, Private, Public, Address).',
    inputSchema: ToolInputSchema(properties: {}),
    callback: (args, [dynamic extra]) async {
      final mnemonic = AptosAccount.generateMnemonic();
      final account = AptosAccount.generateAccount(mnemonic);
      return CallToolResult(
        content: [
          TextContent(text: '--- NEW APTOS ACCOUNT ---\n'
                           'Address: ${account.address}\n'
                           'Mnemonic: $mnemonic\n'
                           'Private Key: ${account.toPrivateKeyObject().toString()}\n'
                           'Public Key: ${account.pubKey}')
        ],
      );
    },
  );

  // Long task tool with progress report
  server.registerTool(
    'long-task',
    description: 'Demonstrates progress reporting for long tasks.',
    inputSchema: ToolInputSchema(properties: {}),
    callback: (args, [dynamic extra]) async {
      if (extra == null) {
        return const CallToolResult(
          isError: true,
          content: [TextContent(text: 'Error: Extra context not available for progress.')],
        );
      }
      for (var i = 0; i < 100; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        await extra.sendProgress(
          i.toDouble(),
          total: 100,
          message: 'Processing step $i of 100...',
        );
      }
      return const CallToolResult(
        content: [TextContent(text: 'Long task completed successfully!')],
      );
    },
  );

  // Complex search tool (Search-Database Pattern)
  server.registerTool(
    'aptos_search_events',
    description: 'Searches for specific events on the blockchain (transfers, deposits) with advanced filters.',
    inputSchema: ToolInputSchema(
      properties: {
        'address': JsonSchema.string(description: 'Address to investigate'),
        'event_type': JsonSchema.string(
          description: 'Event type (e.g., 0x1::coin::DepositEvent)',
          defaultValue: '0x1::coin::WithdrawEvent',
        ),
        'filters': JsonSchema.object(
          properties: {
            'min_amount': JsonSchema.number(description: 'Minimum amount in octas'),
            'network': JsonSchema.string(enumValues: ['mainnet', 'testnet']),
          },
        ),
        'limit': JsonSchema.integer(
          description: 'Maximum number of results',
          minimum: 1,
          maximum: 100,
          defaultValue: 10,
        ),
      },
      required: ['address'],
    ),
    callback: (args, [dynamic extra]) async {
      final address = args!['address'] as String;
      final limit = args['limit'] as int? ?? 10;
      final filters = args['filters'] as Map<String, dynamic>?;
      final network = filters?['network'] as String? ?? 'testnet';
      
      final client = getClient(network);
      
      // Here would go the logic to query the Aptos events API
      // For now we return a structured log of the search attempt
      return CallToolResult(
        content: [
          TextContent(text: 'Searching $limit events of type ${args?['event_type']} for $address on $network...'),
          TextContent(text: 'Filters applied: ${jsonEncode(filters)}'),
        ],
      );
    },
  );

  // --- RESOURCES ---

  // Dynamic network status: aptos://mainnet/status or aptos://testnet/status
  server.registerResourceTemplate(
    'Network Status',
    ResourceTemplateRegistration('aptos://{network}/status', listCallback: null),
    null,
    (uri, vars, [dynamic extra]) async {
      final network = vars!['network'] as String;
      final client = getClient(network);
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

  // Dynamic account info: aptos://testnet/account/0x123...
  server.registerResourceTemplate(
    'Account Details',
    ResourceTemplateRegistration('aptos://{network}/account/{address}', listCallback: null),
    null,
    (uri, vars, [dynamic extra]) async {
      final network = vars!['network'] as String;
      final address = vars['address'] as String;
      final client = getClient(network);
      final account = await client.getAccount(address);
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
    description: 'Generates a professional code review looking for quality and bugs.',
    callback: (args, [dynamic extra]) async {
      return GetPromptResult(
        description: 'Review code for quality and best practices',
        messages: [
          PromptMessage(
            role: PromptMessageRole.user,
            content: TextContent(
              text: 'Please review the following code looking for:\n'
                    '- Code quality and readability\n'
                    '- Flutter/Dart or Move best practices\n'
                    '- Possible bugs or logical errors\n'
                    '- Security issues',
            ),
          ),
        ],
      );
    },
  );

  server.registerPrompt(
    'audit-move-code',
    description: 'Analyzes Move code to detect common vulnerabilities.',
    argsSchema: {
      'code': PromptArgumentDefinition(type: String, description: 'Move code to audit', required: true),
    },
    callback: (args, [dynamic extra]) async {
      final code = args?['code'] as String?;
      return GetPromptResult(
        messages: [
          PromptMessage(
            role: PromptMessageRole.user,
            content: TextContent(text: 'Please audit this Aptos Move code looking for reentrancy errors, resource management issues, or security vulnerabilities:\n\n$code'),
          ),
        ],
      );
    },
  );

  server.registerPrompt(
    'translate',
    description: 'Generates a translation prompt with a specific tone.',
    argsSchema: {
      'target_language': PromptArgumentDefinition(
        type: String,
        description: 'Language to translate to',
        required: true,
      ),
      'formality': PromptArgumentDefinition(
        type: String,
        description: 'Formality level (casual, formal)',
        required: false,
      ),
    },
    callback: (args, [dynamic extra]) async {
      final language = args!['target_language'] as String;
      final formality = args['formality'] as String? ?? 'neutral';

      return GetPromptResult(
        description: 'Translation of text to $language',
        messages: [
          PromptMessage(
            role: PromptMessageRole.user,
            content: TextContent(
              text: 'Translate the following text to $language '
                  'with a $formality tone:',
            ),
          ),
        ],
      );
    },
  );

  server.registerPrompt(
    'brainstorm',
    description: 'Starts a brainstorming session on a topic.',
    argsSchema: {
      'topic': PromptArgumentDefinition(
        type: String,
        description: 'Topic to brainstorm about',
        required: true,
      ),
    },
    callback: (args, [dynamic extra]) async {
      final topic = args?['topic'] as String?;

      return GetPromptResult(
        messages: [
          PromptMessage(
            role: PromptMessageRole.user,
            content: TextContent(
              text: 'Let\'s generate creative ideas about: $topic',
            ),
          ),
          PromptMessage(
            role: PromptMessageRole.assistant,
            content: TextContent(
              text: 'Excellent! I will help you with the brainstorm. What aspect of $topic interests you most?',
            ),
          ),
          PromptMessage(
            role: PromptMessageRole.user,
            content: TextContent(
              text: 'I am particularly interested in practical applications and ease of use.',
            ),
          ),
        ],
      );
    },
  );

  server.registerPrompt(
    'analyze-file',
    description: 'Analyzes a file in depth.',
    argsSchema: {
      'file_uri': PromptArgumentDefinition(
        type: String,
        description: 'URI of the file to analyze',
        required: true,
      ),
    },
    callback: (args, [dynamic extra]) async {
      final fileUri = args?['file_uri'] as String;

      return GetPromptResult(
        messages: [
          PromptMessage(
            role: PromptMessageRole.user,
            content: TextContent(
              text: 'Analyzing file: $fileUri\n\n'
                  'Please analyze this file looking for:\n'
                  '- Logical structure\n'
                  '- Content quality and readability\n'
                  '- Possible improvements and optimizations',
            ),
          ),
        ],
      );
    },
  );

  final transport = StdioServerTransport();
  await server.connect(transport);
}
