# 🚨 FIX YOUR SERVER: It's Returning "success" Without the Filename!

## The Problem

Your server's `upload.php` is returning just the text `"success"` but **NOT returning the actual filename or URL** of the uploaded image.

**Current Server Response:**
```
success
```

**What the app tries to do:**
- Uses "success" as the filename
- Constructs URL: `https://deepcognix.com/rental/success`
- This is NOT an actual image file! ❌

---

## ✅ The Fix: Update Your upload.php

Your server **MUST** return the filename or URL of the uploaded image. Here are the correct ways:

### Option 1: Return JSON with URL (Recommended)

```php
<?php
// ... your upload code ...

if (move_uploaded_file($file_tmp, $destination)) {
    // SUCCESS - Return JSON with full URL
    $full_url = 'https://deepcognix.com/rental/' . $new_filename;
    
    header('Content-Type: application/json');
    echo json_encode([
        'success' => true,
        'filename' => $new_filename,
        'url' => $full_url
    ]);
    exit;
}
?>
```

**App receives:**
```json
{
  "success": true,
  "filename": "1709123456789_basketball.jpg",
  "url": "https://deepcognix.com/rental/1709123456789_basketball.jpg"
}
```

---

### Option 2: Return JSON with Filename Only

```php
<?php
// ... your upload code ...

if (move_uploaded_file($file_tmp, $destination)) {
    header('Content-Type: application/json');
    echo json_encode([
        'success' => true,
        'filename' => $new_filename
    ]);
    exit;
}
?>
```

**App receives:**
```json
{
  "success": true,
  "filename": "1709123456789_basketball.jpg"
}
```

The app will construct: `https://deepcognix.com/rental/1709123456789_basketball.jpg`

---

### Option 3: Return Plain Text Filename

```php
<?php
// ... your upload code ...

if (move_uploaded_file($file_tmp, $destination)) {
    // Just echo the filename (no JSON)
    echo $new_filename;
    exit;
}
?>
```

**App receives:**
```
1709123456789_basketball.jpg
```

The app will construct: `https://deepcognix.com/rental/1709123456789_basketball.jpg`

---

## 🔧 Complete Working Example

Here's a complete `upload.php` that works correctly:

```php
<?php
// CORS Headers (required for web)
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Configuration
$upload_dir = 'rental/';
$max_file_size = 5 * 1024 * 1024; // 5MB

// Create directory if needed
if (!file_exists($upload_dir)) {
    mkdir($upload_dir, 0755, true);
}

// Handle upload
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
        http_response_code(400);
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'error' => 'No file uploaded or upload error'
        ]);
        exit();
    }

    $file = $_FILES['file'];
    $file_name = $file['name'];
    $file_tmp = $file['tmp_name'];
    $file_size = $file['size'];

    // Validate size
    if ($file_size > $max_file_size) {
        http_response_code(400);
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'error' => 'File too large (max 5MB)'
        ]);
        exit();
    }

    // Sanitize filename
    $new_filename = preg_replace('/[^a-zA-Z0-9._-]/', '_', $file_name);
    $destination = $upload_dir . $new_filename;

    // Upload the file
    if (move_uploaded_file($file_tmp, $destination)) {
        // ✅ SUCCESS - Return proper JSON response
        $full_url = 'https://' . $_SERVER['HTTP_HOST'] . '/' . $destination;
        
        http_response_code(200);
        header('Content-Type: application/json');
        echo json_encode([
            'success' => true,
            'filename' => $new_filename,
            'url' => $full_url,
            'size' => $file_size
        ]);
        exit;
    } else {
        // ❌ FAILURE
        http_response_code(500);
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'error' => 'Failed to save file'
        ]);
        exit;
    }
} else {
    http_response_code(405);
    header('Content-Type: application/json');
    echo json_encode([
        'success' => false,
        'error' => 'Only POST method allowed'
    ]);
    exit;
}
?>
```

---

## 🧪 Test the Fix

After updating your `upload.php`, test it manually:

```bash
curl -X POST -F "file=@test.jpg" https://deepcognix.com/rental/upload.php
```

**You should see:**
```json
{
  "success": true,
  "filename": "1709123456789_test.jpg",
  "url": "https://deepcognix.com/rental/1709123456789_test.jpg",
  "size": 12345
}
```

---

## ❌ What NOT to Return

**Don't do this:**
```php
// WRONG - Just text "success"
echo "success";  // ❌ No filename!
```

```php
// WRONG - Success without filename
echo json_encode(['success' => true]);  // ❌ No filename!
```

```php
// WRONG - Just "OK"
echo "OK";  // ❌ No filename!
```

---

## 📝 Summary

**Current Problem:**
- Server returns: `"success"`
- App constructs: `https://deepcognix.com/rental/success` ❌

**After Fix:**
- Server returns: `{"success": true, "filename": "1709123456789_basketball.jpg"}`
- App constructs: `https://deepcognix.com/rental/1709123456789_basketball.jpg` ✅

---

## 🎯 Next Steps

1. **Update your `upload.php`** with one of the solutions above
2. **Test the upload** using curl command
3. **Try uploading in your app again**
4. **Check console** - you should now see: `✅ Image 1 uploaded: https://deepcognix.com/rental/[filename]`
5. **Check product details** - image should now display!

The file is already on your server, you just need to return its name/URL properly so the app knows where to find it!
