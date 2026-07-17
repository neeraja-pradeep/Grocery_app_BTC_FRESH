import 'dart:async';

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
  late CategorySelectionManager _selectionManager;
  late final CategoryStateListener _stateListener;
  // -1 = no filter active. Today only Price Drop (index 1) actually filters;
  // Brand/Popular are visual placeholders.
  int _selectedFilterIndex = -1;
  final GlobalKey<CategoryScreenBodyState> _bodyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectionManager = CategorySelectionManager(
      selectedCategoryId: widget.initialCategoryId,
    );
    _stateListener = CategoryStateListener(ref: ref);
    WidgetsBinding.instance.addObserver(this);

    if (widget.initialCategoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToInitialCategory();
        });
      });
    }

    // Activate polling through the controller (not by accessing PollingManager directly)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(categoryControllerProvider.notifier).activatePolling();
      }
    });
  }

  @override
  void dispose() {
    PollingManager.instance.pauseActive();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scrollToInitialCategory() {
    if (!mounted) return;

    final categoryState = ref.read(categoryControllerProvider);
    final categories = CategoryMapper.toViewItems(categoryState);

    if (categories.isEmpty || widget.initialCategoryId == null) return;

    final initialIndex = categories.indexWhere(
      (cat) => cat.id == widget.initialCategoryId,
    );

    if (initialIndex >= 0) {
      if (_selectionManager.selectedIndex != initialIndex) {
        setState(() {
          _selectionManager = _selectionManager.copyWith(
            selectedIndex: initialIndex,
            selectedCategoryId: widget.initialCategoryId,
          );
        });
      }

      // M4: replaced Future.delayed with addPostFrameCallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
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
    // M1: pass context as argument so the listener never holds a stale reference
    // H13: onSelectionChanged replaces _selectionManager with the new immutable instance
    _stateListener.listen(
      context: context,
      selectionManager: _selectionManager,
      setState: setState,
      onSelectionChanged: (updated) => _selectionManager = updated,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final categoryState = ref.watch(categoryControllerProvider);
    final categories = CategoryMapper.toViewItems(categoryState);

    // C1: selection initialisation removed from build() — _scrollToInitialCategory
    // (called via addPostFrameCallback in initState) handles it after the frame.

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
                  image: AssetImage('assets/bg.png'),
                  repeat: ImageRepeat.repeat,
                  opacity: 0.7,
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
                    _selectionManager = _selectionManager.copyWith(
                      selectedIndex: index,
                      selectedCategoryId: categoryId,
                    );
                  });
                },
                onFilterSelected: (index) {
                  setState(() {
                    // Tap the active chip again to deselect.
                    _selectedFilterIndex =
                        _selectedFilterIndex == index ? -1 : index;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
