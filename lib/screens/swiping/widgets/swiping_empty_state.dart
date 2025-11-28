import 'package:flutter/material.dart';

/// Empty state widget displayed when there are no potential matches.
/// Shows either a loading indicator or a "no matches" message with a filter button.
class SwipingEmptyState extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onFilterTap;

  const SwipingEmptyState({
    super.key,
    required this.isLoading,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : const Text(
                  'No potential matches.\nTry adjusting your preferences.',
                  textAlign: TextAlign.center,
                ),
        ),
        if (!isLoading)
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Material(
                color: Colors.white.withOpacity(0.92),
                shape: const CircleBorder(),
                elevation: 6,
                child: IconButton(
                  tooltip: 'Adjust filters',
                  icon: const Icon(Icons.tune, color: Color(0xFF5B3CF0)),
                  onPressed: onFilterTap,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
