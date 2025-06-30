import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/UI/screens/data_screen.dart';
import 'package:pointeur_app/UI/screens/settings_screen.dart';
import 'package:pointeur_app/UI/widgets/nav_bar.dart';
import 'package:pointeur_app/theme/app_colors.dart';
import 'package:pointeur_app/bloc/backend_bloc.dart';
import 'package:pointeur_app/bloc/backend_events.dart';
import 'package:pointeur_app/bloc/backend_states.dart';
import 'package:pointeur_app/services/work_time_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    context.read<BackendBloc>().add(LoadTodaySessionEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Main content
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
                      } else if (state is BackendLoadedState &&
                          state.successMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.successMessage!),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is BackendLoadingState) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      return _buildMainContent(context, state);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTap: (index) => _handleNavigation(context, index),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, BackendState state) {
    final currentTime = DateTime.now();
    final timeString =
        '${currentTime.hour.toString().padLeft(2, '0')}h${currentTime.minute.toString().padLeft(2, '0')}';
    final dateString =
        '${currentTime.day} ${_getMonthName(currentTime.month)} ${currentTime.year}';

    WorkStatus? currentStatus;
    if (state is BackendLoadedState) {
      currentStatus = state.currentStatus;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Bonjour !',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          timeString,
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          dateString,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 60),

        // Action buttons
        _buildActionButtons(context, currentStatus),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WorkStatus? currentStatus) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 400;

        if (isWide) {
          return Row(
            children: [
              Expanded(child: _buildBreakButton(currentStatus)),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  'CP Aujourd\'hui',
                  AppColors.actionRed,
                  Icons.event_available_rounded,
                  () {
                    // TODO: Implement leave request for today
                  },
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildBreakButton(currentStatus)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      'CP Aujourd\'hui',
                      AppColors.actionRed,
                      Icons.event_available_rounded,
                      () {
                        // TODO: Implement leave request for today
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildArrivalButton(currentStatus)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDepartureButton(currentStatus)),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildArrivalButton(WorkStatus? currentStatus) {
    final isEnabled = currentStatus == WorkStatus.notStarted;
    final color = isEnabled ? AppColors.actionBlue : Colors.grey;

    return _buildActionButton(
      'Arrivée',
      color,
      Icons.login_rounded,
      isEnabled
          ? () {
            context.read<BackendBloc>().add(RecordArrivalEvent());
          }
          : null,
    );
  }

  Widget _buildDepartureButton(WorkStatus? currentStatus) {
    final isEnabled =
        currentStatus == WorkStatus.working ||
        currentStatus == WorkStatus.onBreak;
    final color = isEnabled ? AppColors.actionTeal : Colors.grey;

    return _buildActionButton(
      'Départ',
      color,
      Icons.logout_rounded,
      isEnabled
          ? () {
            context.read<BackendBloc>().add(RecordDepartureEvent());
          }
          : null,
    );
  }

  Widget _buildBreakButton(WorkStatus? currentStatus) {
    final isOnBreak = currentStatus == WorkStatus.onBreak;
    final isWorking = currentStatus == WorkStatus.working;
    final isEnabled = isWorking || isOnBreak;

    String label;
    IconData icon;
    VoidCallback? onTap;

    if (isOnBreak) {
      label = 'Fin pause';
      icon = Icons.play_arrow_rounded;
      onTap = () {
        context.read<BackendBloc>().add(EndBreakEvent());
      };
    } else if (isWorking) {
      label = 'Début pause';
      icon = Icons.pause_rounded;
      onTap = () {
        context.read<BackendBloc>().add(StartBreakEvent());
      };
    } else {
      label = 'Début pause';
      icon = Icons.pause_rounded;
      onTap = null;
    }

    final color = isEnabled ? AppColors.actionOrange : Colors.grey;

    return _buildActionButton(label, color, icon, onTap);
  }

  Widget _buildActionButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return months[month - 1];
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DataScreen()),
        );
        break;
      case 1:
        // Already on home screen
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
    }
  }
}
