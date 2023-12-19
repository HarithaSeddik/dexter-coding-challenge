import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:dexter_challenge/data/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wav/wav_file.dart';

part 'audio_processing_state.dart';

class AudioProcessingCubit extends Cubit<AudioProcessingState> {
  // Pass service layer through constructor for clear class role definition
  AudioProcessingCubit(this._dataService) : super(Initial());
  final DataService _dataService;
  static const EventChannel _audioStreamChannel = EventChannel('audio_stream');
  List<int> audioBuffer = [];
  List<Map<String, dynamic>> transcripts = [];
  int apiCallCounter = 0;
  late Timer timer;

  Future<void> requestPermissionsAndInit() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      print('Microphone permission granted, should start recording');
      // If permissions are granted, start listening to the audio stream
      startProcessing();
    } else {
      // Handle the case when the user refuses to grant permissions
      print('Microphone permission not granted');
    }
  }

  void startProcessing() {
    emit(RecordingStarted());

    // Start a 5-second timer
    timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (audioBuffer.isNotEmpty) {
        // Stop recording and process the audio data
        final audioFile = await saveAudioAsWav(
            audioBuffer); // Implement this function to save audio as .wav

        // Send the audio for transcription
        sendTranscriptionRequest(audioFile);
      }
    });

    // Listen to the audio stream
    _audioStreamChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        final Uint8List audioData = Uint8List.fromList(event.cast<int>());
        print('Received audio data of length: ${audioData.length}');

        // Append the audio data to the buffer
        audioBuffer.addAll(audioData);
      },
      onError: (error) {
        print('Received error: $error');
        onStreamError();
      },
      cancelOnError: true,
    );
  }

  Future<String> saveAudioAsWav(List<int> audioBuffer) async {
    // Convert the int list to a Float64List, required by the Wav package
    // Here, we're assuming 16-bit PCM data.
    final Float64List floatAudioData = Float64List.fromList(
      audioBuffer.map((e) => (e / 32768.0)).toList(),
    );

    // Define the number of channels and sample rate of audio
    const int numChannels = 1;
    const int sampleRate = 44100;

    // Create a List<Float64List> (required by the Wav package)
    final List<Float64List> channels = List.generate(
      numChannels,
      (_) => floatAudioData,
    );

    // Use the Wav package to create a Wav object
    final Wav wav = Wav(channels, sampleRate);

    // Get the path to save the file
    final String filePath = await getFilePath();
    // Write the Wav object to a .wav file
    await wav.writeFile(filePath);
    print("Created wav file: $filePath");
    return filePath;
  }

  Future<String> getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    // Check if the path exists and create it if it doesn't
    final directoryToSave = Directory(path);
    if (!await directoryToSave.exists()) {
      await directoryToSave.create(recursive: true);
    }
    final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.wav';
    return '$path/$fileName';
  }

  void sendTranscriptionRequest(String audioFile) async {
    _dataService.sendAudioFile(audioFile).then((transcriptResponse) {
      print("Transcript received: $transcriptResponse");
      apiCallCounter++;
      // Add new transcript to the start of the list and keep only the last 3
      transcripts.insert(0, transcriptResponse);
      if (transcripts.length > 3) {
        transcripts = transcripts.sublist(0, 3);
      }
      emit(TranscriptionReceived(apiCallCounter, transcripts));
    }).catchError((error) {
      emit(TranscriptionOnError());
      print("Error receiving transcript: $error");
    });
  }

  void onStreamError() {
    emit(AudioStreamProcessingError());
  }
}
