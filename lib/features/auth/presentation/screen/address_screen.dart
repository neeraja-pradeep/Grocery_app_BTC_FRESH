import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/app/router/app_router.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/utils/address_enum.dart';
import 'package:grocery_app/features/auth/application/providers/address_provider.dart';
import 'package:grocery_app/features/auth/application/states/address_states.dart';
import 'package:grocery_app/features/auth/domain/entities/user.dart';
import 'package:grocery_app/features/auth/presentation/components/address_field.dart';
import 'package:grocery_app/features/auth/presentation/components/address_tags.dart';
import 'package:grocery_app/features/auth/presentation/components/address_tip.dart';

class AddressScreen extends ConsumerStatefulWidget {
  final UserEntity user;

  const AddressScreen({super.key, required this.user});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  final houseController = TextEditingController();
  final areaController = TextEditingController();

  AddressType selectedType = AddressType.home;

  @override
  void dispose() {
    houseController.dispose();
    areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(addressEntryProvider);

    // 🔥 LISTEN TO STATE CHANGES
    ref.listen<AddressState>(addressEntryProvider, (prev, next) {
      if (next is AddressSaved) {
        goToHome(context);
      }

      if (next is AddressSkipped) {
        goToHome(context);
      }

      if (next is AddressError) {
        _showError(next.failure.message);
      }
    });

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 40),
              Center(child: Image.asset('assets/logo.png', width: 150)),

              const Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 35,
                    color: AppColors.titleColor,
                  ),
                  Text(
                    'Address',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 35,
                      color: AppColors.titleColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              const AddressTip(),
              const SizedBox(height: 30),

              // HOUSE NUMBER
              AddressField(
                hint: "House / Flat / Block No.",
                controller: houseController,
              ),

              const SizedBox(height: 40),

              // AREA
              AddressField(
                hint: "Apartment / Road / Area",
                controller: areaController,
              ),

              const SizedBox(height: 40),

              Text(
                'Save As',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  AddressTag(
                    label: "Home",
                    icon: Icons.home,
                    isSelected: selectedType == AddressType.home,
                    onTap: () => setState(() {
                      selectedType = AddressType.home;
                    }),
                  ),
                  const SizedBox(width: 10),
                  AddressTag(
                    label: "Work",
                    icon: Icons.work,
                    isSelected: selectedType == AddressType.work,
                    onTap: () => setState(() {
                      selectedType = AddressType.work;
                    }),
                  ),
                  const SizedBox(width: 10),
                  AddressTag(
                    label: "Other",
                    icon: Icons.location_on,
                    isSelected: selectedType == AddressType.other,
                    onTap: () => setState(() {
                      selectedType = AddressType.other;
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // MAIN BUTTON
              GestureDetector(
                onTap: () => _handleSave(addressState),
                child: Container(
                  width: double.infinity,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      addressState is AddressSaving
                          ? "Saving Address..."
                          : "Done",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.titleColor,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Center(
                child: GestureDetector(
                  onTap: () {
                    ref.read(addressEntryProvider.notifier).skipAddress();
                  },
                  child: const Text(
                    "Skip",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontSize: 20,
                      color: AppColors.titleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSave(AddressState state) {
    final house = houseController.text.trim();
    final area = areaController.text.trim();

    if (house.isEmpty || area.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    final fullAddress = "$house, $area";

    ref
        .read(addressEntryProvider.notifier)
        .saveAddress(
          firstName: widget.user.firstName,
          lastName: widget.user.lastName,
          streetAddress: fullAddress,
          addressType: selectedType,
        );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

//     );
//   }
// }
