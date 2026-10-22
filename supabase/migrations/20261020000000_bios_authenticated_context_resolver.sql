-- HA-03E-02D: narrow authenticated-user BIOS access-context resolver.

create function public.resolve_bios_user_context() returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'profile', jsonb_build_object(
      'id', p.id,
      'display_name', p.display_name,
      'preferred_language_code', p.preferred_language_code
    ),
    'memberships', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', m.id,
          'tenant', jsonb_build_object(
            'id', t.id,
            'code', t.code,
            'name', t.name,
            'default_locale', t.default_locale,
            'default_time_zone', t.default_time_zone
          ),
          'roles', coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'id', r.id,
                'code', r.code,
                'name', r.name,
                'capabilities', jsonb_build_object(
                  'manage_memberships', r.can_manage_memberships,
                  'manage_role_assignments', r.can_manage_role_assignments,
                  'read_audit', r.can_read_audit
                )
              ) order by r.code
            )
            from bios_core.membership_roles mr
            join bios_core.roles r on r.id = mr.role_id
            where mr.tenant_membership_id = m.id
              and mr.tenant_id = m.tenant_id
              and mr.revoked_at is null
              and r.status = 'active'
          ), '[]'::jsonb)
        ) order by t.code
      )
      from bios_core.tenant_memberships m
      join bios_core.tenants t on t.id = m.tenant_id
      where m.profile_id = p.id
        and m.status = 'active'
        and t.status = 'active'
        and m.valid_from <= statement_timestamp()
        and (m.valid_until is null or m.valid_until > statement_timestamp())
    ), '[]'::jsonb)
  )
  from bios_core.profiles p
  where p.id = bios_internal.current_profile_id()
$$;

revoke all on function public.resolve_bios_user_context() from public, anon, authenticated, service_role;
grant execute on function public.resolve_bios_user_context() to authenticated;

comment on function public.resolve_bios_user_context() is
  'Read-only PostgREST RPC that resolves the authenticated principal to an active BIOS profile, active Tenant memberships, and current active role assignments.';
