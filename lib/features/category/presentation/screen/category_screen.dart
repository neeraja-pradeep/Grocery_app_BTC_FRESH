import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/polling/polling_manager.dart';
import '../../application/providers/category_providers.dart';
import '../components/header/_header.dart';
import '../components/category_screenbody/category_screen_body.dart';
import '../helpers/category_mapper.dart';
import '../helpers/category_selection_manager.dart';
import '../helpers/category_state_listener.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  const CategoryScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen>
    with WidgetsBindingObserver {
  late final CategorySelectionManager _selectionManager;
  late final CategoryStateListener _stateListener;
  int _selectedFilterIndex = 0;
  final GlobalKey<CategoryScreenBodyState> _bodyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectionManager = CategorySelectionManager(
      selectedCategoryId: widget.initialCategoryId,
    );
    _stateListener = CategoryStateListener(ref: ref, context: context);
    WidgetsBinding.instance.addObserver(this);

    // Trigger initial scroll to selected category if one is provided
    if (widget.initialCategoryId != null) {
      developer.log(
        'CategoryScreen initState: initialCategoryId = "${widget.initialCategoryId}"',
        name: 'CategoryScreen_Init',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        developer.log(
          'First postFrameCallback executed',
          name: 'CategoryScreen_Init',
        );
        // Wait one more frame to ensure ProductGrid is fully initialized
        WidgetsBinding.instance.addPostFrameCallback((_) {
          developer.log(
            'Second postFrameCallback executed, calling _scrollToInitialCategory',
            name: 'CategoryScreen_Init',
          );
          _scrollToInitialCategory();
        });
      });
    }

    // Ensure category_products polling is activated when this screen mounts
    // This handles the case where BottomNavbar's selectTab(0) runs before
    // CategoryProductControllers are registered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log(
        'CategoryScreen mounted - ensuring category_products polling is active',
        name: 'CategoryScreen',
        level: 700,
      );
      // Only activate if we're on the category tab (index 0)
      // Check current active feature to avoid overriding if on another tab
      final currentFeature = PollingManager.instance.activeFeature;
      if (currentFeature == null || currentFeature == 'category_products') {
        PollingManager.instance.setActiveFeature('category_products');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Scrolls to the initial category after the widget tree is built
  void _scrollToInitialCategory() {
    if (!mounted) return;

    final categoryState = ref.read(categoryControllerProvider);
    final categories = CategoryMapper.toViewItems(categoryState);

    if (categories.isEmpty || widget.initialCategoryId == null) return;

    // Debug: Log the IDs to see if there's a mismatch
    developer.log(
      'Searching for initialCategoryId: "${widget.initialCategoryId}"',
      name: 'CategoryScreen_Scroll',
    );
    developer.log(
      'Available category IDs: ${categories.map((c) => '"${c.id}"').join(", ")}',
      name: 'CategoryScreen_Scroll',
    );

    // Find the index of the initial category
    final initialIndex = categories.indexWhere(
      (cat) => cat.id == widget.initialCategoryId,
    );

    developer.log(
      'Found initialIndex: $initialIndex',
      name: 'CategoryScreen_Scroll',
    );

    if (initialIndex >= 0) {
      // Update the selection manager with the correct index (already done in build)
      // But trigger it again in case the build hasn't completed yet
      if (_selectionManager.selectedIndex != initialIndex) {
        setState(() {
          _selectionManager.selectCategory(
            initialIndex,
            widget.initialCategoryId,
          );
        });
      }

      // Add a small delay to ensure the widget tree is fully built
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        // Trigger scroll to the category
        _bodyKey.currentState?.scrollToCategory(initialIndex);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(categoryControllerProvider.notifier).refreshIfStale());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Setup state listener
    _stateListener.listen(
      selectionManager: _selectionManager,
      setState: setState,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final categoryState = ref.watch(categoryControllerProvider);
    final categories = CategoryMapper.toViewItems(categoryState);

    // If we have an initialCategoryId and categories are loaded,
    // update the selection manager to point to the correct index
    if (widget.initialCategoryId != null &&
        categories.isNotEmpty &&
        _selectionManager.selectedCategoryId == widget.initialCategoryId &&
        _selectionManager.selectedIndex == 0) {
      developer.log(
        'Build: Attempting to update selection. initialCategoryId="${widget.initialCategoryId}", categories.length=${categories.length}',
        name: 'CategoryScreen_Build',
      );
      // Find the correct index for the initial category
      final initialIndex = categories.indexWhere(
        (cat) => cat.id == widget.initialCategoryId,
      );
      developer.log(
        'Build: Found initialIndex=$initialIndex for ID "${widget.initialCategoryId}"',
        name: 'CategoryScreen_Build',
      );
      if (initialIndex >= 0 &&
          initialIndex != _selectionManager.selectedIndex) {
        // Update selection manager synchronously before build completes
        _selectionManager.selectCategory(
          initialIndex,
          widget.initialCategoryId,
        );
        developer.log(
          'Build: Updated selection manager to index $initialIndex',
          name: 'CategoryScreen_Build',
        );
      }
    }

    final selectedCategoryId =
        categories.isNotEmpty &&
            _selectionManager.selectedIndex < categories.length
        ? categories[_selectionManager.selectedIndex].id
        : null;

    return Container(
      color: AppColors.green10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 42.h, color: AppColors.green60),
          Header(colorScheme: colorScheme),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background_graphics.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: CategoryScreenBody(
                key: _bodyKey,
                categoryState: categoryState,
                categories: categories,
                selectedCategoryIndex: _selectionManager.selectedIndex,
                selectedCategoryId: selectedCategoryId,
                selectedFilterIndex: _selectedFilterIndex,
                onCategorySelected: (index) {
                  final categoryId = categories[index].id;
                  setState(() {
                    _selectionManager.selectCategory(index, categoryId);
                  });
                },
                onFilterSelected: (index) {
                  setState(() => _selectedFilterIndex = index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
