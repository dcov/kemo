import 'package:flutter/material.dart';

enum _VerticalSwitcherLayoutSlot {
  top,
  bottom
}

class _VerticalSwitcherLayout extends MultiChildLayoutDelegate {

  _VerticalSwitcherLayout({ @required this.animation}) : super(relayout: animation);

  final Animation<double> animation;

  void _placeChild(_VerticalSwitcherLayoutSlot slot, Size size, double offsetY) {
    layoutChild(slot, BoxConstraints.tight(size));
    positionChild(slot, Offset(0, offsetY));
  }

  @override
  void performLayout(Size size) {
    assert(hasChild(_VerticalSwitcherLayoutSlot.top));
    assert(hasChild(_VerticalSwitcherLayoutSlot.bottom));
    final double value = animation.value;
    _placeChild(_VerticalSwitcherLayoutSlot.top, size, -(size.height * value));
    _placeChild(_VerticalSwitcherLayoutSlot.bottom, size, size.height - (size.height * value));
  }

  @override
  bool shouldRelayout(_VerticalSwitcherLayout oldDelegate) {
    return this.animation != oldDelegate.animation;
  }
}

class VerticalSwitcher extends StatelessWidget {

  VerticalSwitcher({
    Key key,
    @required this.animation,
    @required this.top,
    @required this.bottom,
  }) : assert(animation != null),
       assert(top != null),
       assert(bottom != null),
       super(key: key);

  final Animation<double> animation;

  final Widget top;

  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(
      delegate: _VerticalSwitcherLayout(
        animation: animation),
      children: <Widget>[
        LayoutId(
          id: _VerticalSwitcherLayoutSlot.top,
          child: top),
        LayoutId(
          id: _VerticalSwitcherLayoutSlot.bottom,
          child: bottom)
      ]);
  }
}

class IconButtonSwitcher extends AnimatedWidget {

  IconButtonSwitcher({
    Key key,
    @required this.animation,
    @required this.firstIcon,
    @required this.secondIcon,
    @required this.onFirstPressed,
    @required this.onSecondPressed,
  }) : assert(animation != null),
       assert(firstIcon != null),
       assert(secondIcon != null),
       assert(onFirstPressed != null),
       assert(onSecondPressed != null),
       super(key: key, listenable: animation);

  final Animation<double> animation;

  final IconData firstIcon;

  final IconData secondIcon;

  final VoidCallback onFirstPressed;

  final VoidCallback onSecondPressed;

  bool get _isAnimating {
    return animation.status == AnimationStatus.forward ||
           animation.status == AnimationStatus.reverse;
  }

  void _handleTap() {
    assert(!_isAnimating);
    switch (animation.status) {
      case AnimationStatus.dismissed:
        onFirstPressed();
        break;
      case AnimationStatus.completed:
        onSecondPressed();
        break;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double value = animation.value;
    return IgnorePointer(
      ignoring: _isAnimating,
      child: InkWell(
        onTap: _handleTap,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Opacity(
              opacity: 1.0 - value,
              child: Icon(firstIcon)),
            Opacity(
              opacity: value,
              child: Icon(secondIcon))
          ])));
  }
}

