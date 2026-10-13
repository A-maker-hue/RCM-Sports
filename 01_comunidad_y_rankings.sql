-- RCM Sports. Ejecutar primero 00_inspeccion_solo_lectura.sql y revisar ENTREGA.md.
-- Transacción atómica: cualquier incompatibilidad aborta TODO. No elimina filas.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';

do $$
declare tab text; col text;
begin
 if current_setting('server_version_num')::int < 150000 then
  raise exception 'RCM: se necesita PostgreSQL 15+ para vistas security_invoker';
 end if;
 foreach tab in array array['articles','comments','editors'] loop
  if to_regclass('public.'||tab) is null then raise exception 'RCM: falta tabla %. No ejecutar sobre otro proyecto.',tab; end if;
 end loop;
 if exists(select 1 from information_schema.columns where table_schema='public' and table_name='articles'
  and column_name in('status','visibility','published','is_published','deleted_at','deleted','is_deleted')) then
  raise exception 'RCM: existe otro sistema de visibilidad/publicación. Hay que integrarlo antes de ejecutar esta migración.';
 end if;
 foreach col in array array['id','title','body','category','author','image','summary','created_at','featured','created_by'] loop
  if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='articles' and column_name=col) then raise exception 'RCM: articles.% no existe; revisar estructura antes de continuar',col; end if;
 end loop;
 foreach col in array array['id','article_id','parent_id','user_id','author','body','created_at'] loop
  if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='comments' and column_name=col) then raise exception 'RCM: comments.% no existe; revisar estructura',col; end if;
 end loop;
 if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='editors' and column_name='user_id' and udt_name='uuid') then
  raise exception 'RCM: editors.user_id debe existir y ser UUID';
 end if;
end $$;

alter table public.articles add column if not exists is_public boolean not null default true;
-- Preserve the six static articles already shipped in index.html, without fake likes/comments.
-- They become normal editable database articles. Old ?article=1...6 URLs use legacy_id.
alter table public.articles add column if not exists legacy_id text;
create unique index if not exists rcm_article_legacy_id on public.articles(legacy_id) where legacy_id is not null;
do $$ begin
 if exists(select 1 from public.articles where title='Sorpresa en el Fútbol Colegial: Los novatos que revolucionan el ranking nacional' and id::text<>'4cf95ece-db8f-5bfb-81a6-79c7f6fa4c43') then
  raise exception 'RCM: ya existe una publicación con el título del ejemplo 1; revisar para no duplicarla';
 end if;
end $$;
insert into public.articles(id,title,body,category,author,image,summary,created_at,featured,created_by,legacy_id) values('4cf95ece-db8f-5bfb-81a6-79c7f6fa4c43','Sorpresa en el Fútbol Colegial: Los novatos que revolucionan el ranking nacional','<p>El fútbol americano colegial atraviesa una de las temporadas más impredecibles y apasionantes de los últimos años. Equipos fuera del Top 10 han logrado victorias históricas gracias al talento emergente de mariscales de campo novatos.</p>
                       <p>La velocidad de lectura en la bolsa de protección y la efectividad en pases profundos han marcado la diferencia en los momentos más calientes del último cuarto.</p>','Fútbol Americano Colegial','Adrián Mendoza','https://images.unsplash.com/photo-1566577739112-5180d4bf9390?w=1000&auto=format&fit=crop&q=80','Una revisión detallada de las jóvenes promesas universitarias que están rompiendo récords de yardas en la temporada de fútbol colegial.','2026-09-30T00:00:00Z',true,(select user_id from public.editors order by user_id limit 1),'1') on conflict(id) do nothing;
do $$ begin
 if exists(select 1 from public.articles where title='Dominio y Posesión: La lección táctica que definió el choque de la jornada' and id::text<>'0e4f30c4-d860-533c-9eff-a5e8b47edcd6') then
  raise exception 'RCM: ya existe una publicación con el título del ejemplo 2; revisar para no duplicarla';
 end if;
end $$;
insert into public.articles(id,title,body,category,author,image,summary,created_at,featured,created_by,legacy_id) values('0e4f30c4-d860-533c-9eff-a5e8b47edcd6','Dominio y Posesión: La lección táctica que definió el choque de la jornada','<p>En una auténtica exhibición táctica, el equipo local demostró que controlar el ritmo del mediocampo es la mejor defensa.</p>','Fútbol','Editor 2','https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800&auto=format&fit=crop&q=80','Cómo el juego de pases rápidos y la presión alta sofocaron la salida del rival en un partido lleno de intensidad.','2026-09-29T00:00:00Z',false,(select user_id from public.editors order by user_id limit 1),'2') on conflict(id) do nothing;
do $$ begin
 if exists(select 1 from public.articles where title='Estrategia Defensiva en la NFL: El Blitz que paraliza a los Quarterbacks élite' and id::text<>'7625cb83-c5ac-5601-9654-ed719e90b056') then
  raise exception 'RCM: ya existe una publicación con el título del ejemplo 3; revisar para no duplicarla';
 end if;
end $$;
insert into public.articles(id,title,body,category,author,image,summary,created_at,featured,created_by,legacy_id) values('7625cb83-c5ac-5601-9654-ed719e90b056','Estrategia Defensiva en la NFL: El Blitz que paraliza a los Quarterbacks élite','<p>Como se suele decir: las grandes defensivas son las que ganan partidos en enero.</p>','NFL','Editor 3','https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?w=800&auto=format&fit=crop&q=80','Analizamos las formaciones defensivas más agresivas empleadas este domingo para provocar capturas y balones sueltos.','2026-09-28T00:00:00Z',false,(select user_id from public.editors order by user_id limit 1),'3') on conflict(id) do nothing;
do $$ begin
 if exists(select 1 from public.articles where title='Noche de Récord: 45 Puntos y Canasta en la Bocina' and id::text<>'c5f7a75e-f17a-5501-b6d9-1b31100235e3') then
  raise exception 'RCM: ya existe una publicación con el título del ejemplo 4; revisar para no duplicarla';
 end if;
end $$;
insert into public.articles(id,title,body,category,author,image,summary,created_at,featured,created_by,legacy_id) values('c5f7a75e-f17a-5501-b6d9-1b31100235e3','Noche de Récord: 45 Puntos y Canasta en la Bocina','<p>La precisión desde la línea de tres puntos y una frialdad absoluta en los momentos decisivos sellaron la victoria.</p>','Básquetbol','Adrián Mendoza','https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800&auto=format&fit=crop&q=80','Un tiro espectacular a falta de 0.8 segundos le dio el triunfo al equipo de casa en un estadio enloquecido.','2026-09-27T00:00:00Z',false,(select user_id from public.editors order by user_id limit 1),'4') on conflict(id) do nothing;
do $$ begin
 if exists(select 1 from public.articles where title='Duelo Épico en la Pista Central: Batalla a cinco sets por el Grand Slam' and id::text<>'2b4f39c0-a88e-5e83-a9d1-19b4e59d9b47') then
  raise exception 'RCM: ya existe una publicación con el título del ejemplo 5; revisar para no duplicarla';
 end if;
end $$;
insert into public.articles(id,title,body,category,author,image,summary,created_at,featured,created_by,legacy_id) values('2b4f39c0-a88e-5e83-a9d1-19b4e59d9b47','Duelo Épico en la Pista Central: Batalla a cinco sets por el Grand Slam','<p>Con peloteos que superaron los 25 golpes y saques a más de 210 km/h, el encuentro se decidió en un tie-break del quinto set para el recuerdo.</p>','Tenis','Marco Ramirez','https://images.unsplash.com/photo-1622279457486-62dcc4a431d6?w=800&auto=format&fit=crop&q=80','Un enfrentamiento cargado de dinamismo y tiros ganadores que mantuvo en suspenso a la afición en la gran final.','2026-09-26T00:00:00Z',false,(select user_id from public.editors order by user_id limit 1),'5') on conflict(id) do nothing;
do $$ begin
 if exists(select 1 from public.articles where title='Ataque en la Montaña: La etapa reina sacude la clasificación general' and id::text<>'aaab1686-b13c-58b8-943a-5c6bf3eb564c') then
  raise exception 'RCM: ya existe una publicación con el título del ejemplo 6; revisar para no duplicarla';
 end if;
end $$;
insert into public.articles(id,title,body,category,author,image,summary,created_at,featured,created_by,legacy_id) values('aaab1686-b13c-58b8-943a-5c6bf3eb564c','Ataque en la Montaña: La etapa reina sacude la clasificación general','<p>El ascenso de categoría especial demonstrated quiénes tienen las piernas para luchar por el podio al final de la ronda ciclista.</p>','Ciclismo','Eduard Carrera','https://images.unsplash.com/photo-1541625602330-2277a4c46182?w=800&auto=format&fit=crop&q=80','Una arrancada fulgurante a falta de 12 kilómetros para la meta le otorga la victoria de etapa y la camiseta de líder.','2026-09-25T00:00:00Z',false,(select user_id from public.editors order by user_id limit 1),'6') on conflict(id) do nothing;

-- Las publicaciones actuales eran públicas. En adelante is_public=false las retira de la comunidad.

create or replace function public.rcm_is_editor() returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.editors e where e.user_id=(select auth.uid()));
$$;
revoke all on function public.rcm_is_editor() from public;
grant execute on function public.rcm_is_editor() to anon,authenticated;

-- Mantener cuentas/filas y políticas existentes. Las restricciones adicionales impiden
-- que una política permisiva antigua permita escribir como lector.
alter table public.editors enable row level security;
revoke insert,update,delete,truncate,references,trigger on public.editors from anon,authenticated,public;
grant select on public.editors to authenticated;
drop policy if exists rcm_editor_read on public.editors;
create policy rcm_editor_read on public.editors for select to authenticated using(user_id=(select auth.uid()));
drop policy if exists rcm_editor_read_guard on public.editors;
create policy rcm_editor_read_guard on public.editors as restrictive for select to anon,authenticated using(user_id=(select auth.uid()));
drop policy if exists rcm_editor_insert_guard on public.editors;
create policy rcm_editor_insert_guard on public.editors as restrictive for insert to anon,authenticated with check(false);
drop policy if exists rcm_editor_update_guard on public.editors;
create policy rcm_editor_update_guard on public.editors as restrictive for update to anon,authenticated using(false) with check(false);
drop policy if exists rcm_editor_delete_guard on public.editors;
create policy rcm_editor_delete_guard on public.editors as restrictive for delete to anon,authenticated using(false);

alter table public.articles enable row level security;
grant select on public.articles to anon,authenticated;
grant insert,update,delete on public.articles to authenticated;
revoke truncate on public.articles from anon,authenticated,public;
drop policy if exists rcm_articles_read on public.articles;
create policy rcm_articles_read on public.articles for select to anon,authenticated using(is_public or public.rcm_is_editor());
drop policy if exists rcm_articles_read_guard on public.articles;
create policy rcm_articles_read_guard on public.articles as restrictive for select to anon,authenticated using(is_public or public.rcm_is_editor());
drop policy if exists rcm_articles_insert on public.articles;
create policy rcm_articles_insert on public.articles for insert to authenticated with check(public.rcm_is_editor());
drop policy if exists rcm_articles_insert_guard on public.articles;
create policy rcm_articles_insert_guard on public.articles as restrictive for insert to anon,authenticated with check(public.rcm_is_editor());
drop policy if exists rcm_articles_update on public.articles;
create policy rcm_articles_update on public.articles for update to authenticated using(public.rcm_is_editor()) with check(public.rcm_is_editor());
drop policy if exists rcm_articles_update_guard on public.articles;
create policy rcm_articles_update_guard on public.articles as restrictive for update to anon,authenticated using(public.rcm_is_editor()) with check(public.rcm_is_editor());
drop policy if exists rcm_articles_delete on public.articles;
create policy rcm_articles_delete on public.articles for delete to authenticated using(public.rcm_is_editor());
drop policy if exists rcm_articles_delete_guard on public.articles;
create policy rcm_articles_delete_guard on public.articles as restrictive for delete to anon,authenticated using(public.rcm_is_editor());

-- Adaptar votos existentes sin adivinar el significado de información anterior.
do $$
declare idtype text; candidate text; candidates int;
begin
 if to_regclass('public.comment_votes') is null then
  select format_type(a.atttypid,a.atttypmod) into idtype from pg_attribute a
  where a.attrelid='public.comments'::regclass and a.attname='id';
  execute format('create table public.comment_votes(comment_id %s not null references public.comments(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,value smallint not null,primary key(comment_id,user_id))',idtype);
 else
  if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='comment_votes' and column_name='value') then
   select count(*),min(column_name) into candidates,candidate from information_schema.columns
    where table_schema='public' and table_name='comment_votes' and column_name in ('direction','vote','vote_value');
   if candidates=1 then execute format('alter table public.comment_votes rename column %I to value',candidate);
   elsif candidates=0 and not exists(select 1 from public.comment_votes) then alter table public.comment_votes add column value smallint;
   else raise exception 'RCM: votos existentes sin una columna de dirección inequívoca. No se modificó ningún dato; revisar esquema.'; end if;
  end if;
 end if;
 if exists(select 1 from information_schema.columns where table_schema='public' and table_name='comment_votes' and column_name='value' and data_type not in ('smallint','integer','bigint')) then
  raise exception 'RCM: la dirección de voto debe ser un entero -1 o 1. No se convierten datos automáticamente.';
 end if;
 if exists(select 1 from public.comment_votes where value is null or value not in(-1,1) or user_id is null or comment_id is null) then
  raise exception 'RCM: existen votos no válidos. Revisar sin borrar datos.';
 end if;
 if exists(select 1 from public.comment_votes group by comment_id,user_id having count(*)>1) then
  raise exception 'RCM: existen votos duplicados; revisar qué voto conservar antes de continuar.';
 end if;
end $$;
alter table public.comment_votes alter column value set not null;
alter table public.comment_votes alter column user_id set not null;
alter table public.comment_votes alter column comment_id set not null;
alter table public.comment_votes drop constraint if exists rcm_vote_direction;
alter table public.comment_votes add constraint rcm_vote_direction check(value in(-1,1));
do $$ declare cid smallint; uid smallint; begin
 select attnum into cid from pg_attribute where attrelid='public.comment_votes'::regclass and attname='comment_id';
 select attnum into uid from pg_attribute where attrelid='public.comment_votes'::regclass and attname='user_id';
 if not exists(select 1 from pg_index where indrelid='public.comment_votes'::regclass and indisunique and indisvalid
  and indpred is null and indexprs is null and indnkeyatts=2
  and indkey::text in(format('%s %s',cid,uid),format('%s %s',uid,cid))) then
  create unique index rcm_vote_once on public.comment_votes(comment_id,user_id);
 end if;
end $$;
create index if not exists rcm_comments_article on public.comments(article_id,created_at desc);
-- Replace only single-column foreign keys on vote rows pointing to the same known parent.
-- Keeping a previous NO ACTION FK alongside a CASCADE FK can block legitimate deletes.
do $$ declare fk record; begin
 for fk in select conname from pg_constraint
 where conrelid='public.comment_votes'::regclass and contype='f'
 and ((confrelid='public.comments'::regclass and conkey=array[(select attnum from pg_attribute where attrelid='public.comment_votes'::regclass and attname='comment_id')]::smallint[])
 or (confrelid='auth.users'::regclass and conkey=array[(select attnum from pg_attribute where attrelid='public.comment_votes'::regclass and attname='user_id')]::smallint[]))
 loop execute format('alter table public.comment_votes drop constraint %I',fk.conname); end loop;
end $$;
-- Validate foreign keys even on existing tables. An incompatible type or orphan aborts the transaction.
alter table public.comment_votes drop constraint if exists rcm_vote_comment_fk;
alter table public.comment_votes add constraint rcm_vote_comment_fk foreign key(comment_id) references public.comments(id) on delete cascade;
alter table public.comment_votes drop constraint if exists rcm_vote_user_fk;
alter table public.comment_votes add constraint rcm_vote_user_fk foreign key(user_id) references auth.users(id) on delete cascade;

alter table public.comments enable row level security;
grant select on public.comments to anon,authenticated;
grant insert,update,delete on public.comments to authenticated;
revoke truncate on public.comments from anon,authenticated,public;
-- Parent must be a comment from the same article, without depending on article ID type.
create or replace function public.rcm_check_comment_parent() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if tg_op='UPDATE' and (new.id is distinct from old.id or new.article_id is distinct from old.article_id or new.parent_id is distinct from old.parent_id or new.user_id is distinct from old.user_id) then
  raise exception 'RCM: no se puede cambiar la identidad, el propietario o el hilo de un comentario';
 end if;
 if new.parent_id is not null then
  if not exists(select 1 from public.comments c join public.articles a
   on (a.id::text=c.article_id::text or a.legacy_id=c.article_id::text)
   where c.id=new.parent_id and (a.id::text=new.article_id::text or a.legacy_id=new.article_id::text)) then
   raise exception 'RCM: la respuesta debe pertenecer al mismo artículo';
  end if;
  -- Preserve legacy article references and any existing composite parent foreign key.
  if tg_op='INSERT' then select c.article_id into new.article_id from public.comments c where c.id=new.parent_id; end if;
 end if;
 return new;
end $$;
revoke all on function public.rcm_check_comment_parent() from public;
drop trigger if exists rcm_check_parent on public.comments;
create trigger rcm_check_parent before insert or update on public.comments for each row execute function public.rcm_check_comment_parent();

drop policy if exists rcm_comments_read on public.comments;
create policy rcm_comments_read on public.comments for select to anon,authenticated using(exists(select 1 from public.articles a where (a.id::text=article_id::text or a.legacy_id=article_id::text) and a.is_public));
drop policy if exists rcm_comments_read_guard on public.comments;
create policy rcm_comments_read_guard on public.comments as restrictive for select to anon,authenticated using(exists(select 1 from public.articles a where (a.id::text=article_id::text or a.legacy_id=article_id::text) and a.is_public));
drop policy if exists rcm_comments_insert on public.comments;
create policy rcm_comments_insert on public.comments for insert to authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.articles a where (a.id::text=article_id::text or a.legacy_id=article_id::text) and a.is_public));
drop policy if exists rcm_comments_insert_guard on public.comments;
create policy rcm_comments_insert_guard on public.comments as restrictive for insert to anon,authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.articles a where (a.id::text=article_id::text or a.legacy_id=article_id::text) and a.is_public));
drop policy if exists rcm_comments_update on public.comments;
create policy rcm_comments_update on public.comments for update to authenticated using(user_id=(select auth.uid()) or public.rcm_is_editor()) with check(user_id=(select auth.uid()) or public.rcm_is_editor());
drop policy if exists rcm_comments_update_guard on public.comments;
create policy rcm_comments_update_guard on public.comments as restrictive for update to anon,authenticated using(user_id=(select auth.uid()) or public.rcm_is_editor()) with check((user_id=(select auth.uid()) or public.rcm_is_editor()) and exists(select 1 from public.articles a where (a.id::text=article_id::text or a.legacy_id=article_id::text) and a.is_public));
drop policy if exists rcm_comments_delete on public.comments;
create policy rcm_comments_delete on public.comments for delete to authenticated using(user_id=(select auth.uid()) or public.rcm_is_editor());
drop policy if exists rcm_comments_delete_guard on public.comments;
create policy rcm_comments_delete_guard on public.comments as restrictive for delete to anon,authenticated using(user_id=(select auth.uid()) or public.rcm_is_editor());

alter table public.comment_votes enable row level security;
grant select on public.comment_votes to anon,authenticated;
grant insert,update,delete on public.comment_votes to authenticated;
revoke truncate on public.comment_votes from anon,authenticated,public;
drop policy if exists rcm_votes_read on public.comment_votes;
create policy rcm_votes_read on public.comment_votes for select to anon,authenticated using(exists(select 1 from public.comments c where c.id=comment_id));
drop policy if exists rcm_votes_read_guard on public.comment_votes;
create policy rcm_votes_read_guard on public.comment_votes as restrictive for select to anon,authenticated using(exists(select 1 from public.comments c where c.id=comment_id));
drop policy if exists rcm_votes_insert on public.comment_votes;
create policy rcm_votes_insert on public.comment_votes for insert to authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.comments c where c.id=comment_id));
drop policy if exists rcm_votes_insert_guard on public.comment_votes;
create policy rcm_votes_insert_guard on public.comment_votes as restrictive for insert to anon,authenticated with check((not coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false) and user_id=(select auth.uid())) and exists(select 1 from public.comments c where c.id=comment_id));
drop policy if exists rcm_votes_update on public.comment_votes;
create policy rcm_votes_update on public.comment_votes for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()) and exists(select 1 from public.comments c where c.id=comment_id));
drop policy if exists rcm_votes_update_guard on public.comment_votes;
create policy rcm_votes_update_guard on public.comment_votes as restrictive for update to anon,authenticated using((not coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false) and user_id=(select auth.uid()))) with check((not coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false) and user_id=(select auth.uid())) and exists(select 1 from public.comments c where c.id=comment_id));
drop policy if exists rcm_votes_delete on public.comment_votes;
create policy rcm_votes_delete on public.comment_votes for delete to authenticated using(user_id=(select auth.uid()));
drop policy if exists rcm_votes_delete_guard on public.comment_votes;
create policy rcm_votes_delete_guard on public.comment_votes as restrictive for delete to anon,authenticated using((not coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false) and user_id=(select auth.uid())));

create or replace view public.rcm_comment_totals with(security_invoker=true) as
select c.id::text as id,a.id::text as article_id,c.parent_id::text as parent_id,c.author,c.body,c.created_at,a.title as article_title,
 count(v.value) filter(where v.value=1) as upvotes,count(v.value) filter(where v.value=-1) as downvotes,
 coalesce(max(v.value) filter(where v.user_id=(select auth.uid())),0)::int as my_vote
from public.comments c join public.articles a on (a.id::text=c.article_id::text or a.legacy_id=c.article_id::text) and a.is_public
left join public.comment_votes v on v.comment_id=c.id
group by c.id,c.article_id,c.parent_id,c.author,c.body,c.created_at,a.id,a.title;
grant select on public.rcm_comment_totals to anon,authenticated;

create or replace function public.rcm_set_comment_vote(p_comment_id text,p_vote integer) returns void
language plpgsql security invoker set search_path='' as $$
begin
 if auth.uid() is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise exception 'RCM: inicia sesión para votar'; end if;
 if p_vote is null or p_vote not in(-1,0,1) then raise exception 'RCM: voto inválido'; end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text||':'||p_comment_id,0));
 if not exists(select 1 from public.comments c join public.articles a on (a.id::text=c.article_id::text or a.legacy_id=c.article_id::text) where c.id::text=p_comment_id and a.is_public) then
  raise exception 'RCM: comentario no disponible';
 end if;
 if p_vote=0 then delete from public.comment_votes where comment_id::text=p_comment_id and user_id=auth.uid();
 else
  insert into public.comment_votes(comment_id,user_id,value)
  select c.id,auth.uid(),p_vote from public.comments c where c.id::text=p_comment_id
  on conflict(comment_id,user_id) do update set value=excluded.value;
 end if;
end $$;
revoke all on function public.rcm_set_comment_vote(text,integer) from public;
grant execute on function public.rcm_set_comment_vote(text,integer) to authenticated;

create or replace function public.rcm_community_leaders() returns jsonb
language sql stable security invoker set search_path='' as $$
 select jsonb_build_object(
  'supported',(select to_jsonb(c) from public.rcm_comment_totals c where upvotes>0 order by upvotes desc,created_at desc,id desc limit 1),
  'questioned',(select to_jsonb(c) from public.rcm_comment_totals c where downvotes>0 order by downvotes desc,created_at desc,id desc limit 1));
$$;
revoke all on function public.rcm_community_leaders() from public;
grant execute on function public.rcm_community_leaders() to anon,authenticated;

create table if not exists public.nfl_teams(id text primary key,name text not null,logo text not null);
insert into public.nfl_teams(id,name,logo) values
('ARI','Arizona Cardinals','https://a.espncdn.com/i/teamlogos/nfl/500/ari.png'),
('ATL','Atlanta Falcons','https://a.espncdn.com/i/teamlogos/nfl/500/atl.png'),
('BAL','Baltimore Ravens','https://a.espncdn.com/i/teamlogos/nfl/500/bal.png'),
('BUF','Buffalo Bills','https://a.espncdn.com/i/teamlogos/nfl/500/buf.png'),
('CAR','Carolina Panthers','https://a.espncdn.com/i/teamlogos/nfl/500-dark/car.png'),
('CHI','Chicago Bears','https://a.espncdn.com/i/teamlogos/nfl/500/chi.png'),
('CIN','Cincinnati Bengals','https://a.espncdn.com/i/teamlogos/nfl/500/cin.png'),
('CLE','Cleveland Browns','https://a.espncdn.com/i/teamlogos/nfl/500/cle.png'),
('DAL','Dallas Cowboys','https://a.espncdn.com/i/teamlogos/nfl/500/dal.png'),
('DEN','Denver Broncos','https://a.espncdn.com/i/teamlogos/nfl/500/den.png'),
('DET','Detroit Lions','https://a.espncdn.com/i/teamlogos/nfl/500/det.png'),
('GB','Green Bay Packers','https://a.espncdn.com/i/teamlogos/nfl/500/gb.png'),
('HOU','Houston Texans','https://a.espncdn.com/i/teamlogos/nfl/500/hou.png'),
('IND','Indianapolis Colts','https://a.espncdn.com/i/teamlogos/nfl/500/ind.png'),
('JAX','Jacksonville Jaguars','https://a.espncdn.com/i/teamlogos/nfl/500/jax.png'),
('KC','Kansas City Chiefs','https://a.espncdn.com/i/teamlogos/nfl/500/kc.png'),
('LAC','Los Angeles Chargers','https://a.espncdn.com/i/teamlogos/nfl/500/lac.png'),
('LAR','Los Angeles Rams','https://a.espncdn.com/i/teamlogos/nfl/500/lar.png'),
('LV','Las Vegas Raiders','https://a.espncdn.com/i/teamlogos/nfl/500/lv.png'),
('MIA','Miami Dolphins','https://a.espncdn.com/i/teamlogos/nfl/500/mia.png'),
('MIN','Minnesota Vikings','https://a.espncdn.com/i/teamlogos/nfl/500/min.png'),
('NE','New England Patriots','https://a.espncdn.com/i/teamlogos/nfl/500/ne.png'),
('NO','New Orleans Saints','https://a.espncdn.com/i/teamlogos/nfl/500/no.png'),
('NYG','New York Giants','https://a.espncdn.com/i/teamlogos/nfl/500/nyg.png'),
('NYJ','New York Jets','https://a.espncdn.com/i/teamlogos/nfl/500/nyj.png'),
('PHI','Philadelphia Eagles','https://a.espncdn.com/i/teamlogos/nfl/500/phi.png'),
('PIT','Pittsburgh Steelers','https://a.espncdn.com/i/teamlogos/nfl/500/pit.png'),
('SEA','Seattle Seahawks','https://a.espncdn.com/i/teamlogos/nfl/500/sea.png'),
('SF','San Francisco 49ers','https://a.espncdn.com/i/teamlogos/nfl/500/sf.png'),
('TB','Tampa Bay Buccaneers','https://a.espncdn.com/i/teamlogos/nfl/500/tb.png'),
('TEN','Tennessee Titans','https://a.espncdn.com/i/teamlogos/nfl/500/ten.png'),
('WAS','Washington Commanders','https://a.espncdn.com/i/teamlogos/nfl/500/wsh.png')
on conflict(id) do nothing;
alter table public.nfl_teams enable row level security;
revoke all on public.nfl_teams from anon,authenticated,public;
grant select on public.nfl_teams to anon,authenticated;
drop policy if exists rcm_teams_read on public.nfl_teams;
create policy rcm_teams_read on public.nfl_teams for select to anon,authenticated using(true);

create table if not exists public.nfl_rankings(
 id integer primary key default 1 check(id=1),edition text not null check(length(trim(edition)) between 1 and 100),
 team_ids text[] not null check(cardinality(team_ids)=10),updated_at timestamptz not null default clock_timestamp(),updated_by uuid not null references auth.users(id));
create table if not exists public.nfl_ranking_drafts(
 user_id uuid primary key references auth.users(id) on delete cascade,edition text not null check(length(trim(edition)) between 1 and 100),
 team_ids text[] not null check(cardinality(team_ids)=10));
alter table public.nfl_rankings enable row level security;
alter table public.nfl_ranking_drafts enable row level security;
revoke all on public.nfl_rankings from anon,authenticated,public;
revoke all on public.nfl_ranking_drafts from anon,authenticated,public;
grant select on public.nfl_rankings to anon,authenticated;
grant select,insert,update,delete on public.nfl_ranking_drafts to authenticated;
drop policy if exists rcm_ranking_read on public.nfl_rankings;
create policy rcm_ranking_read on public.nfl_rankings for select to anon,authenticated using(true);
drop policy if exists rcm_draft_owner on public.nfl_ranking_drafts;
create policy rcm_draft_owner on public.nfl_ranking_drafts for all to authenticated using(user_id=(select auth.uid()) and public.rcm_is_editor()) with check(user_id=(select auth.uid()) and public.rcm_is_editor());
drop policy if exists rcm_draft_guard on public.nfl_ranking_drafts;
create policy rcm_draft_guard on public.nfl_ranking_drafts as restrictive for all to anon,authenticated using(user_id=(select auth.uid()) and public.rcm_is_editor()) with check(user_id=(select auth.uid()) and public.rcm_is_editor());

create or replace function public.rcm_validate_ranking() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if array_ndims(new.team_ids)<>1 or array_lower(new.team_ids,1)<>1 or cardinality(new.team_ids)<>10 or (select count(distinct x) from unnest(new.team_ids) x)<>10
 or exists(select 1 from unnest(new.team_ids) x where x is null or not exists(select 1 from public.nfl_teams t where t.id=x)) then
  raise exception 'RCM: selecciona exactamente diez equipos distintos del catálogo';
 end if;
 return new;
end $$;
revoke all on function public.rcm_validate_ranking() from public;
drop trigger if exists rcm_ranking_validation on public.nfl_rankings;
create trigger rcm_ranking_validation before insert or update on public.nfl_rankings for each row execute function public.rcm_validate_ranking();

create or replace function public.rcm_publish_ranking(p_edition text,p_team_ids text[],p_expected_updated_at timestamptz default null) returns void
language plpgsql security definer set search_path='' as $$
declare existing_time timestamptz;
begin
 if auth.uid() is null or not public.rcm_is_editor() then raise exception 'RCM: solo administradores'; end if;
 if p_edition is null or length(trim(p_edition)) not between 1 and 100 then raise exception 'RCM: edición inválida'; end if;
 if p_team_ids is null then raise exception 'RCM: faltan equipos'; end if;
 -- Serializa también la primera publicación, cuando todavía no hay fila que bloquear.
 perform pg_advisory_xact_lock(73319,1);
 select updated_at into existing_time from public.nfl_rankings where id=1 for update;
 if existing_time is distinct from p_expected_updated_at then raise exception 'RCM_CONFLICT: cambió la versión publicada'; end if;
 insert into public.nfl_rankings(id,edition,team_ids,updated_at,updated_by)
 values(1,trim(p_edition),p_team_ids,clock_timestamp(),auth.uid())
 on conflict(id) do update set edition=excluded.edition,team_ids=excluded.team_ids,updated_at=excluded.updated_at,updated_by=excluded.updated_by;
 insert into public.nfl_ranking_drafts(user_id,edition,team_ids) values(auth.uid(),trim(p_edition),p_team_ids)
 on conflict(user_id) do update set edition=excluded.edition,team_ids=excluded.team_ids;
end $$;
revoke all on function public.rcm_publish_ranking(text,text[],timestamptz) from public;
grant execute on function public.rcm_publish_ranking(text,text[],timestamptz) to authenticated;

-- Grant usage only for identity/serial sequences actually owned by comment and value columns.
do $$ declare seq record; begin
 for seq in select distinct sn.nspname as schema_name,s.relname as sequence_name
 from pg_class s join pg_namespace sn on sn.oid=s.relnamespace join pg_depend d on d.objid=s.oid
 where s.relkind='S' and d.refobjid in('public.comments'::regclass,'public.comment_votes'::regclass) and d.deptype in('a','i')
 loop execute format('grant usage on sequence %I.%I to authenticated',seq.schema_name,seq.sequence_name); end loop;
end $$;
notify pgrst,'reload schema';
commit;
