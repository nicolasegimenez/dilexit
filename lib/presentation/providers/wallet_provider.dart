// Presentation layer - State Management
import 'package:flutter/material.dart';
import 'package:aptos/aptos.dart';
import 'package:dilexit/data/wallet_repository.dart';
import 'package:dilexit/data/secure_storage_service.dart';
import 'package:dilexit/domain/wallet_entity.dart';
import 'package:dilexit/constants/network.dart';
import 'package:dilexit/models/wallet_activity.dart';
import 'package:dilexit/models/token_balance.dart';

class WalletProvider with ChangeNotifier {
  final WalletRepository _repository;
  final SecureStorageService _storageService;

  WalletProvider(this._repository, this._storageService) : _state = WalletState.loading('Iniciando...') {
    // Intentar cargar la wallet persistida al iniciar
    _loadPersistedWallet();
  }

  WalletState _state;

  WalletState get state => _state;

  Future<void> _loadPersistedWallet() async {
    final wallets = await _storageService.getWalletsData();
    if (wallets.isNotEmpty) {
      _state = WalletState.loading('Cargando wallet...');
      notifyListeners();
      
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        String? activeAddress = await _storageService.getActiveWalletAddress();
        
        Map<String, dynamic> activeData = wallets.last;
        if (activeAddress != null) {
          activeData = wallets.firstWhere((w) => w['publicAddress'] == activeAddress, orElse: () => wallets.last);
        }
        
        final wallet = await _repository.importWallet(activeData['mnemonics']);
        _state = WalletState.loaded(wallet, activeData['mnemonics']).copyWith(savedWallets: wallets);
        notifyListeners();
        fetchBalance();
        fetchActivities();
      } catch (e) {
        debugPrint('Error al cargar wallet persistida: $e');
        _state = WalletState.initial();
        notifyListeners();
      }
    } else {
      _state = WalletState.initial();
      notifyListeners();
    }
  }

  Future<(WalletEntity, String)?> generateNewWalletData() async {
    // Generación local instantánea
    try {
      final String mnemonics = AptosAccount.generateMnemonic();
      final account = AptosAccount.generateAccount(mnemonics);
      final wallet = WalletEntity.zero(account);
      return (wallet, mnemonics);
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
      return null;
    }
  }

  Future<void> finalizeWalletCreation(WalletEntity wallet, String mnemonics, {String? name}) async {
    _state = _state.copyWith(isLoading: true, loadingMessage: 'Finalizando configuración...');
    notifyListeners();
    try {
      // Registrar en la cadena (faucet) y persistir
      await _repository.registerOnChain(wallet.privateKey); 
      
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
      await Future.delayed(const Duration(milliseconds: 500));
      final wallet = await _repository.importWallet(mnemonics);
      
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
      _state = _state.copyWith(isLoading: true, loadingMessage: 'Cambiando wallet...');
      notifyListeners();
      
      try {
        await _storageService.setActiveWalletAddress(publicAddress);
        final wallet = await _repository.importWallet(data['mnemonics']);
        _state = WalletState.loaded(wallet, data['mnemonics']).copyWith(savedWallets: wallets);
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
    _state = _state.copyWith(isLoading: true, loadingMessage: 'Eliminando wallet...');
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
      // Simplemente consultamos al repositorio el balance de esa dirección
      // No necesitamos importar la wallet completa para ver su balance público
      final balanceBigInt = await _repository.getBalance(publicAddress);
      return balanceBigInt / BigInt.from(100000000);
    } catch (e) {
      debugPrint('Error obteniendo balance para $publicAddress: $e');
      return 0.0;
    }
  }

  void logout() async {
    await _storageService.clearWalletsData();
    _state = WalletState.initial();
    notifyListeners();
  }

  void changeNetwork(Network network) {
    if (_state.currentNetwork == network) return;
    
    _state = _state.copyWith(currentNetwork: network, activities: []);
    _repository.updateNetwork(network.apiUrl, network.indexerUrl);
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
        final updatedWallet = await _repository.fetchBalance(wallet);
        _state = _state.copyWith(wallet: updatedWallet, isLoadingBalance: false);
      } catch (e) {
        _state = _state.copyWith(
          isLoadingBalance: false,
          error: 'Error al obtener balance: $e'
        );
      }
      
      // Intentar obtener tokens (Fungible Assets)
      try {
        final tokens = await _repository.getAccountTokens(wallet.publicAddress);
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
        final activities = await _repository.getCoinActivities(wallet.publicAddress);
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
      final txHash = await _repository.transferApt(mnemonics, receiverAddress, amount);
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
