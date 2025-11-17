import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/doctor_availability_service.dart';

class DoctorAvailabilityCalendar extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final Function(DateTime date, String timeSlot)? onSlotSelected;

  const DoctorAvailabilityCalendar({
    super.key,
    required this.doctorId,
    required this.doctorName,
    this.onSlotSelected,
  });

  @override
  State<DoctorAvailabilityCalendar> createState() =>
      _DoctorAvailabilityCalendarState();
}

class _DoctorAvailabilityCalendarState
    extends State<DoctorAvailabilityCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, dynamic>? _selectedDayAvailability;
  bool _isLoading = false;
  Map<String, dynamic>? _nearestSlot;
  Map<String, dynamic>? _doctorStats;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadSelectedDayAvailability();
    _findNearestSlot();
    _loadDoctorStats();
  }

  Future<void> _loadSelectedDayAvailability() async {
    if (_selectedDay == null) return;

    if (mounted) setState(() => _isLoading = true);

    final availability = await DoctorAvailabilityService.getDoctorAvailability(
      widget.doctorId,
      _selectedDay!,
    );

    if (mounted) {
      setState(() {
        _selectedDayAvailability = availability;
        _isLoading = false;
      });
    }
  }

  Future<void> _findNearestSlot() async {
    final nearest = await DoctorAvailabilityService.findNearestAvailableSlot(
      widget.doctorId,
    );
    if (mounted) setState(() => _nearestSlot = nearest);
  }

  Future<void> _loadDoctorStats() async {
    final stats = await DoctorAvailabilityService.getDoctorStatistics(
      widget.doctorId,
    );
    if (mounted) setState(() => _doctorStats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. ${widget.doctorName} - Availability'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildDoctorStatsCard(),
            _buildNearestSlotCard(),
            _buildCalendar(),
            _buildAvailableSlots(),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorStatsCard() {
    if (_doctorStats == null) {
      return const SizedBox.shrink();
    }

    final totalAppointments = _doctorStats!['totalAppointments'] ?? 0;
    final monthlyAppointments = _doctorStats!['monthlyAppointments'] ?? 0;
    final statusCountsRaw =
        _doctorStats!['appointmentsByStatus'] as Map<dynamic, dynamic>? ?? {};
    final statusCounts = Map<String, int>.from(statusCountsRaw);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doctor Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  totalAppointments.toString(),
                  Icons.calendar_today,
                  Colors.blue,
                ),
                _buildStatItem(
                  'This Month',
                  monthlyAppointments.toString(),
                  Icons.calendar_month,
                  Colors.green,
                ),
                _buildStatItem(
                  'Pending',
                  (statusCounts['pending'] ?? 0).toString(),
                  Icons.pending,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Completed',
                  (statusCounts['completed'] ?? 0).toString(),
                  Icons.check_circle,
                  Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildNearestSlotCard() {
    if (_nearestSlot == null) {
      // Don't show a warning card, just show nothing or a subtle message
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.blue[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Select a date from the calendar below to check availability',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final date = _nearestSlot!['date'] as DateTime;
    final timeSlot = _nearestSlot!['timeSlot'] as String;
    final daysFromNow = _nearestSlot!['daysFromNow'] as int;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green[50],
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDay = date;
            _focusedDay = date;
          });
          _loadSelectedDayAvailability();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Nearest Available Slot',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, MMM dd, yyyy').format(date),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    timeSlot,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(
                      daysFromNow == 0
                          ? 'Today'
                          : daysFromNow == 1
                          ? 'Tomorrow'
                          : 'In $daysFromNow days',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.green[100],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  if (widget.onSlotSelected != null) {
                    widget.onSlotSelected!(date, timeSlot);
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Book This Slot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 60)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          weekendTextStyle: const TextStyle(color: Colors.red),
        ),
        enabledDayPredicate: (day) {
          // Disable Sundays
          return day.weekday != DateTime.sunday;
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (selectedDay.weekday == DateTime.sunday) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Doctor is not available on Sundays'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _loadSelectedDayAvailability();
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildAvailableSlots() {
    if (_selectedDay == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_available),
                const SizedBox(width: 8),
                Text(
                  'Slots for ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildSlotsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsGrid() {
    if (_selectedDayAvailability == null) {
      return const Text('No data available');
    }

    final availableSlots = (_selectedDayAvailability!['availableSlots'] as List)
        .cast<String>();
    final slotCounts =
        _selectedDayAvailability!['slotCounts'] as Map<String, dynamic>;

    if (availableSlots.isEmpty) {
      return Column(
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'All slots are booked for this day',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Try selecting a different date',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${availableSlots.length} slots available',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DoctorAvailabilityService.timeSlots.map((slot) {
            final isAvailable = availableSlots.contains(slot);
            final count = slotCounts[slot] ?? 0;
            final slotsLeft =
                DoctorAvailabilityService.maxAppointmentsPerSlot - count;

            return InkWell(
              onTap: isAvailable
                  ? () {
                      if (widget.onSlotSelected != null) {
                        widget.onSlotSelected!(_selectedDay!, slot);
                      }
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green[50] : Colors.grey[200],
                  border: Border.all(
                    color: isAvailable ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      slot,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isAvailable ? Colors.green[900] : Colors.grey,
                      ),
                    ),
                    if (isAvailable && slotsLeft > 0)
                      Text(
                        '$slotsLeft left',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                        ),
                      ),
                    if (!isAvailable)
                      const Text(
                        'Full',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
