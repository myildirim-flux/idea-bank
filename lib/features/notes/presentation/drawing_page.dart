import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

class DrawingPage extends StatefulWidget {
  final String? strokes;

  const DrawingPage({super.key, this.strokes});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  List<List<PointVector>> _strokes = [];
  List<PointVector> _currentStroke = [];
  StrokeOptions _options = StrokeOptions(
    size: 10,
    thinning: 0.0,
    smoothing: 0.5,
    streamline: 0.5,
    simulatePressure: false,
  );
  ui.Image? _backgroundImage;

  bool _isBackgroundImageRendered = false;

  @override
  void initState() {
    super.initState();
    if (widget.strokes != null) {
      _strokes = _deserializeStrokes(widget.strokes!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.strokes != null && !_isBackgroundImageRendered) {
      _renderBackgroundImage();
      _isBackgroundImageRendered = true;
    }
  }

  Future<void> _renderBackgroundImage() async {
    final size = MediaQuery.of(context).size;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = DrawingPainter(_strokes, _options);
    painter.paint(canvas, size);
    final picture = recorder.endRecording();
    _backgroundImage = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    if (mounted) {
      setState(() {});
    }
  }

  String _serializeStrokes(List<List<PointVector>> strokes) {
    return jsonEncode(
      strokes
          .map(
            (stroke) => stroke
                .map(
                  (point) => {'x': point.x, 'y': point.y, 'p': point.pressure},
                )
                .toList(),
          )
          .toList(),
    );
  }

  List<List<PointVector>> _deserializeStrokes(String json) {
    final data = jsonDecode(json) as List;
    return data
        .map(
          (stroke) => (stroke as List)
              .map((point) => PointVector(point['x'], point['y'], point['p']))
              .toList(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw your note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _strokes.clear();
                _backgroundImage = null;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final allStrokes = _strokes + [_currentStroke];
              final recorder = ui.PictureRecorder();
              final canvas = Canvas(recorder);
              final painter = DrawingPainter(allStrokes, _options);
              final size = MediaQuery.of(context).size;
              painter.paint(canvas, size);
              final picture = recorder.endRecording();
              final img = await picture.toImage(
                size.width.toInt(),
                size.height.toInt(),
              );
              final byteData = await img.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final preview = byteData?.buffer.asUint8List();

              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pop(context, {
                'preview': base64Encode(preview!),
                'strokes': _serializeStrokes(allStrokes),
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final updatedOptions = await _showSettingsDialog();
              if (updatedOptions != null) {
                setState(() {
                  _options = updatedOptions;
                });
              }
            },
          ),
        ],
      ),
      body: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _currentStroke = [
              PointVector(
                details.localPosition.dx,
                details.localPosition.dy,
                1,
              ),
            ];
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _currentStroke.add(
              PointVector(
                details.localPosition.dx,
                details.localPosition.dy,
                1,
              ),
            );
          });
        },
        onPanEnd: (details) {
          setState(() {
            _strokes.add(_currentStroke);
            _currentStroke = [];
            _renderBackgroundImage();
          });
        },
        child: CustomPaint(
          painter: LayeredDrawingPainter(_backgroundImage, [
            _currentStroke,
          ], _options),
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      children: [
        Text('$title: ${value.toStringAsFixed(2)}'),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }

  Future<StrokeOptions?> _showSettingsDialog() {
    StrokeOptions tempOptions =
        _options; // Use a temporary variable for dialog state

    return showDialog<StrokeOptions>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Use StatefulBuilder to update dialog content
          builder: (context, setInnerState) {
            return AlertDialog(
              title: const Text('Drawing Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSlider('Size', tempOptions.size, 1, 20, (value) {
                    setInnerState(() {
                      tempOptions = tempOptions.copyWith(size: value);
                    });
                  }),
                  _buildSlider('Thinning', tempOptions.thinning, 0, 1, (value) {
                    setInnerState(() {
                      tempOptions = tempOptions.copyWith(thinning: value);
                    });
                  }),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Apply'),
                  onPressed: () {
                    Navigator.of(context).pop(tempOptions);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<List<PointVector>> strokes;
  final StrokeOptions options;

  DrawingPainter(this.strokes, this.options);

  @override
  void paint(Canvas canvas, Size size) {
    for (final strokePoints in strokes) {
      if (strokePoints.isEmpty) continue;

      final stroke = getStroke(strokePoints, options: options);

      final Path path = Path();
      for (int i = 0; i < stroke.length; i++) {
        final segment = stroke[i];
        if (i == 0) {
          path.moveTo(segment.dx, segment.dy);
        } else {
          path.lineTo(segment.dx, segment.dy);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}

class LayeredDrawingPainter extends CustomPainter {
  final ui.Image? backgroundImage;
  final List<List<PointVector>> newStrokes;
  final StrokeOptions options;

  LayeredDrawingPainter(this.backgroundImage, this.newStrokes, this.options);

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundImage != null) {
      canvas.drawImage(backgroundImage!, Offset.zero, Paint());
    }

    final painter = DrawingPainter(newStrokes, options);
    painter.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant LayeredDrawingPainter oldDelegate) {
    return oldDelegate.backgroundImage != backgroundImage ||
        oldDelegate.newStrokes != newStrokes;
  }
}
