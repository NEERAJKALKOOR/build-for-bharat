class ProductData {
  final String? name;
  final String? brand;
  final String? category;
  final String? imageUrl;
  final String? barcode;
  final String? source; // Which API responded

  ProductData({
    this.name,
    this.brand,
    this.category,
    this.imageUrl,
    this.barcode,
    this.source,
  });

  bool get isValid => name != null && name!.trim().isNotEmpty;

  factory ProductData.fromJson(Map<String, dynamic> json, String apiSource) {
    final product = json['product'] as Map<String, dynamic>?;
    
    if (product == null) {
      return ProductData();
    }

    return ProductData(
      name: product['product_name'] as String? ?? 
            product['generic_name'] as String?,
      brand: product['brands'] as String?,
      category: product['categories'] as String?,
      imageUrl: product['image_url'] as String? ?? 
                product['image_front_url'] as String?,
      barcode: product['code'] as String?,
      source: apiSource,
    );
  }

  @override
  String toString() {
    return 'ProductData(name: $name, brand: $brand, category: $category, source: $source)';
  }
}
