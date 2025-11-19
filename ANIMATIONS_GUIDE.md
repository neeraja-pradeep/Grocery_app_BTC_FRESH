# Product Details Animations Guide

## Overview
This guide documents all animations implemented in the Product Details feature for enhanced user experience.

---

## 1. Button State Transition Animation

### Location
[`lib/features/product_details/presentation/components/add_to_cart_section/add_to_cart_button.dart`](lib/features/product_details/presentation/components/add_to_cart_section/add_to_cart_button.dart)

### Animation Details

**Trigger**: When quantity changes from 0 to 1+ or vice versa

**Animation**: `AnimatedCrossFade`
- **Duration**: 300ms
- **Curve**: Linear (default)
- **Effect**: Smooth fade transition between "Add" button and quantity selector

```dart
AnimatedCrossFade(
  firstChild: _AddButton(onAdd: onAdd),
  secondChild: _QuantitySelector(...),
  crossFadeState: isInCart ? CrossFadeState.showSecond : CrossFadeState.showFirst,
  duration: const Duration(milliseconds: 300),
)
```

**User Experience**:
- When user taps "Add", button smoothly transitions to quantity selector
- When user removes all items (quantity = 0), smoothly transitions back to "Add"

---

## 2. Quantity Counter Scale Animation

### Location
[`_QuantitySelectorState` in add_to_cart_button.dart](lib/features/product_details/presentation/components/add_to_cart_section/add_to_cart_button.dart#L106)

### Animation Details

**Trigger**: When quantity value changes (increment/decrement)

**Animation**: `ScaleTransition`
- **Duration**: 200ms
- **Curve**: `Curves.elasticOut` (bouncy effect)
- **Range**: 1.0 → 1.15 → 1.0
- **Effect**: Number grows slightly then returns to normal

```dart
_quantityScale = Tween<double>(begin: 1.0, end: 1.15).animate(
  CurvedAnimation(parent: _quantityScaleController, curve: Curves.elasticOut),
);
```

**User Experience**:
- Visual feedback that quantity has changed
- Bouncy effect draws attention to the number update
- Plays automatically when user increments/decrements

---

## 3. Plus/Minus Button Press Animation

### Location
[`_AnimatedIconButton` in add_to_cart_button.dart](lib/features/product_details/presentation/components/add_to_cart_section/add_to_cart_button.dart#L196)

### Animation Details

**Trigger**: On tap/press

**Animation**: `ScaleTransition`
- **Duration**: 150ms
- **Curve**: `Curves.easeInOut`
- **Range**: 1.0 → 0.9 → 1.0
- **Effect**: Button shrinks on press, expands on release

```dart
_scale = Tween<double>(begin: 1.0, end: 0.9).animate(
  CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
);
```

**Features**:
- Different styling for positive (green) and negative (white) buttons
- Positive button has subtle green shadow
- Provides tactile feedback

---

## 4. View Cart Button Press Animation

### Location
[`_AnimatedPressButton` in add_to_cart_button.dart](lib/features/product_details/presentation/components/add_to_cart_section/add_to_cart_button.dart#L283)

### Animation Details

**Trigger**: On tap

**Animation**: `ScaleTransition`
- **Duration**: 200ms
- **Curve**: `Curves.easeInOut`
- **Range**: 1.0 → 0.95 → 1.0
- **Effect**: Button slightly shrinks on press

```dart
_scale = Tween<double>(begin: 1.0, end: 0.95).animate(
  CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
);
```

**Features**:
- Green button with shadow
- Smooth press feedback
- Shadow effect enhances depth

---

## 5. Wishlist Heart Animation

### Location
[`_ProductHeaderState` in product_header.dart](lib/features/product_details/presentation/components/product_header/product_header.dart#L23)

### Animation Details

**Trigger**: When wishlist status changes (add/remove)

**Animation**: `ScaleTransition`
- **Duration**: 300ms
- **Curve**: `Curves.elasticOut` (bouncy elastic effect)
- **Range**: 1.0 → 1.2 → 1.0
- **Effect**: Heart "pops" with elastic bounce

```dart
_wishlistScale = Tween<double>(begin: 1.0, end: 1.2).animate(
  CurvedAnimation(parent: _wishlistController, curve: Curves.elasticOut),
);
```

**Trigger Mechanism**:
```dart
@override
void didUpdateWidget(ProductHeader oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.isInWishlist != oldWidget.isInWishlist) {
    _wishlistController.forward().then((_) {
      _wishlistController.reverse();
    });
  }
}
```

**User Experience**:
- Heart icon grows and bounces when added to wishlist
- Icon changes from outline to filled (red)
- Satisfying elastic effect indicates action success

---

## 6. Image Carousel Indicator Animation

### Location
[`_ProductHeaderState` in product_header.dart](lib/features/product_details/presentation/components/product_header/product_header.dart#L134)

### Animation Details

**Trigger**: When user swipes carousel to different image

**Animation**: `AnimatedContainer`
- **Duration**: 300ms
- **Effect**: Active indicator expands horizontally

```dart
AnimatedContainer(
  width: _currentImageIndex == index ? 24.w : 8.w,  // Expands when active
  height: 8.w,
  margin: EdgeInsets.symmetric(horizontal: 4.w),
  duration: const Duration(milliseconds: 300),
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: _currentImageIndex == index ? AppColors.green : AppColors.grey,
  ),
)
```

**User Experience**:
- Active dot indicator smoothly expands to rectangular pill shape
- Inactive dots collapse to small circles
- Provides visual feedback of current carousel position
- Color changes from grey to green when active

---

## 7. Page Content Fade-In Animation

### Location
[`ProductDetailsScreen` in product_details_screen.dart](lib/features/product_details/presentation/screen/product_details_screen.dart#L63)

### Animation Details

**Trigger**: When product data finishes loading

**Animation**: `AnimatedOpacity`
- **Duration**: 400ms
- **Range**: 0.0 → 1.0
- **Effect**: Content fades in smoothly

```dart
AnimatedOpacity(
  opacity: state.hasData ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 400),
  child: _ProductDetailsContent(...),
)
```

**User Experience**:
- Loading spinner displays first
- When data loads, content smoothly fades in
- Prevents jarring appearance of content

---

## 8. Review Cards Stagger Animation

### Location
[`_ProductReviewsState` in product_reviews.dart](lib/features/product_details/presentation/components/product_reviews/product_reviews.dart#L21)

### Animation Details

**Trigger**: When review list loads or updates

**Animations Combined**:
1. **SlideTransition**: Cards slide in from right
   - Begin: `Offset(0.5, 0)` (50% to the right)
   - End: `Offset.zero` (normal position)

2. **FadeTransition**: Cards fade in simultaneously
   - Begin: 0.0 (transparent)
   - End: 1.0 (opaque)

**Stagger Effect**:
```dart
// Each card animates with 100ms delay
for (int i = 0; i < _controllers.length; i++) {
  Future.delayed(Duration(milliseconds: i * 100), () {
    _controllers[i].forward();
  });
}
```

**Animation Sequence**:
- Card 1: Starts at 0ms
- Card 2: Starts at 100ms
- Card 3: Starts at 200ms
- etc.

**Per-Card Animation**:
```dart
SlideTransition(
  position: slideAnimation,  // From right to normal
  child: FadeTransition(
    opacity: fadeAnimation,   // From transparent to opaque
    child: _ReviewCard(...),
  ),
)
```

**User Experience**:
- Reviews cascade into view with staggered timing
- Creates sense of list loading progressively
- Each review slides from right while fading in
- Professional, polished appearance

---

## Animation Summary Table

| Animation | Component | Duration | Type | Trigger |
|-----------|-----------|----------|------|---------|
| Cross Fade | Add/Quantity Button | 300ms | State Change | Quantity ≠ 0 |
| Scale Bounce | Quantity Display | 200ms | Elastic | Quantity Changes |
| Scale Press | ±/Add Buttons | 150-200ms | EaseInOut | Button Tap |
| Scale Bounce | Wishlist Heart | 300ms | Elastic | Wishlist Toggle |
| Container | Carousel Dots | 300ms | Linear | Page Change |
| Opacity Fade | Page Content | 400ms | Linear | Data Loaded |
| Slide + Fade | Review Cards | 400ms | EaseOut | List Load (Staggered) |

---

## Best Practices Implemented

### 1. **Smooth Durations**
- Short interactions: 150-300ms
- Page transitions: 400ms
- User doesn't feel delayed or jerky

### 2. **Appropriate Curves**
- `Curves.easeInOut`: Press/release feedback
- `Curves.elasticOut`: Celebratory effects (wishlist, quantity)
- `Curves.easeOut`: Content entrance animations

### 3. **Resource Cleanup**
All AnimationControllers are properly disposed:
```dart
@override
void dispose() {
  _controller.dispose();  // or _controllers for lists
  super.dispose();
}
```

### 4. **Responsive to Data Changes**
```dart
@override
void didUpdateWidget(Widget oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (dataChanged) {
    _controller.forward();
  }
}
```

### 5. **Mount Safety**
```dart
if (mounted && i < _controllers.length) {
  _controllers[i].forward();
}
```

---

## Usage Examples

### Animating a Custom Widget

```dart
class MyAnimatedButton extends StatefulWidget {
  const MyAnimatedButton({
    required this.onTap,
    required this.label,
  });

  final VoidCallback onTap;
  final String label;

  @override
  State<MyAnimatedButton> createState() => _MyAnimatedButtonState();
}

class _MyAnimatedButtonState extends State<MyAnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          // Your widget
        ),
      ),
    );
  }
}
```

### Stagger Animation for List

```dart
void _initializeAnimations() {
  final itemCount = items.length;
  _controllers = List.generate(
    itemCount,
    (index) => AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    ),
  );

  // Stagger with delay
  for (int i = 0; i < _controllers.length; i++) {
    Future.delayed(Duration(milliseconds: i * 100), () {
      if (mounted) {
        _controllers[i].forward();
      }
    });
  }
}
```

---

## Performance Considerations

1. **AnimationController Disposal**: Always dispose in `dispose()` method
2. **Staggered Delays**: 100ms intervals prevent performance issues
3. **Curve Selection**: `Curves.elasticOut` only for celebratory effects
4. **Scale Animations**: Preferred over size changes for performance
5. **Opacity Animations**: Lightweight, no layout recalculation

---

## Testing Animations

Enable animation slowdown for testing:

```bash
# In DevTools or hot reload
// Slow down animations by 5x
window.flutterRunner.timeFactor = 5;
```

---

## Future Enhancement Ideas

1. **Parallax scrolling** on product images
2. **Shimmer loading** while data fetches
3. **Gesture-based interactions** (swipe to add)
4. **Confetti animation** for added to cart
5. **Morphing transitions** between states

---

**Version**: 1.0
**Last Updated**: November 2025
