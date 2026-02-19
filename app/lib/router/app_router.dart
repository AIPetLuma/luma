import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/pet_state.dart';
import '../features/onboarding/ai_disclosure_screen.dart';
import '../features/onboarding/birth_screen.dart';
import '../features/onboarding/name_screen.dart';
import '../features/home/home_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/settings/settings_screen.dart';
import '../providers/pet_provider.dart';
import '../core/identity/pet_identity.dart';
import '../data/local/secure_storage.dart';
import '../shared/constants.dart';
import '../features/chat/chat_controller.dart' as ctrl;

/// Top-level router that decides which screen to show based on app state.
///
/// Flow: Loading → Onboarding (if no pet) → Home ↔ Chat / Settings
class AppRouter extends ConsumerStatefulWidget {
  const AppRouter({super.key});

  @override
  ConsumerState<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<AppRouter>
    with WidgetsBindingObserver {
  _Screen _screen = _Screen.loading;
  PersonalityPreset? _selectedPreset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(lifeEngineProvider).dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final engine = ref.read(lifeEngineProvider);
    if (state == AppLifecycleState.paused) {
      engine.pause();
      // Compress conversation on background.
      ref.read(chatControllerProvider).endSession();
    } else if (state == AppLifecycleState.resumed) {
      engine.resume().then((_) {
        ref.read(petStateProvider.notifier).refresh();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(petStateProvider);

    return petAsync.when(
      loading: () => const _LoadingScreen(),
      error: (e, _) => _ErrorScreen(error: e.toString()),
      data: (petState) {
        // No pet → start onboarding.
        if (petState == null && _screen != _Screen.onboardingBirth &&
            _screen != _Screen.onboardingName) {
          _screen = _Screen.onboardingDisclosure;
        }

        // Pet exists but screen is still loading → go home.
        if (petState != null && _screen == _Screen.loading) {
          _screen = _Screen.home;
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildScreen(petState),
        );
      },
    );
  }

  Widget _buildScreen(PetState? petState) {
    switch (_screen) {
      case _Screen.loading:
        return const _LoadingScreen();

      case _Screen.onboardingDisclosure:
        return AiDisclosureScreen(
          key: const ValueKey('disclosure'),
          onAccepted: () => setState(() {
            _screen = _Screen.onboardingBirth;
          }),
        );

      case _Screen.onboardingBirth:
        return BirthScreen(
          key: const ValueKey('birth'),
          onSelected: (preset) => setState(() {
            _selectedPreset = preset;
            _screen = _Screen.onboardingName;
          }),
        );

      case _Screen.onboardingName:
        return NameScreen(
          key: const ValueKey('name'),
          onNamed: (name) async {
            await ref.read(petStateProvider.notifier).birthPet(
                  name: name,
                  preset: _selectedPreset,
                );
            if (mounted) setState(() => _screen = _Screen.home);
          },
        );

      case _Screen.home:
        return _buildHome(petState!);

      case _Screen.chat:
        return _buildChat(petState!);

      case _Screen.settings:
        return SettingsScreen(
          key: const ValueKey('settings'),
          petState: petState!,
          onBack: () => setState(() => _screen = _Screen.home),
          onResetPet: () async {
            final petDao = ref.read(petDaoProvider);
            final chatDao = ref.read(chatDaoProvider);
            final engine = ref.read(lifeEngineProvider);
            engine.dispose();
            if (petState != null) {
              await chatDao.deleteAllForPet(petState.id);
              await petDao.delete(petState.id);
            }
            if (mounted) {
              setState(() => _screen = _Screen.onboardingDisclosure);
            }
            ref.invalidate(petStateProvider);
          },
          onApiKeyChanged: (key) async {
            await SecureStorage.setApiKey(key);
            ref.invalidate(apiKeyProvider);
          },
        );
    }
  }

  Widget _buildHome(PetState petState) {
    final diaryAsync = ref.watch(diaryEntriesProvider(petState.id));
    final entries = diaryAsync.valueOrNull ?? [];

    return HomeScreen(
      key: const ValueKey('home'),
      petState: petState,
      diaryEntries: entries,
      onChatTap: () => setState(() {
        ref.read(lifeEngineProvider).isUserInteracting = true;
        _screen = _Screen.chat;
      }),
      onSettingsTap: () => setState(() => _screen = _Screen.settings),
    );
  }

  Widget _buildChat(PetState petState) {
    final messagesAsync = ref.watch(chatMessagesProvider(petState.id));
    final messages = messagesAsync.valueOrNull ?? [];

    // Check if we need to show the disclosure reminder (every 3 hours).
    final lastDisclosure = ref.watch(lastDisclosureTimeProvider);
    final needsReminder = lastDisclosure == null ||
        DateTime.now().difference(lastDisclosure).inMinutes >=
            LumaConstants.disclosureIntervalMinutes;

    return ChatScreen(
      key: const ValueKey('chat'),
      petState: petState,
      messages: messages,
      showDisclosureReminder: needsReminder,
      onDisclosureDismissed: () {
        ref.read(lastDisclosureTimeProvider.notifier).state = DateTime.now();
      },
      onSendMessage: (text) async {
        final result = await ref.read(chatControllerProvider).sendMessage(text);
        // Refresh messages and pet state after sending.
        ref.invalidate(chatMessagesProvider(petState.id));
        ref.read(petStateProvider.notifier).refresh();
        return ChatResult(
          reply: result.reply,
          isCrisis: result.isCrisis,
          riskLevel: result.riskLevel,
          crisisMessage: result.crisisMessage,
          emotion: result.emotion,
        );
      },
      onBack: () => setState(() {
        ref.read(lifeEngineProvider).isUserInteracting = false;
        _screen = _Screen.home;
      }),
    );
  }
}

enum _Screen {
  loading,
  onboardingDisclosure,
  onboardingBirth,
  onboardingName,
  home,
  chat,
  settings,
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Luma is waking up...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Something went wrong:\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
