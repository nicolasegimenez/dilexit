// Presentation layer - State Management
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:aptos/aptos.dart';
import 'package:dilexit/data/aptos_wallet_client.dart';
import 'package:dilexit/data/secure_storage_service.dart';

import 'package:dilexit/constants/network.dart';
import 'package:dilexit/models/wallet_activity.dart';
import 'package:dilexit/models/token_balance.dart';


class WalletEntity {
  final String privateKey;
  final String publicAddress;
  final BigInt balance;

  const WalletEntity({
    required this.privateKey,
    required this.publicAddress,
    required this.balance,
  });

  WalletEntity copyWith({
    String? privateKey,
    String? publicAddress,
    BigInt? balance,
  }) {
    return WalletEntity(
      privateKey: privateKey ?? this.privateKey,
      publicAddress: publicAddress ?? this.publicAddress,
      balance: balance ?? this.balance,
    );
  }

  double get balanceInApt => balance / BigInt.from(100000000);
  String get formattedBalance => '${balanceInApt.toStringAsFixed(4)} APT';
}

class WalletProvider with ChangeNotifier {
  final AptosWalletClient _walletClient;
  final SecureStorageService _storageService;

  WalletProvider(this._walletClient, this._storageService) : _state = WalletState.loading('Starting...') {
    // Try to load persisted wallet on start
    _loadPersistedWallet();
  }

  WalletState _state;

  WalletState get state => _state;

  Future<void> _loadPersistedWallet() async {
    final wallets = await _storageService.getWalletsData();
    if (wallets.isNotEmpty) {
      _state = WalletState.loading('Loading wallet...');
      notifyListeners();
      
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        String? activeAddress = await _storageService.getActiveWalletAddress();
        
        Map<String, dynamic> activeData = wallets.last;
        if (activeAddress != null) {
          activeData = wallets.firstWhere((w) => w['publicAddress'] == activeAddress, orElse: () => wallets.last);
        }
        
        // Derive keys locally without blocking network calls
        final mnemonics = activeData['mnemonics'];
        final (String a, String p) = await compute(_importWalletTask, mnemonics);

        final wallet = WalletEntity(
          privateKey: p,
          publicAddress: a,
          balance: BigInt.zero,
        );
        
        _state = WalletState.loaded(wallet, mnemonics).copyWith(savedWallets: wallets);
        notifyListeners();
        
        fetchBalance();
        fetchActivities();
      } catch (e) {
        debugPrint('Error loading persisted wallet: $e');
        _state = WalletState.initial();
        notifyListeners();
      }
    } else {
      _state = WalletState.initial();
      notifyListeners();
    }
  }


  static (String, String, String) _generateNewWalletTask(dynamic _) {
    final mnemonics = AptosAccount.generateMnemonic();
    final account = AptosAccount.generateAccount(mnemonics);
    return (
      mnemonics, 
      account.address, 
      account.toPrivateKeyObject().privateKeyHex!
    );
  }

  static (String, String) _importWalletTask(dynamic mnemonics) {
    final account = AptosAccount.generateAccount(mnemonics as String);
    return (
      account.address, 
      account.toPrivateKeyObject().privateKeyHex!
    );
  }

  Future<(WalletEntity, String)?> generateNewWalletData() async {

    // CPU-intensive generation moved to isolate
    try {
      final (String m, String a, String p) = await compute(_generateNewWalletTask, null);
      
      final wallet = WalletEntity(
        privateKey: p,
        publicAddress: a,
        balance: BigInt.zero,
      );
      
      return (wallet, m);
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
      return null;
    }
  }

  Future<void> finalizeWalletCreation(WalletEntity wallet, String mnemonics, {String? name}) async {
    _state = _state.copyWith(isLoading: true, loadingMessage: 'Finalizing setup...');
    notifyListeners();
    try {
      // Register on-chain (faucet) but don't block if it fails
      try {
        final account = AptosAccount.fromPrivateKey(wallet.privateKey);
        await _walletClient.createWalletOnChain(account); 
      } catch (e) {
        debugPrint('Faucet funding failed: $e');
      }
      
      await _storageService.addWalletData(
        mnemonics: mnemonics,
        publicAddress: wallet.publicAddress,
        privateKey: wallet.privateKey,
        name: name,
      );
      
      final wallets = await _storageService.getWalletsData();
      _state = WalletState.loaded(wallet, mnemonics).copyWith(
        savedWallets: wallets,
        isLoading: false,
      );
      notifyListeners();
      fetchBalance();
      fetchActivities();
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    }
  }

  void importWallet(String mnemonics, {String? name}) async {
    _state = WalletState.loading('Importing wallet...');
    notifyListeners();

    try {
      // Offload import task to isolate
      final (String a, String p) = await compute(_importWalletTask, mnemonics);

      final wallet = WalletEntity(
        privateKey: p,
        publicAddress: a,
        balance: BigInt.zero,
      );
      
      await _storageService.addWalletData(
        mnemonics: mnemonics,
        publicAddress: wallet.publicAddress,
        privateKey: wallet.privateKey,
        name: name,
      );

      final wallets = await _storageService.getWalletsData();
      
      _state = WalletState.loaded(wallet, mnemonics).copyWith(savedWallets: wallets);
      notifyListeners();
      
      fetchBalance();
      fetchActivities();
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    }
  }

  Future<bool> switchWallet(String publicAddress) async {
    final wallets = await _storageService.getWalletsData();
    final data = wallets.firstWhere((w) => w['publicAddress'] == publicAddress, orElse: () => <String, dynamic>{});
    if (data.isNotEmpty) {
      _state = _state.copyWith(isLoading: true, loadingMessage: 'Switching wallet...');
      notifyListeners();
      
      try {
        await _storageService.setActiveWalletAddress(publicAddress);
        
        final mnemonics = data['mnemonics'];
        final (String a, String p) = await compute(_importWalletTask, mnemonics);

        final wallet = WalletEntity(
          privateKey: p,
          publicAddress: a,
          balance: BigInt.zero,
        );

        _state = WalletState.loaded(wallet, mnemonics).copyWith(savedWallets: wallets);
        notifyListeners();
        
        fetchBalance();
        fetchActivities();
        return true;
      } catch (e) {
        _state = _state.copyWith(isLoading: false, error: e.toString());
        notifyListeners();
        return false;
      }
    }
    return false;
  }

  Future<bool> removeWallet(String publicAddress) async {
    _state = _state.copyWith(isLoading: true, loadingMessage: 'Removing wallet...');
    notifyListeners();

    try {
      final wallets = await _storageService.getWalletsData();
      final updatedWallets = wallets.where((w) => w['publicAddress'] != publicAddress).toList();
      
      if (wallets.length != updatedWallets.length) {
        await _storageService.overwriteWallets(updatedWallets);
        
        if (_state.wallet?.publicAddress == publicAddress) {
          if (updatedWallets.isNotEmpty) {
            await switchWallet(updatedWallets.first['publicAddress']);
          } else {
            logout();
          }
        } else {
          _state = _state.copyWith(savedWallets: updatedWallets, isLoading: false);
          notifyListeners();
        }
        return true;
      }
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<double> getOtherWalletBalance(String publicAddress) async {
    try {
      // Simply query the repository for the balance of that address
      // No need to import the full wallet to see its public balance
      final balanceBigInt = await _walletClient.fetchBalance(publicAddress);
      return balanceBigInt / BigInt.from(100000000);
    } catch (e) {
      debugPrint('Error getting balance for $publicAddress: $e');
      return 0.0;
    }
  }

  Future<void> logout() async {
    _state = _state.copyWith(isLoading: true, loadingMessage: 'Logging out...');
    notifyListeners();
    
    // Clear storage in background (it's already async)
    await _storageService.clearWalletsData();
    
    // Reset state
    _state = WalletState.initial();
    notifyListeners();
  }

  void changeNetwork(Network network) {
    if (_state.currentNetwork == network) return;
    
    _state = _state.copyWith(currentNetwork: network, activities: []);
    _walletClient.updateClient(network.apiUrl, network.indexerUrl);
    notifyListeners();
    
    fetchBalance();
    fetchActivities();
  }

  void fetchBalance() async {
    final wallet = _state.wallet;
    if (wallet != null) {
      _state = _state.copyWith(isLoadingBalance: true);
      notifyListeners();

      try {
        final balance = await _walletClient.fetchBalance(wallet.publicAddress);
        final updatedWallet = wallet.copyWith(balance: balance);
        _state = _state.copyWith(wallet: updatedWallet, isLoadingBalance: false);
      } catch (e) {
        _state = _state.copyWith(
          isLoadingBalance: false,
          error: 'Error getting balance: $e'
        );
      }
      
      // Try to get tokens (Fungible Assets)
      try {
        final tokens = await _walletClient.getAccountTokens(wallet.publicAddress);
        _state = _state.copyWith(tokens: tokens);
      } catch (e) {
        debugPrint('Error fetching tokens: $e');
      }
      
      notifyListeners();
    }
  }

  void fetchActivities() async {
    final wallet = _state.wallet;
    if (wallet != null) {
      _state = _state.copyWith(isLoadingActivities: true);
      notifyListeners();

      try {
        final activities = await _walletClient.getCoinActivities(wallet.publicAddress);
        _state = _state.copyWith(activities: activities, isLoadingActivities: false);
      } catch (e) {
        _state = _state.copyWith(isLoadingActivities: false);
      }
      notifyListeners();
    }
  }

  Future<String?> transferApt(String receiverAddress, BigInt amount) async {
    final wallet = _state.wallet;
    final mnemonics = _state.mnemonics;

    if (wallet == null || mnemonics == null) return null;

    _state = _state.copyWith(isTransferring: true);
    notifyListeners();

    try {
      final (String _, String p) = await compute(_importWalletTask, mnemonics);
      final account = AptosAccount.fromPrivateKey(p);
      final txHash = await _walletClient.transfer(account, receiverAddress, amount);
      _state = _state.copyWith(isTransferring: false);
      notifyListeners();
      
      fetchBalance();
      fetchActivities();
      
      return txHash;
    } catch (e) {
      _state = _state.copyWith(isTransferring: false, error: e.toString());
      notifyListeners();
      rethrow;
    }
  }
}

class WalletState {
  final bool isLoading;
  final String? loadingMessage;
  final bool isLoadingBalance;
  final bool isLoadingActivities;
  final bool isTransferring;
  final WalletEntity? wallet;
  final String? mnemonics;
  final List<WalletActivity> activities;
  final List<TokenBalance> tokens;
  final List<Map<String, dynamic>> savedWallets;
  final String? error;
  final Network currentNetwork;

  const WalletState({
    required this.isLoading,
    this.loadingMessage,
    required this.isLoadingBalance,
    this.isLoadingActivities = false,
    this.isTransferring = false,
    this.wallet,
    this.mnemonics,
    this.activities = const [],
    this.tokens = const [],
    this.savedWallets = const [],
    this.error,
    required this.currentNetwork,
  });

  factory WalletState.initial() => const WalletState(
        isLoading: false,
        isLoadingBalance: false,
        isLoadingActivities: false,
        isTransferring: false,
        currentNetwork: Network.testnet,
        activities: [],
        tokens: [],
        savedWallets: [],
      );

  factory WalletState.loading(String message) => WalletState(
        isLoading: true,
        loadingMessage: message,
        isLoadingBalance: false,
        isLoadingActivities: false,
        isTransferring: false,
        currentNetwork: Network.testnet,
        activities: [],
        tokens: [],
        savedWallets: [],
      );

  factory WalletState.loaded(WalletEntity wallet, String mnemonics) => WalletState(
        isLoading: false,
        isLoadingBalance: false,
        isLoadingActivities: false,
        isTransferring: false,
        wallet: wallet,
        mnemonics: mnemonics,
        currentNetwork: Network.testnet,
        activities: [],
        tokens: [],
        savedWallets: [],
      );

  factory WalletState.error(String error) => WalletState(
        isLoading: false,
        isLoadingBalance: false,
        isLoadingActivities: false,
        isTransferring: false,
        error: error,
        currentNetwork: Network.testnet,
        activities: [],
        tokens: [],
        savedWallets: [],
      );

  WalletState copyWith({
    bool? isLoading,
    String? loadingMessage,
    bool? isLoadingBalance,
    bool? isLoadingActivities,
    bool? isTransferring,
    WalletEntity? wallet,
    String? mnemonics,
    List<WalletActivity>? activities,
    List<TokenBalance>? tokens,
    List<Map<String, dynamic>>? savedWallets,
    String? error,
    Network? currentNetwork,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      isLoadingBalance: isLoadingBalance ?? this.isLoadingBalance,
      isLoadingActivities: isLoadingActivities ?? this.isLoadingActivities,
      isTransferring: isTransferring ?? this.isTransferring,
      wallet: wallet ?? this.wallet,
      mnemonics: mnemonics ?? this.mnemonics,
      activities: activities ?? this.activities,
      tokens: tokens ?? this.tokens,
      savedWallets: savedWallets ?? this.savedWallets,
      error: error ?? this.error,
      currentNetwork: currentNetwork ?? this.currentNetwork,
    );
  }
}
