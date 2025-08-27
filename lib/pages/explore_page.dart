import 'package:beged/pages/explore_category_page.dart';
import 'package:flutter/material.dart';
import 'package:beged/generated/l10n.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExplorePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'name': AppLocalizations.of(context).categorySweaters, 'db_name': 'Sweaters', 'icon': Icons.interests},
      {'name': AppLocalizations.of(context).categoryCoats, 'db_name': 'Coats', 'icon': Icons.dry_cleaning},
      {'name': AppLocalizations.of(context).categoryDresses, 'db_name': 'Dresses', 'icon': Icons.female},
      {'name': AppLocalizations.of(context).categoryShirts, 'db_name': 'T-Shirts', 'icon': Icons.checkroom},
      {'name': AppLocalizations.of(context).categoryPants, 'db_name': 'Pants', 'icon': Icons.checkroom},
      {'name': AppLocalizations.of(context).categoryShoes, 'db_name': 'Shoes', 'icon': Icons.directions_walk},
      {'name': AppLocalizations.of(context).shopAll, 'db_name': '', 'icon': Icons.grid_view},
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CategoryItemsPage(category: cat['db_name'] as String),
                    ),
                  );
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CategoryItemsPage(category: cat['db_name'] as String),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            child: Icon(
                              cat['icon'] as IconData,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  (cat['name'] != null && (cat['name'] as String).isNotEmpty)
                                      ? cat['name'] as String
                                      : AppLocalizations.of(context).shopAll,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate(delay: (50 * index).ms).fadeIn(
                    duration: 600.ms,
                    curve: Curves.easeOutQuad,
                  ).slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 600.ms,
                    curve: Curves.easeOutQuad,
                  );
            },
          ),
        ),
      ),
    );
  }
}
