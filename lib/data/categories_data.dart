import '../models/category.dart';

class CategoriesData {
  static final List<Category> categories = [
    Category(
      name: 'T-Shirts',
      type: 'image',
      image:
          'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/image-7Zih6I1qFheS9XELo0orL76keeJi7H.png',
      description: 'Comfortable and stylish t-shirts for everyday wear',
    ),
    Category(
      name: 'Hoodies',
      type: 'image',
      image:
          'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Hoodie_appimg.PNG-UkgfqGGPgl1p624MNH8gbsGFus8COx.png',
      description: 'Cozy hoodies perfect for casual and street style',
    ),
    Category(
      name: 'Sweatshirts',
      type: 'image',
      image:
          'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Sweatshirt_appimg.PNG-stbgbQ97A0VBOYJiwv3GAzpP8JvyrA.png',
      description: 'Premium sweatshirts for comfort and style',
    ),
    Category(
      name: 'Shirts',
      type: 'image',
      image:
          'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Shirt_appimg-oLQXEbn3cH36bKsWBRUCk5cHRd8EsE.png',
      description: 'Formal and casual shirts for all occasions',
    ),
    Category(
      name: 'Polo',
      type: 'image',
      image:
          'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Polo_appimg-MB1NVY0Jf1xfjqsDV10r7tvAL0dd5O.png',
      description: 'Classic polo shirts for smart casual look',
    ),
    Category(
      name: 'Tank Tops',
      type: 'image',
      image:
          'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Tanktop_appimg-Jq79NUJOe18uWn3nknUVIQEzvTrIx8.png',
      description: 'Breathable tank tops for workouts and summer',
    ),
    Category(
      name: 'Sweatpants',
      type: 'image',
      image:
          'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Sweatpants_appimg-ITYRrT2Y0Ae5LTfoftiIxOl7eosNIU.png',
      description: 'Comfortable sweatpants for lounging and exercise',
    ),
    Category(
      name: 'Shorts',
      type: 'image',
      image:
          'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Shorts_appimg-CRUDzi32VPDQ3wFWDkgrychI9aTFzD.png',
      description: 'Stylish shorts for summer and casual wear',
    ),
    Category(
      name: 'Zipper Hoodies',
      type: 'image',
      image: 'assets/images/zipper_hoodies/black/2.webp',
      description: 'Premium quality zipper hoodies for everyday comfort',
    ),
  ];

  static Category? getCategoryByName(String name) {
    try {
      return categories.firstWhere((category) => category.name == name);
    } catch (e) {
      return null;
    }
  }

  static List<String> getAllCategoryNames() {
    return categories.map((category) => category.name).toList();
  }
}
