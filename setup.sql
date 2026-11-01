-- Bir kez Supabase SQL Editor'da çalıştırın. Gerçek bütçe verisi içermez.
create table if not exists public.budget_state (
 id integer primary key check (id=1),
 body jsonb not null,
 revision bigint not null default 0,
 updated_at timestamptz not null default now()
);
create table if not exists public.budget_history (
 revision bigint primary key, body jsonb not null,
 updated_at timestamptz not null
);
create table if not exists public.budget_operations (
 operation_id uuid primary key, created_at timestamptz not null default now()
);
alter table public.budget_state enable row level security;
alter table public.budget_history enable row level security;
alter table public.budget_operations enable row level security;
revoke all on public.budget_state, public.budget_history, public.budget_operations from anon, authenticated;
grant all on public.budget_state, public.budget_history, public.budget_operations to service_role;
insert into public.budget_state(id,body) values (1,'{"data":{"incomes":[],"expenses":[],"loans":[],"cards":[],"raises":[]},"versions":{}}'::jsonb) on conflict (id) do nothing;

create or replace function public.budget_snapshot()
returns jsonb language sql security invoker set search_path='' as $$
 select jsonb_build_object('data',body->'data','versions',body->'versions','revision',revision,'updatedAt',updated_at) from public.budget_state where id=1;
$$;
create or replace function public.budget_compare_and_swap(p_expected_revision bigint,p_body jsonb,p_operation_id uuid)
returns jsonb language plpgsql security invoker set search_path='' as $$
declare current_row public.budget_state%rowtype;
begin
 select * into current_row from public.budget_state where id=1 for update;
 if exists(select 1 from public.budget_operations where operation_id=p_operation_id) then
  return public.budget_snapshot();
 end if;
 if current_row.revision<>p_expected_revision then return jsonb_build_object('conflict',true); end if;
 if jsonb_typeof(p_body->'data') is distinct from 'object' or jsonb_typeof(p_body->'versions') is distinct from 'object' or octet_length(p_body::text)>4000000 then raise exception 'Invalid budget document'; end if;
 insert into public.budget_history(revision,body,updated_at) values (current_row.revision,current_row.body,current_row.updated_at);
 update public.budget_state set body=p_body,revision=revision+1,updated_at=now() where id=1;
 insert into public.budget_operations(operation_id) values (p_operation_id);
 delete from public.budget_history where revision<current_row.revision-99;
 delete from public.budget_operations where operation_id in (select operation_id from public.budget_operations order by created_at desc offset 500);
 return public.budget_snapshot();
end;
$$;
create or replace function public.budget_list_history()
returns jsonb language sql security invoker set search_path='' as $$
 select coalesce(jsonb_agg(x order by revision desc),'[]'::jsonb) from (select revision,updated_at from public.budget_history order by revision desc limit 100) x;
$$;
create or replace function public.budget_history_document(p_revision bigint)
returns jsonb language sql security invoker set search_path='' as $$
 select body from public.budget_history where revision=p_revision;
$$;
revoke all on function public.budget_snapshot() from public,anon,authenticated;
revoke all on function public.budget_compare_and_swap(bigint,jsonb,uuid) from public,anon,authenticated;
revoke all on function public.budget_list_history() from public,anon,authenticated;
revoke all on function public.budget_history_document(bigint) from public,anon,authenticated;
grant execute on function public.budget_snapshot(), public.budget_compare_and_swap(bigint,jsonb,uuid), public.budget_list_history(), public.budget_history_document(bigint) to service_role;
