import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointeur_app/bloc/backend_events.dart';
import 'package:pointeur_app/bloc/backend_repository_interface.dart';
import 'package:pointeur_app/bloc/backend_states.dart';

class BackendBloc extends Bloc<Event, State> {
  final IRepository backendRepository;

  BackendBloc({required this.backendRepository}) : super(InitialState()) {
    on<FetchData>(_onFetchData);
  }

  Future<void> _onFetchData(FetchData event, Emitter<State> emit) async {
    emit(LoadingState());
    try {
      final data = await backendRepository.fetchAll();
      emit(LoadedState(data));
    } catch (e) {
      emit(ErrorState(e.toString()));
    }
  }
}
