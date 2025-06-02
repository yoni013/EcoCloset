import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../generated/l10n.dart';
import '../models/tag_model.dart';
import '../services/tag_service.dart';
import '../utils/fetch_item_metadata.dart';

class EnhancedFilterPopup extends StatefulWidget {
  final Map<String, dynamic> initialFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const EnhancedFilterPopup({
    Key? key,
    required this.initialFilters,
    required this.onFiltersChanged,
  }) : super(key: key);

  @override
  State<EnhancedFilterPopup> createState() => _EnhancedFilterPopupState();
}

class _EnhancedFilterPopupState extends State<EnhancedFilterPopup>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TagService _tagService = TagService();
  
  // Existing filters
  List<String> _selectedTypes = [];
  List<String> _selectedSizes = [];
  List<String> _selectedBrands = [];
  List<String> _selectedColors = [];
  List<String> _selectedConditions = [];
  RangeValues _priceRange = const RangeValues(0, 1000);

  // Tag filters
  Map<String, List<String>> _selectedTagsByCategory = {};
  
  // Available options
  List<String> _types = [];
  List<String> _sizes = [];
  List<String> _brands = [];
  List<String> _colors = [];
  List<String> _conditions = [];
  Map<String, List<Tag>> _tagsByCategory = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialFilters();
    _loadFilterOptions();
    _loadTags();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInitialFilters() {
    _selectedTypes = List<String>.from(widget.initialFilters['type'] ?? []);
    _selectedSizes = List<String>.from(widget.initialFilters['size'] ?? []);
    _selectedBrands = List<String>.from(widget.initialFilters['brand'] ?? []);
    _selectedColors = List<String>.from(widget.initialFilters['color'] ?? []);
    _selectedConditions = List<String>.from(widget.initialFilters['condition'] ?? []);
    _priceRange = widget.initialFilters['priceRange'] ?? const RangeValues(0, 1000);
    _selectedTagsByCategory = Map<String, List<String>>.from(
      widget.initialFilters['tags'] ?? {}
    );
  }

  Future<void> _loadFilterOptions() async {
    try {
      await Utils.loadMetadata();
      setState(() {
        _types = Utils.types;
        _sizes = Utils.sizes;
        _brands = Utils.brands;
        _colors = Utils.colors;
        _conditions = Utils.conditions;
      });
    } catch (e) {
      debugPrint('Error loading filter options: $e');
    }
  }

  Future<void> _loadTags() async {
    try {
      await _tagService.initialize();
      final availableTags = _tagService.availableTags;
      
      // Group tags by category
      final tagsByCategory = <String, List<Tag>>{};
      for (final tag in availableTags) {
        if (!tagsByCategory.containsKey(tag.category)) {
          tagsByCategory[tag.category] = [];
        }
        tagsByCategory[tag.category]!.add(tag);
      }
      
      setState(() {
        _tagsByCategory = tagsByCategory;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading tags: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final filters = <String, dynamic>{
      'type': _selectedTypes,
      'size': _selectedSizes,
      'brand': _selectedBrands,
      'color': _selectedColors,
      'condition': _selectedConditions,
      'priceRange': _priceRange,
      'tags': _selectedTagsByCategory,
    };
    
    widget.onFiltersChanged(filters);
    Navigator.of(context).pop();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedTypes.clear();
      _selectedSizes.clear();
      _selectedBrands.clear();
      _selectedColors.clear();
      _selectedConditions.clear();
      _priceRange = const RangeValues(0, 1000);
      _selectedTagsByCategory.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).filter,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Basic Filters'),
                Tab(text: 'Style Tags'),
              ],
            ),

            // Tab Views
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBasicFiltersTab(),
                        _buildTagFiltersTab(),
                      ],
                    ),
            ),

            // Apply Button
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).apply,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildBasicFiltersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMultiSelectFilter(
            title: AppLocalizations.of(context).type,
            options: _types,
            selectedValues: _selectedTypes,
            onChanged: (values) => setState(() => _selectedTypes = values),
          ),
          const SizedBox(height: 16),
          _buildMultiSelectFilter(
            title: AppLocalizations.of(context).size,
            options: _sizes,
            selectedValues: _selectedSizes,
            onChanged: (values) => setState(() => _selectedSizes = values),
          ),
          const SizedBox(height: 16),
          _buildMultiSelectFilter(
            title: AppLocalizations.of(context).brand,
            options: _brands,
            selectedValues: _selectedBrands,
            onChanged: (values) => setState(() => _selectedBrands = values),
          ),
          const SizedBox(height: 16),
          _buildMultiSelectFilter(
            title: AppLocalizations.of(context).color,
            options: _colors,
            selectedValues: _selectedColors,
            onChanged: (values) => setState(() => _selectedColors = values),
          ),
          const SizedBox(height: 16),
          _buildMultiSelectFilter(
            title: AppLocalizations.of(context).condition,
            options: _conditions,
            selectedValues: _selectedConditions,
            onChanged: (values) => setState(() => _selectedConditions = values),
          ),
          const SizedBox(height: 24),
          _buildPriceRangeFilter(),
        ],
      ),
    );
  }

  Widget _buildTagFiltersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Style & Preferences',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select tags that match what you\'re looking for',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ..._tagsByCategory.entries.map((entry) {
            final category = entry.key;
            final tags = entry.value;
            
            return _buildTagCategoryFilter(
              category: category,
              tags: tags,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMultiSelectFilter({
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        MultiSelectDialogField(
          items: options.map((option) => MultiSelectItem(option, option)).toList(),
          title: Text('Select $title'),
          selectedColor: Theme.of(context).colorScheme.primary,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          buttonIcon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          buttonText: Text(
            selectedValues.isEmpty
                ? 'Select $title'
                : '${selectedValues.length} selected',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          onConfirm: onChanged,
          initialValue: selectedValues,
        ),
      ],
    );
  }

  Widget _buildTagCategoryFilter({
    required String category,
    required List<Tag> tags,
  }) {
    final selectedTags = _selectedTagsByCategory[category] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatCategoryName(category),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final isSelected = selectedTags.contains(tag.name);
            
            return FilterChip(
              label: Text(tag.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (!_selectedTagsByCategory.containsKey(category)) {
                    _selectedTagsByCategory[category] = [];
                  }
                  
                  if (selected) {
                    _selectedTagsByCategory[category]!.add(tag.name);
                  } else {
                    _selectedTagsByCategory[category]!.remove(tag.name);
                  }
                  
                  // Remove empty categories
                  if (_selectedTagsByCategory[category]!.isEmpty) {
                    _selectedTagsByCategory.remove(category);
                  }
                });
              },
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).priceRange,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 1000,
          divisions: 50,
          labels: RangeLabels(
            '₪${_priceRange.start.round()}',
            '₪${_priceRange.end.round()}',
          ),
          onChanged: (values) {
            setState(() {
              _priceRange = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('₪${_priceRange.start.round()}'),
            Text('₪${_priceRange.end.round()}'),
          ],
        ),
      ],
    );
  }

  String _formatCategoryName(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
} 