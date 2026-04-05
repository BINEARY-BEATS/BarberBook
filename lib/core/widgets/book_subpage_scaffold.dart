import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Full-screen scaffold with a consistent back action for stacked routes.
///
/// Uses [context.pop] when possible; otherwise navigates to [fallbackLocation].
class BookSubpageScaffold extends StatelessWidget {
  /// Creates a subpage with [title] and [body].
  const BookSubpageScaffold({
    required this.title,
    required this.body,
    this.fallbackLocation,
    this.actions,
    super.key,
  });

  /// App bar title.
  final String title;

  /// Page body.
  final Widget body;

  /// Used when there is nothing to pop (e.g. cold open of a deep link).
  final String? fallbackLocation;

  /// Optional app bar actions after the online switch pattern, etc.
  final List<Widget>? actions;

  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else if (fallbackLocation != null) {
      context.go(fallbackLocation!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canLeave = context.canPop() || fallbackLocation != null;

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && fallbackLocation != null) {
          context.go(fallbackLocation!);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: canLeave
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                  onPressed: () => _onBack(context),
                )
              : null,
          title: Text(title),
          actions: actions,
        ),
        body: body,
      ),
    );
  }
}
