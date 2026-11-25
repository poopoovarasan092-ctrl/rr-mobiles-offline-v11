# RR Mobiles V4

Owner-only mobile-friendly web app (installable as a home-screen PWA) with Supabase cloud storage.

## Included
- Owner sign-in using Supabase Auth
- GST-free billing; PDF bill printing/download
- Customer database; WhatsApp number optional
- Product and stock list with low-stock highlighting
- Stock purchase records
- Repair intake and status tracking: Received → Diagnosing → Waiting for parts → In progress → Ready → Delivered
- Loyalty points: 1 point per ₹100 on bills (₹1 redemption value); points earned are recorded for a selected customer
- Sales, estimated gross-profit summary, PDF report and bills CSV export
- Owner-only row-level security policies in Supabase

## Important limitations in this first V4 package
- WhatsApp currently opens a manual customer chat/contact link; it does not automatically send PDF bills. Automated WhatsApp bill delivery requires WhatsApp Business Platform approval, templates and a paid/approved provider. Customers without WhatsApp can still be stored and billed normally.
- Loyalty points can be redeemed from the customer list; 1 point is treated as ₹1. The app records the redemption in the loyalty ledger.
- Profit shown is gross product margin based on item costs entered on each bill. It is not net profit after rent, salaries or other expenses.
- Do not use this as a statutory accounting/tax system. It is intentionally configured without GST as requested.

## Setup (Android phone friendly)
1. Open your Supabase project in Chrome and sign in.
2. Open **SQL Editor → New query**. Open `supabase/schema.sql` from this package, copy all its contents, paste into the SQL editor and press **Run** once.
3. In Supabase, open **Authentication → Users → Add user**. Create your owner login with an email and a strong password. The username `poopoovarasan` is a label only; Supabase email/password authentication requires an email address. Do not share your password.
4. In Supabase, open **Project Settings → API** (or API Keys). Copy the Project URL and the publishable/anon key. Never use a `service_role` or secret key in this app.
5. On a computer or cloud IDE, copy `.env.example` to `.env` and fill in:
   - `VITE_SUPABASE_URL=...`
   - `VITE_SUPABASE_ANON_KEY=...`
6. Run `npm install`, then `npm run dev` to test. For production run `npm run build`; deploy the generated `dist` folder to a static host such as Netlify or Vercel. Add the deployed site URL under Supabase **Authentication → URL Configuration** as the Site URL and an allowed Redirect URL.
7. Open the deployed URL on Android Chrome → browser menu → **Add to Home screen** (or **Install app** if offered).

## Development
```bash
npm install
npm run dev
npm run build
```

## Security
All business tables have RLS enabled and owner_id policies tied to the authenticated Supabase user. Keep the Supabase secret/service-role key private. Create only your own owner user. The browser app uses only the public anon/publishable key.


## V6 stock upgrade

1. In Supabase, open SQL Editor and run `supabase/v6_stock_upgrade.sql` once.
2. Replace the existing `src/main.jsx` with the V6 `src/main.jsx` from this package.
3. Keep your existing `src/style.css`, `package.json`, and other project files.
4. Commit the changes in GitHub. Netlify should build and deploy automatically.
5. Test using one low-value test product: add stock, create a bill for one unit, then confirm stock drops by one. Also test that a bill for more than available stock is rejected.

V6 links bill items to a product UUID. Manual service lines (for example, display repair labour) do not deduct product stock. Stock purchases are saved and increment stock in one database transaction.


## V7 customer history and business reports

V7 does not require a database migration. It uses existing `bills.customer_id`, `bill_date`, `payment_mode`, `total`, and `cost_total` fields.

1. Replace the existing `src/main.jsx` in GitHub with the V7 `src/main.jsx` from this package.
2. Keep your existing `src/style.css`, Supabase SQL migrations, and other project files unchanged.
3. Commit the file and wait for Netlify's production deploy to show Live.
4. In Customers, tap **Purchase history** beside a customer to see linked bills and total spend.
5. In Reports, review today's and this month's sales, estimated gross profit, bill count and payment-mode totals.

The app loads the latest 500 bills. Therefore report totals are based on those loaded records, not necessarily all-time totals if you have more than 500 bills. Gross profit is sales minus recorded item cost; it is not net profit because operating expenses are not included. Cash/UPI/Card/Credit totals are grouped by the exact payment mode saved on each bill.


## V8 expense and net-profit upgrade

### Database setup (required once)
1. Open Supabase Dashboard > SQL Editor > New query.
2. Open `supabase/v8_expenses_upgrade.sql` from this ZIP.
3. Copy all SQL, paste it into the SQL Editor and Run.
4. Confirm the `expenses` table is created in Table Editor.

### App deployment
1. Replace the existing GitHub file `src/main.jsx` with the V8 `src/main.jsx` from this ZIP.
2. Keep `src/style.css`, `package.json`, other source files and previous V6 SQL migration unchanged.
3. Commit the change and wait for Netlify Production deploy to show Live.

### V8 features
- Record operating expenses by date, category, description, amount and payment method.
- View and delete expense entries.
- Daily and monthly expense totals.
- Estimated net profit = sales - item cost - recorded operating expenses.
- Dashboard shows this month's estimated net profit.
- Download a PDF business report.

Important accounting note: do not enter stock purchases again as operating expenses; stock purchases are tracked separately and product costs are already included in bill cost_total. Net profit is only an estimate based on costs and expenses entered in the app. Reports use the latest 500 bills and 500 expenses loaded.


## V9 WhatsApp sharing

V9 adds click-to-chat WhatsApp actions and does not require a database migration.

1. Replace `src/main.jsx` in GitHub with the V9 version in this package.
2. Keep `src/style.css`, the V8 expenses SQL/table, and all other existing project files unchanged.
3. Commit the update and wait for Netlify to show Production deploy · Live.
4. In Bills, use **Share bill** to open WhatsApp with a prepared bill summary. Press Send in WhatsApp.
5. For bills marked **Credit**, use **Reminder** to prepare a payment reminder.
6. In Repairs, use **WhatsApp update** to prepare a repair-status message for the customer.

Important limitations:
- This is manual click-to-chat. The owner must review and press Send; it does not send messages automatically.
- The bill action sends bill details as text, not the PDF attachment. Download the PDF with the PDF button, then attach it manually in WhatsApp if the customer needs the PDF.
- The credit reminder uses the full bill total as the amount due. Use it only when the full bill is still unpaid. Partial payments and outstanding balances are not tracked by this version.
- Phone numbers are normalized by removing spaces/symbols and adding India country code 91 when a 10-digit number is entered. Confirm the number is correct and has WhatsApp before sending.


## V10 customer credit and partial-payment management

### Supabase migration (required once)
1. Open Supabase Dashboard > SQL Editor > New query.
2. Open `supabase/v10_credit_management.sql` from this ZIP.
3. Copy the complete SQL, paste and Run.
4. Confirm the `credit_payments` table exists in Table Editor.

### Deploy app
1. Replace GitHub `src/main.jsx` with V10 `src/main.jsx` from this package.
2. Keep `src/style.css`, the existing V8 expenses table, V6 stock migration and all other files unchanged.
3. Commit changes and wait for Netlify Production deploy to show Live.

### Features and accounting behavior
- Bills marked `Credit` appear in the Credit page.
- Existing Credit bills are treated as fully unpaid until you record collections against them.
- Record full or partial collections by bill, date and payment method.
- Database RPC locks the bill and prevents recorded payments exceeding the bill total.
- Outstanding = bill total - payments recorded in `credit_payments`.
- WhatsApp reminder uses the calculated remaining balance.
- Payment history is shown with date, amount, method and notes.

Important: This tracks collections against credit bills only. It does not automatically convert an existing bill's payment mode from Credit to Cash/UPI when fully paid. It does not import earlier payments that were collected outside this app. Record those past payments manually to correct outstanding balances. Payment records should not be deleted except to correct a genuine mistake; deleting one increases the outstanding balance again.


## V11 safe customer and stock deletion

V11 adds guarded delete actions in Customers and Products:

- A customer can be deleted only when the remaining balance across their Credit bills is ₹0. If any credit amount remains, deletion is blocked and the outstanding amount is shown.
- A product can be deleted only when its stock quantity is exactly 0. Any non-zero quantity is blocked.
- Deleting a zero-stock product removes it from the active Products list only. Existing purchase rows remain, with their product link set to null by the V6 database relationship; bill item snapshots and stock/purchase history remain.
- Deleting a zero-balance customer preserves bill, credit-payment and loyalty history. Customer links in history become unassigned rather than deleting the history.
- The offline app keeps using the existing IndexedDB database name so existing on-device records are not reset by this update.

### Supabase database protection (only if using the Supabase cloud schema)
Run `supabase/v11_safe_delete_rules.sql` once after the V6 stock and V10 credit migrations. This adds database-level guards so a direct database delete cannot bypass the same rules.

### Deploy
1. Replace `src/main.jsx` with the V11 file from this package.
2. Keep the existing `src/localdb.js`, `src/style.css`, and earlier SQL migrations.
3. If using Supabase cloud storage, run the V11 SQL migration once.
4. Build/deploy as usual with `npm install` and `npm run build`.
