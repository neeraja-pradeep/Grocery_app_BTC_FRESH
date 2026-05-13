# Grocery Application - Complete API Documentation

## Table of Contents
- [Overview](#overview)
- [Base URL](#base-url)
- [Authentication](#authentication)
- [Common Features](#common-features)
- [Accounts API](#accounts-api)
- [Products API](#products-api)
- [Orders API](#orders-api)
- [Inventory API](#inventory-api)
- [Delivery API](#delivery-api)
- [System Endpoints](#system-endpoints)

---

## Overview

This document provides comprehensive API documentation for the Grocery Application, a Django-based REST API for managing an online grocery store with delivery functionality.

**Version:** v1
**Last Updated:** 2026-02-09

---

## Base URL

All API endpoints are prefixed with:
```
/api/{app_name}/v1/
```

Where `{app_name}` is one of:
- `auth` - Authentication and user management
- `products` - Product catalog and categories
- `order` - Orders, checkout, and payments
- `inventory` - Warehouses and shipping
- `delivery` - Delivery partners and tracking

---

## Authentication

The API uses session-based authentication with CSRF protection (exempt for specific endpoints).

**Session Authentication:**
- Login via `/api/auth/v1/signin/` to create a session
- Session cookie is automatically managed by the browser
- Include credentials in requests

**Permission Classes:**
- `IsAdmin` - Admin users only
- `IsCustomer` - Customer users only
- `IsDelivery` - Delivery partners only
- `IsAdminOrReadOnly` - Admins can write, all can read
- `IsOwnerOrAdmin` - Owner of resource or admin
- `AllowAny` - No authentication required

---

## Common Features

### Rate Limiting
- All endpoints use throttling (UserRateThrottle, AuthThrottle, PaymentThrottle)
- Custom throttle classes enforce rate limits per user/IP

### Caching
- Version-based caching implemented across all apps
- Cache automatically invalidated on create/update/delete
- Varies by user for user-specific data

### Pagination
- Standard pagination on all list endpoints
- Default page size configurable in settings

### Filtering & Search
- DjangoFilterBackend for field-based filtering
- SearchFilter for text-based search
- OrderingFilter for sorting

### Error Responses

**Standard Error Format:**
```json
{
  "error": "Error message description"
}
```

**Validation Error Format:**
```json
{
  "field_name": ["Error message for this field"]
}
```

**Common HTTP Status Codes:**
- `200 OK` - Successful GET, PUT, PATCH
- `201 Created` - Successful POST
- `204 No Content` - Successful DELETE
- `400 Bad Request` - Validation error
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Permission denied
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

---

## Accounts API

Base URL: `/api/auth/v1/`

### 1. Customer Registration

**POST** `/api/auth/v1/signup/`

Register a new customer account.

**Permissions:** AllowAny
**Throttle:** AuthThrottle

**Request Body:**
```json
{
  "username": "string",
  "email": "string",
  "password": "string",
  "password_confirm": "string",
  "first_name": "string",
  "last_name": "string",
  "phone_number": "string"
}
```

**Response (201):**
```json
{
  "message": "Customer registered successfully",
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "+1234567890",
    "role": "customer",
    "created_at": "2026-02-09T10:00:00Z"
  }
}
```

**Validation:**
- Passwords must match
- Email must be valid and unique
- All fields required except phone_number

---

### 2. Customer Sign In

**POST** `/api/auth/v1/signin/`

Authenticate and create a session.

**Permissions:** AllowAny
**Throttle:** AuthThrottle

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "+1234567890",
    "role": "customer",
    "created_at": "2026-02-09T10:00:00Z"
  }
}
```

**Error Response (401):**
```json
{
  "error": "Invalid credentials"
}
```

---

### 3. OTP Authentication

#### Send OTP

**POST** `/api/auth/v1/send-otp/`

Send OTP to registered phone number for authentication.

**Permissions:** AllowAny
**Throttle:** AuthThrottle

**Request Body:**
```json
{
  "phone_number": "+1234567890"
}
```

**Response (200):**
```json
{
  "message": "OTP sent successfully",
  "phone_number": "+1234567890",
  "status": "pending"
}
```

**Error Responses:**
- `404` - No account found with this phone number
- `403` - Account is disabled
- `500` - Failed to send OTP

#### Verify OTP

**POST** `/api/auth/v1/verify-otp/`

Verify OTP and sign in the user.

**Permissions:** AllowAny
**Throttle:** AuthThrottle

**Request Body:**
```json
{
  "phone_number": "+1234567890",
  "otp_code": "123456"
}
```

**Response (200):**
```json
{
  "message": "OTP verification successful",
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "role": "customer"
  }
}
```

**Error Response (401):**
```json
{
  "error": "Invalid or expired OTP code"
}
```

---

### 4. Logout

**POST** `/api/auth/v1/logout/`

Destroy user session.

**Permissions:** IsUser
**Throttle:** AuthThrottle

**Response (200):**
```json
{
  "message": "Logout successful"
}
```

---

### 5. User Profile

#### Get Profile

**GET** `/api/auth/v1/profile/`

Get authenticated user's profile.

**Permissions:** IsUser
**Cached:** Yes (varies by user)

**Response (200):**
```json
{
  "id": 1,
  "username": "johndoe",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+1234567890",
  "role": "customer",
  "role_display": "Customer",
  "note": "",
  "date_joined": "2026-01-01T00:00:00Z",
  "last_login": "2026-02-09T10:00:00Z",
  "created_at": "2026-01-01T00:00:00Z",
  "updated_at": "2026-02-09T10:00:00Z"
}
```

#### Update Profile

**PATCH** `/api/auth/v1/profile/`

Update user profile (partial update).

**Permissions:** IsUser

**Request Body:**
```json
{
  "first_name": "John",
  "last_name": "Smith",
  "phone_number": "+1234567890",
  "email": "newemail@example.com"
}
```

**Response (200):** Updated user profile object

**Read-only Fields:** id, username, date_joined, last_login, created_at, updated_at, role

---

### 6. Address Management

#### List Addresses

**GET** `/api/auth/v1/address/`

List all addresses for authenticated user.

**Permissions:** IsCustomerOrAdmin | IsOwnerOrAdmin
**Cached:** Yes (varies by user)

**Query Parameters:**
- `selected` (boolean) - Filter by selected status

**Response (200):**
```json
[
  {
    "id": 1,
    "first_name": "John",
    "last_name": "Doe",
    "street_address1": "123 Main St",
    "street_address2": "Apt 4B",
    "city": "New York",
    "state": "NY",
    "postal_code": "10001",
    "country": "US",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "address_type": "home",
    "selected": true,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-02-09T10:00:00Z"
  }
]
```

#### Create Address

**POST** `/api/auth/v1/address/`

Create a new address for authenticated user.

**Request Body:**
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "street_address1": "123 Main St",
  "street_address2": "Apt 4B",
  "city": "New York",
  "state": "NY",
  "postal_code": "10001",
  "country": "US",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "address_type": "home",
  "selected": true
}
```

**Response (201):** Created address object

**Note:** User is automatically set to the authenticated user.

#### Update Address

**PATCH** `/api/auth/v1/address/{id}/`

Partially update an address.

**Request Body:** Any address fields to update

**Response (200):** Updated address object

**Note:** Setting `selected: true` automatically deselects other addresses.

#### Delete Address

**DELETE** `/api/auth/v1/address/{id}/`

Delete an address.

**Response (204):** No content

---

### 7. Delivery Partner Management

#### Register Delivery Partner

**POST** `/api/auth/v1/delivery/register/`

Admin endpoint to register delivery partners.

**Permissions:** IsAuthenticated, IsAdmin
**Throttle:** AuthThrottle

**Request Body:**
```json
{
  "username": "driver1",
  "email": "driver@example.com",
  "password": "password123",
  "password_confirm": "password123",
  "first_name": "Driver",
  "last_name": "One",
  "phone_number": "+1234567890"
}
```

**Response (201):**
```json
{
  "message": "Delivery partner registered successfully and DeliveryProfile created",
  "user": {
    "id": 10,
    "username": "driver1",
    "email": "driver@example.com",
    "role": "delivery"
  }
}
```

#### Delivery Partner Sign In

**POST** `/api/auth/v1/delivery/signin/`

Sign in for delivery partners only.

**Permissions:** AllowAny
**Throttle:** AuthThrottle

**Request Body:**
```json
{
  "username": "driver1",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "message": "Delivery partner login successful",
  "user": {
    "id": 10,
    "username": "driver1",
    "role": "delivery"
  }
}
```

**Error (401):**
```json
{
  "error": "User is not a delivery partner"
}
```

---

### 8. Reset Password

**POST** `/api/auth/v1/reset-password/`

Reset password after OTP verification.

**Permissions:** IsAuthenticated

**Request Body:**
```json
{
  "new_password": "newpassword123"
}
```

**Response (200):**
```json
{
  "message": "Password reset successfully"
}
```

**Validation:** Password must be at least 6 characters long.

---

### 9. Admin Endpoints

#### List Admin Phone Numbers

**GET** `/api/auth/v1/admin/phone/`

Get list of phone numbers for all admin users.

**Permissions:** IsAuthenticated
**Cached:** Yes

**Response (200):**
```json
[
  {
    "phone_number": "+1234567890"
  },
  {
    "phone_number": "+0987654321"
  }
]
```

#### Delete User (Admin)

**DELETE** `/api/auth/v1/admin/users/{user_id}/`

Admin endpoint to delete a user by ID.

**Permissions:** IsAdmin

**Response (204):** No content

**Error (404):**
```json
{
  "error": "User not found"
}
```

#### List Customers (Admin)

**GET** `/api/auth/v1/admin-customers/`

Retrieve a list of all customers with aggregated data.

**Permissions:** IsAdmin
**Cached:** Yes

**Query Parameters:**
- `search` - Search by username, email, phone_number, first_name, last_name
- `ordering` - Order by created_at, username, email
- Filters from CustomerFilter

**Response (200):**
```json
[
  {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "phone_number": "+1234567890",
    "location": "New York, NY",
    "order_count": 15,
    "total_spent": 1250.50,
    "warehouse_name": "N/A - Clarification Needed",
    "created_at": "2026-01-01T00:00:00Z"
  }
]
```

#### Get Customer Details (Admin)

**GET** `/api/auth/v1/admin-customers/{id}/`

Retrieve detailed information about a specific customer.

**Permissions:** IsAdmin
**Cached:** Yes

**Response (200):**
```json
{
  "id": 1,
  "username": "johndoe",
  "name": "John Doe",
  "email": "john@example.com",
  "phone_number": "+1234567890",
  "note": "",
  "order_count": 15,
  "total_spent": 1250.50,
  "addresses": [...],
  "recent_orders": [...],
  "country": "US",
  "time_period_of_customer": "2 months",
  "created_at": "2026-01-01T00:00:00Z",
  "last_login": "2026-02-09T10:00:00Z"
}
```

#### Update Customer Note

**PATCH** `/api/auth/v1/admin-customers/{id}/update_note/`

Add or update notes for a specific customer.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "note": "VIP customer - handle with priority"
}
```

**Response (200):** Full customer details with updated note

#### Bulk Delete Customers

**POST** `/api/auth/v1/admin-customers/bulk_delete/`

Delete multiple customers by their IDs.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "customer_ids": [1, 2, 3]
}
```

**Response (200):**
```json
{
  "message": "Successfully deleted 3 customers.",
  "customer_ids": [1, 2, 3]
}
```

---

## Products API

Base URL: `/api/products/v1/`

### 1. Categories

#### List Categories

**GET** `/api/products/v1/category/`

List all parent categories (parent_id is null by default).

**Permissions:** IsAdminOrReadOnly
**Cached:** Yes

**Query Parameters:**
- `parent_id` (integer) - Override to filter by parent category ID

**Response (200):**
```json
[
  {
    "id": 1,
    "name": "Fruits & Vegetables",
    "slug": "fruits-vegetables",
    "description": "<p>Fresh produce</p>",
    "description_plaintext": "Fresh produce",
    "parent_id": null,
    "background_image_url": "https://cdn.example.com/fruits.jpg",
    "background_image_path": "/media/categories/fruits.jpg",
    "background_image_alt": "Fresh fruits and vegetables",
    "is_offer": false,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-02-09T10:00:00Z"
  }
]
```

#### Create Category

**POST** `/api/products/v1/category/`

Create a new category.

**Permissions:** IsAdmin

**Request Body (multipart/form-data):**
```json
{
  "name": "Organic Fruits",
  "slug": "organic-fruits",
  "description": "<p>Certified organic fruits</p>",
  "description_plaintext": "Certified organic fruits",
  "background_image": "file",
  "background_image_alt": "Organic fruits",
  "parent_id": 1,
  "is_offer": false
}
```

**Response (201):** Created category object

**Validation:**
- Image max 10MB
- Allowed formats: JPEG, JPG, PNG, WebP, HEIC, HEIF

#### Update Category

**PATCH** `/api/products/v1/category/{id}/`

Partially update a category.

**Permissions:** IsAdmin

**Request Body:** Any category fields to update

**Response (200):** Updated category object

#### Delete Category

**DELETE** `/api/products/v1/category/{id}/`

Delete a category.

**Permissions:** IsAdmin

**Response (204):** No content

---

### 2. Product Types

#### List Product Types

**GET** `/api/products/v1/types/`

List all product types.

**Permissions:** IsAdminOrReadOnly
**Cached:** Yes

**Response (200):**
```json
[
  {
    "id": 1,
    "name": "Physical Product",
    "slug": "physical-product",
    "kind": "normal",
    "has_variants": true,
    "is_shipping_required": true,
    "is_digital": false,
    "weight": 0.0,
    "tax_class_id": null,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-02-09T10:00:00Z"
  }
]
```

#### Create Product Type

**POST** `/api/products/v1/types/`

Create a new product type.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "name": "Digital Product",
  "slug": "digital-product",
  "kind": "gift_card",
  "has_variants": false,
  "is_shipping_required": false,
  "is_digital": true,
  "weight": 0.0,
  "tax_class_id": 1
}
```

**Response (201):** Created product type

---

### 3. Products

#### List Products

**GET** `/api/products/v1/`

List products with advanced filtering.

**Permissions:** IsAdminOrReadOnly
**Cached:** Yes

**Query Parameters:**
- `category_id` (integer) - Filter by category ID
- `category_name` (string) - Filter by category name (case-insensitive)
- `product_name` (string) - Filter by product name (case-insensitive)
- `min_price` (decimal) - Minimum price
- `max_price` (decimal) - Maximum price
- `is_discounted` (boolean) - Filter products with active discounts
- `ordering` - Order by: min_price, -min_price, rating, -rating, created_at, -created_at

**Response (200):**
```json
[
  {
    "id": 1,
    "name": "Organic Apples",
    "description_plaintext": "Fresh organic apples from local farms",
    "category_name": "Fruits",
    "product_type_name": "Physical Product",
    "category_id": 1,
    "slug": "organic-apples",
    "rating": 4.5,
    "status": true,
    "tags": "organic,fresh,local",
    "variants": [...],
    "primary_image": "https://cdn.example.com/apples.jpg",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-02-09T10:00:00Z"
  }
]
```

#### Get Product Details

**GET** `/api/products/v1/{id}/`

Retrieve detailed product information.

**Permissions:** IsAdminOrReadOnly
**Cached:** Yes

**Response (200):**
```json
{
  "id": 1,
  "name": "Organic Apples",
  "description": "<p>Fresh organic apples from local farms</p>",
  "category_name": "Fruits",
  "product_type_name": "Physical Product",
  "category_id": 1,
  "slug": "organic-apples",
  "description_plaintext": "Fresh organic apples from local farms",
  "search_document": "organic apples fresh local...",
  "weight": 0.5,
  "default_variant_id": 1,
  "rating": 4.5,
  "tax_class_id": 1,
  "media": [
    {
      "id": 1,
      "image": "https://cdn.example.com/apples.jpg",
      "alt": "Organic red apples"
    }
  ],
  "variants": [
    {
      "id": 1,
      "sku": "APL-ORG-1KG",
      "name": "Organic Apples 1kg",
      "price": 5.99,
      "discounted_price": 4.99,
      "quantity": 100,
      "unit": "kg"
    }
  ],
  "status": true,
  "tags": "organic,fresh,local",
  "created_at": "2026-01-01T00:00:00Z",
  "updated_at": "2026-02-09T10:00:00Z"
}
```

#### Create Product

**POST** `/api/products/v1/`

Create a new product with variants and media.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "name": "Organic Bananas",
  "description": "<p>Fresh organic bananas</p>",
  "description_plaintext": "Fresh organic bananas",
  "category_id": 1,
  "product_type_id": 1,
  "slug": "organic-bananas",
  "weight": 0.15,
  "status": true,
  "tags": "organic,tropical",
  "media": [
    {
      "alt": "Organic bananas",
      "image_file": "file"
    }
  ],
  "variants": [
    {
      "sku": "BAN-ORG-500G",
      "price": 3.99,
      "track_inventory": true,
      "quantity": 200,
      "warehouse": 1
    }
  ]
}
```

**Response (201):** Created product with nested variants and media

#### Update Product

**PATCH** `/api/products/v1/{id}/`

Partially update a product.

**Permissions:** IsAdmin

**Request Body:** Any product fields to update

**Response (200):** Updated product object

#### Delete Product

**DELETE** `/api/products/v1/{id}/`

Delete a product.

**Permissions:** IsAdmin

**Response (204):** No content

---

### 4. Product Variants

#### List Variants

**GET** `/api/products/v1/variants/`

List product variants with filtering.

**Permissions:** IsAdminOrReadOnly
**Cached:** Yes

**Query Parameters:**
- `product_id` (integer) - Filter by product ID
- `unit` (string) - Filter by stock unit
- `search` (string) - Search by SKU, variant name, or product name
- `ordering` - Order by: price, -price, created_at, -created_at

**Response (200):**
```json
[
  {
    "id": 1,
    "sku": "APL-ORG-1KG",
    "name": "Organic Apples 1kg",
    "product_id": 1,
    "price": 5.99,
    "discounted_price": 4.99,
    "track_inventory": true,
    "is_selected": true,
    "is_preorder": false,
    "preorder_end_date": null,
    "preorder_global_threshold": null,
    "quantity_limit_per_customer": 10,
    "weight": 1.0,
    "status": true,
    "tags": "",
    "bar_code": "1234567890123",
    "media": [...],
    "quantity": 100,
    "current_quantity": 100,
    "current_stock_unit": "kg",
    "prod_description": "Fresh organic apples from local farms",
    "product_rating": 4.5,
    "warehouse_name": "Main Warehouse",
    "warehouse_id": 1,
    "primary_image": "https://cdn.example.com/apples.jpg",
    "unit": "kg",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-02-09T10:00:00Z"
  }
]
```

#### Get Discounted Variants

**GET** `/api/products/v1/variants/discounts/`

Get variants with active discounts.

**Permissions:** IsAdminOrReadOnly

**Query Parameters:**
- `category_id` (integer) - Filter by category ID
- `category_name` (string) - Filter by category name
- `parent_category_name` (string) - Filter by parent category
- `min_price` (decimal) - Minimum discounted price
- `max_price` (decimal) - Maximum discounted price
- `ordering` - Order by: price, -price, discounted_price, -discounted_price, created_at, -created_at

**Response (200):** Array of variant objects with discounted_price not null

#### Create Variant

**POST** `/api/products/v1/variants/`

Create a new product variant.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "sku": "APL-ORG-2KG",
  "product_id": 1,
  "price": 10.99,
  "discounted_price": 9.99,
  "track_inventory": true,
  "is_selected": false,
  "is_preorder": false,
  "quantity_limit_per_customer": 5,
  "weight": 2.0,
  "status": true,
  "bar_code": "1234567890124",
  "quantity": 50,
  "warehouse": 1,
  "stock_unit": "kg"
}
```

**Response (201):** Created variant object

#### Link Media to Variant

**POST** `/api/products/v1/variants/{id}/link_media/`

Link existing ProductMedia to a variant.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "media_id": 5
}
```

**Response (201):**
```json
{
  "detail": "ProductMedia 5 successfully linked to Variant APL-ORG-1KG."
}
```

---

### 5. Product Media

#### List Media

**GET** `/api/products/v1/media/`

List product media files.

**Permissions:** IsAdminOrReadOnly
**Cached:** Yes (retrieve only)

**Query Parameters:**
- `product_id` (integer) - Filter by product ID

**Response (200):**
```json
[
  {
    "id": 1,
    "file_path": "products/apples.jpg",
    "image": "https://cdn.example.com/apples.jpg",
    "alt": "Organic red apples",
    "external_url": null,
    "oembed_data": null,
    "to_remove": false,
    "product_id": 1,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-02-09T10:00:00Z"
  }
]
```

#### Upload Media

**POST** `/api/products/v1/media/`

Upload new product media.

**Permissions:** IsAdmin

**Request Body (multipart/form-data):**
```json
{
  "image_file": "file",
  "alt": "Product image",
  "product_id": 1
}
```

**Response (201):** Created media object

**Validation:**
- Image max 10MB
- Allowed formats: JPEG, JPG, PNG, WebP, HEIC, HEIF

#### Delete Media

**DELETE** `/api/products/v1/media/{id}/`

Delete product media.

**Permissions:** IsAdmin

**Response (204):** No content

---

### 6. Product Ratings

#### List Product Ratings

**GET** `/api/products/v1/{product_id}/ratings/`

List all ratings for a product.

**Permissions:** IsCustomer
**Cached:** Yes

**Response (200):**
```json
[
  {
    "id": 1,
    "user": 1,
    "product": 1,
    "stars": 5,
    "body": "Excellent quality and freshness!",
    "created_at": "2026-02-01T00:00:00Z",
    "updated_at": "2026-02-01T00:00:00Z"
  }
]
```

#### Create Rating

**POST** `/api/products/v1/{product_id}/ratings/`

Add a rating to a product.

**Permissions:** IsCustomer

**Request Body:**
```json
{
  "stars": 5,
  "body": "Excellent quality and freshness!"
}
```

**Response (201):** Created rating object

**Validation:**
- Stars must be between 1 and 5
- User can only have one rating per product

#### Update Rating

**PATCH** `/api/products/v1/{product_id}/ratings/{id}/`

Update an existing rating.

**Permissions:** IsCustomer (own ratings only)

**Request Body:**
```json
{
  "stars": 4,
  "body": "Updated review - very good"
}
```

**Response (200):** Updated rating object

#### Delete Rating

**DELETE** `/api/products/v1/{product_id}/ratings/{id}/`

Delete a rating.

**Permissions:** IsCustomer (own ratings only)

**Response (204):** No content

---

### 7. Collections

#### List Collections

**GET** `/api/products/v1/collection/`

List all product collections.

**Permissions:** IsAdminOrReadOnly
**Cached:** Yes

**Response (200):**
```json
[
  {
    "id": 1,
    "name": "Summer Sale",
    "slug": "summer-sale",
    "description": "Hot deals for summer",
    "background_image": "https://cdn.example.com/summer.jpg",
    "background_image_alt": "Summer collection",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-02-09T10:00:00Z"
  }
]
```

#### Create Collection

**POST** `/api/products/v1/collection/`

Create a new collection.

**Permissions:** IsAdmin

**Request Body (multipart/form-data):**
```json
{
  "name": "Winter Sale",
  "slug": "winter-sale",
  "description": "Winter special offers",
  "background_image_file": "file",
  "background_image_alt": "Winter collection"
}
```

**Response (201):** Created collection object

---

### 8. Collection Products

#### List Collection Products

**GET** `/api/products/v1/collection-product/`

List product-collection associations.

**Permissions:** IsAdminOrReadOnly
**Cached:** Yes

**Response (200):**
```json
[
  {
    "id": 1,
    "collection_id": 1,
    "product_id": 1,
    "collection_name": "Summer Sale",
    "product_name": "Organic Apples",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-02-09T10:00:00Z"
  }
]
```

#### Add Product to Collection

**POST** `/api/products/v1/collection-product/`

Associate a product with a collection.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "collection_id": 1,
  "product_id": 5
}
```

**Response (201):** Created association

#### Remove Product from Collection

**DELETE** `/api/products/v1/collection-product/{id}/`

Remove product from collection.

**Permissions:** IsAdmin

**Response (204):** No content

---

### 9. Banners

#### List Banners

**GET** `/api/products/v1/banners/`

List all promotional banners.

**Permissions:** IsAdminOrReadOnly
**Cached:** Yes

**Response (200):**
```json
[
  {
    "id": 1,
    "image": "https://cdn.example.com/banner1.jpg",
    "category": 1,
    "product_variant": null,
    "product": null,
    "name": "Fruits & Vegetables",
    "description_plaintext": "Fresh produce"
  }
]
```

#### Create Banner

**POST** `/api/products/v1/banners/`

Create a new banner.

**Permissions:** IsAdmin

**Request Body (multipart/form-data):**
```json
{
  "banner_image": "file",
  "category": 1
}
```

**Validation:**
- Banner must be associated with exactly ONE of: category, product_variant, or product

**Response (201):** Created banner object

---

### 10. Admin Product Management

#### List Products (Admin)

**GET** `/api/products/v1/admin-products/`

Admin view with aggregated data.

**Permissions:** IsAdmin
**Cached:** Yes

**Query Parameters:**
- `search` - Search by name, description, variants SKU, variants name
- `ordering` - Order by: name, rating, created_at, updated_at
- Filters from AdminProductFilter

**Response (200):**
```json
[
  {
    "id": 1,
    "name": "Organic Apples",
    "category": "Fruits",
    "subcategory": "Organic Fruits",
    "inventory": 100,
    "discount": "17%",
    "price": 5.99,
    "rating": 4.5,
    "vote_count": 25,
    "status": "Active",
    "primary_image": "https://cdn.example.com/apples.jpg",
    "unit": "kg"
  }
]
```

#### Bulk Update Product Status

**PATCH** `/api/products/v1/admin-products/bulk_status_update/`

Update status for multiple products.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "product_ids": [1, 2, 3],
  "status": "active"
}
```

**Response (200):**
```json
{
  "message": "Successfully updated 3 products.",
  "updated_ids": [1, 2, 3]
}
```

#### Bulk Delete Products

**POST** `/api/products/v1/admin-products/bulk_delete/`

Delete multiple products.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "product_ids": [4, 5, 6]
}
```

**Response (200):**
```json
{
  "message": "Successfully deleted 3 products.",
  "deleted_ids": [4, 5, 6]
}
```

#### Bulk Out of Stock

**POST** `/api/products/v1/admin-products/bulk_out_of_stock/`

Set products to out of stock.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "product_ids": [7, 8, 9]
}
```

**Response (200):**
```json
{
  "message": "Successfully set products to out of stock. Updated 15 stock records.",
  "updated_ids": [7, 8, 9]
}
```

#### Bulk Apply Discount

**POST** `/api/products/v1/admin-products/bulk_discount/`

Apply discount to multiple products.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "product_ids": [1, 2, 3],
  "discount_percentage": 15.5
}
```

**Response (200):**
```json
{
  "message": "Successfully applied 15.5% discount to 6 variants.",
  "updated_ids": [1, 2, 3]
}
```

**Validation:** discount_percentage must be 0-100

---

## Orders API

Base URL: `/api/order/v1/`

### 1. Stock Management

#### List Stocks

**GET** `/api/order/v1/stocks/`

List all stock records.

**Permissions:** IsAdminOrReadOnly

**Response (200):**
```json
[
  {
    "id": 1,
    "warehouse": 1,
    "product_variant": 1,
    "quantity": 100,
    "quantity_allocated": 5,
    "unit": "kg"
  }
]
```

#### Create Stock

**POST** `/api/order/v1/stocks/`

Create a new stock record.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "warehouse": 1,
  "product_variant": 1,
  "quantity": 100,
  "quantity_allocated": 0,
  "unit": "kg"
}
```

**Response (201):** Created stock object

#### Update Stock

**PATCH** `/api/order/v1/stocks/{id}/`

Update stock quantity.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "quantity": 150,
  "quantity_allocated": 10
}
```

**Response (200):** Updated stock object

**Note:** Broadcasts Socket.IO inventory update event.

---

### 2. Checkout

#### List Checkouts

**GET** `/api/order/v1/checkouts/`

List user's active checkouts.

**Permissions:** IsCheckoutOwnerOrAdmin
**Cached:** Yes (varies by user)

**Response (200):**
```json
[
  {
    "id": 1,
    "user": 1,
    "created_at": "2026-02-09T10:00:00Z",
    "coupon": null
  }
]
```

#### Create Checkout

**POST** `/api/order/v1/checkouts/`

Create a new checkout session.

**Permissions:** IsCheckoutOwnerOrAdmin

**Request Body:**
```json
{
  "coupon": 1
}
```

**Response (201):** Created checkout object

**Validation:** Only one active checkout per user allowed.

**Error (400):**
```json
{
  "error": "User already has an active checkout"
}
```

#### Update Checkout

**PATCH** `/api/order/v1/checkouts/{id}/`

Update checkout (e.g., apply coupon).

**Permissions:** IsCheckoutOwnerOrAdmin

**Request Body:**
```json
{
  "coupon": 2
}
```

**Response (200):** Updated checkout object

#### Delete Checkout

**DELETE** `/api/order/v1/checkouts/{id}/`

Delete a checkout session.

**Permissions:** IsCheckoutOwnerOrAdmin

**Response (204):** No content

---

### 3. Checkout Lines (Cart Items)

#### List Cart Items

**GET** `/api/order/v1/checkout-lines/`

List items in checkout cart.

**Permissions:** IsCheckoutOwnerOrAdmin
**Cached:** Yes (varies by user)

**Response (200):**
```json
[
  {
    "id": 1,
    "checkout": 1,
    "product_variant_id": 1,
    "quantity": 2,
    "product_variant_details": {
      "id": 1,
      "name": "Organic Apples 1kg",
      "price": 5.99,
      "discounted_price": 4.99,
      "image": "https://cdn.example.com/apples.jpg"
    }
  }
]
```

#### Add to Cart

**POST** `/api/order/v1/checkout-lines/`

Add item to checkout cart.

**Permissions:** IsCheckoutOwnerOrAdmin

**Request Body:**
```json
{
  "product_variant_id": 1,
  "quantity": 2
}
```

**Response (201):** Created checkout line

**Validation:**
- Quantity must be positive
- Stock must be available

#### Update Cart Item

**PATCH** `/api/order/v1/checkout-lines/{id}/`

Update quantity of cart item.

**Permissions:** IsCheckoutOwnerOrAdmin

**Request Body:**
```json
{
  "quantity": 3
}
```

**Response (200):** Updated checkout line

**Note:**
- Supports negative values for decrements
- Auto-deletes when quantity reaches 0 or below

#### Remove from Cart

**DELETE** `/api/order/v1/checkout-lines/{id}/`

Remove item from cart.

**Permissions:** IsCheckoutOwnerOrAdmin

**Response (204):** No content

---

### 4. Orders

#### List Orders

**GET** `/api/order/v1/orders/`

List user's orders (admin sees all).

**Permissions:** IsCustomerOrAdmin, IsOwnerOrAdmin
**Cached:** Yes (varies by user)

**Query Parameters:**
- `status` - Filter by order status
- Filters from OrderFilter
- `search` - Search by id, username, email, phone, razorpay_order_id

**Response (200):**
```json
[
  {
    "id": 1,
    "user_name": "John Doe",
    "status": "shipped",
    "total": 29.95,
    "created_at": "2026-02-08T10:00:00Z",
    "payment_status": "Paid",
    "delivery_assigned": true
  }
]
```

#### Get Order Details

**GET** `/api/order/v1/orders/{id}/`

Retrieve detailed order information.

**Permissions:** IsCustomerOrAdmin, IsOwnerOrAdmin
**Cached:** Yes (varies by user)

**Response (200):**
```json
{
  "id": 1,
  "user": 1,
  "customer_info": {
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890"
  },
  "shipping_address": {...},
  "billing_address": {...},
  "status": "shipped",
  "total": 29.95,
  "order_summary_detail": [
    {
      "product_variant_id": 1,
      "quantity": 2,
      "price": 4.99,
      "name": "Organic Apples 1kg",
      "image": "https://cdn.example.com/apples.jpg"
    }
  ],
  "payment_info": {
    "razorpay_order_id": "order_xxx",
    "razorpay_payment_id": "pay_xxx",
    "payment_status": "Paid"
  },
  "delivery_assigned_to": "Driver One",
  "partner_number": "+1234567890",
  "pickup_from": "Main Warehouse",
  "warehouse_details": {...},
  "refund_details_full": null,
  "created_at": "2026-02-08T10:00:00Z",
  "updated_at": "2026-02-09T10:00:00Z"
}
```

#### Create Order

**POST** `/api/order/v1/orders/`

Create order from checkout (rarely used directly - see Payment Initiate).

**Permissions:** IsCustomerOrAdmin

**Request Body:**
```json
{
  "shipping_address_id": 1,
  "billing_address_id": 1
}
```

**Response (201):** Created order object

#### Update Order

**PATCH** `/api/order/v1/orders/{id}/`

Update order (only before shipping).

**Permissions:** IsCustomerOrAdmin, IsOwnerOrAdmin

**Request Body:**
```json
{
  "shipping_address_id": 2
}
```

**Response (200):** Updated order object

#### Update Order Status (Admin)

**PATCH** `/api/order/v1/orders/{id}/update-status/`

Admin endpoint to update order status.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "status": "delivered"
}
```

**Response (200):** Updated order details

**Valid Statuses:** pending, processing, shipped, delivered, cancelled, failed

#### Bulk Update Order Status

**PATCH** `/api/order/v1/orders/bulk_status_update/`

Update status for multiple orders.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "order_ids": [1, 2, 3],
  "status": "processing"
}
```

**Response (200):**
```json
{
  "message": "Successfully updated 3 orders.",
  "updated_ids": [1, 2, 3]
}
```

---

### 5. Order Ratings

#### List Order Ratings

**GET** `/api/order/v1/{order_id}/ratings/`

List ratings for an order.

**Permissions:** IsCustomerOrAdmin, IsOwnerOrAdmin
**Cached:** Yes (varies by user)

**Response (200):**
```json
[
  {
    "id": 1,
    "user": 1,
    "order": 1,
    "stars": 5,
    "body": "Fast delivery, great service!",
    "created_at": "2026-02-09T10:00:00Z",
    "updated_at": "2026-02-09T10:00:00Z"
  }
]
```

#### Create Order Rating

**POST** `/api/order/v1/{order_id}/ratings/`

Rate a delivered order.

**Permissions:** IsCustomerOrAdmin

**Request Body:**
```json
{
  "stars": 5,
  "body": "Fast delivery, great service!"
}
```

**Response (201):** Created rating object

**Validation:**
- Stars must be between 1 and 5
- Order status must be "Delivered" or "delivered"
- One rating per user per order

---

### 6. Wishlist

#### List Wishlist

**GET** `/api/order/v1/wishlist/`

List user's wishlist items.

**Permissions:** IsCustomerOrAdmin, IsOwnerOrAdmin
**Cached:** Yes (varies by user)

**Response (200):**
```json
[
  {
    "id": 1,
    "user": 1,
    "product_variant_id": 5,
    "name": "Organic Bananas 500g",
    "price": 3.99,
    "image": "https://cdn.example.com/bananas.jpg",
    "image_alt": "Organic bananas"
  }
]
```

#### Add to Wishlist

**POST** `/api/order/v1/wishlist/`

Add item to wishlist.

**Permissions:** IsCustomerOrAdmin

**Request Body:**
```json
{
  "product_variant_id": 5
}
```

**Response (201):** Created wishlist item

#### Remove from Wishlist

**DELETE** `/api/order/v1/wishlist/{id}/`

Remove item from wishlist.

**Permissions:** IsCustomerOrAdmin, IsOwnerOrAdmin

**Response (204):** No content

---

### 7. Coupons

#### List Coupons

**GET** `/api/order/v1/coupons/`

List available coupons.

**Permissions:** IsAdminOrReadOnly
**Cached:** Yes

**Query Parameters:**
- Filters from CouponFilter (status, date range)

**Response (200):**
```json
[
  {
    "id": 1,
    "name": "SUMMER20",
    "description": "20% off summer sale",
    "discount_percentage": 20.0,
    "limit": 100,
    "status": true,
    "usage": 25,
    "start_date": "2026-06-01",
    "end_date": "2026-08-31",
    "created_at": "2026-05-01T00:00:00Z",
    "updated_at": "2026-02-09T10:00:00Z"
  }
]
```

**Visibility:**
- Admins: All coupons
- Customers: Only active coupons within date range

#### Create Coupon(s)

**POST** `/api/order/v1/coupons/`

Create one or multiple coupons.

**Permissions:** IsAdmin

**Request Body (Single):**
```json
{
  "name": "FALL15",
  "description": "15% off fall season",
  "discount_percentage": 15.0,
  "limit": 50,
  "status": true,
  "start_date": "2026-09-01",
  "end_date": "2026-11-30"
}
```

**Request Body (Bulk):**
```json
[
  {
    "name": "WINTER10",
    "discount_percentage": 10.0,
    "limit": 200
  },
  {
    "name": "WINTER15",
    "discount_percentage": 15.0,
    "limit": 100
  }
]
```

**Response (201):** Created coupon(s)

#### Bulk Delete Coupons

**POST** `/api/order/v1/coupons/bulk_delete/`

Delete multiple coupons.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "coupon_ids": [1, 2, 3]
}
```

**Response (200):**
```json
{
  "message": "Successfully deleted 3 coupons.",
  "deleted_count": 3
}
```

---

### 8. Payment & Checkout

#### Initiate Payment

**POST** `/api/order/v1/checkout/`

Initiate Razorpay payment and create order.

**Permissions:** IsCustomer
**Throttle:** PaymentThrottle

**Request Body:** Empty POST

**Response (201 - New Payment):**
```json
{
  "razorpay_order_id": "order_xxx",
  "razorpay_key": "RAZORPAY_KEY_ID",
  "amount": 2995,
  "currency": "INR",
  "order_id": 1
}
```

**Response (200 - Resume Pending):**
```json
{
  "message": "Payment resumption for a pending order.",
  "razorpay_order_id": "order_xxx",
  "razorpay_key": "RAZORPAY_KEY_ID",
  "amount": 2995,
  "currency": "INR",
  "order_id": 1
}
```

**Error Responses:**
- `400` - Invalid checkout or address
- `503` - Payment service unavailable

**Behavior:**
- Creates order from checkout items
- Initiates Razorpay payment
- Resumes pending order if exists
- Amount in paise (smallest currency unit)

#### Verify Payment

**POST** `/api/order/v1/payment/verify/`

Verify Razorpay payment and complete order.

**Permissions:** IsCustomer
**Throttle:** PaymentThrottle

**Request Body:**
```json
{
  "razorpay_payment_id": "pay_xxx",
  "razorpay_order_id": "order_xxx",
  "razorpay_signature": "signature_xxx"
}
```

**Response (200):**
```json
{
  "success": true,
  "order_id": 1,
  "message": "Payment successful and order confirmed"
}
```

**Error Responses:**
- `400` - Missing fields or invalid signature
- `404` - Order not found
- `400` - Checkout session expired

**Behavior:**
- Verifies payment signature
- Confirms order status to "shipped"
- Clears checkout session
- Creates delivery record

---

### 9. Webhooks

#### Razorpay Webhook

**POST** `/api/order/v1/webhooks/razorpay/`

Webhook endpoint for Razorpay events.

**Permissions:** AllowAny (signature verified)
**Authentication:** CSRF exempt, HMAC-SHA256 signature

**Headers:**
- `x-razorpay-signature` - HMAC signature

**Events Handled:**

**payment.authorized:**
- Finalizes order
- Converts reservations to order lines
- Creates delivery record
- Marks order as "shipped"
- Deletes checkout session

**payment.failed:**
- Marks order as "failed"
- Restores allocated stock
- Deletes reservations

**payment.captured:**
- Updates pending order to "shipped"

**Response (200):**
```json
{
  "status": "ok"
}
```

**Error (400):**
```json
{
  "error": "Unauthorized"
}
```

---

### 10. Admin Refund

**POST** `/api/order/v1/admin/refund/{order_id}/`

Admin endpoint to initiate full refund.

**Permissions:** IsAdmin
**Throttle:** PaymentThrottle

**Request Body:** Empty POST

**Response (202 - Queued):**
```json
{
  "status": "queued"
}
```

**Response (200 - Already Refunded):**
```json
{
  "status": "already_refunded",
  "refund_id": "rfnd_xxx"
}
```

**Error Responses:**
- `404` - Order not found
- `400` - No Razorpay payment_id or invalid total

**Behavior:**
- Initiates async refund via Razorpay
- Full refund of order amount
- Idempotency guard prevents duplicates
- Async task via django-q

---

## Inventory API

Base URL: `/api/inventory/v1/`

### 1. Warehouses

#### List Warehouses

**GET** `/api/inventory/v1/warehouses/`

List all warehouses.

**Permissions:** IsAdminOrReadOnly
**Cached:** Yes

**Query Parameters:**
- `name` - Filter by warehouse name
- `is_private` - Filter by privacy status (boolean)

**Response (200):**
```json
[
  {
    "id": 1,
    "name": "Main Warehouse",
    "phone": "+1234567890",
    "slug": "main-warehouse",
    "address": {
      "id": 1,
      "street": "123 Storage St",
      "city": "New York",
      "state": "NY",
      "country": "US",
      "postal_code": "10001"
    },
    "email": "warehouse@example.com",
    "click_and_collect_option": true,
    "is_private": false,
    "is_active": true,
    "stock_status": "45 distinct products in stock"
  }
]
```

#### Create Warehouse

**POST** `/api/inventory/v1/warehouses/`

Create a new warehouse.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "name": "North Warehouse",
  "phone": "+1234567890",
  "slug": "north-warehouse",
  "address": {
    "street": "456 Storage Ave",
    "city": "Boston",
    "state": "MA",
    "country": "US",
    "postal_code": "02101"
  },
  "email": "north@example.com",
  "click_and_collect_option": true,
  "is_private": false,
  "is_active": true
}
```

**Response (201):** Created warehouse object

---

### 2. Shipping Zones

#### List Shipping Zones

**GET** `/api/inventory/v1/shipping-zones/`

List all shipping zones.

**Permissions:** IsAdminOrReadOnly
**Cached:** Yes

**Response (200):**
```json
[
  {
    "id": 1,
    "name": "North America",
    "countries": ["US", "CA", "MX"],
    "default": false,
    "description": "Shipping zone for North America"
  }
]
```

#### Create Shipping Zone

**POST** `/api/inventory/v1/shipping-zones/`

Create a new shipping zone.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "name": "Europe",
  "countries": ["GB", "FR", "DE", "IT"],
  "default": false,
  "description": "European shipping zone"
}
```

**Response (201):** Created shipping zone

**Note:** Countries use ISO 3166-1 alpha-2 codes.

---

### 3. Warehouse Shipping Zones

#### List Associations

**GET** `/api/inventory/v1/warehouse-shipping-zones/`

List warehouse-shipping zone associations.

**Permissions:** IsAdminOrReadOnly
**Cached:** Yes

**Response (200):**
```json
[
  {
    "id": 1,
    "warehouse": 1,
    "shipping_zone": 1,
    "warehouse_name": "Main Warehouse",
    "shipping_zone_name": "North America"
  }
]
```

#### Create Association

**POST** `/api/inventory/v1/warehouse-shipping-zones/`

Associate warehouse with shipping zone.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "warehouse": 1,
  "shipping_zone": 2
}
```

**Response (201):** Created association

---

### 4. Shipping Methods

#### List Shipping Methods

**GET** `/api/inventory/v1/shipping-methods/`

List all shipping methods.

**Permissions:** IsAdminOrReadOnly
**Cached:** Yes

**Query Parameters:**
- `name` - Filter by method name
- `shipping_type` - Filter by shipping type
- `tax_class_id` - Filter by tax class ID

**Response (200):**
```json
[
  {
    "id": 1,
    "shipping_zone_id": 1,
    "name": "Standard Shipping",
    "shipping_type": "standard",
    "minimum_order_weight": 0.0,
    "maximum_order_weight": 50.0,
    "minimum_delivery_days": 3,
    "maximum_delivery_days": 5,
    "description": "Standard delivery in 3-5 business days",
    "tax_class_id": 1
  }
]
```

#### Create Shipping Method

**POST** `/api/inventory/v1/shipping-methods/`

Create a new shipping method.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "shipping_zone_id": 1,
  "name": "Express Shipping",
  "shipping_type": "express",
  "minimum_order_weight": 0.0,
  "maximum_order_weight": 25.0,
  "minimum_delivery_days": 1,
  "maximum_delivery_days": 2,
  "description": "Express delivery in 1-2 business days",
  "tax_class_id": 1
}
```

**Response (201):** Created shipping method

**Validation:** minimum_order_weight must be ≤ maximum_order_weight

---

## Delivery API

Base URL: `/api/delivery/v1/`

### 1. Delivery Profiles

#### List Delivery Profiles

**GET** `/api/delivery/v1/delivery-profiles/`

List delivery partner profiles.

**Permissions:** IsDeliveryOrAdmin

**Response (200):**
```json
[
  {
    "id": 1,
    "user": 10,
    "username": "driver1",
    "email": "driver@example.com",
    "vehicle_type": "motorcycle",
    "vehicle_number": "ABC-1234",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "availability_status": "online",
    "warehouse": 1,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-02-09T10:00:00Z"
  }
]
```

#### Get Current Profile

**GET** `/api/delivery/v1/delivery-profiles/me/`

Get authenticated delivery partner's profile.

**Permissions:** IsDelivery

**Response (200):** Current user's delivery profile

#### Update Current Profile

**PATCH** `/api/delivery/v1/delivery-profiles/me/`

Update current delivery partner's profile.

**Permissions:** IsDelivery

**Request Body:**
```json
{
  "vehicle_type": "car",
  "vehicle_number": "XYZ-5678",
  "availability_status": "on_delivery"
}
```

**Response (200):** Updated profile

#### Change Password

**POST** `/api/delivery/v1/delivery-profiles/change-password/`

Change delivery partner password.

**Permissions:** IsDelivery

**Request Body:**
```json
{
  "current_password": "oldpassword",
  "new_password": "newpassword123",
  "new_password_confirm": "newpassword123"
}
```

**Response (200):**
```json
{
  "message": "Password changed successfully"
}
```

**Validation:**
- Current password must be correct
- New passwords must match
- New password min 8 characters

---

### 2. Deliveries

#### List Deliveries

**GET** `/api/delivery/v1/deliveries/`

List deliveries (filtered by role).

**Permissions:** IsAuthenticated
**Cached:** Yes (varies by user)

**Query Parameters:**
- `status` - Filter by status (pending, assigned, at_pickup, picked_up, out_for_delivery, delivered, failed)
- `delivery_partner__id` - Filter by partner ID
- `order__id` - Filter by order ID

**Response (200):**
```json
[
  {
    "id": 1,
    "order": 1,
    "order_details": {
      "id": 1,
      "user": 1,
      "status": "shipped",
      "total_amount": 29.95
    },
    "delivery_partner": 10,
    "delivery_partner_details": {
      "id": 10,
      "username": "driver1",
      "email": "driver@example.com"
    },
    "delivery_partner_profile": {
      "id": 1,
      "vehicle_type": "motorcycle",
      "vehicle_number": "ABC-1234",
      "availability_status": "on_delivery"
    },
    "status": "out_for_delivery",
    "delivery_fee": 5.00,
    "assigned_at": "2026-02-09T10:00:00Z",
    "picked_up_at": "2026-02-09T10:30:00Z",
    "delivered_at": null,
    "proof_of_delivery": null,
    "notes": "",
    "created_at": "2026-02-09T09:00:00Z",
    "updated_at": "2026-02-09T10:30:00Z"
  }
]
```

**Filtering by Role:**
- Admin: All deliveries
- Delivery Partner: Only assigned deliveries
- Customer: Only their order deliveries

#### Create Delivery

**POST** `/api/delivery/v1/deliveries/`

Create a new delivery assignment.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "order": 1,
  "delivery_partner": 10,
  "status": "assigned",
  "delivery_fee": 5.00,
  "notes": "Handle with care"
}
```

**Response (201):** Created delivery object

#### Update Delivery Status

**PATCH** `/api/delivery/v1/deliveries/{id}/`

Update delivery status.

**Permissions:** IsAdmin or assigned delivery partner

**Request Body:**
```json
{
  "status": "picked_up"
}
```

**Response (200):** Updated delivery object

**Status Transitions:**
| From | Valid Transitions | Allowed Roles |
|------|-------------------|---------------|
| pending | assigned | Admin |
| assigned | at_pickup, pending | Admin, Partner |
| at_pickup | picked_up, pending | Admin, Partner |
| picked_up | out_for_delivery | Admin, Partner |
| out_for_delivery | delivered, failed | Admin, Partner |
| delivered | (none) | Terminal |
| failed | (none) | Terminal |

#### Bulk Assign Deliveries

**POST** `/api/delivery/v1/deliveries/bulk-assign/`

Assign multiple orders to a delivery partner.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "order_ids": [1, 2, 3],
  "delivery_partner_id": 10
}
```

**Response (200):**
```json
{
  "message": "Successfully assigned 3 orders to driver1."
}
```

#### Update Location (Real-time Tracking)

**POST** `/api/delivery/v1/deliveries/{id}/update_location/`

Update delivery partner's real-time location.

**Permissions:** IsDelivery (assigned partner only)

**Request Body:**
```json
{
  "latitude": 40.7580,
  "longitude": -73.9855
}
```

**Response (200):**
```json
{
  "message": "Location updated successfully (cached in Redis)",
  "location": {
    "delivery_id": 1,
    "latitude": 40.7580,
    "longitude": -73.9855,
    "timestamp": "2026-02-09T15:41:26.375228",
    "user_id": 10,
    "order_id": 1,
    "partner_name": "driver1"
  },
  "storage": {
    "cache": "Redis (primary storage)",
    "db_persistence": "Every 10 updates",
    "current_update": 5,
    "next_db_persist": 10
  }
}
```

**Storage Strategy:**
- Primary: Redis cache (real-time, <1ms)
- Secondary: DB persistence every 10 updates
- Broadcast: Redis pub/sub → Socket.IO

**Allowed Statuses:** at_pickup, picked_up, out_for_delivery

**Error (400):**
```json
{
  "error": "Can only update location when status is at_pickup, picked_up, or out_for_delivery"
}
```

---

### 3. Admin Delivery Partner Management

#### List Delivery Partners (Admin)

**GET** `/api/delivery/v1/admin-partners/`

Admin view of delivery partners.

**Permissions:** IsAdmin

**Query Parameters:**
- `availability_status` - Filter by status (online, offline, on_delivery)
- `warehouse` - Filter by warehouse ID
- `search` - Search by username, phone, email
- `ordering` - Order by created_at, username

**Response (200):**
```json
[
  {
    "id": 1,
    "name": "driver1",
    "phone": "+1234567890",
    "status": "Active",
    "warehouse": 1,
    "active_orders": 2,
    "completed_orders": 150,
    "vehicle_type": "motorcycle",
    "vehicle_number": "ABC-1234",
    "availability_status": "on_delivery",
    "created_at": "2026-01-01T00:00:00Z"
  }
]
```

#### Create Delivery Partner (Admin)

**POST** `/api/delivery/v1/admin-partners/`

Create a new delivery partner account.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "username": "driver2",
  "email": "driver2@example.com",
  "password": "password123",
  "phone_number": "+1234567890",
  "warehouse": 1,
  "vehicle_type": "car",
  "vehicle_number": "DEF-9012"
}
```

**Response (201):** Created delivery partner

**Validation:** Password must be at least 8 characters.

#### Update Delivery Partner (Admin)

**PATCH** `/api/delivery/v1/admin-partners/{id}/`

Update delivery partner details.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "warehouse": 2,
  "availability_status": "offline",
  "vehicle_type": "van"
}
```

**Response (200):** Updated partner

#### Bulk Actions on Partners

**POST** `/api/delivery/v1/admin-partners/bulk_action/`

Perform bulk actions on delivery partners.

**Permissions:** IsAdmin

**Request Body:**
```json
{
  "partner_ids": [1, 2, 3],
  "action": "activate"
}
```

**Actions:** activate, deactivate, delete

**Response (200):**
```json
{
  "message": "Successfully updated 3 partners.",
  "partner_ids": [1, 2, 3]
}
```

---

## System Endpoints

### Health Check

**GET** `/api/health/`

Health check endpoint for monitoring.

**Permissions:** AllowAny

**Response (200):**
```json
{
  "status": "healthy",
  "timestamp": "2026-02-09T10:00:00Z"
}
```

---

### API Schema

**GET** `/api/schema/`

OpenAPI schema for the entire API.

**Permissions:** AllowAny

**Response:** OpenAPI 3.0 JSON schema

---

### API Documentation

#### Swagger UI

**GET** `/api/docs/swagger/`

Interactive Swagger UI documentation.

**Permissions:** AllowAny

#### ReDoc

**GET** `/api/docs/redoc/`

ReDoc-style API documentation.

**Permissions:** AllowAny

---

## Appendices

### A. User Roles

- **customer** - Regular customers who can browse and purchase
- **delivery** - Delivery partners who fulfill orders
- **admin** - Administrators with full system access

### B. Order Status Values

- `pending` - Order created, payment pending
- `processing` - Payment received, being processed
- `shipped` - Order shipped/ready for delivery
- `delivered` - Successfully delivered
- `cancelled` - Cancelled by user or admin
- `failed` - Payment or delivery failed

### C. Delivery Status Values

- `pending` - Delivery not yet assigned
- `assigned` - Assigned to delivery partner
- `at_pickup` - Partner at pickup location
- `picked_up` - Order picked up
- `out_for_delivery` - On the way to customer
- `delivered` - Successfully delivered
- `failed` - Delivery failed

### D. Availability Status Values

- `online` - Available for assignments
- `offline` - Not available
- `on_delivery` - Currently delivering

### E. Cache Version Keys

The following cache version keys are used across the application:

- `user_profile` - User profile data
- `admin_phones` - Admin phone numbers
- `address` - User addresses
- `admin_customers` - Customer list/details
- `product_type` - Product types
- `product_media` - Product media
- `product_variant` - Product variants
- `product_variant_discounts` - Discounted variants
- `products` - Products
- `categories` - Categories
- `collection` - Collections
- `collection_products` - Collection products
- `product_rating` - Product ratings
- `banner` - Banners
- `stocks` - Stock records
- `checkout` - Checkout sessions
- `checkoutlines` - Checkout lines
- `reservations` - Stock reservations
- `order` - Orders
- `orderlines` - Order lines
- `wishlist` - Wishlist items
- `coupons` - Coupons
- `order_rating` - Order ratings
- `warehouse` - Warehouses
- `shipping_zone` - Shipping zones
- `warehouse_shipping_zone` - Warehouse-zone associations
- `shipping_method` - Shipping methods
- `delivery` - Deliveries
- `delivery_profile` - Delivery profiles

### F. Real-time Features

The application uses Socket.IO for real-time updates:

**Events:**
- `inventory_update` - Stock quantity changes
- `price_update` - Variant price changes
- `location_update` - Delivery partner location updates

**Subscriptions:**
- Clients can subscribe to specific channels
- Redis pub/sub backend for scalability
- Real-time location tracking for deliveries

---

## Support & Resources

- **OpenAPI Schema:** `/api/schema/`
- **Swagger UI:** `/api/docs/swagger/`
- **ReDoc:** `/api/docs/redoc/`
- **Health Check:** `/api/health/`

---

**Document Version:** 1.0
**Generated:** 2026-02-09
**API Version:** v1
