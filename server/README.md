# Server Upload Configuration

## Problem
The error you're seeing occurs because of **CORS (Cross-Origin Resource Sharing)** restrictions. When your Flutter web app tries to upload files to `https://deepcognix.com/rental/upload.php`, the browser blocks the request unless the server sends proper CORS headers.

## Solution

### Step 1: Update Your Server's upload.php

Replace your current `upload.php` file on the server with the one provided in this folder (`server/upload.php`). 

**Key features:**
- ✅ Proper CORS headers
- ✅ Handles OPTIONS preflight requests
- ✅ Returns JSON response with file URL
- ✅ File size and type validation
- ✅ Secure filename sanitization

### Step 2: Upload the PHP File

Upload the `upload.php` file to your server at:
```
https://deepcognix.com/rental/upload.php
```

Make sure the file has write permissions (755 or 644).

### Step 3: Create Upload Directory

Ensure the `rental/` directory exists on your server with write permissions:
```bash
mkdir -p rental
chmod 755 rental
```

### Step 4: Configure CORS (Important!)

In the `upload.php` file, find this line:
```php
header('Access-Control-Allow-Origin: *');
```

**For Production:** Change `*` to your specific domain:
```php
header('Access-Control-Allow-Origin: https://your-flutter-app-domain.com');
```

**For Development:** Keep `*` to allow all origins (testing only).

### Step 5: Test the Upload

1. Run your Flutter web app
2. Try uploading an image in "Add Listing"
3. Check for success message

## Troubleshooting

### Error: "CORS Error: Unable to upload from web"
- Your server is not sending CORS headers
- Verify `upload.php` is correctly uploaded
- Check server error logs

### Error: "Network Error: Failed to connect"
- URL might be incorrect
- Server might be down
- Check internet connection

### Error: "Server returned status code: 500"
- PHP error in upload.php
- Check PHP error logs on server
- Verify directory write permissions

### Mobile Upload Works but Web Doesn't
- This is a CORS issue (only affects web browsers)
- Update `upload.php` with CORS headers

## File Size Limits

Current limit: **5MB per file**

To change, edit this line in `upload.php`:
```php
$max_file_size = 5 * 1024 * 1024; // 5MB in bytes
```

Also check your PHP configuration:
```ini
upload_max_filesize = 10M
post_max_size = 10M
```

## Security Notes

1. **For Production:** Always specify your exact domain in CORS headers
2. Validate file types server-side (already implemented)
3. Use HTTPS (already using)
4. Consider adding authentication tokens to prevent abuse
5. Implement rate limiting to prevent spam uploads

## Alternative: .htaccess Method

If you can't modify `upload.php`, add this to `.htaccess` in the same directory:

```apache
# Enable CORS
Header set Access-Control-Allow-Origin "*"
Header set Access-Control-Allow-Methods "POST, GET, OPTIONS"
Header set Access-Control-Allow-Headers "Content-Type, Accept"

# Handle preflight
RewriteEngine On
RewriteCond %{REQUEST_METHOD} OPTIONS
RewriteRule ^(.*)$ $1 [R=200,L]
```

## Testing

Test upload manually using curl:
```bash
curl -X POST -F "file=@test.jpg" https://deepcognix.com/rental/upload.php
```

Expected response:
```json
{
  "success": true,
  "filename": "1234567890_test.jpg",
  "url": "https://deepcognix.com/rental/1234567890_test.jpg",
  "size": 12345
}
```

## Support

If you continue to have issues:
1. Check browser console for detailed error messages
2. Check server PHP error logs
3. Verify file permissions on server
4. Test with curl command above
5. Ensure PHP file upload is enabled (`file_uploads = On` in php.ini)
