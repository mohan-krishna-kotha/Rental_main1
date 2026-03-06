<?php
/**
 * Image Upload Script for Rental App
 * 
 * This script handles file uploads from the Flutter app
 * IMPORTANT: Configure CORS headers to allow cross-origin requests
 */

// ==================== CORS CONFIGURATION ====================
// Allow requests from your Flutter web app domain
// For development, you can use '*' but for production, specify your domain
header('Access-Control-Allow-Origin: *'); // Change '*' to your domain in production
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');
header('Access-Control-Max-Age: 86400'); // Cache preflight for 24 hours

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ==================== CONFIGURATION ====================
$upload_dir = 'rental/'; // Directory to store uploaded files
$max_file_size = 5 * 1024 * 1024; // 5MB max file size
$allowed_extensions = array('jpg', 'jpeg', 'png', 'gif', 'webp');

// ==================== CREATE DIRECTORY IF NOT EXISTS ====================
if (!file_exists($upload_dir)) {
    mkdir($upload_dir, 0755, true);
}

// ==================== UPLOAD HANDLING ====================
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Check if file was uploaded
    if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'No file uploaded or upload error occurred'
        ]);
        exit();
    }

    $file = $_FILES['file'];
    $file_size = $file['size'];
    $file_tmp = $file['tmp_name'];
    $file_name = $file['name'];

    // Validate file size
    if ($file_size > $max_file_size) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'File size exceeds maximum allowed size (5MB)'
        ]);
        exit();
    }

    // Get file extension
    $file_ext = strtolower(pathinfo($file_name, PATHINFO_EXTENSION));

    // Validate file extension
    if (!in_array($file_ext, $allowed_extensions)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'Invalid file type. Allowed types: ' . implode(', ', $allowed_extensions)
        ]);
        exit();
    }

    // Generate unique filename (preserve the name sent by client if it has timestamp)
    $new_filename = $file_name;
    
    // If filename doesn't start with a timestamp, add one
    if (!preg_match('/^\d{13}_/', $new_filename)) {
        $new_filename = time() . '_' . $new_filename;
    }

    // Sanitize filename
    $new_filename = preg_replace('/[^a-zA-Z0-9._-]/', '_', $new_filename);
    
    // Full path
    $destination = $upload_dir . $new_filename;

    // Move uploaded file
    if (move_uploaded_file($file_tmp, $destination)) {
        // Success - return JSON response
        $full_url = 'https://' . $_SERVER['HTTP_HOST'] . '/' . $destination;
        
        http_response_code(200);
        header('Content-Type: application/json');
        echo json_encode([
            'success' => true,
            'filename' => $new_filename,
            'url' => $full_url,
            'size' => $file_size
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Failed to save file'
        ]);
    }
} else {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'error' => 'Method not allowed. Use POST.'
    ]);
}
?>
