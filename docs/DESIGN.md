# Design System & Principles

Beinn's design language focuses on a premium, fluid, and immersive e-commerce experience.

## Core Principles

1. **Fluidity Over Static:** Every state change should have a transition. We heavily utilize Flutter's `Hero` animations for product routing and `AnimatedSwitcher` for state changes.
2. **Dark Mode First:** The application defaults to a sleek dark mode utilizing deep blacks and subtle neon accents, enhancing the visual pop of fashion photography.
3. **Typography:** We use **Inter** for clean, legible UI elements and **Playfair Display** for premium editorial headings.

## UI Architecture (Flutter)

### Components
All reusable UI elements reside in `lib/widgets/`. These are purely presentational widgets that do not hold business logic.
- `BeinnPrimaryButton`: Used for main calls to action (Checkout, Accept Order).
- `ProductCard`: A glassmorphism-styled card displaying product imagery, price, and instant stock indicators.

### Animation Layer
We utilize Lottie files for complex onboarding and empty-state animations. Native explicit animations (`AnimationController`) are reserved for interactive elements like the drag-to-confirm checkout slider.

### Map Styling
The `flutter_map` implementation uses a custom dark-themed Mapbox/OSM tile layer to seamlessly integrate with the app's dark aesthetic, hiding unnecessary POIs and emphasizing the delivery route geometry.
