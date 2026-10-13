-- Solo lectura. Confirma esquema y resultados después de ejecutar 01.
select count(*) as total_articulos,count(*) filter(where is_public) as publicos from public.articles;
select count(*) as comentarios_conservados from public.comments;
select count(*) as votos_guardados from public.comment_votes;
select comment_id,user_id,count(*) from public.comment_votes group by comment_id,user_id having count(*)>1;
select count(*) as equipos_catalogo from public.nfl_teams; -- Debe ser 32.
select id,edition,cardinality(team_ids) as posiciones,updated_at from public.nfl_rankings;
-- Sin ranking aún: cero filas es correcto. No se fabrica uno.
begin;
set local role anon;
select public.rcm_community_leaders();
select id,edition,team_ids,updated_at from public.nfl_rankings;
rollback;
