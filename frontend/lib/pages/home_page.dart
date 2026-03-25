import 'package:flutter/material.dart';
import 'package:frontend/pages/add_appointment.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:frontend/models/appointment_models.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/services/user_services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String displayName = 'Loading...';
  Map<DateTime, List<AppointmentPublic>> _groupedAppointments = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  DateTime get _calendarFirstDay => DateTime.utc(_selectedYear, 1, 1);
  DateTime get _calendarLastDay => DateTime.utc(_selectedYear, 12, 31);

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _loadProfile() async {
    try {
      final user = await UserServices.getUserProfile();
      final fetchedAppointments = await UserServices.getUserAppointments(
        _selectedYear,
      );

      Map<DateTime, List<AppointmentPublic>> grouped = {};
      for (var appt in fetchedAppointments) {
        final date = _normalizeDate(appt.appointmentDate);
        if (grouped[date] == null) grouped[date] = [];
        grouped[date]!.add(appt);
      }

      if (!mounted) return;
      setState(() {
        displayName = user.displayName;
        _groupedAppointments = grouped;
        // Default to selecting today if data exists for it
        _selectedDay = _focusedDay;
      });
    } catch (e) {
      debugPrint('HOME PAGE ERROR: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  List<AppointmentPublic> _getEventsForDay(DateTime day) {
    return _groupedAppointments[_normalizeDate(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;
    final List<int> yearOptions = List.generate(6, (index) => (currentYear - 3) + index);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            displayName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          
        ]
      ),
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.75 > 300
            ? 300
            : MediaQuery.of(context).size.width * 0.75,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: Text(
                      displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Profile'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await StorageService.deleteToken();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              const Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: Colors.deepPurple,
              ),
              const SizedBox(width: 8),
              DropdownButton(
                value: _selectedYear,
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                underline: Container(),
                items: yearOptions.map((int year) {
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedYear = newValue;
                      _focusedDay = DateTime.utc(_selectedYear, 1, 1);
                      _selectedDay = null; // Clear selection to avoid confusion
                    });
                    _loadProfile(); // Need to re-fetch data for the new year
                  }
                },
              ),
            ],
          ),
          TableCalendar(
            firstDay: _calendarFirstDay,
            lastDay: DateTime.utc(currentYear + 2, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            "Appointments",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Expanded(
            child: _buildAppointmentList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final bool? refresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAppointmentPage()),
          );
          
          if (refresh == true) {
            _loadProfile(); // Re-fetch data to show the new dots
          }
        },
        child: const Icon(Icons.add),
      ),

    );
  }

  Widget _buildAppointmentList() {
    final events = _getEventsForDay(_selectedDay ?? _focusedDay);

    if (events.isEmpty) {
      return const Center(
        child: Text("No appointments for this day."),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final appt = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.location_on, color: Colors.deepPurple),
            title: Text(appt.clientName),
            subtitle: Text(appt.destinationAddress),
            trailing: Text("${appt.roundtripDistance.toStringAsFixed(1)} mi"),
            onTap: () {
              // Future: View/Edit detail
            },
          ),
        );
      },
    );
  }
}
