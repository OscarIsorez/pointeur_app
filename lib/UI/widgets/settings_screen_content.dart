import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/theme/app_colors.dart';
import 'package:pointeur_app/bloc/settings_bloc.dart';
import 'package:pointeur_app/bloc/settings_events.dart';
import 'package:pointeur_app/bloc/settings_states.dart';
import 'package:pointeur_app/models/work_settings.dart';
import 'package:pointeur_app/UI/widgets/animated_save_button.dart';

class SettingsScreenContent extends StatefulWidget {
  const SettingsScreenContent({super.key});

  @override
  State<SettingsScreenContent> createState() => _SettingsScreenContentState();
}

class _SettingsScreenContentState extends State<SettingsScreenContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();
  final _dailyHoursController = TextEditingController();
  final _dailyMinutesController = TextEditingController();
  final _breakDurationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  // Scroll controllers for the CupertinoPickers
  late FixedExtentScrollController _hoursScrollController;
  late FixedExtentScrollController _minutesScrollController;

  bool _notificationsEnabled = true;
  bool _hasBeenInitialized = false;

  // Values for the roller pickers - will be initialized from settings
  int _selectedHours = 8; // Default fallback
  int _selectedMinutes = 0; // Default fallback

  @override
  void initState() {
    super.initState();

    // Initialize with defaults first
    _hoursScrollController = FixedExtentScrollController(
      initialItem: _selectedHours,
    );
    _minutesScrollController = FixedExtentScrollController(
      initialItem: _selectedMinutes,
    );

    // Initialize text controllers with default values
    _breakDurationController.text = '30'; // Default break duration

    // Check if settings are already available and use them
    final currentState = context.read<SettingsBloc>().state;
    if (currentState is SettingsLoadedState) {
      _initializeWithSettings(currentState.settings);
    }

    _loadDataIfNeeded();
  }

  /// Initialize form fields with settings without animations (for initial load)
  void _initializeWithSettings(WorkSettings settings) {
    if (_hasBeenInitialized) return;

    final totalMinutes = (settings.dailyWorkHours * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    // Update state variables
    _selectedHours = hours;
    _selectedMinutes = minutes;
    _notificationsEnabled = settings.enableNotifications;

    // Update text controllers
    _breakDurationController.text = settings.breakDuration.inMinutes.toString();

    // Jump to the correct positions without animation for initial load
    _hoursScrollController.jumpToItem(hours);
    _minutesScrollController.jumpToItem(_selectedMinutes);

    _hasBeenInitialized = true;
  }

  void _loadDataIfNeeded() {
    final currentState = context.read<SettingsBloc>().state;

    // Load data if we're in initial or error state
    bool needsToLoad = false;

    if (currentState is SettingsInitialState ||
        currentState is SettingsErrorState) {
      needsToLoad = true;
    } else if (currentState is SettingsLoadedState) {
      // If we already have settings, update the form immediately
      _updateFormWithSettings(currentState.settings);
    }

    if (needsToLoad) {
      context.read<SettingsBloc>().add(LoadSettingsEvent());
    }
  }

  @override
  void dispose() {
    _dailyHoursController.dispose();
    _dailyMinutesController.dispose();
    _breakDurationController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _hoursScrollController.dispose();
    _minutesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryTeal, AppColors.primaryTealDark],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Padding(
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
                    child: BlocConsumer<SettingsBloc, SettingsState>(
                      listener: (context, state) {
                        if (state is SettingsErrorState) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else if (state is SettingsLoadedState) {
                          if (state.successMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.successMessage!),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          // Update form with loaded settings
                          _updateFormWithSettings(state.settings);
                        }
                      },
                      builder: (context, state) {
                        if (state is SettingsLoadingState) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          // Ajouter un padding en bas pour éviter que le contenu soit caché par le bouton
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // ...existing code...
                                _buildSettingsCard(
                                  title: 'Heures de travail quotidiennes',
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Heures',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.8),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  height: 120,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                    ),
                                                  ),
                                                  child: CupertinoPicker(
                                                    itemExtent: 40,
                                                    scrollController:
                                                        _hoursScrollController,
                                                    onSelectedItemChanged: (
                                                      int index,
                                                    ) {
                                                      setState(() {
                                                        _selectedHours = index;
                                                      });
                                                    },
                                                    children: List.generate(24, (
                                                      index,
                                                    ) {
                                                      return Center(
                                                        child: Text(
                                                          '$index h',
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                      );
                                                    }),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Minutes',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.8),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  height: 120,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                    ),
                                                  ),
                                                  child: CupertinoPicker(
                                                    itemExtent: 40,
                                                    scrollController:
                                                        _minutesScrollController,
                                                    onSelectedItemChanged: (
                                                      int index,
                                                    ) {
                                                      setState(() {
                                                        _selectedMinutes =
                                                            index;
                                                      });
                                                    },
                                                    children: List.generate(60, (
                                                      index,
                                                    ) {
                                                      return Center(
                                                        child: Text(
                                                          '$index min',
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                      );
                                                    }),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Sélectionné: ${_selectedHours}h ${_selectedMinutes}min',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
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
                                      hintText: '30', // Default value hint
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      labelStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                      suffixText: 'min',
                                      suffixStyle: TextStyle(
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
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                        ),
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
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
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
            // Bouton de sauvegarde animé flottant
            AnimatedSaveButton(onPressed: _saveSettings, isLoading: false),
          ],
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
    // If not initialized yet, use the initialization method instead
    if (!_hasBeenInitialized) {
      _initializeWithSettings(settings);
      return;
    }

    // Convert decimal hours to hours and minutes
    final totalMinutes = (settings.dailyWorkHours * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    setState(() {
      _selectedHours = hours;
      // Use exact minutes value
      _selectedMinutes = minutes;
      _notificationsEnabled = settings.enableNotifications;
    });

    // Update the scroll controllers to show the correct values with animation
    _hoursScrollController.animateToItem(
      hours,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _minutesScrollController.animateToItem(
      _selectedMinutes,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Update text controllers with the loaded values
    _dailyHoursController.text = hours.toString();
    _dailyMinutesController.text = minutes.toString();
    _breakDurationController.text = settings.breakDuration.inMinutes.toString();
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      // Check that total time is not zero
      if (_selectedHours == 0 && _selectedMinutes == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La durée de travail doit être supérieure à 0'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Convert hours and minutes to decimal hours
      final dailyWorkHours = _selectedHours + (_selectedMinutes / 60.0);

      final settings = WorkSettings(
        dailyWorkHours: dailyWorkHours,
        breakDuration: Duration(
          minutes: int.parse(_breakDurationController.text),
        ),
        enableNotifications: _notificationsEnabled,
      );

      context.read<SettingsBloc>().add(UpdateSettingsEvent(settings));
    }
  }
}
