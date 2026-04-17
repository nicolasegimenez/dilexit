// Presentation layer - State Management
import 'package:flutter/material.dart';
import 'package:Dilexit/data/wallet_repository.dart';
import 'package:Dilexit/data/secure_storage_service.dart';
import 'package:Dilexit/domain/wallet_entity.dart';

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
    // Ya está en estado loading por el constructor
    
    final data = await _storageService.getWalletData();
    if (data != null) {
      _state = WalletState.loading('Cargando wallet...');
      notifyListeners();
      
      try {
        // Simulamos un pequeño delay para que se aprecie la transición si es muy rápida
        await Future.delayed(const Duration(milliseconds: 500));
        
        final wallet = await _repository.importWallet(data['mnemonics']);
        _state = WalletState.loaded(wallet, data['mnemonics']);
        notifyListeners();
        // Actualizar el balance inmediatamente al cargar
        fetchBalance();
      } catch (e) {
        debugPrint('Error al cargar wallet persistida: $e');
        _state = WalletState.initial();
        notifyListeners();
      }
    } else {
      // No hay datos, volvemos al estado inicial (sin wallet)
      _state = WalletState.initial();
      notifyListeners();
    }
  }

  void createWallet() async {
    _state = WalletState.loading('Creating wallet...');
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final (wallet, mnemonics) = await _repository.createWallet();
      
      // Persistir los datos
      await _storageService.saveWalletData(
        mnemonics: mnemonics,
        publicAddress: wallet.publicAddress,
        privateKey: wallet.privateKey,
      );

      print('\n=========================================');
      print('NUEVA WALLET CREADA');
      print('Dirección: ${wallet.publicAddress}');
      print('=========================================\n');

      _state = WalletState.loaded(wallet, mnemonics);
    } catch (e) {
      _state = WalletState.error(e.toString());
    }
    notifyListeners();
  }

  void importWallet(String mnemonics) async {
    _state = WalletState.loading('Importing wallet...');
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final wallet = await _repository.importWallet(mnemonics);
      
      // Persistir los datos
      await _storageService.saveWalletData(
        mnemonics: mnemonics,
        publicAddress: wallet.publicAddress,
        privateKey: wallet.privateKey,
      );

      print('\n=========================================');
      print('WALLET IMPORTADA');
      print('Dirección: ${wallet.publicAddress}');
      print('=========================================\n');

      _state = WalletState.loaded(wallet, mnemonics);
    } catch (e) {
      _state = WalletState.error(e.toString());
    }
    notifyListeners();
  }

  void logout() async {
    await _storageService.clearWalletData();
    _state = WalletState.initial();
    notifyListeners();
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
      
      // Update balance automatically after sending
      fetchBalance();
      
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
  final bool isTransferring;
  final WalletEntity? wallet;
  final String? mnemonics;
  final String? error;

  const WalletState({
    required this.isLoading,
    this.loadingMessage,
    required this.isLoadingBalance,
    this.isTransferring = false,
    this.wallet,
    this.mnemonics,
    this.error,
  });

  factory WalletState.initial() => const WalletState(
        isLoading: false,
        isLoadingBalance: false,
        isTransferring: false,
      );

  factory WalletState.loading(String message) => WalletState(
        isLoading: true,
        loadingMessage: message,
        isLoadingBalance: false,
        isTransferring: false,
      );

  factory WalletState.loaded(WalletEntity wallet, String mnemonics) => WalletState(
        isLoading: false,
        isLoadingBalance: false,
        isTransferring: false,
        wallet: wallet,
        mnemonics: mnemonics,
      );

  factory WalletState.error(String error) => WalletState(
        isLoading: false,
        isLoadingBalance: false,
        isTransferring: false,
        error: error,
      );

  WalletState copyWith({
    bool? isLoading,
    String? loadingMessage,
    bool? isLoadingBalance,
    bool? isTransferring,
    WalletEntity? wallet,
    String? mnemonics,
    String? error,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      isLoadingBalance: isLoadingBalance ?? this.isLoadingBalance,
      isTransferring: isTransferring ?? this.isTransferring,
      wallet: wallet ?? this.wallet,
      mnemonics: mnemonics ?? this.mnemonics,
      error: error ?? this.error,
    );
  }
}
