import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/theme/app_colors.dart';
import 'package:pointeur_app/bloc/backend_bloc.dart';
import 'package:pointeur_app/bloc/backend_events.dart';
import 'package:pointeur_app/bloc/backend_states.dart';
import 'package:pointeur_app/models/work_settings.dart';

class SettingsScreenContent extends StatefulWidget {
  const SettingsScreenContent({super.key});

  @override
  State<SettingsScreenContent> createState() => _SettingsScreenContentState();
}

class _SettingsScreenContentState extends State<SettingsScreenContent> {
  final _formKey = GlobalKey<FormState>();
  final _dailyHoursController = TextEditingController();
  final _breakDurationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    context.read<BackendBloc>().add(LoadSettingsEvent());
  }

  @override
  void dispose() {
    _dailyHoursController.dispose();
    _breakDurationController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryTeal, AppColors.primaryTealDark],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 32, color: Colors.white),
                    const SizedBox(width: 16),
                    Text(
                      'Paramètres',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Settings form
              Expanded(
                child: BlocConsumer<BackendBloc, BackendState>(
                  listener: (context, state) {
                    if (state is BackendErrorState) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else if (state is BackendLoadedState) {
                      if (state.successMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.successMessage!),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      // Update form with loaded settings
                      if (state.settings != null) {
                        _updateFormWithSettings(state.settings!);
                      }
                    }
                  },
                  builder: (context, state) {
                    if (state is BackendLoadingState) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Daily hours
                            _buildSettingsCard(
                              title: 'Heures de travail quotidiennes',
                              child: TextFormField(
                                controller: _dailyHoursController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Heures par jour',
                                  labelStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  suffixText: 'h',
                                  suffixStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer le nombre d\'heures';
                                  }
                                  final hours = double.tryParse(value);
                                  if (hours == null ||
                                      hours <= 0 ||
                                      hours > 24) {
                                    return 'Veuillez entrer un nombre valide entre 1 et 24';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Break duration
                            _buildSettingsCard(
                              title: 'Durée des pauses',
                              child: TextFormField(
                                controller: _breakDurationController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Minutes par pause',
                                  labelStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  suffixText: 'min',
                                  suffixStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer la durée des pauses';
                                  }
                                  final minutes = int.tryParse(value);
                                  if (minutes == null ||
                                      minutes <= 0 ||
                                      minutes > 480) {
                                    return 'Veuillez entrer un nombre valide entre 1 et 480';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Work time range
                            _buildSettingsCard(
                              title: 'Heures de travail',
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _startTimeController,
                                          readOnly: true,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Heure de début',
                                            labelStyle: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                            ),
                                            suffixIcon: Icon(
                                              Icons.access_time,
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.white.withValues(
                                                  alpha: 0.5,
                                                ),
                                              ),
                                            ),
                                            focusedBorder:
                                                const UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                          ),
                                          onTap:
                                              () => _selectStartTime(context),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _endTimeController,
                                          readOnly: true,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Heure de fin',
                                            labelStyle: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                            ),
                                            suffixIcon: Icon(
                                              Icons.access_time,
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.white.withValues(
                                                  alpha: 0.5,
                                                ),
                                              ),
                                            ),
                                            focusedBorder:
                                                const UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                          ),
                                          onTap: () => _selectEndTime(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Notifications
                            _buildSettingsCard(
                              title: 'Notifications',
                              child: SwitchListTile(
                                title: Text(
                                  'Activer les notifications',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  'Recevoir des rappels pour les pauses et fin de journée',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                value: _notificationsEnabled,
                                onChanged: (bool value) {
                                  setState(() {
                                    _notificationsEnabled = value;
                                  });
                                },
                                activeColor: Colors.white,
                                inactiveThumbColor: Colors.white.withValues(
                                  alpha: 0.5,
                                ),
                                inactiveTrackColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Save button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _saveSettings,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryTeal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Sauvegarder',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Update form fields with loaded settings
  void _updateFormWithSettings(WorkSettings settings) {
    _dailyHoursController.text = settings.dailyWorkHours.toString();
    _breakDurationController.text = settings.breakDuration.inMinutes.toString();

    // Parse time strings (format: "HH:mm")
    final startTimeParts = settings.workStartTime.split(':');
    final endTimeParts = settings.workEndTime.split(':');

    _selectedStartTime = TimeOfDay(
      hour: int.parse(startTimeParts[0]),
      minute: int.parse(startTimeParts[1]),
    );
    _selectedEndTime = TimeOfDay(
      hour: int.parse(endTimeParts[0]),
      minute: int.parse(endTimeParts[1]),
    );

    _startTimeController.text = _selectedStartTime!.format(context);
    _endTimeController.text = _selectedEndTime!.format(context);
    setState(() {
      _notificationsEnabled = settings.enableNotifications;
    });
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
        _startTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? const TimeOfDay(hour: 17, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedEndTime = picked;
        _endTimeController.text = picked.format(context);
      });
    }
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      if (_selectedStartTime == null || _selectedEndTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner les heures de travail'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Format time as "HH:mm"
      final startTimeString =
          '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}';
      final endTimeString =
          '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}';

      final settings = WorkSettings(
        dailyWorkHours: double.parse(_dailyHoursController.text),
        breakDuration: Duration(
          minutes: int.parse(_breakDurationController.text),
        ),
        workStartTime: startTimeString,
        workEndTime: endTimeString,
        enableNotifications: _notificationsEnabled,
      );

      context.read<BackendBloc>().add(UpdateSettingsEvent(settings));
    }
  }
}
