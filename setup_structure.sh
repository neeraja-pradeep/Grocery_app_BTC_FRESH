#!/usr/bin/env bash
# ================================================
# Flutter Project Folder Scaffold Generator
# Creates full modular architecture for clean code
# ================================================

set -e

ROOT="lib"

echo "Creating folder structure under $ROOT..."

# -------------------------------
# app/
# -------------------------------
mkdir -p $ROOT/app/bootstrap
mkdir -p $ROOT/app/config
mkdir -p $ROOT/app/router/guards
mkdir -p $ROOT/app/theme
mkdir -p $ROOT/app/localization/arb
mkdir -p $ROOT/app/monitoring

touch $ROOT/app/bootstrap/app_bootstrap.dart
touch $ROOT/app/bootstrap/hive_init.dart
touch $ROOT/app/bootstrap/env_loader.dart

touch $ROOT/app/config/env.dart
touch $ROOT/app/config/constants.dart
touch $ROOT/app/config/feature_flags.dart

touch $ROOT/app/router/app_router.dart

touch $ROOT/app/theme/colors.dart
touch $ROOT/app/theme/typography.dart
touch $ROOT/app/theme/theme.dart

touch $ROOT/app/localization/l10n.dart

touch $ROOT/app/monitoring/analytics.dart
touch $ROOT/app/monitoring/crash_reporting.dart

touch $ROOT/app/app.dart

# -------------------------------
# core/
# -------------------------------
mkdir -p $ROOT/core/network
mkdir -p $ROOT/core/storage/hive/adapters
mkdir -p $ROOT/core/utils
mkdir -p $ROOT/core/widgets
mkdir -p $ROOT/core/error

touch $ROOT/core/network/api_client.dart
touch $ROOT/core/network/endpoints.dart
touch $ROOT/core/network/network_exceptions.dart

touch $ROOT/core/storage/hive/boxes.dart
touch $ROOT/core/storage/hive/keys.dart
touch $ROOT/core/storage/secure_store.dart

touch $ROOT/core/utils/date_utils.dart
touch $ROOT/core/utils/validators.dart
touch $ROOT/core/utils/logger.dart

touch $ROOT/core/widgets/app_button.dart
touch $ROOT/core/widgets/app_card.dart
touch $ROOT/core/widgets/app_text_field.dart
touch $ROOT/core/widgets/navbar.dart

touch $ROOT/core/error/failure.dart
touch $ROOT/core/error/error_view.dart

# -------------------------------
# features/auth
# -------------------------------
mkdir -p $ROOT/features/auth/domain/entities
mkdir -p $ROOT/features/auth/domain/repositories
mkdir -p $ROOT/features/auth/application/states
mkdir -p $ROOT/features/auth/application/providers
mkdir -p $ROOT/features/auth/application/usecases
mkdir -p $ROOT/features/auth/infrastructure/data_sources/remote
mkdir -p $ROOT/features/auth/infrastructure/data_sources/local
mkdir -p $ROOT/features/auth/infrastructure/repositories
mkdir -p $ROOT/features/auth/presentation/screen
mkdir -p $ROOT/features/auth/presentation/components

touch $ROOT/features/auth/domain/entities/user.dart
touch $ROOT/features/auth/domain/repositories/auth_repository.dart
touch $ROOT/features/auth/application/states/auth_state.dart
touch $ROOT/features/auth/application/providers/auth_provider.dart
touch $ROOT/features/auth/application/usecases/login.dart
touch $ROOT/features/auth/infrastructure/data_sources/remote/auth_api.dart
touch $ROOT/features/auth/infrastructure/data_sources/local/auth_local_ds.dart
touch $ROOT/features/auth/infrastructure/repositories/auth_repository_impl.dart
touch $ROOT/features/auth/presentation/screen/login_screen.dart
touch $ROOT/features/auth/presentation/components/header_section.dart

# -------------------------------
# features/dashboard
# -------------------------------
mkdir -p $ROOT/features/dashboard/domain/entities
mkdir -p $ROOT/features/dashboard/domain/repositories
mkdir -p $ROOT/features/dashboard/application/states
mkdir -p $ROOT/features/dashboard/application/providers
mkdir -p $ROOT/features/dashboard/application/usecases
mkdir -p $ROOT/features/dashboard/infrastructure/data_sources/remote
mkdir -p $ROOT/features/dashboard/infrastructure/data_sources/local
mkdir -p $ROOT/features/dashboard/infrastructure/repositories
mkdir -p $ROOT/features/dashboard/presentation/screen
mkdir -p $ROOT/features/dashboard/presentation/components

touch $ROOT/features/dashboard/presentation/screen/home_screen.dart

# -------------------------------
# features/profile
# -------------------------------
mkdir -p $ROOT/features/profile/domain/entities
mkdir -p $ROOT/features/profile/domain/repositories
mkdir -p $ROOT/features/profile/application/states
mkdir -p $ROOT/features/profile/application/providers
mkdir -p $ROOT/features/profile/application/usecases
mkdir -p $ROOT/features/profile/infrastructure/data_sources/remote
mkdir -p $ROOT/features/profile/infrastructure/data_sources/local
mkdir -p $ROOT/features/profile/infrastructure/repositories
mkdir -p $ROOT/features/profile/presentation/screen
mkdir -p $ROOT/features/profile/presentation/components

touch $ROOT/features/profile/presentation/screen/profile_screen.dart

# -------------------------------
# features/common
# -------------------------------
mkdir -p $ROOT/features/common/pagination
mkdir -p $ROOT/features/common/attachments

# -------------------------------
# entry files
# -------------------------------
touch $ROOT/main.dart
touch $ROOT/globals.dart

echo "✅ Folder structure created successfully!"
