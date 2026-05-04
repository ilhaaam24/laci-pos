import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/services/session_service.dart';

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
  final SessionService sessionService;

  ReportBloc({
    required this.reportService,
    required this.sessionService,
  }) : super(ReportInitial()) {
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
    try {
      final businessId = sessionService.businessId ?? '';
      final data = await reportService.getDailyReport(businessId, event.date);
      emit(ReportLoaded(data));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }

  Future<void> _onLoadWeeklyReport(
    LoadWeeklyReport event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final businessId = sessionService.businessId ?? '';
      final data = await reportService.getWeeklyReport(businessId, event.date);
      emit(ReportLoaded(data));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }

  Future<void> _onLoadMonthlyReport(
    LoadMonthlyReport event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final businessId = sessionService.businessId ?? '';
      final data = await reportService.getMonthlyReport(businessId, event.date);
      emit(ReportLoaded(data));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }

  Future<void> _onLoadCustomRangeReport(
    LoadCustomRangeReport event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final businessId = sessionService.businessId ?? '';
      final data = await reportService.getCustomRangeReport(
        businessId: businessId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(ReportLoaded(data));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }
}
