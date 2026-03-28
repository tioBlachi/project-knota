import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class DatePickerModalIOS extends StatefulWidget {
  final DateTime initialDateTime;

  const DatePickerModalIOS({super.key, required this.initialDateTime});

  @override
  State<DatePickerModalIOS> createState() => _DatePickerModalIOSState();
}

class _DatePickerModalIOSState extends State<DatePickerModalIOS> {
  late DateTime _tempSelectedDate;

  @override
  void initState() {
    super.initState();
    _tempSelectedDate = widget.initialDateTime;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoButton(
                child: const Text('Done'),
                onPressed: () => Navigator.pop(context, _tempSelectedDate),
              ),
            ],
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              initialDateTime: widget.initialDateTime,
              onDateTimeChanged: (DateTime newDateTime) {
                setState(() {
                  _tempSelectedDate = newDateTime;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
