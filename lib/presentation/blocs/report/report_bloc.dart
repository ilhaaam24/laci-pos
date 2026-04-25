import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/report_service.dart';

// Events
abstract class ReportEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDailyReport extends ReportEvent {
  final DateTime date;
  LoadDailyReport(this.date);
  @override
  List<Object?> get props => [date];
}

class LoadWeeklyReport extends ReportEvent {
  final DateTime date;
  LoadWeeklyReport(this.date);
  @override
  List<Object?> get props => [date];
}

class LoadMonthlyReport extends ReportEvent {
  final DateTime date;
  LoadMonthlyReport(this.date);
  @override
  List<Object?> get props => [date];
}

class LoadCustomRangeReport extends ReportEvent {
  final DateTime startDate;
  final DateTime endDate;
  LoadCustomRangeReport(this.startDate, this.endDate);
  @override
  List<Object?> get props => [startDate, endDate];
}

// States
abstract class ReportState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportLoaded extends ReportState {
  final Map<String, dynamic> reportData;
  ReportLoaded(this.reportData);
  @override
  List<Object?> get props => [reportData];
}

class ReportError extends ReportState {
  final String message;
  ReportError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportService reportService;

  ReportBloc({required this.reportService}) : super(ReportInitial()) {
    on<LoadDailyReport>(_onLoadDailyReport);
    on<LoadWeeklyReport>(_onLoadWeeklyReport);
    on<LoadMonthlyReport>(_onLoadMonthlyReport);
    on<LoadCustomRangeReport>(_onLoadCustomRangeReport);
  }

  Future<void> _onLoadDailyReport(
    LoadDailyReport event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    print('ReportBloc: Loading Daily Report for ${event.date}');
    try {
      final data = await reportService.getDailyReport(event.date);
      print('ReportBloc: Daily Report Loaded: $data');
      emit(ReportLoaded(data));
    } catch (e) {
      print('ReportBloc: Daily Report Error: $e');
      emit(ReportError(e.toString()));
    }
  }

  Future<void> _onLoadWeeklyReport(
    LoadWeeklyReport event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    print('ReportBloc: Loading Weekly Report for ${event.date}');
    try {
      final data = await reportService.getWeeklyReport(event.date);
      print('ReportBloc: Weekly Report Loaded: $data');
      emit(ReportLoaded(data));
    } catch (e) {
      print('ReportBloc: Weekly Report Error: $e');
      emit(ReportError(e.toString()));
    }
  }

  Future<void> _onLoadMonthlyReport(
    LoadMonthlyReport event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    print('ReportBloc: Loading Monthly Report for ${event.date}');
    try {
      final data = await reportService.getMonthlyReport(event.date);
      print('ReportBloc: Monthly Report Loaded: $data');
      emit(ReportLoaded(data));
    } catch (e) {
      print('ReportBloc: Monthly Report Error: $e');
      emit(ReportError(e.toString()));
    }
  }

  Future<void> _onLoadCustomRangeReport(
    LoadCustomRangeReport event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    print('ReportBloc: Loading Custom Range Report from ${event.startDate} to ${event.endDate}');
    try {
      final data = await reportService.getCustomRangeReport(event.startDate, event.endDate);
      print('ReportBloc: Custom Range Report Loaded: $data');
      emit(ReportLoaded(data));
    } catch (e) {
      print('ReportBloc: Custom Range Report Error: $e');
      emit(ReportError(e.toString()));
    }
  }
}
