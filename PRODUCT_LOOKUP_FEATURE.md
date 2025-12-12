# Parallel Product Lookup Feature

## Overview
BharatStore now supports **parallel product lookup** from **4 FREE product databases** when scanning barcodes. This feature automatically fetches product information (name, brand, category, image) from multiple sources simultaneously, making inventory management faster and more accurate.

## Supported Databases (All 100% FREE)
1. **OpenFoodFacts** - Food and beverage products
2. **OpenBeautyFacts** - Cosmetics and beauty products
3. **OpenPetFoodFacts** - Pet food and animal products
4. **OpenProductFacts** - General products database

## How It Works

### 1. Barcode Scanning Flow
When you scan a barcode in the **Add Product** screen:

1. **Parallel API Calls**: All enabled APIs are called simultaneously (not sequentially)
2. **First Valid Response**: The first API that returns valid product data wins
3. **Auto-fill**: Product fields are automatically filled with the retrieved data
4. **Source Tracking**: The system remembers which API provided the data
5. **Manual Fallback**: If no API returns data, you can enter product details manually

### 2. Performance
- **Parallel Execution**: All 4 APIs are queried at the same time
- **Timeout**: Each API has a 5-second timeout
- **Total Time**: ~5-7 seconds maximum (not 20+ seconds if done sequentially)
- **No Blocking**: UI remains responsive during lookup

### 3. Settings Control
Navigate to **Settings** → **Product Lookup** to:
- Enable/disable individual databases
- See which APIs are active
- Customize based on your product types

Example:
- Running a grocery store? → Enable OpenFoodFacts
- Selling cosmetics? → Enable OpenBeautyFacts
- Pet shop? → Enable OpenPetFoodFacts
- General retail? → Enable all databases

## Usage Instructions

### Adding a Product with Barcode
1. Go to **Inventory** → **Add Product**
2. Tap **SCAN BARCODE** button
3. Scan the product barcode
4. **Wait 2-7 seconds** while the system queries databases
5. Product details will auto-fill if found:
   - Product Name
   - Brand
   - Category
   - Product Image
6. A notification will show which database provided the data
7. Fill remaining fields (price, quantity, threshold)
8. Tap **SAVE**

### Manual Entry (Fallback)
If the barcode is not found in any database:
1. You'll see: "Product details not available from any database. Please enter manually."
2. Simply fill in the fields yourself
3. The product will still be saved normally

## Technical Details

### New Files Created
- `lib/models/product_data.dart` - Data model for API responses
- `lib/services/parallel_product_lookup_service.dart` - Core parallel lookup service

### Modified Files
- `lib/models/product.dart` - Added `source` field to track API origin
- `lib/screens/add_product_screen.dart` - Integrated parallel lookup
- `lib/screens/settings_screen.dart` - Added API toggle controls

### Data Model Changes
The `Product` model now includes an optional `source` field:
```dart
Product(
  id: '...',
  name: 'Coca Cola',
  barcode: '5449000000996',
  source: 'OpenFoodFacts', // NEW FIELD
  // ... other fields
)
```

### API Endpoints (No Authentication Required)
All APIs use the same URL pattern:
```
https://world.{database}.org/api/v2/product/{barcode}.json
```

Examples:
- OpenFoodFacts: `https://world.openfoodfacts.org/api/v2/product/5449000000996.json`
- OpenBeautyFacts: `https://world.openbeautyfacts.org/api/v2/product/3600523307876.json`

## Settings Storage
API preferences are stored locally in Hive:
```dart
final box = Hive.box('settings');
box.put('api_enabled_OpenFoodFacts', true);
box.put('api_enabled_OpenBeautyFacts', true);
box.put('api_enabled_OpenPetFoodFacts', true);
box.put('api_enabled_OpenProductFacts', true);
```

## Example Barcodes for Testing

### Food Products (OpenFoodFacts)
- Coca Cola: `5449000000996`
- Nutella: `3017620422003`
- Kit Kat: `7622210449283`

### Beauty Products (OpenBeautyFacts)
- L'Oréal Paris: `3600523307876`

### General Products
- Various electronics and household items

## Error Handling
The system gracefully handles:
- Network timeouts (5 seconds per API)
- Invalid barcodes (returns null, allows manual entry)
- API failures (tries all APIs, doesn't fail on first error)
- All APIs disabled (returns null immediately)
- Malformed API responses (validates data before use)

## Benefits
1. **Faster Data Entry**: No need to type product details manually
2. **Accurate Information**: Data comes from crowdsourced databases
3. **Better Inventory**: Consistent product naming and categorization
4. **Product Images**: Automatically fetch product photos
5. **Source Transparency**: Know where your data came from
6. **100% Free**: No API keys, no subscriptions, no costs
7. **Offline Friendly**: Cached data persists even without internet

## Limitations
- Requires internet connection for initial lookup
- Not all barcodes are in these databases (niche/local products)
- Product data quality depends on community contributions
- Image URLs may occasionally be broken
- No guarantee of data freshness

## Backward Compatibility
- **Existing features unchanged**: Billing, reports, authentication all work as before
- **Old products**: Products without `source` field work normally
- **Manual entry**: Still fully supported if APIs don't return data
- **No breaking changes**: App functions identically if all APIs are disabled

## Future Enhancements (Optional)
- Add more product databases
- Cache successful lookups locally
- Show product images in inventory list
- Bulk barcode scanning
- Product suggestions based on partial barcodes

## Troubleshooting

### "Product not found" message
- Try different databases (toggle in Settings)
- Barcode might not be in any database
- Enter product details manually

### Slow lookup
- Check internet connection
- Each API has 5-second timeout
- Disable unused APIs in Settings for faster results

### Wrong product data
- Data comes from community databases
- Can be edited after auto-fill
- Report to respective database (OpenFoodFacts, etc.)

## Credits
- OpenFoodFacts: https://world.openfoodfacts.org
- OpenBeautyFacts: https://world.openbeautyfacts.org
- OpenPetFoodFacts: https://world.openpetfoodfacts.org
- OpenProductFacts: https://world.openproductfacts.org

All databases are community-driven, open-source projects.
