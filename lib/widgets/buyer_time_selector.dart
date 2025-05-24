import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../generated/l10n.dart';

class BuyerTimeSelector extends StatefulWidget {
  final String orderId;
  final List<Map<String, dynamic>> availableTimeSlots;
  final Function(Map<String, dynamic>) onTimeSlotSelected;

  const BuyerTimeSelector({
    Key? key,
    required this.orderId,
    required this.availableTimeSlots,
    required this.onTimeSlotSelected,
  }) : super(key: key);

  @override
  _BuyerTimeSelectorState createState() => _BuyerTimeSelectorState();
}

class _BuyerTimeSelectorState extends State<BuyerTimeSelector> {
  Map<String, dynamic>? selectedTimeSlot;
  DateTime focusedDate = DateTime.now();
  DateTime? selectedDate;
  Map<DateTime, List<Map<String, dynamic>>> availableSlotsByDate = {};

  @override
  void initState() {
    super.initState();
    _organizeAvailableSlots();
    _setInitialSelectedDate();
  }

  void _organizeAvailableSlots() {
    for (var slot in widget.availableTimeSlots) {
      final timestamp = slot['dateTime'] as Timestamp;
      final dateTime = timestamp.toDate();
      final dateKey = DateTime(dateTime.year, dateTime.month, dateTime.day);
      
      if (availableSlotsByDate[dateKey] == null) {
        availableSlotsByDate[dateKey] = [];
      }
      
      availableSlotsByDate[dateKey]!.add({
        ...slot,
        'hour': dateTime.hour,
        'fullDateTime': dateTime,
      });
    }

    // Sort slots by hour for each date
    availableSlotsByDate.forEach((date, slots) {
      slots.sort((a, b) => a['hour'].compareTo(b['hour']));
    });
  }

  void _setInitialSelectedDate() {
    if (availableSlotsByDate.isNotEmpty) {
      final dates = availableSlotsByDate.keys.toList()..sort();
      selectedDate = dates.first;
    }
  }

  String _formatTime(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  Future<void> _confirmTimeSlot() async {
    if (selectedTimeSlot == null) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Update the order with selected time slot and notify seller
      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(widget.orderId)
          .update({
        'selectedTimeSlot': selectedTimeSlot,
        'status': 'time_slot_confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
        'lastAction': 'buyer_selected_time',
        'buyerConfirmedAt': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Callback to parent widget
      widget.onTimeSlotSelected(selectedTimeSlot!);

      // Show success message with pickup details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).timeSlotSelected,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Pickup time: ${selectedTimeSlot!['formatted']}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 2),
              const Text(
                'The seller has been notified.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.of(context).pop();

    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context, rootNavigator: true).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting time slot: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
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
    // Get available dates and limit to next few days
    final availableDates = availableSlotsByDate.keys.toList()..sort();
    
    if (availableDates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No available dates',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: [
        // Available dates horizontal layout
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableDates.map((date) {
                final isToday = _isSameDay(date, DateTime.now());
                final isSelected = selectedDate != null && _isSameDay(date, selectedDate!);
                final slotsCount = availableSlotsByDate[date]?.length ?? 0;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDate = date;
                        // Clear selected time slot when date changes
                        selectedTimeSlot = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getMonthName(date.month).substring(0, 3),
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(height: 2),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.2)
                                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$slotsCount times',
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildTimeSelector() {
    if (selectedDate == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a date to see available times',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final slotsForDate = availableSlotsByDate[selectedDate] ?? [];
    
    if (slotsForDate.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No available times for this date',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available times for ${selectedDate!.day}/${selectedDate!.month}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
              itemCount: slotsForDate.length,
              itemBuilder: (context, index) {
                final slot = slotsForDate[index];
                final hour = slot['hour'] as int;
                final isSelected = selectedTimeSlot == slot;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedTimeSlot = slot;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _formatTime(hour),
                        style: TextStyle(
                          color: isSelected 
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
          if (selectedTimeSlot != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: ${selectedTimeSlot!['formatted']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).selectPickupTime),
        actions: [
          TextButton(
            onPressed: selectedTimeSlot != null ? _confirmTimeSlot : null,
            child: Text(
              AppLocalizations.of(context).confirm,
              style: TextStyle(
                color: selectedTimeSlot != null 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
            ),
          ),
        ],
      ),
      body: widget.availableTimeSlots.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).noAvailableTimeSlots,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : Column(
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
                        child: Text(
                          'Select a date and time for pickup',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
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
              ],
            ),
    );
  }
} 