# 🗓️ Sprint Backlog — Portfolio v1.0 (Week 1)

**Sprint Period:** 11 Mei – 17 Mei 2026  
**Sprint Goal:** Membangun fondasi lengkap website portofolio + CMS admin panel yang fungsional  
**Current State:** Fresh Next.js 16 + Tailwind CSS 4 boilerplate

---

## 📊 Status Proyek Saat Ini

| Aspek | Status |
|---|---|
| Next.js 16.2.6 | ✅ Installed |
| Tailwind CSS 4 | ✅ Installed |
| Supabase | ❌ Belum setup |
| NextAuth.js | ❌ Belum setup |
| Framer Motion | ❌ Belum install |
| Design System | ❌ Belum ada |
| Halaman | ❌ Hanya boilerplate default |

---

## 🏗️ Arsitektur Folder Target

```
app/
├── (public)/              # Public-facing pages
│   ├── page.tsx           # Home / Hero
│   ├── about/page.tsx
│   ├── education/page.tsx
│   ├── skills/page.tsx
│   ├── experience/page.tsx
│   ├── portfolio/page.tsx
│   ├── projects/page.tsx
│   ├── blog/
│   │   ├── page.tsx
│   │   └── [slug]/page.tsx
│   └── contact/page.tsx
├── (admin)/               # CMS Admin Panel
│   └── admin/
│       ├── layout.tsx
│       ├── page.tsx       # Dashboard
│       ├── about/page.tsx
│       ├── education/page.tsx
│       ├── skills/page.tsx
│       ├── experience/page.tsx
│       ├── portfolio/page.tsx
│       ├── projects/page.tsx
│       ├── blog/page.tsx
│       ├── contact/page.tsx
│       └── media/page.tsx
├── api/                   # API Routes
│   ├── auth/[...nextauth]/route.ts
│   └── upload/route.ts
├── layout.tsx
└── globals.css
components/                # Reusable UI components
lib/                       # Utilities, Supabase client, types
```

---

## 📅 Day 1 — Minggu, 11 Mei: Infrastruktur & Design System

### 🎯 Objektif: Setup semua dependencies dan fondasi visual

| # | Task | Priority | Est. |
|---|---|---|---|
| 1.1 | Install dependencies: `framer-motion`, `react-icons`, `react-hook-form`, `zod`, `@supabase/supabase-js`, `next-auth` | 🔴 High | 15m |
| 1.2 | Setup Supabase project (create project, get API keys) | 🔴 High | 20m |
| 1.3 | Buat `lib/supabase.ts` (client & server) | 🔴 High | 15m |
| 1.4 | Buat `lib/types.ts` — definisi semua TypeScript interfaces | 🔴 High | 30m |
| 1.5 | Setup Google Fonts (Inter + Fira Code) di `layout.tsx` | 🔴 High | 10m |
| 1.6 | Buat design system di `globals.css` — color tokens, spacing, typography | 🔴 High | 45m |
| 1.7 | Buat komponen dasar: `Button`, `Card`, `Badge`, `SectionHeader` | 🔴 High | 60m |
| 1.8 | Buat `Navbar` component (sticky, responsive, mobile hamburger) | 🔴 High | 45m |
| 1.9 | Buat `Footer` component | 🟡 Medium | 30m |
| 1.10 | Setup Dark/Light mode toggle dengan `ThemeProvider` | 🟡 Medium | 30m |

**📦 Deliverable:** Project bisa dijalankan dengan navbar, footer, dan theme toggle functional.

---

## 📅 Day 2 — Senin, 12 Mei: Supabase Schema & Home Page

### 🎯 Objektif: Database siap + Hero section stunning

| # | Task | Priority | Est. |
|---|---|---|---|
| 2.1 | Buat Supabase tables: `about`, `education`, `skills`, `skill_categories` | 🔴 High | 30m |
| 2.2 | Buat Supabase tables: `experience`, `portfolio`, `projects` | 🔴 High | 30m |
| 2.3 | Buat Supabase tables: `articles`, `article_categories`, `contact_info`, `social_links` | 🔴 High | 30m |
| 2.4 | Setup Row Level Security (RLS) policies | 🔴 High | 20m |
| 2.5 | Seed data awal untuk testing | 🟡 Medium | 20m |
| 2.6 | Buat Home/Hero section — intro, animasi typing/fade, CTA buttons | 🔴 High | 90m |
| 2.7 | Implement smooth scroll navigation dari Hero ke sections | 🟡 Medium | 20m |
| 2.8 | Tambah Framer Motion entrance animations | 🟡 Medium | 30m |

**📦 Deliverable:** Database schema lengkap + Home page dengan animasi dan navigasi smooth.

---

## 📅 Day 3 — Selasa, 13 Mei: About, Education, Skills Pages

### 🎯 Objektif: 3 halaman publik selesai dengan data dari Supabase

| # | Task | Priority | Est. |
|---|---|---|---|
| 3.1 | **About Page:** Layout foto + bio, personal story, fun facts | 🔴 High | 60m |
| 3.2 | About: Download CV button + animasi | 🔴 High | 20m |
| 3.3 | About: Fetch data dari Supabase `about` table | 🔴 High | 20m |
| 3.4 | **Education Page:** Timeline component (vertical) | 🔴 High | 60m |
| 3.5 | Education: Sertifikasi & achievements section | 🟡 Medium | 30m |
| 3.6 | Education: Fetch data dari Supabase | 🔴 High | 15m |
| 3.7 | **Skills Page:** Category tabs + progress bars / skill cards | 🔴 High | 60m |
| 3.8 | Skills: Icon/logo tools dengan hover effects | 🟡 Medium | 30m |
| 3.9 | Skills: Fetch data dari Supabase | 🔴 High | 15m |
| 3.10 | Scroll-triggered animations untuk ketiga halaman | 🟡 Medium | 30m |

**📦 Deliverable:** About, Education, Skills pages responsive dan connected ke Supabase.

---

## 📅 Day 4 — Rabu, 14 Mei: Experience, Portfolio, Projects Pages

### 🎯 Objektif: 3 halaman showcase utama selesai

| # | Task | Priority | Est. |
|---|---|---|---|
| 4.1 | **Experience Page:** Timeline horizontal/vertical + company info | 🔴 High | 60m |
| 4.2 | Experience: Job description accordion/expandable | 🟡 Medium | 30m |
| 4.3 | Experience: Fetch data dari Supabase | 🔴 High | 15m |
| 4.4 | **Portfolio Page:** Grid/masonry card layout | 🔴 High | 60m |
| 4.5 | Portfolio: Filter by kategori/teknologi | 🔴 High | 30m |
| 4.6 | Portfolio: Detail modal/page (tech stack, role, links) | 🔴 High | 45m |
| 4.7 | Portfolio: Fetch + image optimization | 🔴 High | 20m |
| 4.8 | **Projects Page:** Card layout + status badges (ongoing/completed) | 🔴 High | 45m |
| 4.9 | Projects: GitHub integration link | 🟡 Medium | 15m |
| 4.10 | Projects: Fetch data dari Supabase | 🔴 High | 15m |

**📦 Deliverable:** Experience, Portfolio, Projects pages dengan filter dan detail view.

---

## 📅 Day 5 — Kamis, 15 Mei: Blog & Contact Pages

### 🎯 Objektif: Blog system + contact form functional

| # | Task | Priority | Est. |
|---|---|---|---|
| 5.1 | **Blog List Page:** Card list + thumbnail, kategori, reading time | 🔴 High | 60m |
| 5.2 | Blog: Search bar + tag filter | 🟡 Medium | 30m |
| 5.3 | Blog: Pagination | 🟡 Medium | 20m |
| 5.4 | **Blog Detail `[slug]`:** Render markdown/rich content | 🔴 High | 45m |
| 5.5 | Blog Detail: Share buttons + related articles | 🟡 Medium | 30m |
| 5.6 | Blog: Fetch dari Supabase + SSG/ISR | 🔴 High | 20m |
| 5.7 | **Contact Page:** Form (nama, email, subject, message) | 🔴 High | 45m |
| 5.8 | Contact: React Hook Form + Zod validation | 🔴 High | 20m |
| 5.9 | Contact: Social media links grid + availability status | 🟡 Medium | 20m |
| 5.10 | Contact: Success/error toast notifications | 🟡 Medium | 15m |
| 5.11 | Contact: Submit ke Supabase `messages` table | 🔴 High | 15m |

**📦 Deliverable:** Blog dengan search & detail page + Contact form dengan validasi.

---

## 📅 Day 6 — Jumat, 16 Mei: CMS Admin Panel

### 🎯 Objektif: Admin dashboard + CRUD untuk semua konten

| # | Task | Priority | Est. |
|---|---|---|---|
| 6.1 | Setup NextAuth.js (credentials provider, Supabase adapter) | 🔴 High | 45m |
| 6.2 | Buat Login page (`/admin/login`) | 🔴 High | 30m |
| 6.3 | Middleware: Protect semua `/admin/*` routes | 🔴 High | 20m |
| 6.4 | Admin Layout: Sidebar navigation + header | 🔴 High | 45m |
| 6.5 | Admin Dashboard: Overview stats (total articles, projects, messages) | 🟡 Medium | 30m |
| 6.6 | Admin About: Edit bio, foto, CV upload | 🔴 High | 45m |
| 6.7 | Admin Education: CRUD table + form modal | 🔴 High | 45m |
| 6.8 | Admin Skills: CRUD categories & items | 🔴 High | 45m |
| 6.9 | Admin Experience: CRUD table + form | 🔴 High | 45m |
| 6.10 | Admin Portfolio: CRUD + image upload (Supabase Storage) | 🔴 High | 60m |
| 6.11 | Admin Projects: CRUD + status toggle | 🔴 High | 30m |
| 6.12 | Admin Blog: Rich text editor + draft/publish toggle | 🔴 High | 60m |
| 6.13 | Admin Contact: Manage social links + view messages | 🟡 Medium | 30m |

**📦 Deliverable:** Admin panel lengkap dengan auth, CRUD semua konten, dan file upload.

> [!WARNING]
> Day 6 adalah hari paling padat. Jika overtime, beberapa fitur admin (media library, rich text editor advanced) bisa dipindah ke Day 7.

---

## 📅 Day 7 — Sabtu, 17 Mei: Polish, SEO, & Testing

### 🎯 Objektif: Production-ready quality

| # | Task | Priority | Est. |
|---|---|---|---|
| 7.1 | SEO: Meta tags, Open Graph, per-page metadata | 🔴 High | 30m |
| 7.2 | SEO: Generate `sitemap.xml` dan `robots.txt` | 🟡 Medium | 15m |
| 7.3 | SEO: Structured data (Schema.org JSON-LD) | 🟢 Low | 20m |
| 7.4 | Performance: Image optimization, lazy loading audit | 🔴 High | 20m |
| 7.5 | Performance: Code splitting review | 🟡 Medium | 15m |
| 7.6 | Responsive testing: Mobile, tablet, desktop | 🔴 High | 30m |
| 7.7 | Cross-browser testing (Chrome, Firefox, Edge) | 🟡 Medium | 20m |
| 7.8 | Accessibility audit (semantic HTML, ARIA labels, keyboard nav) | 🟡 Medium | 20m |
| 7.9 | Loading states & error boundaries untuk semua pages | 🔴 High | 30m |
| 7.10 | 404 page custom | 🟡 Medium | 15m |
| 7.11 | Final Lighthouse audit — target score > 90 | 🔴 High | 15m |
| 7.12 | Populate konten real via CMS | 🟡 Medium | 30m |
| 7.13 | Git cleanup & documentation (README update) | 🟢 Low | 15m |

**📦 Deliverable:** Website production-ready, responsive, SEO-optimized, Lighthouse > 90.

---

## 📊 Sprint Summary

| Metrik | Nilai |
|---|---|
| **Total Tasks** | 65 |
| **High Priority** | 42 |
| **Medium Priority** | 20 |
| **Low Priority** | 3 |
| **Estimated Total Hours** | ~32 jam (~4.5 jam/hari) |

### Tech Stack Final

| Layer | Technology |
|---|---|
| Framework | Next.js 16 (App Router) |
| Styling | Tailwind CSS 4 |
| Animation | Framer Motion |
| Icons | React Icons |
| Forms | React Hook Form + Zod |
| Database | Supabase (PostgreSQL) |
| Auth | NextAuth.js |
| File Storage | Supabase Storage |
| Deployment | Vercel |

---

## 🚨 Risiko & Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Day 6 (CMS) terlalu padat | Delay | Prioritaskan CRUD portfolio & blog, sisanya lanjut post-sprint |
| Supabase RLS complexity | Blokir API | Setup basic RLS dulu, refine setelah launch |
| Rich text editor integration | Overhead | Gunakan library siap pakai (Tiptap/MDX) |
| Image upload bottleneck | Slow UX | Compress client-side sebelum upload |

---

## ❓ Open Questions

> [!IMPORTANT]
> Tolong konfirmasi sebelum mulai development:

1. **Supabase Project:** Apakah sudah punya akun/project Supabase, atau perlu buat baru?
2. **Konten:** Apakah sudah punya konten siap (bio, foto, CV, project details) atau dummy dulu?
3. **Domain:** Sudah punya custom domain atau pakai `.vercel.app` dulu?
4. **Prioritas halaman:** Jika waktu terbatas, halaman mana yang paling penting di-deliver duluan?
5. **Blog editor:** Prefer Markdown editor atau WYSIWYG (rich text)?
6. **Tailwind CSS:** Brief menyebut Tailwind — project sudah pakai Tailwind CSS 4, apakah OK lanjut dengan ini?
