# Quick Fix for CORS Error

## The Problem
Your upload is failing because the server at `https://deepcognix.com/rental/upload.php` is not sending CORS headers. This is required for web browsers.

## Quick Fix (5 minutes)

### 1. Add CORS Headers to Your PHP File

Open your existing `upload.php` on the server and add these lines **at the very top** (before any other code):

```php
<?php
// Add CORS headers - MUST BE FIRST
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Your existing upload code below...
?>
```

### 2. Or Use the Complete PHP File

I've created a fully working `upload.php` with all features:
- ✅ CORS headers included
- ✅ Error handling
- ✅ JSON response format
- ✅ File validation

**Location:** Check the [server/upload.php](server/upload.php) file in this project.

**Upload it to:** `https://deepcognix.com/rental/upload.php` on your server.

### 3. Test Again

After updating the server file, refresh your Flutter app and try uploading again.

## Alternative: .htaccess Fix

If you can't modify the PHP file, create a `.htaccess` file in the `rental/` directory:

```apache
Header set Access-Control-Allow-Origin "*"
Header set Access-Control-Allow-Methods "POST, OPTIONS"
Header set Access-Control-Allow-Headers "Content-Type, Accept"
```

## Expected Server Response

Your server should return JSON like this:

```json
{
  "success": true,
  "filename": "1719234567890_image.jpg",
  "url": "https://deepcognix.com/rental/1719234567890_image.jpg"
}
```

## Why This Happens

- **Mobile apps:** Upload works fine (no CORS restrictions)
- **Web apps:** Browser blocks requests without CORS headers for security

## Need Help?

Check [server/README.md](server/README.md) for detailed troubleshooting steps.
