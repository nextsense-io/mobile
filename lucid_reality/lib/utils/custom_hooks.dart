import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:record/record.dart';

AudioRecorder useAudioController() {
  return use(
    _AudioControllerHook(),
  );
}

class _AudioControllerHook extends Hook<AudioRecorder> {
  const _AudioControllerHook();

  @override
  HookState<AudioRecorder, Hook<AudioRecorder>> createState() => _AudioControllerHookState();
}

class _AudioControllerHookState extends HookState<AudioRecorder, _AudioControllerHook> {
  late final controller = AudioRecorder();

  @override
  AudioRecorder build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();

  @override
  String get debugLabel => 'useTabController';
}

void useInterval(VoidCallback callback, Duration delay) {
  final savedCallback = useRef(callback);
  savedCallback.value = callback;
  useEffect(() {
    final timer = Timer.periodic(delay, (_) => savedCallback.value());
    return timer.cancel;
  }, [delay]);
}
