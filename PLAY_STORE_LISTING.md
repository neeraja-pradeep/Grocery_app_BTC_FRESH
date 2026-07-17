# Easy Gro — Play Store Listing Copy

Package name: `com.nexotech.btcfresh`

---

## Short description

> Play Store limit: **80 characters**

**Primary:**

```
Fresh groceries delivered fast — shop daily essentials with easy UPI checkout.
```
*(79 characters)*

**Alternates:**

```
Groceries, fruits & daily essentials — delivered fresh to your door, fast.
```
*(74 characters)*

```
Order fresh groceries online. Quick delivery, secure payments, easy reorder.
```
*(76 characters)*

---

## Full description

> Play Store limit: **4000 characters**

```
Easy Gro — Fresh Groceries, Delivered to Your Door

Shopping for groceries should be simple. Easy Gro brings your neighborhood store to your phone, so you can order fresh fruits, vegetables, dairy, staples, snacks, and daily essentials in just a few taps — and have them delivered straight to your home.

Whether you're stocking up for the week or grabbing last-minute ingredients for dinner, Easy Gro makes the whole experience fast, friendly, and reliable.

🛒 Why shop with Easy Gro?

• Wide selection of fresh products — fruits, vegetables, dairy, bakery, beverages, snacks, household essentials, and more, all in one place.
• Browse by category — quickly find what you need with a clean, category-wise layout designed for fast shopping.
• Smart search — type or use voice search to find products instantly, even when you're on the go.
• Save your favourites — add items to your wishlist so your regulars are always one tap away.
• Coupons & offers — unlock savings with promo codes, daily deals, and curated discount sections.
• Easy address management — save multiple delivery addresses and pick your exact location on the map.
• Secure, flexible payments — pay your way with UPI (Google Pay, PhonePe, Paytm), credit/debit cards, net banking, and more, powered by Razorpay's trusted payment gateway.
• Real-time order tracking — know exactly where your order is, from confirmation to your doorstep.
• Order history & quick reorder — past orders are saved so you can repeat a previous purchase with a single tap.

📍 Built for everyday convenience

Easy Gro is designed for busy households who want quality groceries without the queue. Skip the trip to the store and let us bring fresh produce, pantry staples, and household must-haves directly to you.

🚚 Fast, reliable delivery

Place your order and we'll pick, pack, and deliver — usually within hours. Live delivery status updates keep you informed every step of the way.

🔒 Safe and secure

Your data and payments are protected with industry-standard encryption. All transactions go through Razorpay, one of India's most trusted payment platforms.

✨ Features at a glance

✓ Fresh fruits, vegetables, dairy & daily essentials
✓ Category-wise browsing
✓ Text & voice search
✓ Wishlist for your favourite items
✓ Promo codes, coupons & seasonal offers
✓ Multiple saved addresses with map-based pin location
✓ UPI, cards, and wallet payments via Razorpay
✓ Live order tracking
✓ Order history & one-tap reorder
✓ Smooth, ad-free shopping experience

📲 Download Easy Gro today and discover a simpler way to shop for groceries. Fresh products, fair prices, and fast delivery — all from one app.

Have feedback or questions? We'd love to hear from you — reach out to our support team anytime through the app.
```

---

## Notes before publishing

1. **Brand name** — uses "Easy Gro" (the `android:label` in `AndroidManifest.xml`). If the Play Store listing name is different, swap it everywhere above.
2. **Live order tracking** — copy says "real-time tracking". If tracking isn't fully wired up in v1, soften to "track your order status".
3. **Voice search** — included because `RECORD_AUDIO` permission is declared. Drop the bullet if voice search isn't user-facing in v1.
4. **Razorpay name** — Play Store allows naming the payment provider. Replace with "a trusted payment gateway" if you want to stay vendor-neutral.
5. **No medical, health, or superlative ("best", "cheapest") claims** — copy is written to comply with Play Store content policy.

---

## Quick reference

| Field             | Value                                                                                 |
|-------------------|----------------------------------------------------------------------------------------|
| App name          | Easy Gro                                                                              |
| Package name      | `com.nexotech.btcfresh`                                                               |
| Privacy policy    | `https://nexotech.cc/privacy-policy` *(use apex, not `www.`, until SSL cert is fixed)* |
| Category          | Shopping / Food & Drink                                                               |
| Payment provider  | Razorpay (UPI, cards, wallets, net banking)                                           |
