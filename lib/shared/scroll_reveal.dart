import 'dart:async';

import 'package:flutter/material.dart';

/// Reveals a card the first time it enters the scroll viewport.
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal> {
  ScrollPosition? _position;
  Timer? _timer;
  bool _revealed = false;
  bool _checkScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (!identical(next, _position)) {
      _position?.removeListener(_scheduleVisibilityCheck);
      _position = next;
      _position?.addListener(_scheduleVisibilityCheck);
    }
    _scheduleVisibilityCheck();
  }

  void _scheduleVisibilityCheck() {
    if (_revealed || _checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (!mounted || _revealed) return;
      final render = context.findRenderObject();
      if (render is! RenderBox || !render.hasSize) return;
      final top = render.localToGlobal(Offset.zero).dy;
      final bottom = top + render.size.height;
      final screenHeight = MediaQuery.sizeOf(context).height;
      if (bottom > 92 && top < screenHeight - 56) {
        _timer = Timer(widget.delay, () {
          if (mounted) setState(() => _revealed = true);
        });
      }
    });
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleVisibilityCheck);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !_revealed,
    child: AnimatedOpacity(
      opacity: _revealed ? 1 : 0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _revealed ? Offset.zero : const Offset(0, .075),
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    ),
  );
}
