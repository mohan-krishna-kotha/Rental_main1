# Server URL Fix - Backslash Issue

## Problem Found

Your server's `upload.php` is returning URLs with **backslashes** instead of **forward slashes**:

**Wrong (Current):**
```
https:\\deepcognix.com\\rental\\1772454204096_Basketball.jpg
```

**Correct:**
```
https://deepcognix.com/rental/1772454204096_Basketball.jpg
```

---

## ✅ App-Side Fix (Already Done)

I've updated the Flutter app to automatically convert backslashes to forward slashes, so **images will now work** even with the server returning backslashes.

---

## 🔧 Server-Side Fix (Recommended)

To fix your PHP server properly, update line 20 in `upload.php`:

### Current Code (Line 20):
```php
$full_url = "https:\\deepcognix.com\\rental\\" . $filename;
```

### Fixed Code:
```php
$full_url = "https://deepcognix.com/rental/" . $filename;
```

Or better yet, let PHP construct it properly:

```php
$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
$host = $_SERVER['HTTP_HOST'];
$full_url = $protocol . "://" . $host . "/rental/" . $filename;
```

---

## Complete Fixed upload.php

Replace lines 18-26 with this:

```php
if (move_uploaded_file($_FILES["file"]["tmp_name"], $target_file)) {
    // Construct proper URL with forward slashes
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
    $host = $_SERVER['HTTP_HOST'];
    $full_url = $protocol . "://" . $host . "/rental/" . $filename;
    
    header('Content-Type: application/json');
    echo json_encode([
        'success' => true,
        'filename' => $filename,
        'url' => $full_url
    ]);
} else {
    header('Content-Type: application/json');
    echo json_encode([
        'success' => false,
        'error' => 'Failed to upload file'
    ]);
}
```

---

## What Changed

### Before:
```json
{
  "url": "https:\\deepcognix.com\\rental\\image.jpg"
}
```

### After:
```json
{
  "url": "https://deepcognix.com/rental/image.jpg"
}
```

---

## Status

✅ **Flutter App:** Fixed - automatically converts backslashes to forward slashes
⚠️ **PHP Server:** Should be fixed for proper URL formatting

Your images will now show correctly in the app!
