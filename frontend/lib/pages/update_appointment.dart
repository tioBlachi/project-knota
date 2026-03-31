import 'package:flutter/material.dart';
import 'package:frontend/services/appointment_services.dart' as appointment_services;
import 'package:intl/intl.dart';
import 'package:frontend/models/appointment_models.dart';
import 'package:frontend/widgets/address_autocomplete.dart';

class UpdateAppointmentPage extends StatefulWidget {
  final AppointmentPublic appointment;

  const UpdateAppointmentPage({super.key, required this.appointment});

  @override
  State<UpdateAppointmentPage> createState() => _UpdateAppointmentPageState();
}

class _UpdateAppointmentPageState extends State<UpdateAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dateController;
  
  String? _updatedAddress;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields with existing data from the model
    _nameController = TextEditingController(text: widget.appointment.clientName);
    _selectedDate = widget.appointment.appointmentDate;
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );
    // Initialize with current address in case they don't change it
    _updatedAddress = widget.appointment.destinationAddress;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Appointment"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Client Name", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter client name",
                ),
                validator: (value) => null// value == null || value.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              
              const Text("Destination Address", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                "Current: ${widget.appointment.destinationAddress}", 
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)
              ),
              const SizedBox(height: 8),
              AddressAutocomplete(
                isRequired: false,
                onSelected: (address) {
                  setState(() {
                    _updatedAddress = address;
                  });
                },
              ),
              const SizedBox(height: 20),

              const Text("Appointment Date", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                    });
                  }
                },
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _submitUpdate,
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }

    Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      String? nameUpdate;
      String? addressUpdate;
      String? dateUpdate;

      // 1. Client Name Logic
      final trimmedName = _nameController.text.trim();
      if (trimmedName.isNotEmpty && trimmedName != widget.appointment.clientName) {
        nameUpdate = trimmedName;
      }

      // 2. Address Logic Shield
      // We only set addressUpdate if there is a NEW, NON-EMPTY, and DIFFERENT string.
      // If the user cleared the box, _updatedAddress.trim().isEmpty becomes true, 
      // addressUpdate remains null, and the backend key is never sent.
      if (_updatedAddress != null && 
          _updatedAddress!.trim().isNotEmpty && 
          _updatedAddress != widget.appointment.destinationAddress) {
        addressUpdate = _updatedAddress;
      } else {
        addressUpdate = null; // Explicitly ensure it's null if cleared or unchanged
      }

      // 3. Date Logic
      final String formattedNewDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final String formattedOldDate = DateFormat('yyyy-MM-dd').format(widget.appointment.appointmentDate);
      
      if (formattedNewDate != formattedOldDate) {
        dateUpdate = formattedNewDate;
      }

      // 4. Guard Clause: If nothing actually changed, just close the page
      if (nameUpdate == null && addressUpdate == null && dateUpdate == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      try {
        // 5. Send only the changed fields to the backend
        await appointment_services.updateAppointment(
          id: widget.appointment.id,
          clientName: nameUpdate,
          address: addressUpdate,
          date: dateUpdate,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Appointment updated successfully")),
          );
          Navigator.pop(context, true); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
