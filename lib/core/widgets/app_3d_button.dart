import 'package:book_inventory_apps/core/theme/app_colors.dart';
import 'package:book_inventory_apps/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tombol interaktif bergaya 3D fisik (tactile push button) dengan ketebalan
/// bevel bawah dan animasi gerak turun (*press translation*) saat disentuh.
///
/// Bila [onPressed] null atau [isLoading] true, tombol otomatis berada dalam status
/// *disabled* (rata/flat tanpa bayangan tebal) dan mencegah interaksi berulang.
class App3DButton extends StatefulWidget {
  const App3DButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.loadingLabel,
    this.backgroundColor,
    this.foregroundColor,
    this.bevelColor,
    this.width,
    this.height = AppTokens.minTouchTarget,
    this.borderRadius,
    this.fontSize,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final String? loadingLabel;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? bevelColor;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final double? fontSize;

  @override
  State<App3DButton> createState() => _App3DButtonState();
}

class _App3DButtonState extends State<App3DButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  Color _resolveBevelColor(Color baseColor) {
    if (widget.bevelColor != null) return widget.bevelColor!;
    // Hitamkan warna dasar sebesar 28% untuk bayangan bevel bawah 3D
    return Color.alphaBlend(Colors.black.withValues(alpha: 0.28), baseColor);
  }

  void _handleTapDown(TapDownDetails _) {
    if (!_isEnabled) return;
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails _) {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final defaultRadius = BorderRadius.circular(AppTokens.radiusFull);
    final radius = widget.borderRadius ?? defaultRadius;

    final baseBgColor = widget.backgroundColor ?? palette.primary;
    final baseFgColor = widget.foregroundColor ?? palette.onPrimary;

    final effectiveBg = _isEnabled
        ? baseBgColor
        : (widget.isLoading ? baseBgColor.withValues(alpha: 0.85) : palette.border);
    final effectiveFg = _isEnabled
        ? baseFgColor
        : (widget.isLoading ? baseFgColor : palette.textMuted);
    final effectiveBevel = _isEnabled
        ? _resolveBevelColor(baseBgColor)
        : (_isEnabled ? palette.border : Colors.transparent);

    const double bevelDepth = 4.0;
    final double currentOffset = (_isPressed && _isEnabled) ? 2.5 : 0.0;

    final currentText = widget.isLoading
        ? (widget.loadingLabel ?? widget.label)
        : widget.label;

    return Semantics(
      button: true,
      enabled: _isEnabled,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _isEnabled ? widget.onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.width,
          height: widget.height + bevelDepth,
          child: Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              // Lapisan Dasar / Bevel 3D (Physical Base)
              Positioned(
                top: bevelDepth,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: effectiveBevel,
                    borderRadius: radius,
                  ),
                ),
              ),

              // Lapisan Atas Tombol (Surface Face) yang bergerak turun saat ditekan
              AnimatedPositioned(
                duration: const Duration(milliseconds: 70),
                curve: Curves.easeOutQuad,
                top: currentOffset,
                left: 0,
                right: 0,
                height: widget.height,
                child: Container(
                  decoration: BoxDecoration(
                    color: effectiveBg,
                    borderRadius: radius,
                    border: Border.all(
                      color: _isEnabled
                          ? Colors.white.withValues(alpha: 0.15)
                          : palette.border,
                      width: 1,
                    ),
                    boxShadow: _isEnabled
                        ? <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              offset: const Offset(0, 1),
                              blurRadius: 1.5,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space16,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (widget.isLoading) ...<Widget>[
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
                          ),
                        ),
                        const SizedBox(width: AppTokens.space8),
                      ] else if (widget.icon != null) ...<Widget>[
                        Icon(
                          widget.icon,
                          size: 18,
                          color: effectiveFg,
                        ),
                        const SizedBox(width: AppTokens.space8),
                      ],
                      Flexible(
                        child: Text(
                          currentText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(
                            color: effectiveFg,
                            fontWeight: FontWeight.w700,
                            fontSize: widget.fontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
