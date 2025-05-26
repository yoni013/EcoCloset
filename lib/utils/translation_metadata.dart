import 'package:flutter/material.dart';
import '../generated/l10n.dart';

class TranslationUtils {
  /// Translates a category/type name based on the app's locale.
  static String getCategory(String category, BuildContext context) {
    final categoryMap = {
      'Activewear': AppLocalizations.of(context).categoryActivewear,
      'Belts': AppLocalizations.of(context).categoryBelts,
      'Coats': AppLocalizations.of(context).categoryCoats,
      'Dresses': AppLocalizations.of(context).categoryDresses,
      'Gloves': AppLocalizations.of(context).categoryGloves,
      'Hats': AppLocalizations.of(context).categoryHats,
      'Jeans': AppLocalizations.of(context).categoryJeans,
      'Jumpsuits': AppLocalizations.of(context).categoryJumpsuits,
      'Overalls': AppLocalizations.of(context).categoryOveralls,
      'Pants': AppLocalizations.of(context).categoryPants,
      'Scarves': AppLocalizations.of(context).categoryScarves,
      'Shirts': AppLocalizations.of(context).categoryShirts,
      'Shoes': AppLocalizations.of(context).categoryShoes,
      'Shorts': AppLocalizations.of(context).categoryShorts,
      'Skirts': AppLocalizations.of(context).categorySkirts,
      'Sleepwear': AppLocalizations.of(context).categorySleepwear,
      'Sweaters': AppLocalizations.of(context).categorySweaters,
      'Swimwear': AppLocalizations.of(context).categorySwimwear,
    };

    return categoryMap[category] ??
        category; // Fallback to English if not found
  }

  /// Translates a color name based on the app's locale.
  static String getColor(String color, BuildContext context) {
    final colorMap = {
      'Beige': AppLocalizations.of(context).colorBeige,
      'Black': AppLocalizations.of(context).colorBlack,
      'Blue': AppLocalizations.of(context).colorBlue,
      'Brown': AppLocalizations.of(context).colorBrown,
      'Custom Color': AppLocalizations.of(context).colorCustom,
      'Gold': AppLocalizations.of(context).colorGold,
      'Gray': AppLocalizations.of(context).colorGray,
      'Green': AppLocalizations.of(context).colorGreen,
      'Maroon': AppLocalizations.of(context).colorMaroon,
      'Multicolor': AppLocalizations.of(context).colorMulticolor,
      'Navy': AppLocalizations.of(context).colorNavy,
      'Orange': AppLocalizations.of(context).colorOrange,
      'Pink': AppLocalizations.of(context).colorPink,
      'Purple': AppLocalizations.of(context).colorPurple,
      'Red': AppLocalizations.of(context).colorRed,
      'Silver': AppLocalizations.of(context).colorSilver,
      'Teal': AppLocalizations.of(context).colorTeal,
      'White': AppLocalizations.of(context).colorWhite,
      'Yellow': AppLocalizations.of(context).colorYellow,
    };

    return colorMap[color] ?? color; // Fallback to English if not found
  }

  /// Translates a condition name based on the app's locale.
  static String getCondition(String condition, BuildContext context) {
    final conditionMap = {
      'Never Used': AppLocalizations.of(context).conditionNeverUsed,
      'Used Once': AppLocalizations.of(context).conditionUsedOnce,
      'New': AppLocalizations.of(context).conditionNew,
      'Like New': AppLocalizations.of(context).conditionLikeNew,
      'Gently Used': AppLocalizations.of(context).conditionGentlyUsed,
      'Worn (Good Condition)': AppLocalizations.of(context).conditionWornGood,
      'Vintage': AppLocalizations.of(context).conditionVintage,
      'Damaged (Repair Needed)': AppLocalizations.of(context).conditionDamaged,
    };

    return conditionMap[condition] ??
        condition; // Fallback to English if not found
  }

  static String getItemType(String type, BuildContext context) {
    switch (type.toLowerCase()) {
      case 'coats':
        return AppLocalizations.of(context).coats;
      case 'sweaters':
        return AppLocalizations.of(context).sweaters;
      case 't-shirts':
        return AppLocalizations.of(context).tShirts;
      case 'pants':
        return AppLocalizations.of(context).pants;
      case 'shoes':
        return AppLocalizations.of(context).shoes;
      default:
        return type;
    }
  }

  static String getItemCondition(String condition, BuildContext context) {
    switch (condition.toLowerCase()) {
      case 'new':
        return AppLocalizations.of(context).newCondition;
      case 'like new':
        return AppLocalizations.of(context).likeNewCondition;
      case 'good':
        return AppLocalizations.of(context).goodCondition;
      case 'fair':
        return AppLocalizations.of(context).fairCondition;
      case 'poor':
        return AppLocalizations.of(context).goodCondition;
      default:
        return condition;
    }
  }

  static String getOrderStatus(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pending_seller':
      case 'awaiting_seller_response':
        return AppLocalizations.of(context).pendingSeller;
      case 'approved':
        return AppLocalizations.of(context).approved;
      case 'declined':
        return AppLocalizations.of(context).declined;
      case 'shipped':
        return AppLocalizations.of(context).shipped;
      case 'delivered':
        return AppLocalizations.of(context).delivered;
      case 'pending_buyer':
      case 'awaiting_buyer_time_selection':
        return AppLocalizations.of(context).pendingBuyer;
      case 'confirmed':
      case 'time_slot_confirmed':
        return AppLocalizations.of(context).confirmed;
      case 'completed':
        return AppLocalizations.of(context).completed;
      case 'cancelled':
        return AppLocalizations.of(context).cancelled;
      default:
        return status;
    }
  }
}
