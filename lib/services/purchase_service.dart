import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'storage_service.dart';

class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const String yearlySubscriptionId = 'viora_premium_yearly';
  static const String monthlySubscriptionId = 'viora_premium_monthly';
  static const Set<String> productIds = {
    yearlySubscriptionId,
    monthlySubscriptionId,
  };

  final ValueNotifier<bool> isPremiumNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  List<ProductDetails> products = [];
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  Future<void> init() async {
    isPremiumNotifier.value = StorageService.instance.isPremium;

    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (dynamic error) {
        debugPrint('IAP Stream Error: $error');
      },
    );

    await loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        debugPrint('In-App Purchase store is not available on this device');
        return;
      }

      final ProductDetailsResponse response =
          await _iap.queryProductDetails(productIds);

      if (response.error != null) {
        debugPrint('Error loading products: ${response.error!.message}');
      }

      products = response.productDetails;
      // Urutkan tahunan dulu baru bulanan
      products.sort((a, b) => b.id.compareTo(a.id));
    } catch (e) {
      debugPrint('Failed to load store products: $e');
    }
  }

  Future<bool> buyProduct(ProductDetails product) async {
    if (!_isAvailable) {
      await loadProducts();
      if (!_isAvailable) return false;
    }

    isLoadingNotifier.value = true;
    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error initiating purchase: $e');
      isLoadingNotifier.value = false;
      return false;
    }
  }

  Future<void> restorePurchases() async {
    isLoadingNotifier.value = true;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        isLoadingNotifier.value = true;
      } else {
        if (purchase.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchase.error?.message}');
          isLoadingNotifier.value = false;
        } else if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          final bool valid = await _verifyPurchase(purchase);
          if (valid) {
            await _deliverProduct(purchase);
          }
        }

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        isLoadingNotifier.value = false;
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Pada production: Verifikasi server-side receipt ke Google Play / Apple Server
    // Untuk client-side standard, status purchased/restored dianggap valid
    return true;
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    await StorageService.instance.setPremium(true);
    isPremiumNotifier.value = true;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
