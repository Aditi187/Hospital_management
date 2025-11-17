import 'package:flutter/material.dart';
import '../services/doctor_availability_service.dart';

class DoctorAvailabilityCard extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String specialty;
  final bool isSelected;
  final VoidCallback onTap;

  const DoctorAvailabilityCard({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<DoctorAvailabilityCard> createState() => _DoctorAvailabilityCardState();
}

class _DoctorAvailabilityCardState extends State<DoctorAvailabilityCard> {
  Map<String, dynamic>? _nearestSlot;
  int _totalAppointments = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    try {
      final nearest = await DoctorAvailabilityService.findNearestAvailableSlot(
        widget.doctorId,
        daysToSearch: 7,
      );

      final total = await DoctorAvailabilityService.getDoctorTotalAppointments(
        widget.doctorId,
      );

      if (mounted) {
        setState(() {
          _nearestSlot = nearest;
          _totalAppointments = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: widget.isSelected ? 4 : 1,
      color: widget.isSelected ? Colors.blue[50] : null,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      widget.doctorName.isNotEmpty
                          ? widget.doctorName[0].toUpperCase()
                          : 'D',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${widget.doctorName}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: widget.isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.specialty,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isSelected)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Icon(Icons.event, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      '$_totalAppointments total appointments',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_nearestSlot != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _getAvailabilityText(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[900],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Don't show "Fully booked" message - just show nothing
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getAvailabilityText() {
    if (_nearestSlot == null) return '';

    final daysFromNow = _nearestSlot!['daysFromNow'] as int;
    final timeSlot = _nearestSlot!['timeSlot'] as String;

    if (daysFromNow == 0) {
      return 'Available today at $timeSlot';
    } else if (daysFromNow == 1) {
      return 'Available tomorrow at $timeSlot';
    } else {
      return 'Available in $daysFromNow days';
    }
  }
}
