import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pointeur_app/models/work_session.dart';
import 'package:pointeur_app/models/break_model.dart';
import 'package:pointeur_app/theme/app_colors.dart';
import 'package:pointeur_app/services/work_time_service.dart';

class EditSessionDialog extends StatefulWidget {
  final DateTime initialDate;
  final Function(WorkSession) onSave;

  const EditSessionDialog({
    super.key,
    required this.initialDate,
    required this.onSave,
  });

  /// Static method to show the edit session dialog
  static Future<void> show(
    BuildContext context, {
    DateTime? date,
    Function(WorkSession)? onSave,
  }) {
    return showDialog(
      context: context,
      builder:
          (context) => EditSessionDialog(
            initialDate: date ?? DateTime.now(),
            onSave:
                onSave ??
                (session) {
                  // Default behavior - you might want to emit an event to a bloc here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Session mise à jour avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
          ),
    );
  }

  @override
  State<EditSessionDialog> createState() => _EditSessionDialogState();
}

class _EditSessionDialogState extends State<EditSessionDialog> {
  late DateTime? _arrivalTime;
  late DateTime? _departureTime;
  late List<BreakPeriod> _breaks;
  late bool _isComplete;
  late DateTime _selectedDate;

  final WorkTimeService _workTimeService = WorkTimeService();
  bool _isLoading = true;
  String? _errorMessage;
  WorkSession? _currentSession;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _initializeWithDefaults();
    _loadSessionData();
  }

  void _initializeWithDefaults() {
    _arrivalTime = null;
    _departureTime = null;
    _breaks = [];
    _isComplete = false;
  }

  Future<void> _loadSessionData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get session for the selected date
      _currentSession = await _workTimeService.getSessionByDate(_selectedDate);

      setState(() {
        _arrivalTime = _currentSession!.arrivalTime;
        _departureTime = _currentSession!.departureTime;
        _breaks = List.from(_currentSession!.breaks);
        _isComplete = _currentSession!.isComplete;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Erreur lors du chargement des données: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child:
            _isLoading
                ? _buildLoadingWidget()
                : _errorMessage != null
                ? _buildErrorWidget()
                : _buildContentWidget(),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: AppColors.primaryTeal),
        const SizedBox(height: 16),
        Text(
          'Chargement des données...',
          style: TextStyle(color: AppColors.primaryTeal),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _loadSessionData,
                child: const Text('Réessayer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.edit, color: AppColors.primaryTeal, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Modifier la session',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Date display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryTeal.withValues(alpha: 0.3),
            ),
          ),
          child: InkWell(
            onTap: _selectDate,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primaryTeal,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date: ${_formatDate(_selectedDate)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                      Text(
                        'Appuyez pour modifier',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryTeal.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit, color: AppColors.primaryTeal, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Warning message when editing past dates
        if (!_isToday(_selectedDate))
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous modifiez une session passée. Assurez-vous que les heures sont correctes.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Arrival time
                _buildTimeSection(
                  'Heure d\'arrivée',
                  _arrivalTime,
                  (time) => setState(() => _arrivalTime = time),
                  canDelete: true,
                ),
                const SizedBox(height: 16),

                // Departure time
                _buildTimeSection(
                  'Heure de départ',
                  _departureTime,
                  (time) => setState(() => _departureTime = time),
                  canDelete: true,
                ),
                const SizedBox(height: 16),

                // Breaks section
                _buildBreaksSection(),
                const SizedBox(height: 16),

                // Session complete toggle
                _buildCompleteToggle(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.primaryTeal),
                ),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Sauvegarder'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSection(
    String title,
    DateTime? time,
    Function(DateTime?) onChanged, {
    bool canDelete = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(time, onChanged),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppColors.primaryTeal,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time != null ? _formatTime(time) : 'Non défini',
                          style: TextStyle(
                            fontSize: 16,
                            color: time != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (canDelete && time != null)
                IconButton(
                  onPressed: () => onChanged(null),
                  icon: const Icon(Icons.clear, color: Colors.red),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreaksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Pauses',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            IconButton(
              onPressed: _addBreak,
              icon: Icon(Icons.add_circle, color: AppColors.primaryTeal),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_breaks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Aucune pause enregistrée',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Column(
            children:
                _breaks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final breakPeriod = entry.value;
                  return _buildBreakItem(breakPeriod, index);
                }).toList(),
          ),
      ],
    );
  }

  Widget _buildBreakItem(BreakPeriod breakPeriod, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.coffee, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pause ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _removeBreak(index),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildBreakTimeField(
                  'Début',
                  breakPeriod.startTime,
                  (time) => _updateBreakStartTime(index, time),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBreakTimeField(
                  'Fin',
                  breakPeriod.endTime,
                  (time) => _updateBreakEndTime(index, time),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakTimeField(
    String label,
    DateTime? time,
    Function(DateTime?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _selectTime(time, onChanged),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              time != null ? _formatTime(time) : 'Non défini',
              style: TextStyle(
                fontSize: 14,
                color: time != null ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteToggle() {
    return Row(
      children: [
        const Text(
          'Session terminée',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Switch.adaptive(
          value: _isComplete,
          onChanged: (value) => setState(() => _isComplete = value),
          activeColor: AppColors.primaryTeal,
        ),
      ],
    );
  }

  void _selectDate() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        DateTime selectedDate = _selectedDate;
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = selectedDate;
                      });
                      // Reload data for the new date
                      _loadSessionData();
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (date) {
                    selectedDate = date;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectTime(DateTime? currentTime, Function(DateTime?) onChanged) {
    final now = DateTime.now();
    final initialTime = currentTime ?? now;

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        DateTime selectedTime = initialTime;
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () {
                      onChanged(selectedTime);
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialTime,
                  onDateTimeChanged: (time) {
                    selectedTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      time.hour,
                      time.minute,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addBreak() {
    final now = DateTime.now();
    final breakStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
    );

    setState(() {
      _breaks.add(
        BreakPeriod(
          startTime: breakStart,
          endTime: breakStart.add(const Duration(minutes: 15)),
          isComplete: true,
        ),
      );
    });
  }

  void _removeBreak(int index) {
    setState(() {
      _breaks.removeAt(index);
    });
  }

  void _updateBreakStartTime(int index, DateTime? time) {
    if (time != null) {
      setState(() {
        _breaks[index] = _breaks[index].copyWith(startTime: time);
      });
    }
  }

  void _updateBreakEndTime(int index, DateTime? time) {
    setState(() {
      _breaks[index] = _breaks[index].copyWith(
        endTime: time,
        isComplete: time != null,
      );
    });
  }

  void _saveChanges() async {
    if (_currentSession == null) return;

    final updatedSession = _currentSession!.copyWith(
      date: _selectedDate,
      arrivalTime: _arrivalTime,
      departureTime: _departureTime,
      breaks: _breaks,
      isComplete: _isComplete,
    );

    try {
      // Save the session using the service
      await _workTimeService.updateSession(updatedSession);
      widget.onSave(updatedSession);
      Navigator.of(context).pop();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }
}
