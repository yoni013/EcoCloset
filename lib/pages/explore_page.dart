import 'package:eco_closet/pages/explore_category_page.dart';
import 'package:flutter/material.dart';
import 'package:eco_closet/generated/l10n.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExplorePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': AppLocalizations.of(context).categorySweaters, 'db_name': 'Sweaters', 'image': 'assets/images/sweaters.png'},
      {'name': AppLocalizations.of(context).categoryCoats, 'db_name': 'Coats', 'image': 'assets/images/coats.png'},
      {'name': AppLocalizations.of(context).categoryDresses, 'db_name': 'Dresses', 'image': 'assets/images/dresses.png'},
      {'name': AppLocalizations.of(context).categoryShirts, 'db_name': 'T-Shirts', 'image': 'assets/images/shirts.png'},
      {'name': AppLocalizations.of(context).categoryPants, 'db_name': 'Pants', 'image': 'assets/images/pants.png'},
      {'name': AppLocalizations.of(context).categoryShoes, 'db_name': 'Shoes', 'image': 'assets/images/shoes.png'},
      {'name': AppLocalizations.of(context).shopAll, 'db_name': '', 'image': 'assets/images/all.png'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).chooseCategories,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        elevation: 0,
      ),
      body: Padding(
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
                        CategoryItemsPage(category: cat['db_name']!),
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
                            CategoryItemsPage(category: cat['db_name']!),
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
                          child: Image.asset(
                            cat['image']!,
                            fit: BoxFit.contain,
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
                                (cat['name'] != null && cat['name']!.isNotEmpty)
                                    ? cat['name']!
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
    );
  }
}
