import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:aptos/aptos.dart';
import 'package:aptos/coin_client.dart';
import 'package:aptos/indexer_client.dart';
import 'package:dilexit/models/wallet_activity.dart';
import 'package:dilexit/models/token_balance.dart';

class WalletException implements Exception {
  final String message;
  WalletException(this.message);
  @override
  String toString() => message;
}

class AptosWalletClient {
  AptosClient client;
  IndexerClient indexerClient;
  String indexerUrl;

  AptosWalletClient(this.client, this.indexerClient, {this.indexerUrl = 'https://api.testnet.aptoslabs.com/v1/graphql'});

  void updateClient(String apiUrl, String newIndexerUrl) {
    client = AptosClient(apiUrl);
    indexerClient = IndexerClient(newIndexerUrl);
    indexerUrl = newIndexerUrl;
  }

  /// Fetches the balance for a given wallet address
  Future<BigInt> fetchBalance(String address) async {
    try {
      final balanceResp = await client.view(
        "0x1::coin::balance",
        ["0x1::aptos_coin::AptosCoin"],
        [address],
      );
      
      if (balanceResp != null && balanceResp.isNotEmpty) {
        return BigInt.parse(balanceResp[0].toString());
      }
      return BigInt.zero;
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('account not found') || 
          errorMessage.contains('resource not found') ||
          errorMessage.contains('404') ||
          errorMessage.contains('bad response') ||
          errorMessage.contains('table item not found')) {
        return BigInt.zero;
      }
      throw WalletException('Failed to fetch balance for $address: $e');
    }
  }

  /// Placeholder for on-chain creation (not strictly needed for basic transfers)
  Future<void> createWalletOnChain(AptosAccount account) async {
    // Currently Aptos accounts are created automatically upon first deposit
    return;
  }

  /// Transfers APT to another account
  Future<String> transfer(AptosAccount sender, String receiverAddress, BigInt amount) async {
    try {
      final txHash = await CoinClient(client).transfer(
        sender,
        receiverAddress,
        amount,
        createReceiverIfMissing: true,
      );
      return txHash;
    } catch (e) {
      throw WalletException('Failed to transfer: $e');
    }
  }

  /// Fetches coin activities using the new fungible_asset_activities indexer table
  Future<List<WalletActivity>> getCoinActivities(String address, {int limit = 20, int offset = 0}) async {
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
          'variables': {
            'address': address,
            'limit': limit,
            'offset': offset,
          }
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

  /// Fetches all fungible asset (token) balances for a given wallet address
  Future<List<TokenBalance>> getAccountTokens(String address) async {
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
          'variables': {
            'address': address,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errors'] != null) {
          debugPrint('GraphQL Error: ${data['errors']}');
          return [];
        }
        
        final List assets = data['data']['current_fungible_asset_balances'] ?? [];
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
}
