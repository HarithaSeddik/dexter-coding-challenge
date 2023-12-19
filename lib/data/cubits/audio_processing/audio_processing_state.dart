part of 'audio_processing_cubit.dart';

@immutable
sealed class AudioProcessingState {}

final class Initial extends AudioProcessingState {}

final class RecordingStarted extends AudioProcessingState {}

final class AudioCaptured extends AudioProcessingState {}

abstract class TranscriptionState extends AudioProcessingState {}

final class TranscriptionReceived extends TranscriptionState {
  final int apiCallCounter;
  final List<Map<String, dynamic>> transcripts;

  TranscriptionReceived(this.apiCallCounter, this.transcripts);
}

final class TranscriptionOnError extends TranscriptionState {}

final class AudioStreamProcessingError extends AudioProcessingState {}
