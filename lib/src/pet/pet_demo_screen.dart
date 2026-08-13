import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'pet_controller.dart';
import 'pet_widget.dart';

/// Dev playground for the cat: the character centred, one button per state.
/// Reached from the settings pet section.
class PetDemoScreen extends StatefulWidget {
  const PetDemoScreen({super.key});

  @override
  State<PetDemoScreen> createState() => _PetDemoScreenState();
}

class _PetDemoScreenState extends State<PetDemoScreen> {
  final _controller = PetController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const Spacer(),
          Center(child: PetWidget(size: 260, controller: _controller)),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Wrap(
              spacing: 12,
              children: [
                for (final (key, action) in [
                  ('settings.pet.state_idle', _controller.idle),
                  ('settings.pet.state_walk', _controller.walk),
                  ('settings.pet.state_jump', _controller.jump),
                  ('settings.pet.state_wink', _controller.wink),
                ])
                  OutlinedButton(onPressed: action, child: Text(tr(key))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              tr('settings.pet.demo_hint'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
