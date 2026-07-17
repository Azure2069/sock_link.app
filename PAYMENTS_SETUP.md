# Supabase + Paystack setup

The Flutter app invokes a Supabase Edge Function. The Paystack secret key is never stored in the app. The client is configured for Supabase project `bbhnpvxqaczxqteznmdp`.

## 1. Create and link Supabase

Install the Supabase CLI, sign in, and link this folder to your project:

```sh
supabase login
supabase link --project-ref bbhnpvxqaczxqteznmdp
```

## 2. Configure and deploy Paystack

Use the Paystack **test** secret key first:

```sh
supabase secrets set PAYSTACK_SECRET_KEY=sk_test_your_key
supabase functions deploy paystack --no-verify-jwt
```

## 3. Run Flutter

The URL and client-safe publishable key have defaults in the app:

```sh
flutter run
```

They can still be overridden for another environment using the `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` dart-defines.

Open **Outstanding debts**, choose **Paystack online**, enter the amount and customer mobile number, and open checkout. After the customer completes payment in the browser, return to the app and select **Verify payment**.

Before production, replace the Edge Function secret with the Paystack live secret key and complete Paystack's go-live requirements. Never add a Paystack secret key to Flutter or commit it to source control.
