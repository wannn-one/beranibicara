# Database Migration Guide

## Berani Bicara - Anti-Bullying Application

This guide provides step-by-step instructions for migrating your Supabase database to the new schema with best practices, proper indexing, and enhanced security.

---

## Table of Contents

1. [Installation Type Selection](#installation-type-selection)
2. [Prerequisites](#prerequisites)
3. [Migration Overview](#migration-overview)
4. [Execution Order](#execution-order)
5. [Step-by-Step Instructions](#step-by-step-instructions)
6. [Rollback Procedures](#rollback-procedures)
7. [Post-Migration Verification](#post-migration-verification)
8. [Troubleshooting](#troubleshooting)

---



## Installation Type Selection

Choose the appropriate installation type for your situation:

### 🆕 Option A: Clean Installation (Fresh Start)

**Use this if:**

- ✅ You have no production data
- ✅ You're setting up a new database
- ✅ You're in a development/testing environment
- ✅ You want to completely reset your database

**Steps:**

1. **Backup (if you have any data)**: Create a backup first
2. **Run**: `00_drop_all.sql` - Drops all existing tables and objects
3. **Continue**: Follow normal execution order starting from `00_types.sql`

**⚠️ WARNING**: This will **permanently delete ALL data**. Only use in non-production environments or with a confirmed backup.

```sql
-- Execute this to drop everything
\i database/00_drop_all.sql

-- Then proceed with fresh installation
\i database/00_types.sql
\i database/01_init.sql
-- ... continue with remaining files
```



### 🔄 Option B: Incremental Migration (Preserve Data)

**Use this if:**

- ✅ You have production data to preserve
- ✅ You're upgrading an existing database
- ✅ You want to maintain existing records
- ✅ You need zero data loss

**Steps:**

1. **Backup**: Mandatory - create full database backup
2. **Skip**: Do NOT run `00_drop_all.sql`
3. **Start**: Begin with `00_types.sql` and continue in order
4. **Migrate**: Existing tables will be modified, not replaced

**Note**: Some tables (like `notifications`) will be dropped and recreated with new structure, but this is handled safely by the migration scripts.

---



## Prerequisites



### Before You Begin

1. **Backup Your Database**
  ```bash
   # Create a full database backup
   pg_dump -h your-supabase-url -U postgres -d postgres > backup_$(date +%Y%m%d_%H%M%S).sql
  ```
2. **Supabase Access**
  - SQL Editor access in Supabase Dashboard
  - Or direct PostgreSQL connection credentials
3. **Maintenance Window**
  - Estimated downtime: 30-60 minutes
  - Schedule during low-traffic period
  - Notify users of maintenance
4. **Test Environment**
  - Strongly recommended to test migration on staging first
  - Verify all changes work with your Flutter app

---



## Migration Overview



### What Will Change

**Added:**

- ✅ 5 new enum types for better type safety
- ✅ 40+ indexes for query performance (10-100x faster)
- ✅ Device tokens table (replaces old notifications)
- ✅ Notification history table
- ✅ Audit log for compliance
- ✅ Soft delete functionality
- ✅ Automatic updated_at triggers
- ✅ Comprehensive data constraints
- ✅ RLS policies for all tables
- ✅ Full documentation

**Modified:**

- 🔄 Foreign key cascade behaviors
- 🔄 RLS helper functions (performance optimized)
- 🔄 Existing table structures (added columns)

**Removed:**

- ❌ Old notifications table (replaced with device_tokens)
- ❌ Duplicate RLS policies



### Breaking Changes

⚠️ **IMPORTANT**: The following changes may affect your application:

1. **Notifications Table Dropped**
  - Old table: `public.notifications` (single device per user)
  - New tables: `public.device_tokens` and `public.notification_history`
  - **Action Required**: Users will need to re-register FCM tokens
  - **Code Update**: Update Flutter app to use new tables
2. **Enum Types**
  - Columns now use proper enum types instead of TEXT
  - **Action Required**: Update Flutter models to match enum values
  - Values remain the same, only type changed
3. **Updated_at Columns**
  - New `updated_at` columns added to several tables
  - **Action Required**: Update Flutter models if using strong typing

---



## Execution Order



### For Clean Installation (Option A)

Run files in this order:

```
0. ⚠️  00_drop_all.sql       - DROP EVERYTHING (fresh start only)
1. ✅ 00_types.sql           - Create enum types
2. ✅ 01_init.sql            - Create tables
3. ✅ 02_user_policies_trigger.sql - User profile triggers
4-15. Continue with remaining files below...
```



### For Incremental Migration (Option B)

Skip `00_drop_all.sql` and run the SQL files in this **EXACT** order:

### Phase 1: Foundation (Types & Schema)

```
1. ✅ 00_types.sql           - Create enum types
2. ✅ 01_init.sql            - Updated table definitions (already exists, updated)
3. ✅ 02_user_policies_trigger.sql - User profile triggers (already exists)
```



### Phase 2: Performance & Structure

```
4. ✅ 06_indexes.sql         - Add performance indexes
5. ✅ 07_fix_notifications.sql - Restructure notifications
6. ✅ 08_add_cascades.sql    - Add cascade behaviors
7. ✅ 09_updated_at_triggers.sql - Add update triggers
```



### Phase 3: Security & Compliance

```
8. ✅ 10_audit_trail.sql     - Add audit logging
9. ✅ 11_data_constraints.sql - Add business logic constraints
10. ✅ 03_rls_policies.sql   - Base RLS policies (already exists, updated)
11. ✅ 12_optimize_rls.sql   - Additional RLS policies
12. ✅ 13_soft_delete.sql    - Add soft delete
```



### Phase 4: Data & Documentation

```
13. ✅ 04_tambah_kelas.sql   - Kelas table (if not already created)
14. ✅ 05_seed_kelas_no_guru.sql - Seed class data (if needed)
15. ✅ 14_documentation.sql  - Add documentation
```

---



## Step-by-Step Instructions



### Important: Choose Your Installation Type First

- **Clean Installation**: Run `00_drop_all.sql` FIRST, then continue below
- **Incremental Migration**: Skip `00_drop_all.sql`, start with Step 1 below



### Option A: Supabase SQL Editor (Recommended)

1. **Navigate to SQL Editor**
  - Open Supabase Dashboard
  - Go to SQL Editor tab
2. **Execute Each File**
  ```sql
   -- For each file in order:
   -- 1. Copy contents of SQL file
   -- 2. Paste into SQL Editor
   -- 3. Click "Run"
   -- 4. Verify "Success" message
   -- 5. Check for any errors
  ```
3. **Wait Between Large Operations**
  - After indexes (06_indexes.sql): Wait 30 seconds
  - After audit trail (10_audit_trail.sql): Wait 30 seconds



### Option B: Command Line (psql)

```bash
# Connect to your database
psql -h your-db-host -U postgres -d postgres

# FOR CLEAN INSTALLATION ONLY:
\i database/00_drop_all.sql

# Then run each file in order
\i database/00_types.sql
\i database/01_init.sql
\i database/02_user_policies_trigger.sql
\i database/06_indexes.sql
\i database/07_fix_notifications.sql
\i database/08_add_cascades.sql
\i database/09_updated_at_triggers.sql
\i database/10_audit_trail.sql
\i database/11_data_constraints.sql
\i database/03_rls_policies.sql
\i database/12_optimize_rls.sql
\i database/13_soft_delete.sql
\i database/04_tambah_kelas.sql
\i database/05_seed_kelas_no_guru.sql
\i database/14_documentation.sql
```

---



## Detailed Migration Steps



### Step 0: Clean Installation (Optional - Fresh Start Only)

```bash
# File: 00_drop_all.sql
# Drops: ALL tables, functions, triggers, types, views
# Expected time: 5-10 seconds
# ⚠️  WARNING: DELETES ALL DATA
```

**Verification:**

```sql
-- Verify all tables are gone
SELECT tablename FROM pg_tables WHERE schemaname = 'public';
-- Should return empty or very few system tables

-- Verify all types are gone
SELECT typname FROM pg_type 
WHERE typnamespace = 'public'::regnamespace;
-- Should return empty
```

**⚠️ CRITICAL**: Only proceed if you:

- Have a complete backup
- Want to delete all existing data
- Are in development/testing environment

---



### Step 1: Create Enum Types

```bash
# File: 00_types.sql
# Creates: user_role, user_status, report_status, tahapan, file_type
# Expected time: < 5 seconds
# Rollback: DROP TYPE type_name CASCADE;
```

**Verification:**

```sql
SELECT typname FROM pg_type WHERE typname IN (
  'user_role', 'user_status', 'report_status', 'tahapan', 'file_type'
);
-- Should return 5 rows
```



### Step 2: Update Table Definitions

```bash
# File: 01_init.sql (already exists, run updated version)
# Updates: Column types from TEXT to proper enums
# Expected time: < 5 seconds
```

**Verification:**

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'role';
-- Should show: user_role (not text)
```



### Step 3: Add Performance Indexes

```bash
# File: 06_indexes.sql
# Creates: 40+ indexes
# Expected time: 30-60 seconds (depends on data volume)
```

**Verification:**

```sql
SELECT count(*) FROM pg_indexes WHERE schemaname = 'public';
-- Should be significantly higher than before
```



### Step 4: Restructure Notifications

```bash
# File: 07_fix_notifications.sql
# Drops: public.notifications
# Creates: device_tokens, notification_history
# Expected time: 5-10 seconds
# ⚠️ BREAKING: Users must re-register devices
```

**Verification:**

```sql
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('device_tokens', 'notification_history');
-- Should return 2 rows
```



### Step 5: Add Cascade Behaviors

```bash
# File: 08_add_cascades.sql
# Updates: Foreign key constraints
# Expected time: 10-15 seconds
```

**Verification:**

```sql
SELECT conname, confdeltype 
FROM pg_constraint 
WHERE conrelid = 'public.evidence'::regclass;
-- Should show 'c' (CASCADE) for evidence_report_id_fkey
```



### Step 6: Add Update Triggers

```bash
# File: 09_updated_at_triggers.sql
# Creates: Triggers for automatic updated_at
# Expected time: 10-15 seconds
```

**Verification:**

```sql
SELECT tgname FROM pg_trigger 
WHERE tgname LIKE '%updated_at%';
-- Should show triggers for multiple tables
```



### Step 7: Add Audit Trail

```bash
# File: 10_audit_trail.sql
# Creates: audit_log table and triggers
# Expected time: 15-20 seconds
```

**Verification:**

```sql
SELECT count(*) FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'audit_log';
-- Should return 1
```



### Step 8: Add Data Constraints

```bash
# File: 11_data_constraints.sql
# Creates: CHECK constraints and validation triggers
# Expected time: 15-20 seconds
```

**Verification:**

```sql
SELECT conname FROM pg_constraint 
WHERE contype = 'c' 
AND conrelid IN (SELECT oid FROM pg_class WHERE relnamespace = 'public'::regnamespace);
-- Should show multiple CHECK constraints
```



### Step 9-10: Optimize RLS

```bash
# File: 03_rls_policies.sql (updated version)
# File: 12_optimize_rls.sql
# Updates: RLS policies with performance improvements
# Expected time: 20-30 seconds
```

**Verification:**

```sql
SELECT tablename, COUNT(*) 
FROM pg_policies 
WHERE schemaname = 'public' 
GROUP BY tablename;
-- All tables should have policies
```



### Step 11: Add Soft Delete

```bash
# File: 13_soft_delete.sql
# Adds: deleted_at, deleted_by columns and functions
# Expected time: 10-15 seconds
```

**Verification:**

```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'reports' AND column_name = 'deleted_at';
-- Should return 1 row
```



### Step 12-13: Seed Data (Optional)

```bash
# File: 04_tambah_kelas.sql (if not already run)
# File: 05_seed_kelas_no_guru.sql (if not already run)
# Expected time: < 5 seconds
```



### Step 14: Add Documentation

```bash
# File: 14_documentation.sql
# Adds: COMMENT ON statements
# Expected time: 10-15 seconds
```

**Verification:**

```sql
SELECT obj_description('public.profiles'::regclass);
-- Should return a description
```

---



## Rollback Procedures



### Quick Rollback (Restore from Backup)

```bash
# Stop application traffic
# Restore from backup
psql -h your-db-host -U postgres -d postgres < backup_YYYYMMDD_HHMMSS.sql
# Restart application
```



### Selective Rollback

If only specific migrations failed:

```sql
-- Rollback Step 14 (Documentation)
-- No action needed, comments don't affect functionality

-- Rollback Step 13 (Soft Delete)
ALTER TABLE public.reports DROP COLUMN IF EXISTS deleted_at CASCADE;
ALTER TABLE public.reports DROP COLUMN IF EXISTS deleted_by CASCADE;
ALTER TABLE public.cerita_kelas DROP COLUMN IF EXISTS deleted_at CASCADE;
ALTER TABLE public.cerita_kelas DROP COLUMN IF EXISTS deleted_by CASCADE;
ALTER TABLE public.socialization DROP COLUMN IF EXISTS deleted_at CASCADE;
ALTER TABLE public.socialization DROP COLUMN IF EXISTS deleted_by CASCADE;
DROP FUNCTION IF EXISTS public.soft_delete_report(BIGINT) CASCADE;
DROP FUNCTION IF EXISTS public.restore_report(BIGINT) CASCADE;

-- Rollback Step 12 (RLS Optimization)
-- Policies can be recreated, no data loss

-- Rollback Step 11 (Data Constraints)
-- Find and drop specific constraints
SELECT 'ALTER TABLE ' || tablename || ' DROP CONSTRAINT ' || conname || ';'
FROM pg_constraint c
JOIN pg_tables t ON c.conrelid = t.tablename::regclass
WHERE t.schemaname = 'public'
AND contype = 'c'
AND conname LIKE 'check_%';

-- Rollback Step 10 (Audit Trail)
DROP TABLE IF EXISTS public.audit_log CASCADE;
DROP FUNCTION IF EXISTS public.audit_trigger_function() CASCADE;

-- Rollback Step 9 (Updated At Triggers)
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS updated_at;
ALTER TABLE public.reports DROP COLUMN IF EXISTS updated_at;

-- Rollback Step 8 (Cascades)
-- Would need to recreate old foreign keys without CASCADE

-- Rollback Step 7 (Notifications)
-- ⚠️ DESTRUCTIVE: Would need to recreate old notifications table
DROP TABLE IF EXISTS public.device_tokens CASCADE;
DROP TABLE IF EXISTS public.notification_history CASCADE;
-- Recreate old table (see original 01_init.sql)

-- Rollback Step 6 (Indexes)
-- Find and drop new indexes
SELECT 'DROP INDEX IF EXISTS ' || indexname || ';'
FROM pg_indexes
WHERE schemaname = 'public'
AND indexname LIKE 'idx_%';

-- Rollback Step 1 (Enum Types)
-- ⚠️ DESTRUCTIVE: Would break tables using these types
-- Not recommended unless necessary
```

---



## Post-Migration Verification



### 1. Check Database Health

```sql
-- Check for any failed migrations
SELECT * FROM pg_stat_activity WHERE state = 'idle in transaction';

-- Verify all tables exist
SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;

-- Check for missing indexes
SELECT schemaname, tablename 
FROM pg_tables t
LEFT JOIN pg_indexes i ON t.tablename = i.tablename AND t.schemaname = i.schemaname
WHERE t.schemaname = 'public'
GROUP BY t.schemaname, t.tablename
HAVING COUNT(i.indexname) = 0;

-- Verify RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = false;
-- Should be empty or only show expected tables
```



### 2. Test Queries

```sql
-- Test reports query (should use indexes)
EXPLAIN ANALYZE
SELECT * FROM public.reports 
WHERE status = 'baru' 
ORDER BY created_at DESC 
LIMIT 10;
-- Check that it uses idx_reports_status_created

-- Test profile query
EXPLAIN ANALYZE
SELECT * FROM public.profiles WHERE role = 'siswa';
-- Check that it uses idx_profiles_role

-- Test audit log
SELECT count(*) FROM public.audit_log;
-- Should be 0 initially, will populate on changes
```



### 3. Test RLS Policies

```sql
-- Test as student
SET LOCAL role authenticated;
SET LOCAL request.jwt.claim.sub = 'test-student-uuid';

SELECT count(*) FROM public.reports WHERE reporter_id = 'test-student-uuid';
-- Should succeed

SELECT count(*) FROM public.reports WHERE reporter_id != 'test-student-uuid';
-- Should return 0 (RLS filtering works)
```



### 4. Performance Checks

```sql
-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC
LIMIT 20;

-- Check slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_%'
ORDER BY mean_exec_time DESC
LIMIT 10;
```

---



## Troubleshooting



### Common Issues



#### 1. "Type already exists"

```
ERROR: type "user_role" already exists
```

**Solution:** Skip to next file, type already created

#### 2. "Column already exists"

```
ERROR: column "updated_at" already exists
```

**Solution:** Skip to next file, continue migration

#### 3. "Constraint violation"

```
ERROR: constraint "check_blocked_fields" is violated by some row
```

**Solution:** Fix data first

```sql
-- Find problematic rows
SELECT * FROM public.profiles 
WHERE status = 'blocked' 
AND (blocked_reason IS NULL OR blocked_by IS NULL);

-- Fix them
UPDATE public.profiles 
SET blocked_reason = 'Migration cleanup', blocked_by = admin_uuid
WHERE status = 'blocked' AND blocked_reason IS NULL;
```



#### 4. "Function does not exist"

```
ERROR: function get_my_role() does not exist
```

**Solution:** Run 12_optimize_rls.sql first, or ensure 03_rls_policies.sql was run

#### 5. Slow Index Creation

**Solution:** 

- Indexes on large tables take time
- Monitor progress:

```sql
SELECT now() - query_start as duration, query
FROM pg_stat_activity
WHERE query LIKE 'CREATE INDEX%';
```



#### 6. Out of Memory

**Solution:**

- Increase maintenance_work_mem temporarily:

```sql
SET maintenance_work_mem = '1GB';
-- Then run CREATE INDEX
```

---



## Maintenance Tasks



### Regular Maintenance (Recommended Schedule)



#### Daily

```sql
-- Check audit log growth
SELECT pg_size_pretty(pg_total_relation_size('public.audit_log'));

-- Check notification history growth
SELECT pg_size_pretty(pg_total_relation_size('public.notification_history'));
```



#### Weekly

```sql
-- Cleanup old notifications (older than 6 months)
SELECT public.cleanup_old_notifications();

-- Cleanup inactive device tokens (older than 90 days)
SELECT public.cleanup_inactive_device_tokens();
```



#### Monthly

```sql
-- Archive old audit logs (older than 2 years)
SELECT public.archive_old_audit_logs();

-- Permanently delete soft-deleted records (older than 90 days)
SELECT * FROM public.permanent_delete_old_records(90);

-- Vacuum and analyze
VACUUM ANALYZE;

-- Reindex (if needed)
REINDEX DATABASE postgres;
```

---



## Flutter App Updates Required



### 1. Update Models

```dart
// Update UserRole enum
enum UserRole {
  siswa,  // student
  guru,   // teacher
  tppk,   // counselor
  admin,  // admin
}

// Update UserStatus enum
enum UserStatus {
  aktif,    // active
  nonaktif, // inactive
  blocked,  // suspended
}

// Update ReportStatus enum
enum ReportStatus {
  baru,              // new
  ditinjau,          // under review
  ditindaklanjuti,   // action taken
  selesai,           // resolved
  ditolak,           // rejected
}
```



### 2. Update Notification Service

```dart
// Old (DELETE)
// await supabase.from('notifications').insert({...});

// New (USE THIS)
await supabase.from('device_tokens').insert({
  'user_id': userId,
  'fcm_token': token,
  'device_name': deviceName,
  'device_os': deviceOS,
});

// Get notification history
final notifications = await supabase
  .from('notification_history')
  .select()
  .eq('user_id', userId)
  .order('sent_at', ascending: false);
```



### 3. Add updated_at to Models

```dart
class Profile {
  final String id;
  final String fullName;
  final DateTime createdAt;
  final DateTime? updatedAt;  // NEW: Add this
  // ... other fields
}
```

---



## Support & Questions

For issues during migration:

1. Check logs in Supabase Dashboard > Database > Logs
2. Review error messages carefully
3. Consult this guide's troubleshooting section
4. If stuck, restore from backup and retry

---



## Summary Checklist



### For Clean Installation

- [ ] Confirmed this is dev/test environment OR have complete backup
- [ ] Executed 00_drop_all.sql successfully
- [ ] All tables and functions dropped
- [ ] Proceeded with fresh installation (00_types.sql onwards)
- [ ] All 15 SQL files executed in order
- [ ] Post-migration verification passed
- [ ] Flutter app updated and tested
- [ ] Monitoring set up for new audit logs
- [ ] Maintenance tasks scheduled



### For Incremental Migration

- [ ] Database backup created
- [ ] Test environment migration successful
- [ ] Maintenance window scheduled
- [ ] All 15 SQL files executed in order (skipped 00_drop_all.sql)
- [ ] Post-migration verification passed
- [ ] Flutter app updated and tested
- [ ] Users notified about re-registering devices
- [ ] Monitoring set up for new audit logs
- [ ] Maintenance tasks scheduled

---

**Migration Complete!** 🎉

Your database now has:

- ✅ 40+ performance indexes
- ✅ Proper enum types
- ✅ Comprehensive audit trail
- ✅ Soft delete functionality
- ✅ Enhanced security (RLS)
- ✅ Data integrity constraints
- ✅ Full documentation

**Next Steps:**

1. Monitor application performance
2. Check audit logs daily for first week
3. Schedule regular maintenance tasks
4. Update Flutter app to use new features

