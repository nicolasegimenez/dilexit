import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:dilexit/models/wallet_activity.dart';
import 'package:dilexit/models/token_balance.dart';

// ponytail: removed AptosWalletClient wrapper and WalletException
// Fetches coin activities using the fungible_asset_activities indexer table
Future<List<WalletActivity>> getCoinActivities(
  String address,
  String indexerUrl, {
  int limit = 20,
  int offset = 0,
}) async {
  try {
    final query = '''
      query GetUserFAActivities(\$address: String!, \$limit: Int, \$offset: Int) {
        fungible_asset_activities(
          where: { owner_address: { _eq: \$address } }
          limit: \$limit
          offset: \$offset
          order_by: { transaction_version: desc }
        ) {
          amount
          type
          asset_type
          transaction_version
          entry_function_id_str
        }
      }
    ''';

    final response = await http.post(
      Uri.parse(indexerUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'variables': {'address': address, 'limit': limit, 'offset': offset},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['errors'] != null) {
        debugPrint('GraphQL Error: ${data['errors']}');
        return [];
      }

      final List activities = data['data']['fungible_asset_activities'] ?? [];
      return activities.map((e) => WalletActivity.fromJson(e)).toList();
    } else {
      debugPrint('HTTP Error fetching activities: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    debugPrint('Error en el indexador: $e');
    return [];
  }
}

// Fetches all fungible asset (token) balances for a given wallet address
Future<List<TokenBalance>> getAccountTokens(String address, String indexerUrl) async {
  try {
    final query = '''
      query GetUserFungibleAssets(\$address: String!) {
        current_fungible_asset_balances(
          where: { owner_address: { _eq: \$address }, amount: { _gt: 0 } }
        ) {
          amount
          asset_type
          metadata {
            name
            symbol
            decimals
            asset_type
          }
        }
      }
    ''';

    final response = await http.post(
      Uri.parse(indexerUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'variables': {'address': address},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['errors'] != null) {
        debugPrint('GraphQL Error: ${data['errors']}');
        return [];
      }

      final List assets =
          data['data']['current_fungible_asset_balances'] ?? [];
      return assets.map((e) => TokenBalance.fromJson(e)).toList();
    } else {
      debugPrint('HTTP Error fetching tokens: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    debugPrint('Error obteniendo tokens: $e');
    return [];
  }
}
