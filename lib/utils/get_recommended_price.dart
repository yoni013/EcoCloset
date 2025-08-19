// Hardcoded brand base prices
const Map<String, double> brandBasePrices = {
  'Adidas': 80.0,
  'Adika': 50.0,
  'Alexander McQueen': 600.0,
  'Armani Exchange': 300.0,
  'Balenciaga': 700.0,
  'Banana Republic': 100.0,
  'Bershka': 60.0,
  'Boots': 50.0,
  'Breitling': 1200.0,
  'Burberry': 500.0,
  'Bvlgari': 900.0,
  'Calvin Klein': 150.0,
  'Calzedonia': 70.0,
  'Camper': 120.0,
  'Cartier': 2000.0,
  'Castro': 80.0,
  'Chanel': 1000.0,
  'Chloé': 400.0,
  'Coach': 250.0,
  'Converse': 90.0,
  'Cos': 110.0,
  'Crazy Line': 50.0,
  'Crocs': 70.0,
  'Deichmann': 60.0,
  'Diesel': 200.0,
  'Dior': 800.0,
  'DKNY': 250.0,
  'Dolce Gabbana': 600.0,
  'Emporio Armani': 350.0,
  'Ermenegildo Zegna': 500.0,
  'Estée Lauder': 200.0,
  'Fendi': 700.0,
  'Fila': 80.0,
  'Foot Locker': 70.0,
  'Fox': 50.0,
  'Fossil': 150.0,
  'G-Star Raw': 180.0,
  'Gant': 200.0,
  'Gap': 70.0,
  'Givenchy': 750.0,
  'Golf & Co.': 90.0,
  'Gucci': 1000.0,
  'H&M': 40.0,
  'Hermès': 2000.0,
  'Hollister California': 90.0,
  'Hugo Boss': 300.0,
  'Jean Paul Gaultier': 500.0,
  'Jordan': 150.0,
  'Kenzo': 350.0,
  'Lacoste': 200.0,
  'Levi\'s': 100.0,
  'L\'Oréal': 60.0,
  'Louis Vuitton': 1500.0,
  'MAC': 80.0,
  'Mango': 70.0,
  'Maybelline': 50.0,
  'Michael Kors': 400.0,
  'Moncler': 800.0,
  'Nike': 90.0,
  'Nina Ricci': 300.0,
  'Omega': 1500.0,
  'Patagonia': 250.0,
  'Prada': 1200.0,
  'Primark': 40.0,
  'Pull & Bear': 60.0,
  'Puma': 85.0,
  'Ralph Lauren': 250.0,
  'Ray-Ban': 200.0,
  'Reebok': 80.0,
  'Renuar': 70.0,
  'Rolex': 3000.0,
  'Salvatore Ferragamo': 600.0,
  'Sebago': 150.0,
  'Sephora': 100.0,
  'Scoop': 50.0,
  'Swatch': 90.0,
  'Tamnoon': 60.0,
  'Ted Baker': 200.0,
  'The North Face': 250.0,
  'Tiffany & Co.': 2000.0,
  'Timberland': 150.0,
  'Tommy Hilfiger': 200.0,
  'Twentyfourseven': 70.0,
  'Under Armour': 100.0,
  'Uniqlo': 80.0,
  'United Colors of Benetton': 90.0,
  'Valentino': 900.0,
  'Vans': 85.0,
  'Versace': 700.0,
  'Victoria\'s Secret': 150.0,
  'Yves Saint Laurent': 800.0,
  'Zara': 50.0,
};

// Hardcoded condition multipliers
const Map<String, double> conditionMultiplier = {
  'Never Used': 1.0,
  'Used Once': 0.9,
  'New': 0.85,
  'Like New': 0.8,
  'Gently Used': 0.75,
  'Worn (Good Condition)': 0.6,
  'Vintage': 0.9,
  'Damaged (Repair Needed)': 0.3,
};

// Type multipliers
const Map<String, double> typeMultiplier = {
  'Accessories': 0.8,
  'Activewear': 1.0,
  'Belts': 0.5,
  'Blazers': 1.2,
  'Cardigans': 1.0,
  'Coats': 1.5,
  'Dresses': 1.3,
  'Gloves': 0.7,
  'Hats': 0.6,
  'Hoodies': 1.1,
  'Jackets': 1.4,
  'Jeans': 1.2,
  'Jumpsuits': 1.3,
  'Lingerie': 0.8,
  'Overalls': 1.1,
  'Pants': 1.0,
  'Scarves': 0.6,
  'Shirts': 1.0,
  'Shoes': 1.5,
  'Shorts': 0.9,
  'Skirts': 1.0,
  'Sleepwear': 0.8,
  'Socks': 0.5,
  'Suits': 1.6,
  'Sweaters': 1.1,
  'Swimwear': 0.8,
  'Tank Tops': 0.7,
  'T-Shirts': 0.9,
  'Tracksuits': 1.2,
};

// Size multipliers - uncommon sizes may have different demand
const Map<String, double> sizeMultiplier = {
  'XXS': 0.85, // Less common, lower demand
  'XS': 0.95,
  'S': 1.0,
  'M': 1.0,
  'L': 1.0,
  'XL': 0.95,
  'XXL': 0.85, // Less common, lower demand
  'XXXL': 0.75,
  // Shoe sizes
  '35': 0.9,
  '36': 0.95,
  '37': 1.0,
  '38': 1.0,
  '39': 1.0,
  '40': 1.0,
  '41': 1.0,
  '42': 0.95,
  '43': 0.9,
  '44': 0.85,
  '45': 0.8,
  '46': 0.75,
};

// Color multipliers - neutral colors vs unique/fashion colors
const Map<String, double> colorMultiplier = {
  // Classic/Neutral colors - high demand
  'Black': 1.1,
  'White': 1.05,
  'Navy': 1.05,
  'Gray': 1.0,
  'Grey': 1.0,
  'Brown': 0.95,
  'Beige': 0.95,
  'Cream': 1.0,
  
  // Popular fashion colors
  'Red': 1.0,
  'Blue': 1.0,
  'Green': 0.95,
  'Pink': 0.95,
  'Purple': 0.9,
  'Yellow': 0.85,
  'Orange': 0.85,
  
  // Unique/Bold colors - may have lower demand
  'Neon': 0.8,
  'Fluorescent': 0.75,
  'Multi-color': 0.9,
  'Rainbow': 0.8,
};

// Premium keywords in description that may increase value
const List<String> premiumKeywords = [
  'limited edition', 'rare', 'vintage', 'collectible', 'exclusive',
  'designer', 'handmade', 'artisan', 'premium', 'luxury',
  'authentic', 'original', 'special edition', 'unique', 'one-of-a-kind',
  'silk', 'cashmere', 'leather', 'suede', 'wool', 'linen',
  'diamond', 'gold', 'silver', 'platinum', 'crystal'
];

// Enhanced price estimation with additional factors
int estimateItemValue(String brand, String condition, String type, {
  String? size,
  String? color,
  String? description,
}) {
  // Get the base price, default to 30 if brand is unknown
  double basePrice = brandBasePrices[brand] ?? 30.0;

  // Get the condition multiplier, default to 0.5 for unknown condition
  double conditionFactor = conditionMultiplier[condition] ?? 0.5;

  // Get the type multiplier, default to 1.0 for unknown types
  double typeFactor = typeMultiplier[type] ?? 1.0;

  // Get the size multiplier, default to 1.0 for unknown sizes
  double sizeFactor = 1.0;
  if (size != null && size.isNotEmpty) {
    sizeFactor = sizeMultiplier[size] ?? 1.0;
  }

  // Get the color multiplier, default to 1.0 for unknown colors
  double colorFactor = 1.0;
  if (color != null && color.isNotEmpty) {
    colorFactor = colorMultiplier[color] ?? 1.0;
  }

  // Analyze description for premium keywords
  double descriptionFactor = 1.0;
  if (description != null && description.isNotEmpty) {
    final lowerDescription = description.toLowerCase();
    int premiumKeywordCount = 0;
    
    for (final keyword in premiumKeywords) {
      if (lowerDescription.contains(keyword.toLowerCase())) {
        premiumKeywordCount++;
      }
    }
    
    // Each premium keyword adds 5% to the value, capped at 25% increase
    descriptionFactor = 1.0 + (premiumKeywordCount * 0.05).clamp(0.0, 0.25);
  }

  // Calculate estimated price with all factors
  double estimatedPrice = basePrice * conditionFactor * typeFactor * sizeFactor * colorFactor * descriptionFactor;

  // Round to nearest 10 (e.g., 53 -> 50, 77 -> 80)
  int roundedPrice = (estimatedPrice / 10).round() * 10;

  // Ensure minimum price of 10
  return roundedPrice < 10 ? 10 : roundedPrice;
}

// Legacy function for backward compatibility
int estimateItemValueBasic(String brand, String condition, String type) {
  return estimateItemValue(brand, condition, type);
}
