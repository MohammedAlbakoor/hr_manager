# نشر مجاني على alwaysdata

هذا المسار هو الأسهل إذا أردت تشغيل المشروع مجانًا بسرعة للتجربة.

مهم:
- هذا مناسب للتجربة والاختبار.
- خطة `alwaysdata` المجانية مذكور عليها أنها `Personal use` فقط، ولا تسمح بالأهداف التجارية/الربحية، كما أن الدومين المجاني يكون على `alwaysdata.net`.
- إذا أردت تشغيله فعليًا لشركة أو على دومينك الخاص، انتقل إلى الخطة المدفوعة الأرخص عندهم بدل المجانية.

المراجع الرسمية:
- Laravel hosting: https://www.alwaysdata.com/en/laravel-hosting/
- قيود الخطة المجانية: https://help.alwaysdata.com/en/admin-billing/public-cloud-restrictions/
- Composer على alwaysdata: https://help.alwaysdata.com/en/web-hosting/languages/php/packages/

## الفكرة

سنرفع Laravel والواجهة Flutter Web على نفس الاستضافة:

- الـ API سيكون تحت: `https://YOUR_ACCOUNT.alwaysdata.net/api`
- الواجهة ستكون تحت: `https://YOUR_ACCOUNT.alwaysdata.net/app`

ولهذا السبب نبني Flutter مع:
- `--base-href /app/`
- `API_BASE_URL=https://YOUR_ACCOUNT.alwaysdata.net/api`

## ما الذي تفعله أنت مرة واحدة فقط

1. أنشئ حسابًا مجانيًا على alwaysdata.
2. فعّل الدخول إلى لوحة الإدارة.
3. أنشئ قاعدة بيانات `MySQL/MariaDB` أو `PostgreSQL`.
4. فعّل SSH من لوحة alwaysdata.

## ما الذي ستحتاجه من لوحة alwaysdata

جهّز هذه القيم:

- اسم الحساب: `YOUR_ACCOUNT`
- اسم قاعدة البيانات
- اسم مستخدم قاعدة البيانات
- كلمة مرور قاعدة البيانات
- المضيف `DB_HOST`
- المنفذ `DB_PORT`

## تجهيز نسخة الويب محليًا

من جذر المشروع شغّل:

```powershell
.\scripts\prepare_alwaysdata_release.ps1 -AlwaysdataHost "YOUR_ACCOUNT.alwaysdata.net"
```

هذا السكربت سيقوم بـ:
- بناء Flutter Web مع `base-href=/app/`
- ربط الواجهة مع `https://YOUR_ACCOUNT.alwaysdata.net/api`
- نسخ ناتج البناء إلى `backend/public/app`

## رفع الملفات إلى الاستضافة

ارفع محتويات مجلد `backend` كاملة إلى حساب alwaysdata عبر SFTP/SSH.

بعد الرفع، ادخل SSH إلى alwaysdata وشغّل داخل مجلد المشروع:

```bash
composer install --no-dev --optimize-autoloader
cp .env.example .env
php artisan key:generate
```

ثم عدّل ملف `.env` ليكون قريبًا من هذا:

```env
APP_NAME=HRManager
APP_ENV=production
APP_DEBUG=false
APP_URL=https://YOUR_ACCOUNT.alwaysdata.net

CORS_ALLOWED_ORIGINS=https://YOUR_ACCOUNT.alwaysdata.net

DB_CONNECTION=mysql
DB_HOST=YOUR_DB_HOST
DB_PORT=3306
DB_DATABASE=YOUR_DB_NAME
DB_USERNAME=YOUR_DB_USER
DB_PASSWORD=YOUR_DB_PASSWORD

SESSION_DRIVER=database
QUEUE_CONNECTION=database
CACHE_STORE=database
```

إذا اخترت PostgreSQL بدل MySQL:

```env
DB_CONNECTION=pgsql
DB_HOST=YOUR_DB_HOST
DB_PORT=5432
DB_DATABASE=YOUR_DB_NAME
DB_USERNAME=YOUR_DB_USER
DB_PASSWORD=YOUR_DB_PASSWORD
```

## تشغيل التهيئة الأولى

بعد ضبط `.env` شغّل:

```bash
php artisan migrate --force
php artisan db:seed --force
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan config:cache
```

## ضبط الموقع في alwaysdata

اجعل جذر الموقع يشير إلى:

```text
<project>/public
```

أي إلى مجلد `public` داخل مشروع Laravel المرفوع.

بهذا الشكل:
- `/api/*` سيعمل عبر Laravel
- `/app/*` سيعرض ملفات Flutter التي نسخناها إلى `public/app`

## التحقق بعد الرفع

جرّب الروابط التالية:

1. `https://YOUR_ACCOUNT.alwaysdata.net/api/auth/login`
المتوقع: طريقة `GET` غير مسموحة أو استجابة API، وهذا طبيعي لأن المسار موجود.

2. `https://YOUR_ACCOUNT.alwaysdata.net/app`
المتوقع: تفتح شاشة التطبيق.

3. جرّب تسجيل الدخول من التطبيق.

## ملاحظات مهمة

- الـ seeder الحالي ينشئ بيانات تجريبية، لذلك غيّر كلمات المرور مباشرة بعد أول تشغيل إذا أردت إبقاءه.
- عند كل تعديل على الواجهة، أعد تشغيل سكربت التحضير ثم ارفع مجلد `backend/public/app`.
- الخطة المجانية لا تناسب إطلاقًا استخدامًا تجاريًا حقيقيًا أو دومينًا مخصصًا بحسب وثائق alwaysdata.

## لو أردت الانتقال إلى تشغيل فعلي

أسهل ترقية من نفس المزود:
- استخدم خطة `Plus` بدل المجانية.
- اربط دومينك الحقيقي.
- أبقِ نفس البنية تقريبًا: Laravel في `public` وFlutter في `public/app`.
