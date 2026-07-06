import '../models/product.dart';

class ProductsData {
  static final Map<String, List<Product>> _productsByCategory = {
    'T-Shirts': [
      Product(
        id: 'tshirt_acid_wash',
        name: 'Acid Wash Oversized Tee',
        price: '₹849',
        originalPrice: '₹1299',
        image: 'assets/images/oversized_tshirts/acid_wash/25.webp',
        discount: '33% OFF',
        images: [
          'assets/images/oversized_tshirts/acid_wash/25.webp',
          'assets/images/oversized_tshirts/acid_wash/29.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        variantLabel: 'Design',
        colors: [
          'Beinn Left',
          'Unorthodox',
          'Nevermind',
          'Go To God First',
          'Beinn Middle'
        ],
        colorImages: {
          'Beinn Left': [
            'assets/images/oversized_tshirts/acid_wash/25.webp',
            'assets/images/oversized_tshirts/acid_wash/29.webp'
          ],
          'Unorthodox': [
            'assets/images/oversized_tshirts/acid_wash/24.webp',
            'assets/images/oversized_tshirts/acid_wash/29.webp'
          ],
          'Nevermind': [
            'assets/images/oversized_tshirts/acid_wash/26.webp',
            'assets/images/oversized_tshirts/acid_wash/29.webp'
          ],
          'Go To God First': [
            'assets/images/oversized_tshirts/acid_wash/27.webp',
            'assets/images/oversized_tshirts/acid_wash/30.webp'
          ],
          'Beinn Middle': [
            'assets/images/oversized_tshirts/acid_wash/28.webp',
            'assets/images/oversized_tshirts/acid_wash/29.webp'
          ],
        },
        description:
            'Premium acid wash oversized t-shirt with distinctive texture.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent only.\n• Do not bleach or tumble dry.\n• Gentle machine or hand wash.\n• Iron inside out. No iron on print.',
        details: '100% Cotton. Oversized fit. Machine wash cold.',
        category: 'T-Shirts',
      ),
      Product(
        id: 'tshirt_be_real',
        name: 'Be Real Graphic Tee',
        price: '₹799',
        originalPrice: '₹1199',
        image: 'assets/images/oversized_tshirts/be_real/42.webp',
        discount: '31% OFF',
        images: [
          'assets/images/oversized_tshirts/be_real/42.webp',
          'assets/images/oversized_tshirts/back/50.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Beige', 'Green', 'Pearl Blue', 'Black', 'Maroon', 'Grey'],
        colorImages: {
          'Beige': [
            'assets/images/oversized_tshirts/be_real/42.webp',
            'assets/images/oversized_tshirts/back/50.webp'
          ],
          'Green': [
            'assets/images/oversized_tshirts/be_real/3.webp',
            'assets/images/oversized_tshirts/back/6.webp'
          ],
          'Pearl Blue': [
            'assets/images/oversized_tshirts/be_real/12.webp',
            'assets/images/oversized_tshirts/back/14.webp'
          ],
          'Black': [
            'assets/images/oversized_tshirts/be_real/21.webp',
            'assets/images/oversized_tshirts/back/22.webp'
          ],
          'Maroon': [
            'assets/images/oversized_tshirts/be_real/60.webp',
            'assets/images/oversized_tshirts/back/62.webp'
          ],
          'Grey': [
            'assets/images/oversized_tshirts/be_real/69.webp',
            'assets/images/oversized_tshirts/back/72.webp'
          ],
        },
        description: 'Statement graphic tee with "Be Real" print.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent only.\n• Do not bleach or tumble dry.\n• Gentle machine or hand wash.\n• Iron inside out. No iron on print.',
        details: 'Soft cotton fabric. High quality print.',
        category: 'T-Shirts',
      ),
      Product(
        id: 'tshirt_beinn_flower',
        name: 'Beinn Flower Edition',
        price: '₹899',
        originalPrice: '₹1299',
        image: 'assets/images/oversized_tshirts/beinn_flower/35.webp',
        discount: '32% OFF',
        images: [
          'assets/images/oversized_tshirts/beinn_flower/35.webp',
          'assets/images/oversized_tshirts/back/40.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['White', 'Beige'],
        colorImages: {
          'White': [
            'assets/images/oversized_tshirts/beinn_flower/35.webp',
            'assets/images/oversized_tshirts/back/40.webp'
          ],
          'Beige': [
            'assets/images/oversized_tshirts/beinn_flower/48.webp',
            'assets/images/oversized_tshirts/back/50.webp'
          ],
        },
        description: 'Floral inspired design from the Beinn collection.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent only.\n• Do not bleach or tumble dry.\n• Gentle machine or hand wash.\n• Iron inside out. No iron on print.',
        details: 'Premium cotton blend. Modern fit.',
        category: 'T-Shirts',
      ),
      Product(
        id: 'tshirt_beinn_middle',
        name: 'Beinn Middle Logo Tee',
        price: '₹749',
        originalPrice: '₹1199',
        image: 'assets/images/oversized_tshirts/beinn_middle/70.webp',
        discount: '31% OFF',
        images: [
          'assets/images/oversized_tshirts/beinn_middle/70.webp',
          'assets/images/oversized_tshirts/back/72.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: [
          'Grey',
          'Green',
          'Pearl Blue',
          'Black',
          'White',
          'Beige',
          'Maroon',
        ],
        colorImages: {
          'Grey': [
            'assets/images/oversized_tshirts/beinn_middle/70.webp',
            'assets/images/oversized_tshirts/back/72.webp'
          ],
          'Green': [
            'assets/images/oversized_tshirts/beinn_middle/5.webp',
            'assets/images/oversized_tshirts/back/6.webp'
          ],
          'Pearl Blue': [
            'assets/images/oversized_tshirts/beinn_middle/13.webp',
            'assets/images/oversized_tshirts/back/14.webp'
          ],
          'Black': [
            'assets/images/oversized_tshirts/beinn_middle/20.webp',
            'assets/images/oversized_tshirts/back/22.webp'
          ],
          'White': [
            'assets/images/oversized_tshirts/beinn_middle/39.webp',
            'assets/images/oversized_tshirts/back/40.webp'
          ],
          'Beige': [
            'assets/images/oversized_tshirts/beinn_middle/49.webp',
            'assets/images/oversized_tshirts/back/50.webp'
          ],
          'Maroon': [
            'assets/images/oversized_tshirts/beinn_middle/59.webp',
            'assets/images/oversized_tshirts/back/62.webp'
          ],
        },
        description: 'Centered logo design for a balanced look.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent only.\n• Do not bleach or tumble dry.\n• Gentle machine or hand wash.\n• Iron inside out. No iron on print.',
        details: '100% Cotton. Standard fit.',
        category: 'T-Shirts',
      ),
      Product(
        id: 'tshirt_beinn_side',
        name: 'Beinn Side Logo Tee',
        price: '₹749',
        originalPrice: '₹1199',
        image: 'assets/images/oversized_tshirts/beinn_side/58.webp',
        discount: '31% OFF',
        images: [
          'assets/images/oversized_tshirts/beinn_side/58.webp',
          'assets/images/oversized_tshirts/back/62.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: [
          'Maroon',
          'Green',
          'Pearl Blue',
          'Black',
          'White',
          'Beige',
          'Grey'
        ],
        colorImages: {
          'Maroon': [
            'assets/images/oversized_tshirts/beinn_side/58.webp',
            'assets/images/oversized_tshirts/back/62.webp'
          ],
          'Green': [
            'assets/images/oversized_tshirts/beinn_side/1.webp',
            'assets/images/oversized_tshirts/back/6.webp'
          ],
          'Pearl Blue': [
            'assets/images/oversized_tshirts/beinn_side/7.webp',
            'assets/images/oversized_tshirts/back/14.webp'
          ],
          'Black': [
            'assets/images/oversized_tshirts/beinn_side/15.webp',
            'assets/images/oversized_tshirts/back/22.webp'
          ],
          'White': [
            'assets/images/oversized_tshirts/beinn_side/31.webp',
            'assets/images/oversized_tshirts/back/40.webp'
          ],
          'Beige': [
            'assets/images/oversized_tshirts/beinn_side/41.webp',
            'assets/images/oversized_tshirts/back/50.webp'
          ],
          'Grey': [
            'assets/images/oversized_tshirts/beinn_side/68.webp',
            'assets/images/oversized_tshirts/back/72.webp'
          ],
        },
        description: 'Minimalist side logo placement.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent only.\n• Do not bleach or tumble dry.\n• Gentle machine or hand wash.\n• Iron inside out. No iron on print.',
        details: 'Premium fabric. Casual wear.',
        category: 'T-Shirts',
      ),
      Product(
        id: 'tshirt_corporeal',
        name: 'Corporeal Print Tee',
        price: '₹899',
        originalPrice: '₹1299',
        image: 'assets/images/oversized_tshirts/corporeal/10.webp',
        discount: '31% OFF',
        images: [
          'assets/images/oversized_tshirts/corporeal/10.webp',
          'assets/images/oversized_tshirts/back/14.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Pearl Blue', 'Black', 'White', 'Beige'],
        colorImages: {
          'Pearl Blue': [
            'assets/images/oversized_tshirts/corporeal/10.webp',
            'assets/images/oversized_tshirts/back/14.webp'
          ],
          'Black': [
            'assets/images/oversized_tshirts/corporeal/16.webp',
            'assets/images/oversized_tshirts/back/22.webp'
          ],
          'White': [
            'assets/images/oversized_tshirts/corporeal/32.webp',
            'assets/images/oversized_tshirts/back/40.webp'
          ],
          'Beige': [
            'assets/images/oversized_tshirts/corporeal/47.webp',
            'assets/images/oversized_tshirts/back/50.webp'
          ],
        },
        description: 'Abstract corporeal design.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent only.\n• Do not bleach or tumble dry.\n• Gentle machine or hand wash.\n• Iron inside out. No iron on print.',
        details: 'Soft touch fabric.',
        category: 'T-Shirts',
      ),
      Product(
        id: 'tshirt_plains',
        name: 'Classic Plain Tee',
        price: '₹599',
        originalPrice: '₹999',
        image: 'assets/images/oversized_tshirts/plains/2.webp',
        discount: '33% OFF',
        images: [
          'assets/images/oversized_tshirts/plains/2.webp',
          'assets/images/oversized_tshirts/back/6.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Green', 'Pearl Blue', 'Black', 'White', 'Beige'],
        colorImages: {
          'Green': [
            'assets/images/oversized_tshirts/plains/2.webp',
            'assets/images/oversized_tshirts/back/6.webp'
          ],
          'Pearl Blue': [
            'assets/images/oversized_tshirts/plains/9.webp',
            'assets/images/oversized_tshirts/back/14.webp'
          ],
          'Black': [
            'assets/images/oversized_tshirts/plains/18.webp',
            'assets/images/oversized_tshirts/back/22.webp'
          ],
          'White': [
            'assets/images/oversized_tshirts/plains/33.webp',
            'assets/images/oversized_tshirts/back/40.webp'
          ],
          'Beige': [
            'assets/images/oversized_tshirts/plains/44.webp',
            'assets/images/oversized_tshirts/back/50.webp'
          ],
        },
        description: 'Essential plain t-shirt for everyday wear.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent only.\n• Do not bleach or tumble dry.\n• Gentle machine or hand wash.\n• Iron inside out. No iron on print.',
        details: '100% Organic Cotton. Breathable.',
        category: 'T-Shirts',
      ),
      Product(
        id: 'tshirt_unorthodox',
        name: 'Unorthodox Graphic Tee',
        price: '₹749',
        originalPrice: '₹1199',
        image: 'assets/images/oversized_tshirts/unorthodox/19.webp',
        discount: '33% OFF',
        images: [
          'assets/images/oversized_tshirts/unorthodox/19.webp',
          'assets/images/oversized_tshirts/back/22.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Black', 'Green', 'Pearl Blue', 'Beige', 'Maroon', 'Grey'],
        colorImages: {
          'Black': [
            'assets/images/oversized_tshirts/unorthodox/19.webp',
            'assets/images/oversized_tshirts/back/22.webp'
          ],
          'Green': [
            'assets/images/oversized_tshirts/unorthodox/4.webp',
            'assets/images/oversized_tshirts/back/6.webp'
          ],
          'Pearl Blue': [
            'assets/images/oversized_tshirts/unorthodox/11.webp',
            'assets/images/oversized_tshirts/back/14.webp'
          ],
          'Beige': [
            'assets/images/oversized_tshirts/unorthodox/45.webp',
            'assets/images/oversized_tshirts/back/50.webp'
          ],
          'Maroon': [
            'assets/images/oversized_tshirts/unorthodox/61.webp',
            'assets/images/oversized_tshirts/back/62.webp'
          ],
          'Grey': [
            'assets/images/oversized_tshirts/unorthodox/71.webp',
            'assets/images/oversized_tshirts/back/72.webp'
          ],
        },
        description: 'Bold Unorthodox printed t-shirt.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent only.\n• Do not bleach or tumble dry.\n• Gentle machine or hand wash.\n• Iron inside out. No iron on print.',
        details: 'Streetwear fit. Durable print.',
        category: 'T-Shirts',
      ),
    ],
    'Shirts': [
      Product(
        id: 'shirt_1',
        name: 'Formal White Shirt',
        price: '₹849',
        originalPrice: '₹1199',
        image: 'assets/images/shirts/b_shirt/1.webp',
        discount: '30% OFF',
        images: [
          'assets/images/shirts/b_shirt/1.webp',
          'assets/images/shirts/back/3.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Beige', 'Blue', 'Charcoal Grey', 'White', 'Black'],
        colorImages: {
          'Beige': [
            'assets/images/shirts/b_shirt/1.webp',
            'assets/images/shirts/back/3.webp'
          ],
          'Blue': [
            'assets/images/shirts/b_shirt/4.webp',
            'assets/images/shirts/back/6.webp'
          ],
          'Charcoal Grey': [
            'assets/images/shirts/b_shirt/7.webp',
            'assets/images/shirts/back/9.webp'
          ],
          'White': [
            'assets/images/shirts/b_shirt/10.webp',
            'assets/images/shirts/back/12.webp'
          ],
          'Black': [
            'assets/images/shirts/b_shirt/13.webp',
            'assets/images/shirts/back/15.webp'
          ],
        },
        description:
            'Classic formal shirt perfect for office wear and business meetings.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent only.\n• Do not bleach or tumble dry.\n• Gentle machine or hand wash.\n• Iron inside out. No iron on print.',
        details: 'Premium cotton blend. Wrinkle-resistant. Professional fit.',
        category: 'Shirts',
      ),
      Product(
        id: 'shirt_2',
        name: 'Casual Denim Shirt',
        price: '₹849',
        originalPrice: '₹1199',
        image: 'assets/images/shirts/plain_t_shirt/5.webp',
        discount: '32% OFF',
        images: [
          'assets/images/shirts/plain_t_shirt/5.webp',
          'assets/images/shirts/back/6.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Blue', 'Beige', 'Charcoal Grey', 'White', 'Black'],
        colorImages: {
          'Blue': [
            'assets/images/shirts/plain_t_shirt/5.webp',
            'assets/images/shirts/back/6.webp'
          ],
          'Beige': [
            'assets/images/shirts/plain_t_shirt/2.webp',
            'assets/images/shirts/back/3.webp'
          ],
          'Charcoal Grey': [
            'assets/images/shirts/plain_t_shirt/8.webp',
            'assets/images/shirts/back/9.webp'
          ],
          'White': [
            'assets/images/shirts/plain_t_shirt/11.webp',
            'assets/images/shirts/back/12.webp'
          ],
          'Black': [
            'assets/images/shirts/plain_t_shirt/14.webp',
            'assets/images/shirts/back/15.webp'
          ],
        },
        description: 'Casual denim shirt perfect for weekend outings.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent only.\n• Do not bleach or tumble dry.\n• Gentle machine or hand wash.\n• Iron inside out. No iron on print.',
        details: 'High-quality denim fabric. Classic fit.',
        category: 'Shirts',
      ),
    ],
    'Hoodies': [
      Product(
        id: 'hoodie_1',
        name: 'Beinn Left Logo Hoodie',
        price: '₹999',
        originalPrice: '₹1499',
        image: 'assets/images/hoodies/beinn_left/1.webp',
        discount: '35% OFF',
        images: [
          'assets/images/hoodies/beinn_left/1.webp',
          'assets/images/hoodies/back/5.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: [
          'Jordy Blue',
          'Black',
          'Purple',
          'White',
          'Beige',
          'Stone Wash',
          'Aquamarine',
          'Firefly',
          'Chocolate Brown',
          'Cinder'
        ],
        colorImages: {
          'Jordy Blue': [
            'assets/images/hoodies/beinn_left/1.webp',
            'assets/images/hoodies/back/5.webp'
          ],
          'Black': [
            'assets/images/hoodies/beinn_left/6.webp',
            'assets/images/hoodies/back/11.webp'
          ],
          'Purple': [
            'assets/images/hoodies/beinn_left/13.webp',
            'assets/images/hoodies/back/18.webp'
          ],
          'White': [
            'assets/images/hoodies/beinn_left/34.webp',
            'assets/images/hoodies/back/39.webp'
          ],
          'Beige': [
            'assets/images/hoodies/beinn_left/41.webp',
            'assets/images/hoodies/back/43.webp'
          ],
          'Stone Wash': [
            'assets/images/hoodies/beinn_left/49.webp',
            'assets/images/hoodies/back/51.webp'
          ],
          'Aquamarine': [
            'assets/images/hoodies/beinn_left/56.webp',
            'assets/images/hoodies/back/52.webp'
          ],
          'Firefly': [
            'assets/images/hoodies/beinn_left/58.webp',
            'assets/images/hoodies/back/61.webp'
          ],
          'Chocolate Brown': [
            'assets/images/hoodies/beinn_left/63.webp',
            'assets/images/hoodies/back/66.webp'
          ],
          'Cinder': [
            'assets/images/hoodies/beinn_left/68.webp',
            'assets/images/hoodies/back/71.webp'
          ],
        },
        description:
            'Comfortable sports hoodie perfect for workouts and casual wear.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent. No bleach.\n• Gentle machine or hand wash.\n• Do not tumble dry. Dry in shade.\n• Iron inside out on low heat.',
        details:
            'Moisture-wicking fabric. Machine washable. Perfect for active lifestyle.',
        category: 'Hoodies',
      ),
      Product(
        id: 'hoodie_2',
        name: 'Beinn Middle Logo Hoodie',
        price: '₹1049',
        originalPrice: '₹1499',
        image: 'assets/images/hoodies/beinn_middle/37.webp',
        discount: '30% OFF',
        images: [
          'assets/images/hoodies/beinn_middle/37.webp',
          'assets/images/hoodies/back/39.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: [
          'White',
          'Jordy Blue',
          'Black',
          'Purple',
          'Beige',
          'Stone Wash',
          'Aquamarine',
          'Firefly',
          'Chocolate Brown',
          'Cinder'
        ],
        colorImages: {
          'White': [
            'assets/images/hoodies/beinn_middle/37.webp',
            'assets/images/hoodies/back/39.webp'
          ],
          'Jordy Blue': [
            'assets/images/hoodies/beinn_middle/4.webp',
            'assets/images/hoodies/back/5.webp'
          ],
          'Black': [
            'assets/images/hoodies/beinn_middle/10.webp',
            'assets/images/hoodies/back/11.webp'
          ],
          'Purple': [
            'assets/images/hoodies/beinn_middle/17.webp',
            'assets/images/hoodies/back/18.webp'
          ],
          'Beige': [
            'assets/images/hoodies/beinn_middle/46.webp',
            'assets/images/hoodies/back/43.webp'
          ],
          'Stone Wash': [
            'assets/images/hoodies/beinn_middle/48.webp',
            'assets/images/hoodies/back/51.webp'
          ],
          'Aquamarine': [
            'assets/images/hoodies/beinn_middle/55.webp',
            'assets/images/hoodies/back/52.webp'
          ],
          'Firefly': [
            'assets/images/hoodies/beinn_middle/59.webp',
            'assets/images/hoodies/back/61.webp'
          ],
          'Chocolate Brown': [
            'assets/images/hoodies/beinn_middle/64.webp',
            'assets/images/hoodies/back/66.webp'
          ],
          'Cinder': [
            'assets/images/hoodies/beinn_middle/67.webp',
            'assets/images/hoodies/back/71.webp'
          ],
        },
        description: 'Classic pullover hoodie with kangaroo pocket.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent. No bleach.\n• Gentle machine or hand wash.\n• Do not tumble dry. Dry in shade.\n• Iron inside out on low heat.',
        details: 'Soft fleece interior. Adjustable drawstring hood.',
        category: 'Hoodies',
      ),
      Product(
        id: 'hoodie_3',
        name: 'Plain Hoodie',
        price: '₹1099',
        originalPrice: '₹1499',
        image: 'assets/images/hoodies/plain/50.webp',
        discount: '30% OFF',
        images: [
          'assets/images/hoodies/plain/50.webp',
          'assets/images/hoodies/back/51.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: [
          'Stone Wash',
          'White',
          'Jordy Blue',
          'Black',
          'Purple',
          'Beige',
          'Aquamarine',
          'Firefly',
          'Chocolate Brown',
          'Cinder'
        ],
        colorImages: {
          'Stone Wash': [
            'assets/images/hoodies/plain/50.webp',
            'assets/images/hoodies/back/51.webp'
          ],
          'White': [
            'assets/images/hoodies/plain/35.webp',
            'assets/images/hoodies/back/39.webp'
          ],
          'Jordy Blue': [
            'assets/images/hoodies/plain/3.webp',
            'assets/images/hoodies/back/5.webp'
          ],
          'Black': [
            'assets/images/hoodies/plain/7.webp',
            'assets/images/hoodies/back/11.webp'
          ],
          'Purple': [
            'assets/images/hoodies/plain/15.webp',
            'assets/images/hoodies/back/18.webp'
          ],
          'Beige': [
            'assets/images/hoodies/plain/45.webp',
            'assets/images/hoodies/back/43.webp'
          ],
          'Aquamarine': [
            'assets/images/hoodies/plain/53.webp',
            'assets/images/hoodies/back/52.webp'
          ],
          'Firefly': [
            'assets/images/hoodies/plain/60.webp',
            'assets/images/hoodies/back/61.webp'
          ],
          'Chocolate Brown': [
            'assets/images/hoodies/plain/62.webp',
            'assets/images/hoodies/back/66.webp'
          ],
          'Cinder': [
            'assets/images/hoodies/plain/70.webp',
            'assets/images/hoodies/back/71.webp'
          ],
        },
        description: 'Classic pullover hoodie with kangaroo pocket.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent. No bleach.\n• Gentle machine or hand wash.\n• Do not tumble dry. Dry in shade.\n• Iron inside out on low heat.',
        details: 'Soft fleece interior. Adjustable drawstring hood.',
        category: 'Hoodies',
      ),
      Product(
        id: 'hoodie_4',
        name: 'Whatever Hoodie',
        price: '₹1599',
        originalPrice: '₹2299',
        image: 'assets/images/hoodies/whatever/14.webp',
        discount: '30% OFF',
        images: [
          'assets/images/hoodies/whatever/14.webp',
          'assets/images/hoodies/back/18.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: [
          'Purple',
          'White',
          'Jordy Blue',
          'Black',
          'Beige',
          'Stone Wash',
          'Aquamarine',
          'Firefly',
          'Chocolate Brown',
          'Cinder'
        ],
        colorImages: {
          'Purple': [
            'assets/images/hoodies/whatever/14.webp',
            'assets/images/hoodies/back/18.webp'
          ],
          'White': [
            'assets/images/hoodies/whatever/36.webp',
            'assets/images/hoodies/back/39.webp'
          ],
          'Jordy Blue': [
            'assets/images/hoodies/whatever/4.webp',
            'assets/images/hoodies/back/5.webp'
          ],
          'Black': [
            'assets/images/hoodies/whatever/8.webp',
            'assets/images/hoodies/back/11.webp'
          ],
          'Beige': [
            'assets/images/hoodies/whatever/44.webp',
            'assets/images/hoodies/back/43.webp'
          ],
          'Stone Wash': [
            'assets/images/hoodies/whatever/47.webp',
            'assets/images/hoodies/back/51.webp'
          ],
          'Aquamarine': [
            'assets/images/hoodies/whatever/54.webp',
            'assets/images/hoodies/back/52.webp'
          ],
          'Firefly': [
            'assets/images/hoodies/whatever/57.webp',
            'assets/images/hoodies/back/61.webp'
          ],
          'Chocolate Brown': [
            'assets/images/hoodies/whatever/25.webp',
            'assets/images/hoodies/back/66.webp'
          ],
          'Cinder': [
            'assets/images/hoodies/whatever/69.webp',
            'assets/images/hoodies/back/71.webp'
          ],
        },
        description: 'Classic pullover hoodie with kangaroo pocket.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent. No bleach.\n• Gentle machine or hand wash.\n• Do not tumble dry. Dry in shade.\n• Iron inside out on low heat.',
        details: 'Soft fleece interior. Adjustable drawstring hood.',
        category: 'Hoodies',
      ),
    ],
    'Sweatshirts': [
      Product(
        id: 'sweatshirt_1',
        name: 'Beinn Left Logo Sweatshirt',
        price: '₹999',
        originalPrice: '₹1499',
        image: 'assets/images/sweatshirts/beinn_left/4.webp',
        discount: '33% OFF',
        images: [
          'assets/images/sweatshirts/beinn_left/4.webp',
          'assets/images/sweatshirts/back/7.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['White', 'Sky Blue', 'Black', 'Dark Green', 'Cinder'],
        colorImages: {
          'White': [
            'assets/images/sweatshirts/beinn_left/4.webp',
            'assets/images/sweatshirts/back/7.webp'
          ],
          'Sky Blue': [
            'assets/images/sweatshirts/beinn_left/9.webp',
            'assets/images/sweatshirts/back/12.webp'
          ],
          'Black': [
            'assets/images/sweatshirts/beinn_left/13.webp',
            'assets/images/sweatshirts/back/18.webp'
          ],
          'Dark Green': [
            'assets/images/sweatshirts/beinn_left/22.webp',
            'assets/images/sweatshirts/back/23.webp'
          ],
          'Cinder': [
            'assets/images/sweatshirts/beinn_left/25.webp',
            'assets/images/sweatshirts/back/28.webp'
          ],
        },
        description:
            'Comfortable crew neck sweatshirt perfect for casual wear.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent. No bleach.\n• Gentle machine or hand wash.\n• Do not tumble dry. Dry in shade.\n• Iron inside out. No iron on print.',
        details: 'Soft fleece interior. Ribbed cuffs and hem.',
        category: 'Sweatshirts',
      ),
      Product(
        id: 'sweatshirt_2',
        name: 'Beinn Middle Logo Sweatshirt',
        price: '₹999',
        originalPrice: '₹1499',
        image: 'assets/images/sweatshirts/beinn_middle/16.webp',
        discount: '33% OFF',
        images: [
          'assets/images/sweatshirts/beinn_middle/16.webp',
          'assets/images/sweatshirts/back/18.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Black', 'White', 'Sky Blue', 'Dark Green', 'Cinder'],
        colorImages: {
          'Black': [
            'assets/images/sweatshirts/beinn_middle/16.webp',
            'assets/images/sweatshirts/back/18.webp'
          ],
          'White': [
            'assets/images/sweatshirts/beinn_middle/2.webp',
            'assets/images/sweatshirts/back/7.webp'
          ],
          'Sky Blue': [
            'assets/images/sweatshirts/beinn_middle/11.webp',
            'assets/images/sweatshirts/back/12.webp'
          ],
          'Dark Green': [
            'assets/images/sweatshirts/beinn_middle/19.webp',
            'assets/images/sweatshirts/back/23.webp'
          ],
          'Cinder': [
            'assets/images/sweatshirts/beinn_middle/24.webp',
            'assets/images/sweatshirts/back/28.webp'
          ],
        },
        description:
            'Comfortable crew neck sweatshirt perfect for casual wear.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent. No bleach.\n• Gentle machine or hand wash.\n• Do not tumble dry. Dry in shade.\n• Iron inside out. No iron on print.',
        details: 'Soft fleece interior. Ribbed cuffs and hem.',
        category: 'Sweatshirts',
      ),
      Product(
        id: 'sweatshirt_3',
        name: 'Offline Sweatshirt',
        price: '₹999',
        originalPrice: '₹1499',
        image: 'assets/images/sweatshirts/offline/27.webp',
        discount: '33% OFF',
        images: [
          'assets/images/sweatshirts/offline/27.webp',
          'assets/images/sweatshirts/back/28.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Cinder', 'Black', 'White', 'Sky Blue', 'Dark Green'],
        colorImages: {
          'Cinder': [
            'assets/images/sweatshirts/offline/27.webp',
            'assets/images/sweatshirts/back/28.webp'
          ],
          'Black': [
            'assets/images/sweatshirts/offline/14.webp',
            'assets/images/sweatshirts/back/18.webp'
          ],
          'White': [
            'assets/images/sweatshirts/offline/5.webp',
            'assets/images/sweatshirts/back/7.webp'
          ],
          'Sky Blue': [
            'assets/images/sweatshirts/offline/10.webp',
            'assets/images/sweatshirts/back/12.webp'
          ],
          'Dark Green': [
            'assets/images/sweatshirts/offline/20.webp',
            'assets/images/sweatshirts/back/23.webp'
          ],
        },
        description:
            'Comfortable crew neck sweatshirt perfect for casual wear.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent. No bleach.\n• Gentle machine or hand wash.\n• Do not tumble dry. Dry in shade.\n• Iron inside out. No iron on print.',
        details: 'Soft fleece interior. Ribbed cuffs and hem.',
        category: 'Sweatshirts',
      ),
      Product(
        id: 'sweatshirt_4',
        name: 'Plain Sweatshirt',
        price: '₹1199',
        originalPrice: '₹1799',
        image: 'assets/images/sweatshirts/plain/26.webp',
        discount: '33% OFF',
        images: [
          'assets/images/sweatshirts/plain/26.webp',
          'assets/images/sweatshirts/back/12.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Sky Blue', 'Cinder', 'Black', 'White', 'Dark Green'],
        colorImages: {
          'Sky Blue': [
            'assets/images/sweatshirts/plain/26.webp',
            'assets/images/sweatshirts/back/12.webp'
          ],
          'Cinder': [
            'assets/images/sweatshirts/plain/26.webp',
            'assets/images/sweatshirts/back/28.webp'
          ],
          'Black': [
            'assets/images/sweatshirts/plain/17.webp',
            'assets/images/sweatshirts/back/18.webp'
          ],
          'White': [
            'assets/images/sweatshirts/plain/3.webp',
            'assets/images/sweatshirts/back/7.webp'
          ],
          'Dark Green': [
            'assets/images/sweatshirts/plain/21.webp',
            'assets/images/sweatshirts/back/23.webp'
          ],
        },
        description:
            'Comfortable crew neck sweatshirt perfect for casual wear.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent. No bleach.\n• Gentle machine or hand wash.\n• Do not tumble dry. Dry in shade.\n• Iron inside out. No iron on print.',
        details: 'Soft fleece interior. Ribbed cuffs and hem.',
        category: 'Sweatshirts',
      ),
    ],
    'Tank Tops': [
      Product(
        id: 'tank_1',
        name: "Men's Beinn Oversized Tank Top",
        price: '₹649',
        originalPrice: '₹999',
        image: 'assets/images/tank_tops/beinn_left/3.webp',
        discount: '33% OFF',
        images: [
          'assets/images/tank_tops/beinn_left/3.webp',
          'assets/images/tank_tops/back/6.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Beige', 'Pearl Blue', 'White', 'Black', 'Maroon', 'Grey'],
        colorImages: {
          'Beige': [
            'assets/images/tank_tops/beinn_left/3.webp',
            'assets/images/tank_tops/back/6.webp',
          ],
          'Pearl Blue': [
            'assets/images/tank_tops/beinn_left/9.webp',
            'assets/images/tank_tops/back/11.webp',
          ],
          'White': [
            'assets/images/tank_tops/beinn_left/41.webp',
            'assets/images/tank_tops/back/17.webp',
          ],
          'Black': [
            'assets/images/tank_tops/beinn_left/19.webp',
            'assets/images/tank_tops/back/21.webp',
          ],
          'Maroon': [
            'assets/images/tank_tops/beinn_left/24.webp',
            'assets/images/tank_tops/back/26.webp',
          ],
          'Grey': [
            'assets/images/tank_tops/beinn_left/27.webp',
            'assets/images/tank_tops/back/30.webp',
          ],
        },
        description: 'Comfortable tank top perfect for gym and casual wear.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent. No bleach.\n• Gentle machine or hand wash.\n• Do not tumble dry. Dry in shade.\n• Iron inside out. No iron on print.',
        details: 'Breathable cotton blend. Moisture-wicking. Athletic fit.',
        category: 'Tank Tops',
      ),
      Product(
        id: 'tank_2',
        name: "Men's Beinn Oversized Tank Top",
        price: '₹749',
        originalPrice: '₹999',
        image: 'assets/images/tank_tops/beinn_middle/23.webp',
        discount: '33% OFF',
        images: [
          'assets/images/tank_tops/beinn_middle/23.webp',
          'assets/images/tank_tops/back/26.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Maroon', 'Beige', 'Pearl Blue', 'White', 'Black', 'Grey'],
        colorImages: {
          'Maroon': [
            'assets/images/tank_tops/beinn_middle/23.webp',
            'assets/images/tank_tops/back/26.webp',
          ],
          'Beige': [
            'assets/images/tank_tops/beinn_middle/1.webp',
            'assets/images/tank_tops/back/6.webp',
          ],
          'Pearl Blue': [
            'assets/images/tank_tops/beinn_middle/7.webp',
            'assets/images/tank_tops/back/11.webp',
          ],
          'White': [
            'assets/images/tank_tops/beinn_middle/14.webp',
            'assets/images/tank_tops/back/17.webp',
          ],
          'Black': [
            'assets/images/tank_tops/beinn_middle/18.webp',
            'assets/images/tank_tops/back/21.webp',
          ],
          'Grey': [
            'assets/images/tank_tops/beinn_middle/28.webp',
            'assets/images/tank_tops/back/30.webp',
          ],
        },
        description: 'Comfortable tank top perfect for gym and casual wear.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent. No bleach.\n• Gentle machine or hand wash.\n• Do not tumble dry. Dry in shade.\n• Iron inside out. No iron on print.',
        details: 'Breathable cotton blend. Moisture-wicking. Athletic fit.',
        category: 'Tank Tops',
      ),
      Product(
        id: 'tank_3',
        name: "Men's Real is Rare Oversized Tank Top",
        price: '₹749',
        originalPrice: '₹999',
        image: 'assets/images/tank_tops/designs/42.webp',
        discount: '33% OFF',
        images: [
          'assets/images/tank_tops/designs/42.webp',
          'assets/images/tank_tops/back/30.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Grey', 'Maroon', 'Beige', 'Pearl Blue', 'White', 'Black'],
        colorImages: {
          'Grey': [
            'assets/images/tank_tops/designs/42.webp',
            'assets/images/tank_tops/back/30.webp',
          ],
          'Maroon': [
            'assets/images/tank_tops/designs/43.webp',
            'assets/images/tank_tops/back/26.webp',
          ],
          'Beige': [
            'assets/images/tank_tops/designs/4.webp',
            'assets/images/tank_tops/back/6.webp',
          ],
          'Pearl Blue': [
            'assets/images/tank_tops/designs/45.webp',
            'assets/images/tank_tops/back/11.webp',
          ],
          'White': [
            'assets/images/tank_tops/designs/46.webp',
            'assets/images/tank_tops/back/17.webp',
          ],
          'Black': [
            'assets/images/tank_tops/designs/44.webp',
            'assets/images/tank_tops/back/21.webp',
          ],
        },
        description: 'Comfortable tank top perfect for gym and casual wear.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent. No bleach.\n• Gentle machine or hand wash.\n• Do not tumble dry. Dry in shade.\n• Iron inside out. No iron on print.',
        details: 'Breathable cotton blend. Moisture-wicking. Athletic fit.',
        category: 'Tank Tops',
      ),
      Product(
        id: 'tank_4',
        name: "Men's Plain Oversized Tank Top",
        price: '₹749',
        originalPrice: '₹999',
        image: 'assets/images/tank_tops/plain/13.webp',
        discount: '33% OFF',
        images: [
          'assets/images/tank_tops/plain/13.webp',
          'assets/images/tank_tops/back/17.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['White', 'Maroon', 'Beige', 'Pearl Blue', 'Black', 'Grey'],
        colorImages: {
          'White': [
            'assets/images/tank_tops/plain/13.webp',
            'assets/images/tank_tops/back/17.webp',
          ],
          'Maroon': [
            'assets/images/tank_tops/plain/25.webp',
            'assets/images/tank_tops/back/26.webp',
          ],
          // 'Beige': [
          // 'assets/images/tank_tops/plain/1.webp',
          // 'assets/images/tank_tops/back/6.webp',
          // ],
          'Pearl Blue': [
            'assets/images/tank_tops/plain/8.webp',
            'assets/images/tank_tops/back/11.webp',
          ],
          'Black': [
            'assets/images/tank_tops/plain/20.webp',
            'assets/images/tank_tops/back/21.webp',
          ],
          'Grey': [
            'assets/images/tank_tops/plain/29.webp',
            'assets/images/tank_tops/back/30.webp',
          ],
        },
        description: 'Comfortable tank top perfect for gym and casual wear.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent. No bleach.\n• Gentle machine or hand wash.\n• Do not tumble dry. Dry in shade.\n• Iron inside out. No iron on print.',
        details: 'Breathable cotton blend. Moisture-wicking. Athletic fit.',
        category: 'Tank Tops',
      ),
      Product(
        id: 'tank_5',
        name: "Men's Skeleton Oversized Tank Top",
        price: '₹749',
        originalPrice: '₹999',
        image: 'assets/images/tank_tops/designs/22.webp',
        discount: '33% OFF',
        images: [
          'assets/images/tank_tops/designs/22.webp',
          'assets/images/tank_tops/back/21.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Black', 'Grey', 'Maroon', 'Off White', 'Pearl Blue', 'White'],
        colorImages: {
          'Black': [
            'assets/images/tank_tops/designs/22.webp',
            'assets/images/tank_tops/back/21.webp',
          ],
          'Grey': [
            'assets/images/tank_tops/designs/47.webp',
            'assets/images/tank_tops/back/30.webp',
          ],
          'Maroon': [
            'assets/images/tank_tops/designs/48.webp',
            'assets/images/tank_tops/back/26.webp',
          ],
          'Off White': [
            'assets/images/tank_tops/designs/5.webp',
            'assets/images/tank_tops/back/6.webp',
          ],
          'Pearl Blue': [
            'assets/images/tank_tops/designs/10.webp',
            'assets/images/tank_tops/back/11.webp',
          ],
          'White': [
            'assets/images/tank_tops/designs/15.webp',
            'assets/images/tank_tops/back/17.webp',
          ],
        },
        description: 'Comfortable tank top perfect for gym and casual wear.',
        washCare:
            '• Wash inside out in cold water.\n• Use mild detergent. No bleach.\n• Gentle machine or hand wash.\n• Do not tumble dry. Dry in shade.\n• Iron inside out. No iron on print.',
        details: 'Breathable cotton blend. Moisture-wicking. Athletic fit.',
        category: 'Tank Tops',
      ),
    ],
    'Zipper Hoodies': [
      Product(
        id: 'zipper_hoodie_1',
        name: 'Essential Zipper Hoodie (Black)',
        price: '₹1049',
        originalPrice: '₹1499',
        image: 'assets/images/zipper_hoodies/black/2.webp',
        discount: '25% OFF',
        images: [
          'assets/images/zipper_hoodies/black/2.webp',
          'assets/images/zipper_hoodies/black/1.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Black'],
        colorImages: {
          'Black': [
            'assets/images/zipper_hoodies/black/2.webp',
            'assets/images/zipper_hoodies/black/1.webp'
          ],
        },
        description: 'Premium quality zipper hoodie for everyday comfort.',
        washCare:
            '• Wash inside out.\n• Machine wash cold.\n• Do not bleach.\n• Tumble dry low.',
        details: 'Soft fleece fabric. Full zip closure. Two front pockets.',
        category: 'Zipper Hoodies',
      ),
      Product(
        id: 'zipper_hoodie_2',
        name: 'Essential Zipper Hoodie (White)',
        price: '₹1049',
        originalPrice: '₹1499',
        image: 'assets/images/zipper_hoodies/white/3.webp',
        discount: '25% OFF',
        images: [
          'assets/images/zipper_hoodies/white/3.webp',
          'assets/images/zipper_hoodies/white/4.webp',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['White'],
        colorImages: {
          'White': [
            'assets/images/zipper_hoodies/white/3.webp',
            'assets/images/zipper_hoodies/white/4.webp'
          ],
        },
        description: 'Premium quality zipper hoodie for everyday comfort.',
        washCare:
            '• Wash inside out.\n• Machine wash cold.\n• Do not bleach.\n• Tumble dry low.',
        details: 'Soft fleece fabric. Full zip closure. Two front pockets.',
        category: 'Zipper Hoodies',
      ),
    ],
    'Perfumes': [
      Product(
        id: 'perfume_dark_desire',
        name: 'Dark Desire',
        price: '₹599',
        originalPrice: '₹999',
        image: 'assets/images/perfume/dark_desire/55.webp',
        discount: '40% OFF',
        images: [
          'assets/images/perfume/dark_desire/55.webp',
          'assets/images/perfume/dark_desire/53.webp',
          'assets/images/perfume/dark_desire/52.webp',
          'assets/images/perfume/dark_desire/51.webp',
        ],
        sizes: [],
        variantLabel: 'Types',
        colors: ['50 ML', '20 ML'],
        colorImages: {
          '50 ML': [
            'assets/images/perfume/dark_desire/55.webp',
            'assets/images/perfume/dark_desire/53.webp',
            'assets/images/perfume/dark_desire/52.webp',
            'assets/images/perfume/dark_desire/51.webp',
          ],
          '20 ML': [
            'assets/images/perfume/dark_desire/56.webp',
            'assets/images/perfume/dark_desire/57.webp',
            'assets/images/perfume/dark_desire/52.webp',
            'assets/images/perfume/dark_desire/51.webp'
          ],
        },
        description:
            'A mysterious blend of deep and enchanting notes, Dark Desire is crafted for the night. Designed for bold personalities, this intoxicating perfume wraps you in a sensual aura that commands attention. Its luxurious base notes linger on the skin, leaving a lasting impression wherever you go.',
        washCare: '',
        details: 'Premium fragrance formulation.',
        category: 'Perfumes',
      ),
      Product(
        id: 'perfume_oud_love',
        name: 'Oud Love',
        price: '₹599',
        originalPrice: '₹999',
        image: 'assets/images/perfume/oud_Love/6.webp',
        discount: '40% OFF',
        images: [
          'assets/images/perfume/oud_Love/6.webp',
          'assets/images/perfume/oud_Love/7.webp',
          'assets/images/perfume/oud_Love/8.webp',
          'assets/images/perfume/oud_Love/2.webp',
          'assets/images/perfume/oud_Love/1.webp',
        ],
        sizes: [],
        variantLabel: 'Types',
        colors: ['50 ML', '20 ML'],
        colorImages: {
          '50 ML': [
            'assets/images/perfume/oud_Love/6.webp',
            'assets/images/perfume/oud_Love/7.webp',
            'assets/images/perfume/oud_Love/8.webp',
            'assets/images/perfume/oud_Love/2.webp',
            'assets/images/perfume/oud_Love/1.webp',
          ],
          '20 ML': [
            'assets/images/perfume/oud_Love/5.webp',
            'assets/images/perfume/oud_Love/4.webp',
            'assets/images/perfume/oud_Love/3.webp',
            'assets/images/perfume/oud_Love/2.webp',
            'assets/images/perfume/oud_Love/1.webp',
          ],
        },
        description:
            'A rich, woody, and classic oriental fragrance. Oud Love elegantly offers intense depth and warmth, creating a regal and timeless signature scent. The luxurious essence of pure oud is harmoniously blended with spicy and resinous accords for a majestic sensory experience.',
        washCare: '',
        details: 'Premium fragrance formulation.',
        category: 'Perfumes',
      ),
      Product(
        id: 'perfume_gorgeous',
        name: 'Gorgeous',
        price: '₹599',
        originalPrice: '₹999',
        image: 'assets/images/perfume/gorgeous/42.webp',
        discount: '40% OFF',
        images: [
          'assets/images/perfume/gorgeous/42.webp',
          'assets/images/perfume/gorgeous/40.webp',
          'assets/images/perfume/gorgeous/41.webp',
          'assets/images/perfume/gorgeous/39.webp',
          'assets/images/perfume/gorgeous/38.webp',
        ],
        sizes: [],
        variantLabel: 'Types',
        colors: [],
        colorImages: {},
        description:
            'A beautifully elegant and luminous fragrance. Gorgeous makes you feel confident and poised, beautifully elevating any occasion. With an exquisite heart of fresh florals resting on a soft, sophisticated base, this luxurious scent unveils a radiant and universally flattering signature profile.',
        washCare: '',
        details: 'Premium fragrance formulation.',
        category: 'Perfumes',
      ),
      Product(
        id: 'perfume_moonrise',
        name: 'Moonrise',
        price: '₹599',
        originalPrice: '₹999',
        image: 'assets/images/perfume/moonrise/21.webp',
        discount: '40% OFF',
        images: [
          'assets/images/perfume/moonrise/21.webp',
          'assets/images/perfume/moonrise/20.webp',
          'assets/images/perfume/moonrise/19.webp',
          'assets/images/perfume/moonrise/18.webp',
          'assets/images/perfume/moonrise/17.webp',
        ],
        sizes: [],
        variantLabel: 'Types',
        colors: ['50 ML', '20 ML'],
        colorImages: {
          '50 ML': [
            'assets/images/perfume/moonrise/21.webp',
            'assets/images/perfume/moonrise/20.webp',
            'assets/images/perfume/moonrise/19.webp',
            'assets/images/perfume/moonrise/18.webp',
            'assets/images/perfume/moonrise/17.webp',
          ],
          '20 ML': [
            'assets/images/perfume/moonrise/24.webp',
            'assets/images/perfume/moonrise/23.webp',
            'assets/images/perfume/moonrise/22.webp',
            'assets/images/perfume/moonrise/18.webp',
            'assets/images/perfume/moonrise/17.webp',
          ],
        },
        description:
            'An adventurous and fresh olfactory journey. Moonrise brings an exhilarating splash of night-blooming nuances, perfect for explorers of the night. With its crisp opening and mesmerizing depths, it captures the mystery and excitement of a midnight adventure under the stars.',
        washCare: '',
        details: 'Premium fragrance formulation.',
        category: 'Perfumes',
      ),
      Product(
        id: 'perfume_love_story',
        name: 'Love Story',
        price: '₹599',
        originalPrice: '₹999',
        image: 'assets/images/perfume/love_story/45.webp',
        discount: '40% OFF',
        images: [
          'assets/images/perfume/love_story/45.webp',
          'assets/images/perfume/love_story/46.webp',
          'assets/images/perfume/love_story/47.webp',
          'assets/images/perfume/love_story/44.webp',
          'assets/images/perfume/love_story/43.webp',
        ],
        sizes: [],
        variantLabel: 'Types',
        colors: ['50 ML', '20 ML'],
        colorImages: {
          '50 ML': [
            'assets/images/perfume/love_story/45.webp',
            'assets/images/perfume/love_story/46.webp',
            'assets/images/perfume/love_story/47.webp',
            'assets/images/perfume/love_story/44.webp',
            'assets/images/perfume/love_story/43.webp',
          ],
          '20 ML': [
            'assets/images/perfume/love_story/48.webp',
            'assets/images/perfume/love_story/49.webp',
            'assets/images/perfume/love_story/50.webp',
            'assets/images/perfume/love_story/44.webp',
            'assets/images/perfume/love_story/43.webp',
          ],
        },
        description:
            'A romantic and heartfelt scent. Love Story gently weaves delicate notes together to create a charming, unforgettable fragrance. Evoking the profound emotions of intimate moments and cherished memories, it gracefully lingers with a gentle, sweet softness that warms the soul.',
        washCare: '',
        details: 'Premium fragrance formulation.',
        category: 'Perfumes',
      ),
      Product(
        id: 'perfume_fetish',
        name: 'Fetish',
        price: '₹599',
        originalPrice: '₹999',
        image: 'assets/images/perfume/fetish/13.webp',
        discount: '40% OFF',
        images: [
          'assets/images/perfume/fetish/13.webp',
          'assets/images/perfume/fetish/12.webp',
          'assets/images/perfume/fetish/11.webp',
          'assets/images/perfume/fetish/10.webp',
          'assets/images/perfume/fetish/9.webp',
        ],
        sizes: [],
        variantLabel: 'Types',
        colors: ['50 ML', '20 ML'],
        colorImages: {
          '50 ML': [
            'assets/images/perfume/fetish/13.webp',
            'assets/images/perfume/fetish/12.webp',
            'assets/images/perfume/fetish/11.webp',
            'assets/images/perfume/fetish/10.webp',
            'assets/images/perfume/fetish/9.webp',
          ],
          '20 ML': [
            'assets/images/perfume/fetish/16.webp',
            'assets/images/perfume/fetish/15.webp',
            'assets/images/perfume/fetish/14.webp',
            'assets/images/perfume/fetish/10.webp',
            'assets/images/perfume/fetish/9.webp',
          ],
        },
        description:
            'An addictive and captivating fragrance. Fetish is a daring statement perfume that wraps you in a spellbinding and irresistible scent trail all day. Its perfectly balanced composition of provocative top notes and a warm, inviting dry down makes it the ultimate choice for those who dare to stand out.',
        washCare: '',
        details: 'Premium fragrance formulation.',
        category: 'Perfumes',
      ),
      Product(
        id: 'perfume_sugar_sin',
        name: 'Sugar Sin',
        price: '₹599',
        originalPrice: '₹999',
        image: 'assets/images/perfume/sugar_sin/37.webp',
        discount: '40% OFF',
        images: [
          'assets/images/perfume/sugar_sin/37.webp',
          'assets/images/perfume/sugar_sin/35.webp',
          'assets/images/perfume/sugar_sin/36.webp',
          'assets/images/perfume/sugar_sin/34.webp',
          'assets/images/perfume/sugar_sin/33.webp',
        ],
        sizes: [],
        variantLabel: 'Types',
        colors: [],
        colorImages: {},
        description:
            'A playful, sweet, and intoxicating gourmand delight. Sugar Sin brings a delicious and tempting aura that is playfully wicked, yet impossible to resist. Mouth-watering accords of spun sugar and rich vanilla mingle together to satisfy even your most decadent cravings.',
        washCare: '',
        details: 'Premium fragrance formulation.',
        category: 'Perfumes',
      ),
      Product(
        id: 'perfume_wildest_dreams',
        name: 'Wildest Dreams',
        price: '₹599',
        originalPrice: '₹999',
        image: 'assets/images/perfume/wildest_dreams/92.webp',
        discount: '40% OFF',
        images: [
          'assets/images/perfume/wildest_dreams/92.webp',
          'assets/images/perfume/wildest_dreams/93.webp',
          'assets/images/perfume/wildest_dreams/91.webp',
          'assets/images/perfume/wildest_dreams/95.webp',
        ],
        sizes: [],
        variantLabel: 'Types',
        colors: ['50 ML', '20 ML'],
        colorImages: {
          '50 ML': [
            'assets/images/perfume/wildest_dreams/92.webp',
            'assets/images/perfume/wildest_dreams/93.webp',
            'assets/images/perfume/wildest_dreams/91.webp',
            'assets/images/perfume/wildest_dreams/95.webp',
          ],
          '20 ML': [
            'assets/images/perfume/wildest_dreams/90.webp',
            'assets/images/perfume/wildest_dreams/96.webp',
            'assets/images/perfume/wildest_dreams/91.webp',
            'assets/images/perfume/wildest_dreams/95.webp',
          ],
        },
        description:
            'A vibrant, exciting, and untamed fragrance. Wildest Dreams captures the very essence of freedom and passion, sparking the imagination with every spritz. Let this energetic and fiercely unique composition inspire you to break boundaries and pursue the impossible.',
        washCare: '',
        details: 'Premium fragrance formulation.',
        category: 'Perfumes',
      )
    ],
  };

  static List<Product> getProductsByCategory(String categoryName) {
    return _productsByCategory[categoryName] ?? [];
  }

  static List<Product> getAllProducts() {
    List<Product> allProducts = [];
    for (var products in _productsByCategory.values) {
      allProducts.addAll(products);
    }
    return allProducts;
  }

  static Product? getProductById(String id) {
    for (var products in _productsByCategory.values) {
      try {
        return products.firstWhere((product) => product.id == id);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  static List<String> getAvailableCategories() {
    return _productsByCategory.keys.toList();
  }
}
