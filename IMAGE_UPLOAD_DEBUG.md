# Image Upload Debug Guide

## Problem: Images Not Showing After Upload

If you uploaded images but they're not appearing in the product details, follow these steps to diagnose the issue.

---

## Step 1: Check Debug Console Output

When you submit a listing, look for these debug messages in your console:

### ✅ **Success Messages (What You Should See):**
```
🖼️ Uploading 3 images...
✅ Successfully uploaded 3 images
📸 Image URLs: [https://deepcognix.com/rental/1234567890_image1.jpg, ...]
💾 Saving product with 3 images to Firestore...
✅ Product saved successfully!
```

### ❌ **Error Messages (What Indicates a Problem):**
```
❌ Image upload failed: CORS Error: Unable to upload from web...
❌ Image upload failed: ClientException: Failed to fetch...
❌ Image upload failed: Server returned status code: 500
```

---

## Step 2: Common Issues & Solutions

### Issue 1: CORS Error (Most Common for Web)

**Symptoms:**
- Error: `ClientException: Failed to fetch`
- Error: `CORS Error: Unable to upload from web`

**Solution:**
Your server needs CORS headers configured. See [CORS_FIX.md](CORS_FIX.md) for the complete solution.

**Quick Fix:**
Make sure your `upload.php` on the server has these lines at the top:
```php
<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
```

---

### Issue 2: Images Upload But Don't Show

**Symptoms:**
- No error messages
- Console shows: `✅ Successfully uploaded X images`
- But product details show placeholder icon

**Possible Causes:**

1. **Server returned wrong URL format**
   - Check console for `📸 Image URLs:` 
   - URLs should be valid: `https://deepcognix.com/rental/filename.jpg`
   - If URLs look wrong, update your `upload.php` to return proper JSON:
   ```php
   echo json_encode([
       'success' => true,
       'url' => 'https://deepcognix.com/rental/' . $filename,
       'filename' => $filename
   ]);
   ```

2. **Images uploaded but server file permissions issue**
   - Check if images are actually on the server in `/rental/` folder
   - Verify folder permissions: `chmod 755 rental/`
   - Test URL directly in browser: `https://deepcognix.com/rental/your_image.jpg`

3. **Mixed content (HTTP/HTTPS) issue**
   - Ensure image URLs use HTTPS, not HTTP
   - Browser blocks HTTP images on HTTPS sites

---

### Issue 3: Network/Connection Issues

**Symptoms:**
- Error: `Network Error: Failed to connect to server`
- Timeout errors

**Solutions:**
- Check internet connection
- Verify server is accessible: `curl https://deepcognix.com/rental/upload.php`
- Check if server is down or blocking requests
- Firewall might be blocking uploads

---

## Step 3: Test Your Server Manually

Run this command to test if your server accepts uploads:

```bash
curl -X POST -F "file=@test.jpg" https://deepcognix.com/rental/upload.php
```

**Expected Response:**
```json
{
  "success": true,
  "filename": "1234567890_test.jpg",
  "url": "https://deepcognix.com/rental/1234567890_test.jpg"
}
```

If this fails, the problem is with your server setup, not the app.

---

## Step 4: New Features Added

I've added these improvements to help you debug:

### 1. **Detailed Console Logging**
   - Shows exactly how many images are being uploaded
   - Displays the URLs returned from server
   - Logs success/failure of each step

### 2. **Upload Verification**
   - Checks if all selected images were uploaded
   - Verifies no empty URLs returned
   - Alerts if upload count doesn't match

### 3. **User-Friendly Error Dialog**
   - Shows specific error message when upload fails
   - Gives option to continue without images or cancel
   - Prevents saving product with failed uploads (unless you choose to continue)

---

## Step 5: Check Firestore Database

Go to Firebase Console → Firestore Database → products collection

Find your product and check the `images` field:

### ✅ **Correct:**
```json
{
  "images": [
    "https://deepcognix.com/rental/1234567890_image1.jpg",
    "https://deepcognix.com/rental/1234567890_image2.jpg"
  ]
}
```

### ❌ **Wrong (Empty):**
```json
{
  "images": []
}
```

If images array is empty, the upload failed before saving.

---

## Step 6: Mobile vs Web

**Note:** Image upload works differently on mobile vs web:

- **Mobile (Android/iOS):** Works even without CORS headers
- **Web (Flutter Web):** Requires CORS headers on server

If it works on mobile but not web, it's definitely a CORS issue.

---

## Quick Checklist

Before submitting a listing:

- [ ] Selected images show thumbnails in the app
- [ ] Server has CORS headers configured (for web)
- [ ] Server `rental/` folder exists with write permissions
- [ ] Server `upload.php` returns valid JSON with URLs
- [ ] Test upload works with curl command
- [ ] Console shows no error messages
- [ ] Check Firestore to verify images array is populated

---

## Still Not Working?

1. **Clear all console output**
2. **Try uploading 1 image** to a new listing
3. **Copy ALL console output** (every message from submission)
4. **Check Firestore** for the new product's images field
5. **Try accessing image URL directly** in browser

This will help identify exactly where the process is failing.
