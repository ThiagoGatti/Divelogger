import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class WaveBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const WaveBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const List<IconData> icons = [
    Icons.map_outlined,
    Icons.scuba_diving_outlined,
    Icons.bar_chart_outlined,
    Icons.location_on_outlined,
    Icons.person_outline,
  ];

  static const List<IconData> selectedIcons = [
    Icons.map,
    Icons.scuba_diving,
    Icons.bar_chart,
    Icons.location_on,
    Icons.person,
  ];

  static const List<String> labels = [
    'Mapa',
    'Mergulhos',
    'Atividade',
    'Sites',
    'Perfil',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: WavePainter(),
          ),

          SafeArea(
            top: false,
            child: Row(
              children: List.generate(
                labels.length,
                    (index) {
                  final selected = selectedIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDestinationSelected(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              selected
                                  ? selectedIcons[index]
                                  : icons[index],
                              size: 23,
                              color: selected
                                  ? DiverrTheme.primary
                                  : Colors.white,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8ED8E5)
      ..style = PaintingStyle.fill;

    final path = Path();

    path.moveTo(0, 25);

    path.cubicTo(
      size.width * 0.15,
      5,
      size.width * 0.30,
      45,
      size.width * 0.50,
      25,
    );

    path.cubicTo(
      size.width * 0.70,
      5,
      size.width * 0.85,
      45,
      size.width,
      20,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}