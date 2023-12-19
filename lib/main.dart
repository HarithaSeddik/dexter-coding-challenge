import 'dart:io';

import 'package:dexter_challenge/data/cubits/audio_processing/audio_processing_cubit.dart';
import 'package:dexter_challenge/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = CustomHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define primary and secondary colors
    const primaryColor = Color.fromARGB(255, 156, 34, 31);
    const secondaryColor = Color.fromARGB(255, 34, 156, 156);

    return MaterialApp(
      title: 'Dexter Health Coding Challenge!',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          secondary: secondaryColor,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // BlocProviders serve as the reference entry point in the widget tree with respect to build context for other Bloc widgets. Always define providers higher up in the tree.
      home: BlocProvider(
        create: (context) => AudioProcessingCubit(SttApiService())
          ..requestPermissionsAndInit(), // start process as soon as we instantiate our cubit
        child: const MyHomePage(title: 'Always Listening'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dexter Health Flutter Challenge!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const UserProfileWidget(),
            const SizedBox(height: 20),
            const TitleSection(),
            const Spacer(),
            Expanded(child: _buildTranscriptionSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptionSection() {
    // Wrap state-dependent widgets with Bloc widgets like BlocConsumer/BlocBuilder
    // Additionally you can choose when to build these widgets by specifying "buildWhen" callback to further improve performance.
    return BlocConsumer<AudioProcessingCubit, AudioProcessingState>(
      builder: (context, state) {
        int apiCallCounter = 0;
        List<Map<String, dynamic>> transcripts = [];

        if (state is TranscriptionReceived) {
          apiCallCounter = state.apiCallCounter;
          transcripts = state.transcripts;
        }

        return Column(
          children: [
            Text(
              'API call counter: $apiCallCounter',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            for (var transcript in transcripts) ...[
              ListTile(
                leading: const Icon(Icons.record_voice_over),
                title: Text(transcript.toString()),
              ),
              const Divider(),
            ],
          ],
        );
      },
      listener: (context, state) {
        if (state is AudioStreamProcessingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error while handling the audio stream"),
            ),
          );
        }
      },
    );
  }
}

class TitleSection extends StatelessWidget {
  const TitleSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Always Listening',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'This app is always listening to you. Every 5 seconds, the audio is sent through the STT API. The last 3 transcripts will be shown on the screen. Additionally, a counter is shown every time the API has been called successfully',
        ),
      ],
    );
  }
}

class UserProfileWidget extends StatelessWidget {
  const UserProfileWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const CircleAvatar(
          child: Icon(Icons.account_circle),
        ),
        const SizedBox(width: 15),
        const Text(
          'Eren',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }
}
