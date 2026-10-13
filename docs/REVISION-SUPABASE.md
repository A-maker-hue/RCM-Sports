# Revisión del esquema enviado el 13 de octubre de 2026

La exportación recibida contiene columnas, políticas y restricciones de `articles`, `comments`, `comment_votes` y `editors`. No contiene filas de triggers. No se consultaron ni modificaron datos privados del proyecto.

## Hallazgo principal

Las políticas actuales de INSERT y UPDATE de `comment_votes` exigen que el usuario sea propietario del voto **y**, además, que la sesión sea anónima de Supabase o que el usuario pertenezca a `editors`. Eso excluye a un lector registrado normal. Se reprodujo ese rechazo antes de ejecutar la migración en una base de prueba.

La migración revisada permite votar a los lectores registrados con su propio usuario, manteniendo las restricciones de propiedad. Las sesiones anónimas de Supabase no pueden crear o cambiar votos, aunque más adelante se habilite ese proveedor.

## Compatibilidad confirmada localmente

- `articles.id` es UUID y `comments.article_id` es texto: se conserva esa estructura.
- `articles.created_by` es obligatorio: la importación de los ejemplos necesita al menos un administrador existente en `editors`. Si no lo hay, no hay que crear uno a ciegas; se debe revisar la configuración.
- Se conserva `comment_votes.value`, de tipo smallint, sin renombrarla.
- Se reutiliza la clave primaria `(comment_id, user_id)`, que ya evita votos duplicados; no se agrega otro índice idéntico.
- Se conserva la relación compuesta `(parent_id, article_id)` de las respuestas. La prueba incluye responder a un comentario antiguo del artículo `1` después de la migración.
- Se probaron dos ejecuciones de la migración, votos previos, dos usuarios, cambio y retirada del voto, rechazo de votos ajenos, restricciones de administrador, destacados, ocultación y eliminación, ranking y conflictos de publicación.

Las pruebas se ejecutaron en PGlite, con las columnas, restricciones y políticas reconstruidas de tu exportación. Las concesiones de permisos a roles y el estado RLS se configuraron en esa base de prueba; la exportación no contiene esos dos datos. No es una prueba en tu Supabase real.

## Siguiente paso

1. Usa la entrega actualizada `RCM-Sports-mejoras-revisadas.zip`. Sustituye el ZIP anterior.
2. Prepara los archivos nuevos en una rama de GitHub, sin fusionarla ni cambiar la fuente de GitHub Pages.
3. Cuando la actualización de la web esté lista, guarda respaldo y ejecuta el `01_comunidad_y_rankings.sql` de esta entrega coordinándolo con la publicación de los archivos nuevos.

No conviene ejecutar ahora el SQL y dejar la web antigua durante días: al trasladar a la base los seis ejemplos existentes, la versión antigua puede mostrarlos dos veces hasta que se actualice el HTML. Esa es una consecuencia conocida de la transición, no un fallo en la conservación de los datos.

Después se ejecuta `02_verificacion_solo_lectura.sql` y se comprueban dos cuentas reales. No se ha ejecutado SQL, creado una rama remota, publicado ni fusionado automáticamente.
