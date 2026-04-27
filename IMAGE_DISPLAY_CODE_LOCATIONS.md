# Image Display Code Locations

## Where Images Are Displayed in the Flutter App

Here are all the places where product/item images are loaded and displayed:

---

## 1. **Item Details Screen** (Main Product View)
**File:** `lib/features/home/presentation/screens/item_details_screen.dart`  
**Lines:** ~138-145

```dart
child: item.images.isNotEmpty
    ? Image.network(
        item.images.first,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(
            Icons.image,
            size: 100,
            color: Colors.white54,
          ),
        ),
      )
    : const Center(
        child: Icon(
          Icons.image,
          size: 100,
          color: Colors.white54,
        ),
      ),
```

**What it does:** Shows the main product image when viewing product details.

---

## 2. **My Listings Screen** (User's Products)
**File:** `lib/features/profile/presentation/screens/my_listings_screen.dart`  
**Lines:** ~93-110

```dart
leading: item.images.isNotEmpty
    ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          item.images.first,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Image error for ${item.title}: $error');
            return Container(
              width: 50,
              height: 50,
              color: Colors.red.shade900,
              child: const Icon(Icons.broken_image, color: Colors.white),
            );
          },
        ),
      )
    : const Icon(Icons.image, size: 50, color: Colors.grey),
```

**What it does:** Shows thumbnail images in the user's listings.

---

## 3. **Home Screen** (Product Carousel & Grid)
**File:** `lib/features/home/presentation/screens/home_screen.dart`  
**Lines:** ~714 and ~828

```dart
// Carousel Item
heroImage != null
    ? Image.network(
        heroImage,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: Colors.grey.shade800,
          child: const Icon(Icons.image, size: 80),
        ),
      )
    : Container(...)

// Grid Item  
thumbnail != null
    ? Image.network(
        thumbnail,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      )
    : Container(...)
```

**What it does:** Shows images in the home page carousel and grid.

---

## 4. **Map Screen** (Product Markers)
**File:** `lib/features/map/presentation/screens/map_screen.dart`  
**Lines:** ~266-270

```dart
image: product.images.isNotEmpty
    ? DecorationImage(
        image: NetworkImage(product.images.first),
        fit: BoxFit.cover,
      )
    : null,
```

**What it does:** Shows product images in map marker popups.

---

## 5. **Favorites Screen**
**File:** `lib/features/profile/presentation/screens/favorites_screen.dart`  
**Lines:** ~81-88

```dart
image: item.images.isNotEmpty
    ? DecorationImage(
        image: NetworkImage(item.images.first),
        fit: BoxFit.cover,
      )
    : null,
```

**What it does:** Shows images in the favorites list.

---

## 6. **Admin Screens**
**Files:** 
- `lib/features/admin/presentation/screens/admin_products_screen.dart`
- `lib/features/admin/presentation/screens/admin_flagged_items_screen.dart`

```dart
leading: product.images.isNotEmpty
    ? Image.network(
        product.images.first,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      )
    : const Icon(Icons.image),
```

**What it does:** Shows product thumbnails in admin panels.

---

## 🔍 How Image Loading Works

### The Flow:
1. App makes HTTP GET request to: `https://deepcognix.com/rental/[filename].jpg`
2. Server needs to respond with:
   - Status: `200 OK`
   - Header: `Access-Control-Allow-Origin: *` (or specific domain)
   - Content-Type: `image/jpeg` or `image/png`
   - Image data

### Current Issue:
- ❌ Browser request works (shows image)
- ❌ Flutter Web app request fails with `statusCode: 0`
- **Reason:** Missing CORS headers on image files

---

## 🔧 What the Server Needs to Do

When the app requests an image like:
```
GET https://deepcognix.com/rental/1772454471128_Basketball.jpg
```

The server must respond with these headers:
```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, OPTIONS
Content-Type: image/jpeg
Content-Length: [file size]

[image binary data]
```

---

## 📋 Example Request from Flutter App

```dart
// This is what Flutter's Image.network() does internally:
final response = await http.get(
  Uri.parse('https://deepcognix.com/rental/1772454471128_Basketball.jpg'),
  headers: {
    'Accept': 'image/jpeg,image/png,image/*',
  },
);

// Server must return 200 with CORS headers
// Otherwise, browser blocks the response (statusCode: 0)
```

---

## ✅ Solution: `.htaccess` File

Create this file in the `rental/` folder on your server:

**File:** `rental/.htaccess`
```apache
Header set Access-Control-Allow-Origin "*"
Header set Access-Control-Allow-Methods "GET, OPTIONS"
Header set Access-Control-Allow-Headers "Content-Type"

# Handle preflight OPTIONS requests
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{REQUEST_METHOD} OPTIONS
    RewriteRule ^(.*)$ $1 [R=200,L]
</IfModule>
```

This tells Apache to add CORS headers to **all files** in the `rental/` folder.

---

## 🧪 Test CORS Headers

The server admin can test if CORS headers are working:

```bash
curl -I https://deepcognix.com/rental/1772454471128_Basketball.jpg
```

Should see:
```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
Content-Type: image/jpeg
```

Or test in browser console (press F12 on the image URL page):
```javascript
fetch('https://deepcognix.com/rental/1772454471128_Basketball.jpg')
  .then(r => console.log('SUCCESS:', r.status))
  .catch(e => console.error('FAILED:', e));
```

If it logs "SUCCESS: 200" → CORS is working!  
If it logs "FAILED" → CORS headers missing.

---

## Summary for Server Admin

**Issue:** Flutter web app can't load images due to missing CORS headers  
**Solution:** Add `.htaccess` file with CORS headers to `rental/` folder  
**Test:** Use curl or browser console to verify headers are present  
**Result:** Images will load in the Flutter app ✨
