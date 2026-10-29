import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xurmo/core/errors/app_exception.dart';
import 'package:xurmo/core/widgets/state_view.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/map_config.dart';
import 'package:xurmo/core/utils/phone_number.dart';
import 'package:xurmo/core/theme/app_theme.dart';
import 'package:xurmo/data/models/delivery_location.dart';
import 'package:xurmo/data/models/saved_address.dart';
import 'package:xurmo/data/repositories/saved_address_repository.dart';
import 'package:xurmo/presentation/basket/cart.dart';
import 'package:xurmo/presentation/location/location_picker_page.dart';
import 'package:xurmo/presentation/orders/order_confirm_page.dart';
import 'package:xurmo/presentation/orders/widgets/saved_address_picker.dart';
import 'package:xurmo/core/constants/app_pricing.dart';
import 'package:xurmo/core/localization/app_strings.dart';
import 'package:xurmo/core/utils/haptics.dart';
import 'package:xurmo/core/utils/money.dart';

class CheckoutPage extends StatefulWidget {
  /// Injected by tests; production uses the device store.
  final SavedAddressRepository? savedAddresses;

  const CheckoutPage({super.key, this.savedAddresses});

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

  late final SavedAddressRepository _savedRepo;

  /// Addresses kept from earlier orders, most recently used first.
  List<SavedAddress> _saved = const [];

  /// The saved address currently filling the form, while the text still
  /// matches it. Editing the address clears this.
  String? _selectedSavedId;

  /// Offered by default for an address that is not saved yet; once the
  /// customer flips the switch themselves, [_saveSwitchTouched] stops it from
  /// turning back on while they keep typing.
  bool _saveAddress = true;
  bool _saveSwitchTouched = false;

  /// Null until the customer picks a chip, so the first localised suggestion
  /// can be the default without reading strings in initState.
  String? _saveLabel;

  @override
  void initState() {
    super.initState();
    _savedRepo = widget.savedAddresses ?? SavedAddressRepository();
    _loadSavedAddresses();
  }

  Future<void> _loadSavedAddresses() async {
    final saved = await _savedRepo.load();
    if (!mounted || saved.isEmpty) return;

    setState(() => _saved = saved);
    // Ordering to the same place as last time is the common case, so the most
    // recent address fills the form straight away — but never over something
    // the customer already typed.
    if (_addressController.text.trim().isEmpty) {
      _applySavedAddress(saved.first, haptic: false);
    }
  }

  /// Fills the delivery fields from [address]. A phone number typed by hand
  /// survives: the saved one only fills an empty field.
  void _applySavedAddress(SavedAddress address, {bool haptic = true}) {
    if (haptic) Haptics.selection();
    setState(() {
      _selectedSavedId = address.id;
      _addressController.text = address.address;
      _location = address.location;
      _saveAddress = false;
      _saveSwitchTouched = false;
      _saveLabel = address.label;
      if (address.phone.isNotEmpty && _phoneController.text.trim().isEmpty) {
        _phoneController.text = address.phone;
      }
    });
  }

  Future<void> _removeSavedAddress(SavedAddress address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('remove_address_title')),
        content: Text(
          context.tr('remove_address_msg').replaceAll('{label}', address.label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('keep')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(context.tr('remove')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    Haptics.warning();
    final remaining = await _savedRepo.remove(address.id);
    if (!mounted) return;
    setState(() {
      _saved = remaining;
      // The fields keep what they hold; only the highlight goes away.
      if (_selectedSavedId == address.id) _selectedSavedId = null;
    });
  }

  /// Keeps the address now on the form, under the chosen label.
  Future<void> _persistCurrentAddress(String label) async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final saved = await _savedRepo.save(SavedAddress(
      id: now.toString(),
      label: label.trim().isEmpty ? 'Address' : label.trim(),
      address: address,
      latitude: _location?.latitude,
      longitude: _location?.longitude,
      phone: _phoneController.text.trim(),
      lastUsedAt: now,
    ));
    if (!mounted) return;
    setState(() => _saved = saved);
  }

  /// True when the text on the form is already one of the saved addresses, in
  /// which case there is nothing to offer saving.
  bool get _addressAlreadySaved =>
      _savedMatching(_addressController.text) != null;

  /// The saved address whose text matches [value], ignoring case and spacing.
  SavedAddress? _savedMatching(String value) {
    final key = SavedAddress.normalize(value);
    if (key.isEmpty) return null;
    for (final address in _saved) {
      if (address.key == key) return address;
    }
    return null;
  }

  /// Keeps the saved-address highlight and the save switch in step with what
  /// the customer types.
  void _onAddressChanged(String value) {
    final match = _savedMatching(value);
    setState(() {
      _selectedSavedId = match?.id;
      if (!_saveSwitchTouched) {
        _saveAddress = match == null && value.trim().isNotEmpty;
      }
    });
  }

  Future<void> _pickOnMap() async {
    final picked = await Navigator.of(context).push<DeliveryLocation>(
      MaterialPageRoute(builder: (_) => LocationPickerPage(initial: _location)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _location = picked;
      _addressController.text = picked.address;
      _selectedSavedId = null;
      // A freshly pinned address is worth keeping unless it is already saved.
      if (!_saveSwitchTouched) _saveAddress = !_addressAlreadySaved;
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
        title: Text(context.tr('checkout')),
        // Was hardcoded white-on-black, so the bar stayed light in dark mode.
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: cart.items.isEmpty
          ? StateView.empty(
              icon: CupertinoIcons.cart,
              title: context.tr('cart_empty'),
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
              Text(context.tr('order_summary'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

              Text(context.tr('delivery_details'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              Text(context.tr('delivery_address'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.iconPrimary)),
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

              Text(context.tr('phone_number'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.iconPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: context.tr('phone_hint'),
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

              Text(context.tr('delivery_notes'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.iconPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: context.tr('notes_hint'),
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
                        children: [Text(context.tr('subtotal')), Text(formatSum(subtotal))]),
                    if (cart.discount > 0) ...[
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${context.tr('discount')} (${AppPricing.promoDiscountPercent}%)'),
                            Text('-${formatSum(cart.discount)}',
                                style: const TextStyle(color: AppColors.success)),
                          ]),
                    ],
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text(context.tr('delivery_fee')), Text(formatSum(deliveryFee))]),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr('total'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                      : Text(context.tr('place_order'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onPrimary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}