import 'package:flutter/material.dart';
import 'package:frontend/services/appointment_services.dart';
import 'package:frontend/widgets/ios_datetime.dart';
import 'package:intl/intl.dart';
import 'package:frontend/widgets/address_autocomplete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class AddAppointmentPage extends StatefulWidget {
  final DateTime? initialDate;
  const AddAppointmentPage({super.key, this.initialDate});

  @override
  State<AddAppointmentPage> createState() => _AddAppointmentPageState();
}

class _AddAppointmentPageState extends State<AddAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedAddress;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDate ?? DateTime.now();
    _dateController.text = DateFormat(
      'yyyy-MM-dd h:mm a',
    ).format(_selectedDateTime);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    DateTime? pickedDate;
    TimeOfDay? pickedTime;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS
      final selectedDateTime = await showCupertinoModalPopup<DateTime>(
        context: context,
        builder: (context) =>
            DatePickerModalIOS(initialDateTime: _selectedDateTime),
      );

      if (selectedDateTime != null) {
        setState(() {
          _selectedDateTime = selectedDateTime;
          _dateController.text = DateFormat(
            'yyyy-MM-dd h:mm a',
          ).format(_selectedDateTime);
        });
      }
    } else {
      // Android, doesn't need its own custom class
      pickedDate = await showDatePicker(
        context: context,
        initialDate: _selectedDateTime,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );

      if (pickedDate != null) {
        if (!mounted) return;
        pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        );

        if (pickedTime != null) {
          setState(() {
            _selectedDateTime = DateTime(
              pickedDate!.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime!.hour,
              pickedTime.minute,
            );
            _dateController.text = DateFormat(
              'yyyy-MM-dd h:mm a',
            ).format(_selectedDateTime);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Appointment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Client Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              AddressAutocomplete(
                onSelected: (address) => _selectedAddress = address,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Appointment Date & Time",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _pickDateTime(),
                validator: (value) => value == null || value.isEmpty
                    ? "Please select a date"
                    : null,
              ),
              const SizedBox(height: 30),
              FilledButton(
                onPressed: _submitForm,
                child: const Text("Create Appointment"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedAddress != null) {
      try {
        await createAppointment(
          clientName: _nameController.text,
          address: _selectedAddress!,
          date: _selectedDateTime.toIso8601String(),//_dateController.text,
        );
        if (mounted) {
          Navigator.pop(context, true); // Return 'true' to trigger refresh
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
