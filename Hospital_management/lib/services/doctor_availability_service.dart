import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DoctorAvailabilityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Time slots available per day
  static const List<String> timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
  ];

  /// Maximum appointments per slot per doctor
  static const int maxAppointmentsPerSlot = 3;

  /// Get doctor's availability for a specific date
  static Future<Map<String, dynamic>> getDoctorAvailability(
    String doctorId,
    DateTime date,
  ) async {
    try {
      // Get all appointments for this doctor on this date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // Count appointments per time slot
      Map<String, int> slotCounts = {};
      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        final timeSlot = data['timeSlot'] as String?;
        if (timeSlot != null) {
          slotCounts[timeSlot] = (slotCounts[timeSlot] ?? 0) + 1;
        }
      }

      // Determine which slots are available
      List<String> availableSlots = [];
      List<String> bookedSlots = [];

      for (var slot in timeSlots) {
        final count = slotCounts[slot] ?? 0;
        if (count < maxAppointmentsPerSlot) {
          availableSlots.add(slot);
        } else {
          bookedSlots.add(slot);
        }
      }

      return {
        'availableSlots': availableSlots,
        'bookedSlots': bookedSlots,
        'slotCounts': slotCounts,
        'totalAppointments': appointmentsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting doctor availability: $e');
      return {
        'availableSlots': [],
        'bookedSlots': [],
        'slotCounts': {},
        'totalAppointments': 0,
        'error': e.toString(),
      };
    }
  }

  /// Find the nearest available slot for a doctor (auto-detect)
  static Future<Map<String, dynamic>?> findNearestAvailableSlot(
    String doctorId, {
    DateTime? startDate,
    int daysToSearch = 14,
  }) async {
    try {
      final searchStart = startDate ?? DateTime.now();

      for (int i = 0; i < daysToSearch; i++) {
        final checkDate = searchStart.add(Duration(days: i));

        // Skip past dates
        if (checkDate.isBefore(
          DateTime.now().subtract(const Duration(days: 1)),
        )) {
          continue;
        }

        // Skip Sundays (day 7)
        if (checkDate.weekday == DateTime.sunday) {
          continue;
        }

        final availability = await getDoctorAvailability(doctorId, checkDate);
        final availableSlots = (availability['availableSlots'] as List)
            .cast<String>();

        if (availableSlots.isNotEmpty) {
          // Return the first available slot
          return {
            'date': checkDate,
            'timeSlot': availableSlots.first,
            'availableSlots': availableSlots,
            'daysFromNow': i,
          };
        }
      }

      return null; // No available slots found
    } catch (e) {
      print('Error finding nearest available slot: $e');
      return null;
    }
  }

  /// Get total appointments for a doctor (all time)
  static Future<int> getDoctorTotalAppointments(String doctorId) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting doctor total appointments: $e');
      return 0;
    }
  }

  /// Get appointments count by status for a doctor
  static Future<Map<String, int>> getDoctorAppointmentsByStatus(
    String doctorId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      Map<String, int> statusCounts = {
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
      };

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] as String? ?? 'pending';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      return statusCounts;
    } catch (e) {
      print('Error getting doctor appointments by status: $e');
      return {};
    }
  }

  /// Get weekly availability overview for a doctor
  static Future<List<Map<String, dynamic>>> getWeeklyAvailability(
    String doctorId, {
    DateTime? startDate,
  }) async {
    final start = startDate ?? DateTime.now();
    List<Map<String, dynamic>> weeklyData = [];

    for (int i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));

      // Skip Sundays
      if (date.weekday == DateTime.sunday) {
        weeklyData.add({
          'date': date,
          'dayName': DateFormat('EEEE').format(date),
          'available': false,
          'reason': 'Closed',
          'availableSlots': [],
          'totalAppointments': 0,
        });
        continue;
      }

      final availability = await getDoctorAvailability(doctorId, date);
      final availableSlots = availability['availableSlots'] as List<String>;

      weeklyData.add({
        'date': date,
        'dayName': DateFormat('EEEE').format(date),
        'available': availableSlots.isNotEmpty,
        'availableSlots': availableSlots,
        'bookedSlots': availability['bookedSlots'],
        'totalAppointments': availability['totalAppointments'],
        'slotsRemaining': availableSlots.length,
      });
    }

    return weeklyData;
  }

  /// Check if a specific slot is available
  static Future<bool> isSlotAvailable(
    String doctorId,
    DateTime date,
    String timeSlot,
  ) async {
    try {
      final availability = await getDoctorAvailability(doctorId, date);
      final availableSlots = availability['availableSlots'] as List<String>;
      return availableSlots.contains(timeSlot);
    } catch (e) {
      print('Error checking slot availability: $e');
      return false;
    }
  }

  /// Get doctor statistics
  static Future<Map<String, dynamic>> getDoctorStatistics(
    String doctorId,
  ) async {
    try {
      final totalAppointments = await getDoctorTotalAppointments(doctorId);
      final appointmentsByStatus = await getDoctorAppointmentsByStatus(
        doctorId,
      );
      final nearestSlot = await findNearestAvailableSlot(doctorId);

      // Get appointments for current month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final monthlySnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      return {
        'totalAppointments': totalAppointments,
        'appointmentsByStatus': appointmentsByStatus,
        'monthlyAppointments': monthlySnapshot.docs.length,
        'nearestAvailableSlot': nearestSlot,
      };
    } catch (e) {
      print('Error getting doctor statistics: $e');
      return {};
    }
  }

  /// Get busy dates for calendar (dates with no available slots)
  static Future<List<DateTime>> getBusyDates(
    String doctorId, {
    DateTime? startDate,
    int daysToCheck = 30,
  }) async {
    final start = startDate ?? DateTime.now();
    List<DateTime> busyDates = [];

    for (int i = 0; i < daysToCheck; i++) {
      final date = start.add(Duration(days: i));

      final availability = await getDoctorAvailability(doctorId, date);
      final availableSlots = availability['availableSlots'] as List<String>;

      if (availableSlots.isEmpty) {
        busyDates.add(date);
      }
    }

    return busyDates;
  }
}
