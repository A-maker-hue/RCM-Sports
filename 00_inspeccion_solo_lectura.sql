-- Solo lectura. Ejecutar antes de la migración; no incluye datos de usuarios.
select table_name,column_name,data_type,is_nullable,column_default
from information_schema.columns where table_schema='public'
and table_name in ('articles','comments','comment_votes','editors') order by table_name,ordinal_position;
select tablename,policyname,permissive,roles,cmd,qual,with_check
from pg_policies where schemaname='public' and tablename in ('articles','comments','comment_votes','editors');
select conrelid::regclass as tabla,conname,pg_get_constraintdef(oid) as definicion
from pg_constraint where connamespace='public'::regnamespace
and conrelid in (to_regclass('public.articles'),to_regclass('public.comments'),to_regclass('public.comment_votes'),to_regclass('public.editors'));
select event_object_table,trigger_name,action_statement from information_schema.triggers
where trigger_schema='public' and event_object_table in ('articles','comments','comment_votes','editors');
-- Revisar también funciones SECURITY DEFINER antiguas que puedan escribir sin comprobar permisos.
select p.oid::regprocedure as funcion,p.proacl as permisos,p.proconfig as configuracion
from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.prosecdef;

-- Triggers sobre nuevas cuentas: comprobar que ninguno convierte lectores en editores automáticamente.
select n.nspname as esquema,c.relname as tabla,t.tgname as trigger,p.oid::regprocedure as funcion
from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace
join pg_proc p on p.oid=t.tgfoid where not t.tgisinternal and n.nspname='auth' and c.relname='users';
