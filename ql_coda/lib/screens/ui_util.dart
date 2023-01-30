import 'package:flutter/material.dart';

Widget dismissBackground(alignment) {
  return Container(
    color: Colors.amberAccent,
    child: Align(
      alignment: alignment,
      child: const Icon(Icons.delete_sweep),
    ),
  );
}

List<String> performerRoles(String perfRoles) {
  RegExp re = RegExp(r"([^,(]*\([^)]*\))*[^,]*(,|$)");
  List l = re.allMatches(perfRoles).toList();
  List<String> performerRoles = [];
  for (Match e in l) {
    String s0 = e.group(0)!.trimLeft();

    // strip trailing ','
    String s1 = s0.length > 0 && s0.endsWith(',')
        ? s0.substring(0, s0.length - 1)
        : s0;

    performerRoles.add(s1);
  }
  return performerRoles;
}

class NilWidget extends StatelessWidget {
  const NilWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
