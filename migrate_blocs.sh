#!/bin/bash

# BLoC Migration Script - Migrate from Bloc to BaseBloc
# This script helps migrate BLoCs to use BaseBloc for memory leak prevention

echo "Starting BLoC migration to BaseBloc..."

# List of BLoC files that need migration (excluding already migrated ones)
bloc_files=(
  "lib/features/market/presentation/blocs/add_product/add_product_bloc.dart"
  "lib/features/market/presentation/blocs/comment/comment_bloc.dart" 
  "lib/features/market/presentation/blocs/theme/theme_bloc.dart"
  "lib/features/business_card/presentation/bloc/business_bloc.dart"
  "lib/features/create_workspace/presentation/bloc/create_workspace_bloc.dart"
  "lib/features/job_managment/presentation/bloc/jobmanagment_bloc.dart"
  "lib/features/splash/blocs/splash_bloc.dart"
  "lib/features/payment/blocs/payment_bloc.dart"
  "lib/features/product/blocs/product_bloc.dart"
  "lib/features/service/blocs/service_bloc.dart"
  "lib/features/reservation/blocs/reservation_bloc.dart"
  "lib/features/notification/blocs/notification_bloc.dart"
  "lib/features/customer/presentation/blocs/profile/profile_bloc.dart"
  "lib/features/customer/presentation/blocs/customer/customer_bloc.dart"
  "lib/features/chat/blocs/chat_bloc.dart"
  "lib/features/inquiry/presentation/blocs/inquiry_bloc.dart"
  "lib/features/cart/presentation/blocs/cart_bloc.dart"
)

migrated_count=0
total_files=${#bloc_files[@]}

for file in "${bloc_files[@]}"; do
  if [ -f "$file" ]; then
    echo "Processing $file..."
    
    # Check if file already imports BaseBloc
    if grep -q "import.*base_bloc" "$file"; then
      echo "  ✅ Already migrated: $file"
      ((migrated_count++))
      continue
    fi
    
    # Check if file extends Bloc
    if grep -q "extends Bloc<" "$file"; then
      echo "  🔄 Migrating: $file"
      
      # Replace bloc import with base_bloc import
      sed -i 's|import '\''package:bloc/bloc.dart'\'';|import '\''package:asood/core/architecture/base_bloc.dart'\'';|g' "$file"
      
      # Replace Bloc extension with BaseBloc extension
      sed -i 's|extends Bloc<|extends BaseBloc<|g' "$file"
      
      echo "  ✅ Migrated: $file"
      ((migrated_count++))
    else
      echo "  ⚠️  No Bloc extension found in: $file"
    fi
  else
    echo "  ❌ File not found: $file"
  fi
done

echo ""
echo "Migration Summary:"
echo "=================="
echo "Total files processed: $total_files"
echo "Successfully migrated: $migrated_count"
echo ""
echo "Next steps:"
echo "1. Run 'flutter pub get' to ensure dependencies are correct"
echo "2. Run 'flutter analyze' to check for any issues"
echo "3. Test the application to ensure BLoCs work correctly"
echo "4. Monitor memory usage to verify leak prevention"

# Generate verification script
cat > verify_bloc_migration.sh << 'EOF'
#!/bin/bash
echo "Verifying BLoC migration..."
echo "=========================="

# Check for any remaining direct Bloc extensions
echo "Checking for unmigrated BLoCs:"
grep -r "extends Bloc<" lib/ --include="*_bloc.dart" | grep -v "BaseBloc"

echo ""
echo "Checking BaseBloc usage:"
grep -r "extends BaseBloc<" lib/ --include="*_bloc.dart" | wc -l

echo ""
echo "Checking BaseBloc imports:"
grep -r "base_bloc.dart" lib/ --include="*_bloc.dart" | wc -l

echo ""
echo "Files with memory leak potential (still using Bloc directly):"
grep -r "extends Bloc<" lib/ --include="*_bloc.dart" | grep -v "base_bloc.dart" | cut -d: -f1 | sort | uniq
EOF

chmod +x verify_bloc_migration.sh
echo "Created verification script: verify_bloc_migration.sh"