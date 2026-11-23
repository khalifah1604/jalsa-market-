# Jalsa Market: Supabase Setup

## 1. Create the Supabase project

1. Create a project at https://supabase.com.
2. Open **Project Settings > API**.
3. Copy the **Project URL** and **publishable/anon key**.
4. Replace the empty values in `CONFIG` near the top of `index.html`.

Never put the service-role key in this browser application.

## 2. Enable authentication

For the production login, use **email OTP/magic links**. This requires no SMS or Twilio provider.

In **Authentication > Providers**:

1. Ensure the **Email** provider is enabled.
2. Under **URL Configuration**, add the deployed site URL and `http://localhost:4173` for local testing.
3. Use email OTP or Supabase magic-link authentication.

The browser flow should be:

1. Enter email, name, and phone during signup.
2. Call `supabase.auth.signInWithOtp({ email })`.
3. Open the confirmation/magic link in the email.
4. Load the `profiles` record by `auth.uid()`.
5. For vendor login, load `vendors` by `owner_id = auth.uid()`.
6. For a vendor without a profile, collect business details and create the profile/vendor records after OTP verification.

Name and phone values are saved for future WhatsApp use and account lookup. The Supabase session comes from email OTP/magic-link authentication.

## 3. Create the database

Open **SQL Editor** and run `supabase_schema.sql`.

The schema creates:

- `profiles`
- `vendors`
- `categories`
- `events`
- `announcements`
- `products`
- `product_images`
- `saved_products`
- `carts`
- `cart_items`
- `storefront_views`
- `product_views`
- `whatsapp_clicks`
- `user_consents`
- `admin_users`
- `vendor_verification_logs`
- `reports`
- `platform_settings`

## 4. Create storage buckets

In **Storage**, create these public buckets:

| Bucket | Used for |
|---|---|
| `vendor-logos` | Vendor logos |
| `store-covers` | Vendor cover images |
| `product-images` | Product images |

Suggested storage policy:

- Everyone may read public bucket objects.
- Authenticated owners may upload/update/delete objects only inside their vendor ID folder.

## 5. Add initial data

Add the Jalsa categories, an active event, and platform settings through the Supabase dashboard or SQL.

The app reads:

- categories from `categories`
- the active event from `events`
- announcements from `announcements`
- approved vendors from `vendors.status = 'approved'`
- available products linked to approved vendors

## 6. Create an administrator

1. Create a Supabase Auth user for the administrator.
2. Insert that user's UUID into `admin_users`.
3. Keep the administrator email/password login for the restricted admin route.

## 7. Remaining project work

### High priority

- Replace name/phone-only login with real email OTP/magic-link sessions.
- Apply the SQL schema and RLS policies.
- Configure storage buckets and policies.
- Remove demo fallback/auth code or clearly keep it for local preview only.
- Test signup, login, logout, cart, saved products, uploads, and vendor verification.

### Product setup

- Add real categories and Jalsa event information.
- Add sample vendors and products.
- Verify WhatsApp numbers and support number.
- Complete payment/preorder rules if checkout is not WhatsApp-only.

### Operations

- Deploy over HTTPS for PWA install support.
- Configure PWA screenshots/icons as needed.
- Test on a physical Android/iOS device.
- Review privacy policy and WhatsApp consent text.
- Configure custom domain and redirect URLs.

## 8. Launch checks

- Vendor signup creates a profile and pending vendor record.
- Vendor login returns the owned vendor using `auth.uid()`.
- User login creates or restores only the signed-in user profile.
- RLS prevents one user from editing another user's vendor, cart, or saved products.
- Vendor images save under the correct bucket.
- PWA can install and relaunch offline.
- Logout clears Supabase session and local demo state.
