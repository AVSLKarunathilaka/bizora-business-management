import 'package:flutter/material.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  String _selectedCategory = 'All Categories';

  final List<String> _categories = [
    'All Categories',
    'Electronics',
    'Clothing',
    'Grocery',
    'Cosmetics',
    'Handcraft',
    'Furniture',
    'Other',
  ];

  final List<Map<String, dynamic>> _products = [
    {
      'id': 1,
      'name': 'Wireless Headphones',
      'sku': 'ELEC-001',
      'category': 'Electronics',
      'stock': 25,
      'sellingPrice': 8500.00,
      'description': 'Bluetooth wireless headphones.',
    },
    {
      'id': 2,
      'name': 'Cotton T-Shirt',
      'sku': 'CLO-001',
      'category': 'Clothing',
      'stock': 8,
      'sellingPrice': 2500.00,
      'description': 'Premium cotton casual T-shirt.',
    },
    {
      'id': 3,
      'name': 'Rice 5kg',
      'sku': 'GRO-001',
      'category': 'Grocery',
      'stock': 4,
      'sellingPrice': 1850.00,
      'description': '5kg rice pack.',
    },
    {
      'id': 4,
      'name': 'Handmade Wall Art',
      'sku': 'HAN-001',
      'category': 'Handcraft',
      'stock': 0,
      'sellingPrice': 4500.00,
      'description': 'Handmade decorative wall art.',
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    final search = _searchController.text.trim().toLowerCase();

    return _products.where((product) {
      final matchesSearch =
          product['name'].toString().toLowerCase().contains(search) ||
          product['sku'].toString().toLowerCase().contains(search) ||
          product['category'].toString().toLowerCase().contains(search);

      final matchesCategory =
          _selectedCategory == 'All Categories' ||
          product['category'] == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  String _getStockStatus(int stock) {
    if (stock <= 0) return 'Out of Stock';
    if (stock <= 5) return 'Low Stock';
    return 'In Stock';
  }

  Color _getStockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }

  // ============================================================
  // DIALOG TEXT FIELD
  // ============================================================

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // ============================================================
  // ADD PRODUCT
  // ============================================================

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final descriptionController = TextEditingController();

    String category = 'Electronics';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.add_box_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add Product',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogTextField(
                        controller: nameController,
                        label: 'Product Name',
                        hint: 'Enter product name',
                        icon: Icons.inventory_2_outlined,
                      ),

                      const SizedBox(height: 16),

                      _buildDialogTextField(
                        controller: skuController,
                        label: 'SKU',
                        hint: 'Example: ELEC-001',
                        icon: Icons.qr_code_2,
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _categories
                            .where((item) => item != 'All Categories')
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            category = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 350) {
                            return Column(
                              children: [
                                _buildDialogTextField(
                                  controller: stockController,
                                  label: 'Stock',
                                  hint: '0',
                                  icon: Icons.inventory_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 16),
                                _buildDialogTextField(
                                  controller: priceController,
                                  label: 'Selling Price',
                                  hint: '0.00',
                                  icon: Icons.payments_outlined,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: _buildDialogTextField(
                                  controller: stockController,
                                  label: 'Stock',
                                  hint: '0',
                                  icon: Icons.inventory_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDialogTextField(
                                  controller: priceController,
                                  label: 'Selling Price',
                                  hint: '0.00',
                                  icon: Icons.payments_outlined,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildDialogTextField(
                        controller: descriptionController,
                        label: 'Description',
                        hint: 'Enter product description',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton.icon(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final sku = skuController.text.trim();

                    final stock = int.tryParse(stockController.text.trim());

                    final price = double.tryParse(priceController.text.trim());

                    if (name.isEmpty ||
                        sku.isEmpty ||
                        stock == null ||
                        price == null ||
                        stock < 0 ||
                        price < 0) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter valid product information.',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _products.add({
                        'id': DateTime.now().millisecondsSinceEpoch,
                        'name': name,
                        'sku': sku,
                        'category': category,
                        'stock': stock,
                        'sellingPrice': price,
                        'description': descriptionController.text.trim(),
                      });
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Product added successfully.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // ============================================================
// EDIT PRODUCT
// ============================================================

void _showEditProductDialog(Map<String, dynamic> product) {
  final nameController = TextEditingController(
    text: product['name'].toString(),
  );

  final skuController = TextEditingController(
    text: product['sku'].toString(),
  );

  final priceController = TextEditingController(
    text: product['sellingPrice'].toString(),
  );

  final stockController = TextEditingController(
    text: product['stock'].toString(),
  );

  final descriptionController = TextEditingController(
    text: product['description']?.toString() ?? '',
  );

  String category = product['category'].toString();

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Edit Product',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogTextField(
                      controller: nameController,
                      label: 'Product Name',
                      icon: Icons.inventory_2_outlined,
                    ),

                    const SizedBox(height: 16),

                    _buildDialogTextField(
                      controller: skuController,
                      label: 'SKU',
                      icon: Icons.qr_code_2,
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .where(
                            (item) => item != 'All Categories',
                          )
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          category = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 350) {
                          return Column(
                            children: [
                              _buildDialogTextField(
                                controller: stockController,
                                label: 'Stock',
                                icon: Icons.inventory_outlined,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              _buildDialogTextField(
                                controller: priceController,
                                label: 'Selling Price',
                                icon: Icons.payments_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: _buildDialogTextField(
                                controller: stockController,
                                label: 'Stock',
                                icon: Icons.inventory_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDialogTextField(
                                controller: priceController,
                                label: 'Selling Price',
                                icon: Icons.payments_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildDialogTextField(
                      controller: descriptionController,
                      label: 'Description',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),

              ElevatedButton.icon(
                onPressed: () {
                  final name = nameController.text.trim();
                  final sku = skuController.text.trim();

                  final stock = int.tryParse(
                    stockController.text.trim(),
                  );

                  final price = double.tryParse(
                    priceController.text.trim(),
                  );

                  if (name.isEmpty ||
                      sku.isEmpty ||
                      stock == null ||
                      price == null ||
                      stock < 0 ||
                      price < 0) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter valid product information.',
                        ),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    product['name'] = name;
                    product['sku'] = sku;
                    product['category'] = category;
                    product['stock'] = stock;
                    product['sellingPrice'] = price;
                    product['description'] =
                        descriptionController.text.trim();
                  });

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Product updated successfully.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Changes'),
              ),
            ],
          );
        },
      );
    },
  );
}

  // ============================================================
  // DELETE PRODUCT
  // ============================================================

  void _showDeleteConfirmation(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Product?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${product['name']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _products.removeWhere((item) => item['id'] == product['id']);
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted successfully.'),
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PRODUCT DETAILS
  // ============================================================

  void _showProductDetails(Map<String, dynamic> product) {
    final stock = product['stock'] as int;
    final price = product['sellingPrice'] as double;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  product['name'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(
                    'SKU',
                    product['sku'].toString(),
                    Icons.qr_code_2,
                  ),
                  _buildDetailRow(
                    'Category',
                    product['category'].toString(),
                    Icons.category_outlined,
                  ),
                  _buildDetailRow(
                    'Stock',
                    stock.toString(),
                    Icons.inventory_outlined,
                  ),
                  _buildDetailRow(
                    'Selling Price',
                    'Rs. ${price.toStringAsFixed(2)}',
                    Icons.payments_outlined,
                  ),
                  _buildDetailRow(
                    'Stock Status',
                    _getStockStatus(stock),
                    Icons.info_outline,
                  ),
                  const Divider(height: 28),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      product['description']?.toString().isNotEmpty == true
                          ? product['description'].toString()
                          : 'No description available.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STOCK BADGE
  // ============================================================

  Widget _buildStockBadge(int stock) {
    final status = _getStockStatus(stock);
    final color = _getStockColor(stock);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT TABLE
  // ============================================================

  Widget _buildProductTable() {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'No products found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Try changing your search or category filter.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // ======================================================
        // SMALL WINDOW
        // ======================================================

        if (constraints.maxWidth < 1000) {
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final product = products[index];

              final stock = product['stock'] as int;
              final price = product['sellingPrice'] as double;

              return _buildResponsiveProductCard(product, stock, price);
            },
          );
        }

        // ======================================================
        // MEDIUM / LARGE WINDOW
        // ======================================================

        return Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalController,
            scrollDirection: Axis.vertical,
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              notificationPredicate: (notification) => notification.depth == 1,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 28,
                  horizontalMargin: 20,
                  headingRowHeight: 52,
                  dataRowMinHeight: 64,
                  dataRowMaxHeight: 72,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Product Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'SKU',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Category',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      numeric: true,
                      label: Text(
                        'Stock',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      numeric: true,
                      label: Text(
                        'Selling Price',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Stock Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Actions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: products.map((product) {
                    final stock = product['stock'] as int;
                    final price = product['sellingPrice'] as double;

                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 170,
                            child: Text(
                              product['name'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(product['sku'].toString())),
                        DataCell(
                          _buildCategoryBadge(product['category'].toString()),
                        ),
                        DataCell(
                          Text(
                            stock.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: stock <= 5 ? _getStockColor(stock) : null,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            'Rs. ${price.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(_buildStockBadge(stock)),
                        DataCell(_buildProductActions(product)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CATEGORY BADGE
  // ============================================================

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ============================================================
  // PRODUCT ACTIONS
  // ============================================================

  Widget _buildProductActions(Map<String, dynamic> product) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View Details',
          icon: const Icon(Icons.visibility_outlined, size: 20),
          onPressed: () => _showProductDetails(product),
        ),
        IconButton(
          tooltip: 'Edit',
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () => _showEditProductDialog(product),
        ),
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(product),
        ),
      ],
    );
  }

  // ============================================================
  // RESPONSIVE PRODUCT CARD
  // ============================================================

  Widget _buildResponsiveProductCard(
    Map<String, dynamic> product,
    int stock,
    double price,
  ) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------
            // Product header
            // ----------------------------------------------------

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 19,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product['sku'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                SizedBox(
                  width: 32,
                  height: 32,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 19,
                    onSelected: (value) {
                      if (value == 'view') {
                        _showProductDetails(product);
                      } else if (value == 'edit') {
                        _showEditProductDialog(product);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(product);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'view', child: Text('View Details')),
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ----------------------------------------------------
            // Category
            // ----------------------------------------------------
            Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    product['category'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 9),

            const Divider(height: 1),

            const SizedBox(height: 9),

            // ----------------------------------------------------
            // Stock + Price
            // ----------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: _buildProductInfo(
                    'Stock',
                    stock.toString(),
                    Icons.inventory_outlined,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildProductInfo(
                    'Price',
                    'Rs. ${price.toStringAsFixed(0)}',
                    Icons.payments_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 9),

            // ----------------------------------------------------
            // Status
            // ----------------------------------------------------
            Row(
              children: [
                Text(
                  'Status',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Flexible(child: _buildStockBadge(stock)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT INFO
  // ============================================================

  Widget _buildProductInfo(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search products, SKU or category...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _searchController.clear,
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY FILTER
  // ============================================================

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.filter_list),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: _categories
          .map(
            (category) => DropdownMenuItem(
              value: category,
              child: Text(category, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallWidth = constraints.maxWidth < 1000;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================

                  if (isSmallWidth)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Products',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your products, stock and pricing',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showAddProductDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product'),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Products',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Manage your products, stock and pricing',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),

                        ElevatedButton.icon(
                          onPressed: _showAddProductDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // SEARCH + FILTER
                  // ==================================================
                  if (isSmallWidth)
                    Column(
                      children: [
                        _buildSearchField(),
                        const SizedBox(height: 10),
                        _buildCategoryDropdown(),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(flex: 3, child: _buildSearchField()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCategoryDropdown()),
                      ],
                    ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // COUNT
                  // ==================================================
                  Row(
                    children: [
                      Text(
                        '${_filteredProducts.length} product${_filteredProducts.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if (_selectedCategory != 'All Categories')
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = 'All Categories';
                            });
                          },
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text('Clear Filter'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // PRODUCTS
                  // ==================================================
                  Expanded(
                    child: Card(
                      elevation: 0,
                      clipBehavior: Clip.antiAlias,
                      child: _buildProductTable(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
