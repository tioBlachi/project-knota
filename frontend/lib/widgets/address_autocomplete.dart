import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/services/address_service.dart';
import 'package:frontend/widgets/required_label.dart';

class AddressAutocomplete extends StatefulWidget {
  final ValueChanged<String> onSelected;

  const AddressAutocomplete({
    super.key,
    required this.onSelected,
  });

  @override
  State<AddressAutocomplete> createState() => _AddressAutocompleteState();
}

class _AddressAutocompleteState extends State<AddressAutocomplete> {
  final TextEditingController _addressController = TextEditingController();
  final FocusNode _addressFocusNode = FocusNode();

  List<String> _addressSuggestions = [];
  Timer? _debounce;
  bool _isLoadingAddresses = false;
  String? _selectedAddress;

  Future<void> _fetchAddressSuggestions(String query) async {
    final normalizedQuery = query.trim().toUpperCase();

    if (normalizedQuery.length < 3) {
      if (!mounted) return;
      setState(() {
        _addressSuggestions = [];
        _isLoadingAddresses = false;
      });
      return;
    }

    setState(() {
      _isLoadingAddresses = true;
    });

    try {
      final suggestions = await AddressService.fetchSuggestions(normalizedQuery);

      if (!mounted) return;
      setState(() {
        _addressSuggestions = suggestions;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _addressSuggestions = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingAddresses = false;
      });
    }
  }

  void _onAddressChanged(String value) {
    _selectedAddress = null;
    widget.onSelected('');

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchAddressSuggestions(value);
    });
  }

  void _selectSuggestion(String suggestion) {
    setState(() {
      _addressController.text = suggestion;
      _selectedAddress = suggestion;
      _addressSuggestions = [];
    });

    widget.onSelected(suggestion);
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _addressController,
          focusNode: _addressFocusNode,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.streetAddress,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _onAddressChanged,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Address is required';
            }
            return null;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            label: RequiredLabel(label: 'Address'),
            suffixIcon: _isLoadingAddresses
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _selectedAddress != null
                    ? const Icon(Icons.check_circle_outline)
                    : null,
          ),
        ),

        if (_addressSuggestions.isNotEmpty)
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _addressSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _addressSuggestions[index];

                return ListTile(
                  title: Text(suggestion),
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }
}