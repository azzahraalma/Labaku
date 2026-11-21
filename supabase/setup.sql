-- =====================================================================
-- LABAKU - setup backend TANPA EMAIL (jalankan SEKALI di Supabase > SQL Editor)
-- Murni pakai: Nama Pengguna + Nama Usaha + Password + PIN 6 digit.
-- Aman dijalankan ulang. Tidak perlu Edge Function dan tidak perlu setting Email Auth.
-- =====================================================================
create extension if not exists pgcrypto with schema extensions;

-- 1. Lepas ketergantungan ke auth.users (karena tidak memakai email/Supabase Auth)
alter table public.businesses drop constraint if exists businesses_owner_id_fkey;
alter table public.profiles   drop constraint if exists profiles_id_fkey;

-- 2. Tambah kolom password_hash di profiles (untuk hash bcrypt password)
alter table public.profiles add column if not exists password_hash text;

-- 3. Tabel percobaan PIN (3x salah = kunci 5 menit, server-side)
drop table if exists public.pin_attempts;
create table public.pin_attempts (
  user_id      uuid primary key references public.profiles(id) on delete cascade,
  attempts     int not null default 0,
  locked_until timestamptz
);
alter table public.pin_attempts enable row level security;

-- 4. Helper internal: verifikasi PIN + hitung percobaan
create or replace function public._check_pin(p_uid uuid, p_pin text) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare v_hash text; v_att public.pin_attempts%rowtype;
begin
  select * into v_att from public.pin_attempts where user_id = p_uid;
  if found and v_att.locked_until is not null and v_att.locked_until > now() then
    return jsonb_build_object('ok', false, 'left', 0, 'locked_until', v_att.locked_until);
  end if;

  select pin_hash into v_hash from public.profiles where id = p_uid;
  if v_hash is not null and v_hash = crypt(p_pin, v_hash) then
    delete from public.pin_attempts where user_id = p_uid;
    return jsonb_build_object('ok', true, 'left', 3);
  end if;

  insert into public.pin_attempts(user_id, attempts) values (p_uid, 1)
  on conflict (user_id) do update
    set attempts = public.pin_attempts.attempts + 1, locked_until = null
  returning * into v_att;

  if v_att.attempts >= 3 then
    update public.pin_attempts
      set attempts = 0, locked_until = now() + interval '5 minutes'
      where user_id = p_uid
      returning * into v_att;
    return jsonb_build_object('ok', false, 'left', 0, 'locked_until', v_att.locked_until);
  end if;

  return jsonb_build_object('ok', false, 'left', 3 - v_att.attempts);
end $$;

-- 5. Cek apakah nama usaha (slug) masih tersedia
create or replace function public.business_available(p_slug text) returns boolean
language sql stable security definer set search_path = public as
$$ select not exists (select 1 from public.businesses where slug = p_slug) $$;

-- 6. Cek identitas (nama pengguna + nama usaha)
create or replace function public.login_check(p_slug text, p_username text) returns text
language plpgsql stable security definer set search_path = public as $$
declare v_biz uuid;
begin
  select id into v_biz from public.businesses where slug = p_slug;
  if v_biz is null then
    if exists (select 1 from public.profiles where lower(username) = lower(trim(p_username)))
      then return 'business_invalid';
      else return 'both_invalid';
    end if;
  end if;
  if exists (
    select 1 from public.profiles
    where business_id = v_biz and lower(username) = lower(trim(p_username))
  ) then
    return 'ok';
  else
    return 'user_invalid';
  end if;
end $$;

-- 7. Daftar Bos + Usaha + Password + PIN dalam 1 transaksi (TANPA EMAIL)
drop function if exists public.register_owner(text,text,text,text,text,text,text,text);
create or replace function public.register_owner(
  p_username  text,
  p_password  text,
  p_nama      text,
  p_slug      text,
  p_kategori  text,
  p_deskripsi text,
  p_logo_url  text,
  p_foto_url  text,
  p_pin       text
) returns uuid
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_uid uuid := gen_random_uuid();
  v_biz uuid;
begin
  if p_pin !~ '^\d{6}$' then raise exception 'invalid_pin'; end if;
  if length(coalesce(p_password, '')) < 6 then raise exception 'password_short'; end if;
  if exists (select 1 from public.businesses where slug = p_slug) then
    raise exception 'business_taken';
  end if;

  insert into public.businesses(owner_id, nama, slug, kategori, deskripsi, logo_url)
    values (v_uid, trim(p_nama), p_slug, p_kategori, p_deskripsi, p_logo_url)
    returning id into v_biz;

  insert into public.profiles(id, business_id, username, role, foto_url, password_hash, pin_hash)
    values (
      v_uid,
      v_biz,
      trim(p_username),
      'bos',
      p_foto_url,
      crypt(p_password, gen_salt('bf')),
      crypt(p_pin, gen_salt('bf'))
    );

  return v_uid;
end $$;

-- 8. Login (Nama Pengguna + Nama Usaha + Password) dalam 1 panggilan
create or replace function public.login_user(
  p_slug     text,
  p_username text,
  p_password text
) returns jsonb
language plpgsql stable security definer set search_path = public, extensions as $$
declare
  v_biz  uuid;
  v_prof record;
begin
  select id into v_biz from public.businesses where slug = p_slug;
  if v_biz is null then
    if exists (select 1 from public.profiles where lower(username) = lower(trim(p_username))) then
      return jsonb_build_object('status', 'business_invalid');
    else
      return jsonb_build_object('status', 'both_invalid');
    end if;
  end if;

  select id, password_hash into v_prof
  from public.profiles
  where business_id = v_biz and lower(username) = lower(trim(p_username))
  limit 1;

  if not found then
    return jsonb_build_object('status', 'user_invalid');
  end if;

  if v_prof.password_hash is null or v_prof.password_hash <> crypt(p_password, v_prof.password_hash) then
    return jsonb_build_object('status', 'password_invalid');
  end if;

  return jsonb_build_object('status', 'ok', 'user_id', v_prof.id);
end $$;

-- 9. Verifikasi PIN
drop function if exists public.verify_pin(text);
create or replace function public.verify_pin(p_uid uuid, p_pin text) returns jsonb
language sql security definer set search_path = public as
$$ select public._check_pin(p_uid, p_pin) $$;

-- 10. Lupa PIN (verifikasi pakai Password -> simpan PIN baru)
create or replace function public.reset_pin(
  p_slug     text,
  p_username text,
  p_password text,
  p_new_pin  text
) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_login jsonb;
  v_uid   uuid;
begin
  if p_new_pin !~ '^\d{6}$' then
    return jsonb_build_object('status', 'invalid_pin');
  end if;

  v_login := public.login_user(p_slug, p_username, p_password);
  if v_login->>'status' <> 'ok' then
    return v_login;
  end if;

  v_uid := (v_login->>'user_id')::uuid;
  update public.profiles set pin_hash = crypt(p_new_pin, gen_salt('bf')) where id = v_uid;
  delete from public.pin_attempts where user_id = v_uid;
  return jsonb_build_object('status', 'ok');
end $$;

-- 11. Lupa Kata Sandi (verifikasi pakai PIN -> simpan Password baru, TANPA Edge Function)
create or replace function public.reset_password(
  p_slug         text,
  p_username     text,
  p_pin          text,
  p_new_password text
) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_biz uuid;
  v_uid uuid;
  v_res jsonb;
begin
  if length(coalesce(p_new_password, '')) < 6 then
    return jsonb_build_object('ok', false, 'left', 0, 'error', 'password_short');
  end if;

  select id into v_biz from public.businesses where slug = p_slug;
  if v_biz is null then
    return jsonb_build_object('ok', false, 'left', 0, 'error', 'business_invalid');
  end if;

  select id into v_uid from public.profiles
  where business_id = v_biz and lower(username) = lower(trim(p_username))
  limit 1;

  if v_uid is null then
    return jsonb_build_object('ok', false, 'left', 0, 'error', 'user_invalid');
  end if;

  v_res := public._check_pin(v_uid, p_pin);
  if (v_res->>'ok')::boolean then
    update public.profiles
      set password_hash = crypt(p_new_password, gen_salt('bf'))
      where id = v_uid;
  end if;

  return v_res;
end $$;

-- 12. Ambil profil user aktif (tanpa pernah membocorkan password_hash / pin_hash)
create or replace function public.get_profile(p_uid uuid) returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'id', p.id,
    'username', p.username,
    'role', p.role,
    'foto_url', p.foto_url,
    'business_id', p.business_id,
    'business_name', b.nama,
    'business_logo', b.logo_url
  )
  from public.profiles p
  left join public.businesses b on b.id = p.business_id
  where p.id = p_uid
  limit 1
$$;

-- 13. Hak eksekusi RPC
revoke all on function public._check_pin(uuid, text) from public, anon, authenticated;

grant execute on function public.business_available(text) to anon, authenticated;
grant execute on function public.login_check(text, text) to anon, authenticated;
grant execute on function public.register_owner(text,text,text,text,text,text,text,text,text) to anon, authenticated;
grant execute on function public.login_user(text, text, text) to anon, authenticated;
grant execute on function public.verify_pin(uuid, text) to anon, authenticated;
grant execute on function public.reset_pin(text, text, text, text) to anon, authenticated;
grant execute on function public.reset_password(text, text, text, text) to anon, authenticated;
grant execute on function public.get_profile(uuid) to anon, authenticated;

-- Lindungi kolom hash agar tidak bisa dibaca dari client
revoke select on public.profiles from anon, authenticated;
grant select (id, business_id, username, role, foto_url, tarif, satuan_tarif)
  on public.profiles to anon, authenticated;

-- 14. Storage bucket foto profil & logo usaha
insert into storage.buckets (id, name, public) values
  ('avatars', 'avatars', true),
  ('logos', 'logos', true)
on conflict (id) do nothing;

drop policy if exists "labaku_upload_own" on storage.objects;
drop policy if exists "labaku_update_own" on storage.objects;
drop policy if exists "labaku_public_upload" on storage.objects;
create policy "labaku_public_upload" on storage.objects for insert to anon, authenticated
  with check (bucket_id in ('avatars', 'logos'));

drop policy if exists "labaku_public_update" on storage.objects;
create policy "labaku_public_update" on storage.objects for update to anon, authenticated
  using (bucket_id in ('avatars', 'logos'));
