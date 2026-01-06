import 'package:flutter/material.dart';
import '../../utils/exercise_icon_utils.dart';

class PulsingExerciseIcon extends StatefulWidget {
  final String exerciseId;
  final String muscleGroup;
  final double size;
  final bool isActive;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool showShadow;
  final bool useGradient;

  const PulsingExerciseIcon({
    super.key,
    required this.exerciseId,
    required this.muscleGroup,
    this.size = 50,
    this.isActive = true,
    this.onTap,
    this.showBorder = true,
    this.showShadow = true,
    this.useGradient = false,
  });

  @override
  State<PulsingExerciseIcon> createState() => _PulsingExerciseIconState();
}

class _PulsingExerciseIconState extends State<PulsingExerciseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isActive) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller.repeat(reverse: true);
  }

  void _stopAnimation() {
    _controller.stop();
    _controller.value = 0;
  }

  @override
  void didUpdateWidget(PulsingExerciseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
    
    if (widget.exerciseId != oldWidget.exerciseId || 
        widget.muscleGroup != oldWidget.muscleGroup) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = ExerciseIconUtils.getMuscleGroupColor(widget.muscleGroup);
    final icon = ExerciseIconUtils.getExerciseIcon(widget.exerciseId);
    final gradient = ExerciseIconUtils.getMuscleGroupGradient(widget.muscleGroup);

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: widget.onTap != null 
            ? SystemMouseCursors.click 
            : SystemMouseCursors.basic,
        child: ScaleTransition(
          scale: _animation,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.useGradient ? null : color.withAlpha(38), // 0.15 * 255 ≈ 38
              gradient: widget.useGradient
                  ? LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              shape: BoxShape.circle,
              border: widget.showBorder
                  ? Border.all(
                      color: color,
                      width: 2.0,
                    )
                  : null,
              boxShadow: widget.showShadow
                  ? [
                      BoxShadow(
                        color: color.withAlpha(76), // 0.3 * 255 ≈ 76
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: widget.size * 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}