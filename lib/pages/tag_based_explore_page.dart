import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'explore_category_page.dart';

class TagBasedExplorePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Simple static categories - no complex loading or Firebase dependencies
    final exploreCategories = [
      {
        'key': 'summer',
        'name': 'Summer Wear',
        'description': 'Light & breezy',
        'icon': Icons.wb_sunny,
        'color': Colors.orange,
      },
      {
        'key': 'shoes',
        'name': 'Shoes',
        'description': 'Step in style',
        'icon': Icons.accessibility_new,
        'color': Colors.brown,
      },
      {
        'key': 'accessories',
        'name': 'Accessories',
        'description': 'Complete the look',
        'icon': Icons.watch,
        'color': Colors.purple,
      },
      {
        'key': 'new-arrivals',
        'name': 'New Arrivals',
        'description': 'Fresh additions',
        'icon': Icons.new_releases,
        'color': Colors.green,
      },
      {
        'key': 'activewear',
        'name': 'Active Wear',
        'description': 'Move with confidence',
        'icon': Icons.fitness_center,
        'color': Colors.blue,
      },
      {
        'key': 'filters',
        'name': 'Shop by Filters',
        'description': 'Find exactly what you want',
        'icon': Icons.tune,
        'color': Colors.grey,
      },
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
            itemCount: exploreCategories.length,
            itemBuilder: (context, index) {
              final category = exploreCategories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryItemsPage(
                        category: '', // Empty category for new system
                        categoryKey: category['key'] as String, // Pass the categoryKey for tag-based filtering
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                (category['color'] as Color).withOpacity(0.1),
                                (category['color'] as Color).withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: Icon(
                            category['icon'] as IconData,
                            size: 48,
                            color: category['color'] as Color,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                category['name'] as String,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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