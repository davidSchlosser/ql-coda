import 'package:flutter/material.dart';

class AssembleRoute extends PopupRoute {
  final WidgetBuilder builder;
  final bool dismissible;
  final String label;
  final Color color;

  AssembleRoute({
    required this.builder,
    this.dismissible = true,
    this.label = '',
    this.color = const Color(0),
    RouteSettings setting = const RouteSettings(),
  }) : super(settings: setting);

  @override
  Color get barrierColor => color;

  @override
  bool get barrierDismissible => dismissible;

  @override
  String get barrierLabel => label;

  @override
  bool get opaque => false;

  @override
  bool get semanticsDismissible => false;

  @override
  Widget buildPage(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      ) {
    return builder(context);
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);


}