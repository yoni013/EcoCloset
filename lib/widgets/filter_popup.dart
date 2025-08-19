import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:eco_closet/generated/l10n.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eco_closet/utils/translation_metadata.dart';

class FilterPopup extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApply;
  final List<String> sizes;
  final List<String> brands;
  final List<String> types;
  final List<String> colors;
  final List<String> conditions;

  const FilterPopup({
    Key? key,
    required this.currentFilters,
    required this.onApply,
    required this.sizes,
    required this.brands,
    required this.types,
    required this.colors,
    required this.conditions,
  }) : super(key: key);

  @override
  _FilterPopupState createState() => _FilterPopupState();
}

class _FilterPopupState extends State<FilterPopup> {
  late Map<String, dynamic> localFilters;

  @override
  void initState() {
    super.initState();
    // Copy from widget.currentFilters into localFilters
    localFilters = {
      'type': List<String>.from(widget.currentFilters['type'] ?? []),
      'size': List<String>.from(widget.currentFilters['size'] ?? []),
      'brand': List<String>.from(widget.currentFilters['brand'] ?? []),
      'color': List<String>.from(widget.currentFilters['color'] ?? []),
      'condition': List<String>.from(widget.currentFilters['condition'] ?? []),
      'priceRange':
          widget.currentFilters['priceRange'] ?? const RangeValues(0, 1000),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).filter,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).priceRange,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Min: ₪${localFilters['priceRange'].start.round()}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Max: ₪${localFilters['priceRange'].end.round()}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      RangeSlider(
                        values: localFilters['priceRange'],
                        min: 0,
                        max: 1000,
                        divisions: 100,
                        labels: RangeLabels(
                          '₪${localFilters['priceRange'].start.round()}',
                          '₪${localFilters['priceRange'].end.round()}',
                        ),
                        onChanged: (range) {
                          setState(() {
                            localFilters['priceRange'] = range;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 600.ms,
                    curve: Curves.easeOutQuad,
                  ),
              const SizedBox(height: 16),
              _buildMultiselectField(
                label: AppLocalizations.of(context).type,
                options: widget.types,
                initialValues: localFilters['type'],
                onConfirm: (values) => localFilters['type'] = values,
                type: 'category',
              ),
              _buildMultiselectField(
                label: AppLocalizations.of(context).size,
                options: widget.sizes,
                initialValues: localFilters['size'],
                onConfirm: (values) => localFilters['size'] = values,
                type: '',
              ),
              _buildMultiselectField(
                label: AppLocalizations.of(context).brand,
                options: widget.brands,
                initialValues: localFilters['brand'],
                onConfirm: (values) => localFilters['brand'] = values,
                type: '',
              ),
              _buildMultiselectField(
                label: AppLocalizations.of(context).color,
                options: widget.colors,
                initialValues: localFilters['color'],
                onConfirm: (values) => localFilters['color'] = values,
                type: 'color',
              ),
              _buildMultiselectField(
                label: AppLocalizations.of(context).condition,
                options: widget.conditions,
                initialValues: localFilters['condition'],
                onConfirm: (values) => localFilters['condition'] = values,
                type: 'condition',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                      label: Text(AppLocalizations.of(context).cancel),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.onApply(localFilters);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check),
                      label: Text(AppLocalizations.of(context).apply),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 600.ms,
                    curve: Curves.easeOutQuad,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiselectField({
    required String label,
    required List<String> options,
    required List<String> initialValues,
    required Function(List<String>) onConfirm,
    required String type,
  }) {
    final items = options.map((option) {
      String translatedOption = option;
      if (type == 'category') {
        translatedOption = TranslationUtils.getCategory(option, context);
      } else if (type == 'color') {
        translatedOption = TranslationUtils.getColor(option, context);
      } else if (type == 'condition') {
        translatedOption = TranslationUtils.getCondition(option, context);
      }
      return MultiSelectItem<String>(option, translatedOption);
    }).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            MultiSelectDialogField<String>(
              title: Text(label),
              items: items,
              searchable: true,
              initialValue: initialValues,
              dialogHeight: MediaQuery.of(context).size.height * 0.5,
              dialogWidth: MediaQuery.of(context).size.width * 0.85,
              buttonText: Text(
                AppLocalizations.of(context).select(label),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              buttonIcon: const Icon(Icons.arrow_drop_down),
              selectedItemsTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              searchTextStyle: Theme.of(context).textTheme.bodyLarge,
              itemsTextStyle: Theme.of(context).textTheme.bodyLarge,
              chipDisplay: MultiSelectChipDisplay(
                chipColor: Theme.of(context).colorScheme.primaryContainer,
                textStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onConfirm: onConfirm,
            ),
          ],
        ),
      ),
    )
        .animate(delay: (50 * options.indexOf(options.first)).ms)
        .fadeIn(
          duration: 600.ms,
          curve: Curves.easeOutQuad,
        )
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutQuad,
        );
  }
} 