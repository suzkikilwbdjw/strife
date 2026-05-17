import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/presentation/blocs/home/home_event.dart';
import 'package:strife/presentation/blocs/home/home_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(NavigationState(currentTabIndex: 0)) {
    on<ChangeTab>(
      (event, emit) => emit(NavigationState(currentTabIndex: event.tabIndex)),
    );
  }
}
