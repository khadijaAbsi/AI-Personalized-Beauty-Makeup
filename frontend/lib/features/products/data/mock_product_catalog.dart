import 'package:flutter/material.dart';

import '../models/product.dart';

/// Mock product source for the Explore screen.
///
/// This is catalog data only. It is never written to a user's Favorites; a
/// product reaches Favorites only when the user taps its heart.
///
/// The first eight products keep the exact brand and name they had in the old
/// Recommended Products list, so favorites users already saved still match.
/// Every brand + name pair must be unique (that pair is the favorites key); a
/// test enforces it. Brands are fictional. Photos are optional: with no
/// `imageUrl` a tinted placeholder is shown.
const List<Product> mockProductCatalog = [
  Product(
    id: 'glow-soft-matte-lipstick',
    name: 'Soft Matte Lipstick',
    brand: 'Glow Beauty',
    category: 'Lips',
    shade: 'Rosewood',
    price: 24.99,
    description:
        'A creamy, comfortable lipstick with a beautiful matte finish for an '
        'elegant look.',
    color: Color(0xFFD9909C),
    icon: Icons.brush,
  ),
  Product(
    id: 'blush-rose-blush',
    name: 'Rose Blush',
    brand: 'Blush Studio',
    category: 'Cheeks',
    shade: 'Petal Rose',
    price: 18.50,
    description:
        'A soft rose blush that adds a natural flush and a fresh glow to your '
        'cheeks.',
    color: Color(0xFFF0A9A8),
    icon: Icons.circle,
  ),
  Product(
    id: 'glow-luminous-foundation',
    name: 'Luminous Foundation',
    brand: 'Glow Beauty',
    category: 'Face',
    shade: 'Warm Beige',
    price: 32.00,
    description:
        'A lightweight foundation designed to create a smooth, '
        'radiant-looking complexion.',
    color: Color(0xFFE2BE9F),
    icon: Icons.face_retouching_natural,
  ),
  Product(
    id: 'lash-volume-mascara',
    name: 'Volume Mascara',
    brand: 'Lash & Co.',
    category: 'Eyes',
    shade: 'Soft Black',
    price: 21.99,
    description:
        'A defining mascara that gives lashes a fuller and more dramatic '
        'appearance.',
    color: Color(0xFF8E8296),
    icon: Icons.remove_red_eye_outlined,
  ),
  Product(
    id: 'blush-nude-lip-gloss',
    name: 'Nude Lip Gloss',
    brand: 'Blush Studio',
    category: 'Lips',
    shade: 'Honey Nude',
    price: 16.99,
    description:
        'A glossy nude lip finish that gives your lips a soft, luminous '
        'appearance.',
    color: Color(0xFFE3B6A3),
    icon: Icons.water_drop_outlined,
  ),
  Product(
    id: 'velvet-eyeshadow-palette',
    name: 'Eyeshadow Palette',
    brand: 'Velvet Touch',
    category: 'Eyes',
    shade: 'Mauve Neutrals',
    price: 39.99,
    description:
        'A versatile palette of wearable shades for everyday makeup and '
        'special occasions.',
    color: Color(0xFFC4A2B0),
    icon: Icons.palette_outlined,
  ),
  Product(
    id: 'glow-setting-powder',
    name: 'Setting Powder',
    brand: 'Glow Beauty',
    category: 'Face',
    shade: 'Translucent',
    price: 22.50,
    description:
        'A lightweight finishing powder to help your makeup look smooth and '
        'polished.',
    color: Color(0xFFE9DCCB),
    icon: Icons.blur_on,
  ),
  Product(
    id: 'lash-brow-definer',
    name: 'Brow Definer',
    brand: 'Lash & Co.',
    category: 'Eyes',
    shade: 'Taupe',
    price: 14.99,
    description:
        'A precise brow product for defining and shaping your brows with a '
        'natural finish.',
    color: Color(0xFFB59C8E),
    icon: Icons.edit_outlined,
  ),
  Product(
    id: 'velvet-lip-stain',
    name: 'Velvet Tint Lip Stain',
    brand: 'Velvet Touch',
    category: 'Lips',
    shade: 'Berry Crush',
    price: 17.50,
    description:
        'A weightless liquid stain that dries to a soft, velvety finish with '
        'lasting colour.',
    color: Color(0xFFB24A63),
    icon: Icons.water_drop,
  ),
  Product(
    id: 'glow-satin-lip-liner',
    name: 'Satin Lip Liner',
    brand: 'Glow Beauty',
    category: 'Lips',
    shade: 'Soft Mauve',
    price: 13.00,
    description:
        'A smooth, long-wearing liner that shapes and defines lips without '
        'feathering.',
    color: Color(0xFFB98393),
    icon: Icons.edit,
  ),
  Product(
    id: 'blush-peach-glow-blush',
    name: 'Peach Glow Blush',
    brand: 'Blush Studio',
    category: 'Cheeks',
    shade: 'Peach Nectar',
    price: 19.00,
    description:
        'A silky powder blush with a sheer peach tone for a sun-warmed '
        'complexion.',
    color: Color(0xFFF2B79B),
    icon: Icons.circle_outlined,
  ),
  Product(
    id: 'velvet-silk-bronzer',
    name: 'Silk Bronzer',
    brand: 'Velvet Touch',
    category: 'Cheeks',
    shade: 'Warm Sand',
    price: 26.00,
    description:
        'A finely milled bronzer that adds soft warmth and dimension without '
        'looking heavy.',
    color: Color(0xFFC99566),
    icon: Icons.wb_sunny_outlined,
  ),
  Product(
    id: 'glow-pearl-highlighter',
    name: 'Pearl Highlighter',
    brand: 'Glow Beauty',
    category: 'Cheeks',
    shade: 'Champagne Pearl',
    price: 23.50,
    description:
        'A buildable highlighter with a fine pearl sheen for a lit-from-within '
        'glow.',
    color: Color(0xFFF1DCC0),
    icon: Icons.auto_awesome,
  ),
  Product(
    id: 'glow-skin-tint',
    name: 'Skin Tint SPF 30',
    brand: 'Glow Beauty',
    category: 'Face',
    shade: 'Medium Neutral',
    price: 28.00,
    description:
        'A breathable, sheer tint with SPF 30 that evens tone and leaves skin '
        'looking fresh.',
    color: Color(0xFFDDB391),
    icon: Icons.face_retouching_natural,
  ),
  Product(
    id: 'blush-cream-concealer',
    name: 'Cream Concealer',
    brand: 'Blush Studio',
    category: 'Face',
    shade: 'Light Warm',
    price: 17.99,
    description:
        'A creamy, blendable concealer that covers shadows and blemishes '
        'without creasing.',
    color: Color(0xFFEBCDB5),
    icon: Icons.brush_outlined,
  ),
  Product(
    id: 'lash-gel-eyeliner',
    name: 'Gel Eyeliner',
    brand: 'Lash & Co.',
    category: 'Eyes',
    shade: 'Deep Plum',
    price: 15.50,
    description:
        'A smooth, smudge-resistant gel liner for a precise line that lasts '
        'all day.',
    color: Color(0xFF6E3F5A),
    icon: Icons.edit_outlined,
  ),
  Product(
    id: 'velvet-rose-gold-eye-stick',
    name: 'Rose Gold Eyeshadow Stick',
    brand: 'Velvet Touch',
    category: 'Eyes',
    shade: 'Rose Gold',
    price: 20.00,
    description:
        'A creamy shimmer stick that glides on in seconds for an easy, '
        'radiant eye look.',
    color: Color(0xFFD9A38F),
    icon: Icons.star_outline,
  ),
];
