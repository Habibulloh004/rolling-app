import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:get/get.dart';

import '../../Consts/Colors.dart';
import '../../Localzition/locals.dart';
import '../../Store/PromocodeStore.dart';

class PromocodeDialog extends StatefulWidget {
  final List<dynamic> promotions;
  final List<dynamic> productsData;
  final List<dynamic> categoriesData;

  const PromocodeDialog({
    Key? key,
    required this.promotions,
    required this.productsData,
    required this.categoriesData,
  }) : super(key: key);

  @override
  State<PromocodeDialog> createState() => _PromocodeDialogState();
}

class _PromocodeDialogState extends State<PromocodeDialog> {
  final TextEditingController promoCodeController = TextEditingController();
  final PromocodeStore promocodeStore = Get.find<PromocodeStore>();
  String? errorMessage;
  bool isLoading = false;
  late List<dynamic> _promotionsCache;

  List<dynamic> _normalizePromotions(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['response'] is List) {
      return raw['response'] as List<dynamic>;
    }
    if (raw == null) return const [];
    return [raw];
  }

  @override
  void initState() {
    super.initState();
    _promotionsCache = [];
    try {
      _promotionsCache = _normalizePromotions(widget.promotions);
      promocodeStore.cacheBackendData(
        productsData: widget.productsData,
        categoriesData: widget.categoriesData,
      );
    } catch (e) {
      print('Error initializing promocode dialog: $e');
    }
  }

  @override
  void dispose() {
    promoCodeController.dispose();
    super.dispose();
  }

  void handleRemovePromo() {
    promocodeStore.handleRemovePromo();
    promoCodeController.clear();
    setState(() {
      errorMessage = null;
    });

    Get.back(result: 'removed');
    Get.snackbar(
      LocaleData.success.getString(context),
      LocaleData.promocodeRemoved.getString(context),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Future<void> handleApply() async {
    final promoCode = promoCodeController.text.trim();

    if (promoCode.isEmpty) {
      setState(() {
        errorMessage = LocaleData.pleaseEnterPromocode.getString(context);
      });
      return;
    }

    if (promocodeStore.activePromocode.value != null) {
      setState(() {
        errorMessage = LocaleData.promocodeAlreadyUsed.getString(context);
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String? successMessage;
      String? localError;

      final applied = await promocodeStore.applyPromocode(
        promoCode,
        _promotionsCache,
        widget.productsData,
        widget.categoriesData,
        (message) {
          localError = message;
        },
        (message) {
          successMessage = message;
        },
      );

      setState(() {
        isLoading = false;
        errorMessage = localError;
      });

      if (applied) {
        promoCodeController.clear();
        Get.back(result: 'applied');
        Get.snackbar(
          LocaleData.success.getString(context),
          successMessage ?? LocaleData.promocodeApplied.getString(context),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else if (localError == null || localError!.isEmpty) {
        setState(() {
          errorMessage = LocaleData.errorApplyingPromocode.getString(context);
        });
      }
    } catch (e) {
      print('Error applying promocode: $e');
      setState(() {
        errorMessage = LocaleData.errorApplyingPromocode.getString(context);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final appliedPromo = promocodeStore.activePromocode.value;
      final hasActivePromo = appliedPromo != null;
      final appliedName = promocodeStore.getPromocodeName();
      final appliedDescription = promocodeStore.getPromocodeDescription();

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasActivePromo
                  ? LocaleData.activePromocode.getString(context)
                  : LocaleData.enterPromocode.getString(context),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cDarkGreen,
              ),
            ),
            const SizedBox(height: 20),
            if (hasActivePromo) ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appliedName.isNotEmpty
                                ? appliedName
                                : LocaleData.promocode.getString(context),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cDarkGreen,
                            ),
                          ),
                          if (appliedDescription.isNotEmpty)
                            Text(appliedDescription),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: handleRemovePromo,
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ] else ...[
              TextField(
                controller: promoCodeController,
                decoration: InputDecoration(
                  labelText: LocaleData.promocode.getString(context),
                  hintText: LocaleData.enterPromocode.getString(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorText: errorMessage,
                  prefixIcon: const Icon(Icons.local_offer),
                ),
                onChanged: (value) {
                  setState(() {
                    errorMessage = null;
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleApply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cDarkGreen,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              LocaleData.apply.getString(context),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      LocaleData.cancel.getString(context),
                      style: const TextStyle(color: cDarkGreen),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }
}
