-- Reconstructed from the user-provided schema export dated 2026-10-13.
-- TEST ONLY. No production rows or credentials. Grants and RLS-enabled flags are test assumptions.
create table public."editors"("user_id" uuid not null);
create table public."articles"("author" text not null,
"body" text not null,
"category" text not null,
"created_at" timestamptz not null default now(),
"created_by" uuid not null default auth.uid(),
"featured" bool not null default false,
"id" uuid not null default gen_random_uuid(),
"image" text,
"summary" text not null default ''::text,
"title" text not null);
create table public."comments"("article_id" text not null,
"author" text not null,
"body" text not null,
"created_at" timestamptz not null default now(),
"id" uuid not null default gen_random_uuid(),
"parent_id" uuid,
"user_id" uuid);
create table public."comment_votes"("comment_id" uuid not null,
"created_at" timestamptz not null default now(),
"user_id" uuid not null,
"value" int2 not null);
alter table public."articles" add constraint "articles_pkey" PRIMARY KEY (id);
alter table public."articles" add constraint "articles_title_check" CHECK ((length(TRIM(BOTH FROM title)) > 0));
alter table public."comment_votes" add constraint "comment_votes_pkey" PRIMARY KEY (comment_id, user_id);
alter table public."comment_votes" add constraint "comment_votes_value_check" CHECK ((value = ANY (ARRAY['-1'::integer, 1])));
alter table public."comments" add constraint "comments_author_check" CHECK (((char_length(TRIM(BOTH FROM author)) >= 1) AND (char_length(TRIM(BOTH FROM author)) <= 80)));
alter table public."comments" add constraint "comments_body_check" CHECK (((char_length(TRIM(BOTH FROM body)) >= 1) AND (char_length(TRIM(BOTH FROM body)) <= 2000)));
alter table public."comments" add constraint "comments_id_article_unique" UNIQUE (id, article_id);
alter table public."comments" add constraint "comments_pkey" PRIMARY KEY (id);
alter table public."editors" add constraint "editors_pkey" PRIMARY KEY (user_id);
alter table public."articles" add constraint "articles_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id);
alter table public."comment_votes" add constraint "comment_votes_comment_id_fkey" FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE;
alter table public."comment_votes" add constraint "comment_votes_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public."comments" add constraint "comments_parent_same_article_fk" FOREIGN KEY (parent_id, article_id) REFERENCES comments(id, article_id) ON DELETE CASCADE;
alter table public."comments" add constraint "comments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table public."editors" add constraint "editors_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public."editors" enable row level security;
grant select,insert,update,delete on public."editors" to authenticated;
alter table public."articles" enable row level security;
grant select,insert,update,delete on public."articles" to authenticated;
grant select on public."articles" to anon;
alter table public."comments" enable row level security;
grant select,insert,update,delete on public."comments" to authenticated;
grant select on public."comments" to anon;
alter table public."comment_votes" enable row level security;
grant select,insert,update,delete on public."comment_votes" to authenticated;
grant select on public."comment_votes" to anon;
create policy "RCM editors can update article images" on public."articles" as PERMISSIVE for UPDATE to "authenticated" using((EXISTS ( SELECT 1
   FROM editors
  WHERE (editors.user_id = ( SELECT auth.uid() AS uid))))) with check((EXISTS ( SELECT 1
   FROM editors
  WHERE (editors.user_id = ( SELECT auth.uid() AS uid)))));
create policy "Solo editores pueden editar" on public."articles" as PERMISSIVE for UPDATE to "authenticated" using((EXISTS ( SELECT 1
   FROM editors
  WHERE (editors.user_id = ( SELECT auth.uid() AS uid))))) with check((EXISTS ( SELECT 1
   FROM editors
  WHERE (editors.user_id = ( SELECT auth.uid() AS uid)))));
create policy "Solo editores pueden eliminar" on public."articles" as PERMISSIVE for DELETE to "authenticated" using((EXISTS ( SELECT 1
   FROM editors
  WHERE (editors.user_id = ( SELECT auth.uid() AS uid)))));
create policy "Solo editores pueden publicar" on public."articles" as PERMISSIVE for INSERT to "authenticated" with check(((created_by = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM editors
  WHERE (editors.user_id = ( SELECT auth.uid() AS uid))))));
create policy "Todos pueden leer publicaciones" on public."articles" as PERMISSIVE for SELECT to "anon","authenticated" using(true);
create policy "Anyone can read comment votes" on public."comment_votes" as PERMISSIVE for SELECT to "anon","authenticated" using(true);
create policy "Visitors can cast their own votes" on public."comment_votes" as PERMISSIVE for INSERT to "authenticated" with check(((user_id = ( SELECT auth.uid() AS uid)) AND (COALESCE(( SELECT ((auth.jwt() ->> 'is_anonymous'::text))::boolean AS bool), false) OR (EXISTS ( SELECT 1
   FROM editors
  WHERE (editors.user_id = ( SELECT auth.uid() AS uid)))))));
create policy "Visitors can change their own votes" on public."comment_votes" as PERMISSIVE for UPDATE to "authenticated" using((user_id = ( SELECT auth.uid() AS uid))) with check(((user_id = ( SELECT auth.uid() AS uid)) AND (COALESCE(( SELECT ((auth.jwt() ->> 'is_anonymous'::text))::boolean AS bool), false) OR (EXISTS ( SELECT 1
   FROM editors
  WHERE (editors.user_id = ( SELECT auth.uid() AS uid)))))));
create policy "Visitors can remove their own votes" on public."comment_votes" as PERMISSIVE for DELETE to "authenticated" using((user_id = ( SELECT auth.uid() AS uid)));
create policy "Anyone can read comments" on public."comments" as PERMISSIVE for SELECT to "anon","authenticated" using(true);
create policy "Comentarios visibles para todos" on public."comments" as PERMISSIVE for SELECT to "public" using(true);
create policy "Registered users can post comments" on public."comments" as PERMISSIVE for INSERT to "authenticated" with check((user_id = auth.uid()));
create policy "Usuarios autenticados pueden comentar" on public."comments" as PERMISSIVE for INSERT to "public" with check((auth.uid() = user_id));
create policy "Cada editor consulta su permiso" on public."editors" as PERMISSIVE for SELECT to "authenticated" using((user_id = ( SELECT auth.uid() AS uid)));
