import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eco_closet/pages/item_page.dart';

class ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int? animationIndex;

  const ItemCard({
    Key? key,
    required this.item,
    this.animationIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = item['image_preview'] ?? item['imageUrl'] ?? '';
    
    return Card(
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
              builder: (context) => ItemPage(itemId: item['id']),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(context, imageUrl),
                  _buildPriceTag(context),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: _buildItemInfo(context),
            ),
          ],
        ),
      ),
    ).animate(delay: animationIndex != null ? (50 * animationIndex!).ms : 0.ms)
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

  Widget _buildImage(BuildContext context, String imageUrl) {
    if (imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Icon(
            Icons.image_not_supported,
            size: 50,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } else {
      return Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Icon(
          Icons.image_not_supported,
          size: 50,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
  }

  Widget _buildPriceTag(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '\₪${item['Price'] ?? 'N/A'}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildItemInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item['Brand'] ?? 'Unknown',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            item['Type'] ?? '',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
} 