# Integration Document \- BTC Grocery

The Figma design for this assignment can be found here:

https://www.figma.com/design/mrrqGcoTKQEgGMVOKWxAIR/btc-grocery?node-id=106-1388\&p=f\&t=MwbKebTHE31q50RF-0  
The screens provided in the Figma file show:

## **API Endpoints**

All endpoints are non-authenticated and return JSON responses. Use REST GET calls to fetch and render the UI data. The base URL: http://156.67.104.149:8080 and use the extension given below, test these endpoints in postman to get an idea on the response of each endpoints.

**User IDs**

Superadmin \- 1  
Customer \- 2

**Headers \-**  
 dev \- {user\_id}  
If-Modified-Since \- Sun, 26 Oct 2025 09:51:00 GMT

## Note:- The timestamp mentioned here must be the timestamp fetched from the header of the responses.  

![][image1]

**Customer Application** 

---

### **Screen : Login User**

#### **a) Login**

**Endpoint:**  
[`http://156.67.104.149:8080/api/docs/swagger/#/auth/auth_signin_create`](http://156.67.104.149:8080/api/docs/swagger/#/auth/auth_signin_create)

**b) Login with OTP**  
**Endpoint:**

- **Send OTP**

[`http://156.67.104.149:8080/api/docs/swagger/#/auth/auth_send_otp_create`](http://156.67.104.149:8080/api/docs/swagger/#/auth/auth_send_otp_create)

- **`Verify OTP`**

[`http://156.67.104.149:8080/api/docs/swagger/#/auth/auth_verify_otp_create`](http://156.67.104.149:8080/api/docs/swagger/#/auth/auth_verify_otp_create)

**c) Signup**

**Endpoint:**  
`http://156.67.104.149:8080/api/docs/swagger/#/auth/auth_signup_create`

**d) Address**

**Endpoint;**  
[`http://156.67.104.149:8080/api/docs/swagger/#/auth/auth_address_create`](http://156.67.104.149:8080/api/docs/swagger/#/auth/auth_address_create)

`Required Fields: first_name, last_name, street_address1, street_address2 and address_type[home, work and other]`

---

### **Screen : Home**

1) **Shop by category**

**Endpoint:**

[`http://156.67.104.149:8080/api/docs/swagger/#/products/products_category_list`](http://156.67.104.149:8080/api/docs/swagger/#/products/products_category_list)

2) **Mega Fresh Offers**

**Endpoint:**

`http://156.67.104.149:8080/api/docs/swagger/#/products/products_variants_discounts_retrieve`

---

### **Screen : Category**

1) **Category Listing**

**Endpoint:**

[`http://156.67.104.149:8080/api/docs/swagger/#/products/products_category_list`](http://156.67.104.149:8080/api/docs/swagger/#/products/products_category_list)

2) **Category wise product listing** 

**Endpoint:**

[`http://156.67.104.149:8080/api/docs/swagger/#/products/products_list`](http://156.67.104.149:8080/api/docs/swagger/#/products/products_list)

---

### **Screen : Wishlist**

1) **My whishlist**

**Endpoint:**

[`http://156.67.104.149:8080/api/docs/swagger/#/order/order_wishlist_list`](http://156.67.104.149:8080/api/docs/swagger/#/order/order_wishlist_list)

2) **Add to wishlist** 

**Endpoints:**

`http://156.67.104.149:8080/api/docs/swagger/#/order/order_wishlist_create`

---

### **Screen : Profile**

1) **My profile**

**Endpoint:**

`http://156.67.104.149:8080/api/docs/swagger/#/auth/auth_profile_retrieve`

---

### **Screen : Active orders**

1) **Active orders**

**Endpoint:**

[`http://156.67.104.149:8080/api/docs/swagger/#/order/order_orders_list`](http://156.67.104.149:8080/api/docs/swagger/#/order/order_orders_list)

`Status:- active`

2) **Pending orders** 

**Endpoint:**

[`http://156.67.104.149:8080/api/docs/swagger/#/order/order_orders_list`](http://156.67.104.149:8080/api/docs/swagger/#/order/order_orders_list)  
`Status:- Pending` 

---

### **Screen : Item Page**

1) **Product detail**

**Endpoint:**

`http://156.67.104.149:8080/api/docs/swagger/#/products/products_variants_retrieve`

`Fields necessary:- media.image, name, price, prod_description, product_rating`

---

### **Screen : Cart**

1) **Add to cart**

**Endpoint:**

`http://156.67.104.149:8080/api/docs/swagger/#/order/order_checkout_lines_create`

2) **Display cart**

**Endpoint:**

[`http://156.67.104.149:8080/api/docs/swagger/#/order/order_checkout_lines_list`](http://156.67.104.149:8080/api/docs/swagger/#/order/order_checkout_lines_list)

3) **`Update cart`**

`Endpoint`

[`http://156.67.104.149:8080/api/docs/swagger/#/order/order_checkout_lines_partial_update`](http://156.67.104.149:8080/api/docs/swagger/#/order/order_checkout_lines_partial_update)

4) **`Place order`**

`Endpoint`

`http://156.67.104.149:8080/api/docs/swagger/#/order/order_checkout_create`

---

[image1]: <data:image/png;base64,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>