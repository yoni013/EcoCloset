import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../generated/l10n.dart';

class TimeAvailabilitySelector extends StatefulWidget {
  final String orderId;
  final Function(List<Map<String, dynamic>>) onTimeSlotsSaved;

  const TimeAvailabilitySelector({
    Key? key,
    required this.orderId,
    required this.onTimeSlotsSaved,
  }) : super(key: key);

  @override
  _TimeAvailabilitySelectorState createState() => _TimeAvailabilitySelectorState();
}

class _TimeAvailabilitySelectorState extends State<TimeAvailabilitySelector> {
  Map<DateTime, Set<int>> selectedTimeSlots = {}; // DateTime -> Set of hours
  DateTime focusedDate = DateTime.now();
  DateTime? selectedDate;
  late DateTime startDate;
  late DateTime endDate;

  @override
  void initState() {
    super.initState();
    startDate = DateTime.now();
    endDate = startDate.add(const Duration(days: 2)); // Only 3 days (today + 2)
    selectedDate = startDate;
  }

  List<int> _getAvailableHours() {
    // Available hours from 8 AM to 10 PM
    return List.generate(15, (index) => 8 + index); // 8 to 22
  }

  bool _isHourInPast(DateTime date, int hour) {
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);
    if (!isToday) return false;
    return hour <= now.hour;
  }

  String _formatTime(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  bool _isTimeSlotSelected(DateTime date, int hour) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return selectedTimeSlots[dateKey]?.contains(hour) ?? false;
  }

  void _toggleTimeSlot(DateTime date, int hour) {
    final dateKey = DateTime(date.year, date.month, date.day);
    setState(() {
      if (selectedTimeSlots[dateKey] == null) {
        selectedTimeSlots[dateKey] = <int>{};
      }
      
      if (selectedTimeSlots[dateKey]!.contains(hour)) {
        selectedTimeSlots[dateKey]!.remove(hour);
        if (selectedTimeSlots[dateKey]!.isEmpty) {
          selectedTimeSlots.remove(dateKey);
        }
      } else {
        selectedTimeSlots[dateKey]!.add(hour);
      }
    });
  }

  void _selectAllHoursForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    final availableHours = _getAvailableHours();
    
    setState(() {
      if (selectedTimeSlots[dateKey] == null) {
        selectedTimeSlots[dateKey] = <int>{};
      }
      
      for (int hour in availableHours) {
        if (!_isHourInPast(date, hour)) {
          selectedTimeSlots[dateKey]!.add(hour);
        }
      }
    });
  }

  void _deselectAllHoursForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    setState(() {
      selectedTimeSlots.remove(dateKey);
    });
  }

  int _getTotalSelectedSlots() {
    int total = 0;
    selectedTimeSlots.values.forEach((hours) {
      total += hours.length;
    });
    return total;
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        'Select a date for pickup',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCalendar() {
    // Generate the next 3 days starting from today
    final days = List.generate(3, (index) {
      return DateTime.now().add(Duration(days: index));
    });
    
    return Column(
      children: [
        // 3-day horizontal layout
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: days.map((date) {
              final isToday = _isSameDay(date, DateTime.now());
              final isSelected = selectedDate != null && _isSameDay(date, selectedDate!);
              final hasSelectedSlots = selectedTimeSlots.containsKey(DateTime(date.year, date.month, date.day));
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : hasSelectedSlots
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : hasSelectedSlots
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getDayName(date.weekday),
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _getMonthName(date.month).substring(0, 3),
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isToday || (hasSelectedSlots && !isSelected)) 
                          const SizedBox(height: 1),
                        if (isToday)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (hasSelectedSlots && !isSelected)
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildTimeSelector() {
    if (selectedDate == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a date first',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final availableHours = _getAvailableHours();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _selectAllHoursForDate(selectedDate!),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                  child: Text(
                    'Select All',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _deselectAllHoursForDate(selectedDate!),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Text(
                    'Deselect All',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: availableHours.length,
              itemBuilder: (context, index) {
                final hour = availableHours[index];
                final isSelected = _isTimeSlotSelected(selectedDate!, hour);
                final isInPast = _isHourInPast(selectedDate!, hour);
                
                return InkWell(
                  onTap: isInPast ? null : () => _toggleTimeSlot(selectedDate!, hour),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isInPast
                          ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
                          : isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: isInPast
                            ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                            : isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _formatTime(hour),
                        style: TextStyle(
                          color: isInPast
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                              : isSelected 
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAvailability() async {
    try {
      // Convert selected time slots to a format suitable for Firestore
      List<Map<String, dynamic>> timeSlotData = [];
      
      selectedTimeSlots.forEach((date, hours) {
        for (int hour in hours) {
          final dateTime = DateTime(date.year, date.month, date.day, hour);
          timeSlotData.add({
            'dateTime': Timestamp.fromDate(dateTime),
            'formatted': '${date.day}/${date.month} ${_formatTime(hour)}',
            'isAvailable': true,
          });
        }
      });

      // Get order data to retrieve item ID
      final orderDoc = await FirebaseFirestore.instance
          .collection('Orders')
          .doc(widget.orderId)
          .get();
      
      final orderData = orderDoc.data();
      final itemId = orderData?['itemId'];

      // Update the order with available time slots and change status
      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(widget.orderId)
          .update({
        'availableTimeSlots': timeSlotData,
        'status': 'pending_buyer',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update item status to "Pending Buyer"
      if (itemId != null) {
        await FirebaseFirestore.instance
            .collection('Items')
            .doc(itemId)
            .update({'status': 'Pending Buyer'});
      }

      // Callback to parent widget
      widget.onTimeSlotsSaved(timeSlotData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).saveAvailability),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving availability: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).selectAvailableHours),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      children: [
                        const TextSpan(text: 'Select '),
                        TextSpan(
                          text: 'ALL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const TextSpan(text: ' dates and times for pickup'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                // Calendar section
                Expanded(
                  flex: 2,
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        _buildCalendarHeader(),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildCalendar(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Time selector section
                Expanded(
                  flex: 3,
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: _buildTimeSelector(),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_getTotalSelectedSlots()} ${AppLocalizations.of(context).selectTimeSlots}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Save availability button at the bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _getTotalSelectedSlots() > 0 ? _saveAvailability : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).saveAvailability,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
} 