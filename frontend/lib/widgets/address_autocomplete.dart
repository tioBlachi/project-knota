import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/services/address_service.dart';
import 'package:frontend/widgets/required_label.dart';

class AddressAutocomplete extends StatefulWidget {
  final ValueChanged<String> onSelected;
  final bool isRequired;

  const AddressAutocomplete({
    super.key,
    required this.onSelected,
    this.isRequired = true,
  });

  @override
  State<AddressAutocomplete> createState() => _AddressAutocompleteState();
}

class _AddressAutocompleteState extends State<AddressAutocomplete> {
  // Tracking the current query to discard obsolete async results
  String? _currentQuery;
  Iterable<String> _lastOptions = <String>[];
  late final _Debounceable<Iterable<String>?, String> _debouncedSearch;

  @override
  void initState() {
    super.initState();
    // Initialize the debouncer with the search function
    _debouncedSearch = _debounce<Iterable<String>?, String>(_search);
  }

  // The actual search logic calling the backend
  Future<Iterable<String>?> _search(String query) async {
    debugPrint('DEBUG: Searching for: $query');
    _currentQuery = query;
    final trimmedQuery = query.trim();

    if (trimmedQuery.length < 3) {
      return const Iterable<String>.empty();
    }

    try {
      final List<String> options = await AddressService.fetchSuggestions(
        trimmedQuery.toUpperCase(),
      );

      debugPrint('DEBUG: Found ${options.length} results');

      // If a new search happened while this was loading, return null (discard)
      if (_currentQuery != query) {
        return null;
      }
      _currentQuery = null;

      return options;
    } catch (e) {
      debugPrint('Autocomplete API Error: $e');
      return const Iterable<String>.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      // 1. Handle async fetching and debouncing
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final Iterable<String>? options = await _debouncedSearch(
          textEditingValue.text,
        );
        if (options == null) {
          return _lastOptions;
        }
        _lastOptions = options;
        return options;
      },

      // 2. Build the input field (matches your existing design)
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            label: RequiredLabel(
              label: 'Address',
              isRequired: widget.isRequired,
            ),
          ),
          onFieldSubmitted: (value) => onFieldSubmitted(),
          validator: (value) {
            if (widget.isRequired && (value == null || value.trim().isEmpty)) {
              return 'Address is required';
            }
            return null;
          },
        );
      },

      // 3. Handle selection
      onSelected: (String selection) {
        widget.onSelected(selection);
        FocusScope.of(context).unfocus();
      },

      // 4. Customizing the dropdown appearance
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              height: 200,
              // Match width to parent container
              width: MediaQuery.of(context).size.width - 40, 
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- HELPER CLASSES (From Flutter Docs) ---

typedef _Debounceable<S, T> = Future<S?> Function(T parameter);

/// Returns a new function that is a debounced version of the given function.
_Debounceable<S, T> _debounce<S, T>(_Debounceable<S?, T> function) {
  _DebounceTimer? debounceTimer;

  return (T parameter) async {
    if (debounceTimer != null && !debounceTimer!.isCompleted) {
      debounceTimer!.cancel();
    }
    debounceTimer = _DebounceTimer();
    try {
      await debounceTimer!.future;
    } on _CancelException {
      return null;
    }
    return function(parameter);
  };
}

class _DebounceTimer {
  _DebounceTimer() {
    _timer = Timer(const Duration(milliseconds: 500), _onComplete);
  }

  late final Timer _timer;
  final Completer<void> _completer = Completer<void>();

  void _onComplete() => _completer.complete();
  Future<void> get future => _completer.future;
  bool get isCompleted => _completer.isCompleted;

  void cancel() {
    _timer.cancel();
    _completer.completeError(const _CancelException());
  }
}

class _CancelException implements Exception {
  const _CancelException();
}
