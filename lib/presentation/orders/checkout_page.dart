import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xurmo/core/errors/app_exception.dart';
import 'package:xurmo/core/widgets/state_view.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/map_config.dart';
import 'package:xurmo/core/utils/phone_number.dart';
import 'package:xurmo/data/models/delivery_location.dart';
import 'package:xurmo/presentation/basket/cart.dart';
import 'package:xurmo/presentation/location/location_picker_page.dart';
import 'package:xurmo/presentation/orders/order_confirm_page.dart';
import 'package:xurmo/core/utils/haptics.dart';
import 'package:xurmo/core/utils/money.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  /// The point chosen on the map, if any. The address text stays editable so
  /// the customer can add an apartment or entrance number.
  DeliveryLocation? _location;

  Future<void> _pickOnMap() async {
    final picked = await Navigator.of(context).push<DeliveryLocation>(
      MaterialPageRoute(builder: (_) => LocationPickerPage(initial: _location)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _location = picked;
      _addressController.text = picked.address;
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      Haptics.warning();
      return;
    }
    Haptics.tap();

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw const AppException(
          AppErrorType.unauthorized,
          'Please sign in to place your order.',
        );
      }

      final cart = Cart.instance;
      if (cart.items.isEmpty) {
        throw const AppException(
          AppErrorType.unknown,
          'Your cart is empty.',
        );
      }

      final subtotal = cart.subtotal;
      final deliveryFee = cart.deliveryFee;
      final total = cart.totalPrice;
      final discount = cart.discount;
      List<Map<String, dynamic>> orderItems = cart.items.map((item) => {
        'id': item.product.id,
        'name': item.product.name,
        'price': item.product.price,
        'quantity': item.quantity,
        'image': item.product.imageUrl,
      }).toList();

      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        // Phone accounts sign in with a synthetic email that is not a real
        // address, so don't store it as the customer's email.
        'userEmail': isSyntheticEmail(user.email) ? '' : (user.email ?? ''),
        'items': orderItems,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'discount': discount,
        'address': _addressController.text,
        if (_location != null)
          'location': GeoPoint(_location!.latitude, _location!.longitude),
        'phone': _phoneController.text,
        'notes': _notesController.text,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      cart.clear();

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) => OrderConfirmationPage(orderId: orderRef.id),
        ));
      }
    } catch (e) {
      debugPrint('Order failed: ${AppException.from(e).message}');
    } finally {
      // The success path navigates away, so guard before touching state.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Cart.instance;
    final subtotal = cart.subtotal;
    final deliveryFee = cart.deliveryFee;
    final total = cart.totalPrice;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: cart.items.isEmpty
          ? StateView.empty(
              icon: CupertinoIcons.cart,
              title: 'Your cart is empty',
              message: 'Add something to your basket before checking out.',
              actionLabel: 'Back to basket',
              onAction: () => Navigator.pop(context),
            )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${cart.items.length} items', style: const TextStyle(fontSize: 16)),
                    Text(formatSum(total),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text('Delivery Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              Text('Delivery Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.iconPrimary)),
              const SizedBox(height: 8),
              if (MapConfig.isMapAvailable) SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickOnMap,
                  icon: Icon(_location == null ? CupertinoIcons.map : CupertinoIcons.checkmark_alt_circle_fill),
                  label: Text(_location == null ? 'Choose on map' : 'Pinned on map · Change'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Or type your address, apartment, entrance',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(CupertinoIcons.location_solid),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                maxLines: 3,
                validator: (v) => v?.isEmpty ?? true ? 'Address is required' : null,
              ),
              const SizedBox(height: 20),

              Text('Phone Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.iconPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Enter your phone number',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(CupertinoIcons.phone_fill),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 20),

              Text('Delivery Notes (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.iconPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'e.g., Ring doorbell, leave at door',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(CupertinoIcons.doc_text),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [const Text('Subtotal'), Text(formatSum(subtotal))]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [const Text('Delivery Fee'), Text(formatSum(deliveryFee))]),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(formatSum(total),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              //place order btn
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Place Order',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}