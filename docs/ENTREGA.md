# RCM Sports: entrega de comunidad y NFL

Estado: cambios preparados y probados localmente. **No se ha modificado Supabase, no se ha publicado la web y no se ha fusionado ninguna rama.**

Repositorio revisado: https://github.com/A-maker-hue/RCM-Sports

Base de trabajo: `7038202221fe63b79b9d499d58b68488317254b7`, rama `main`.
Rama creada localmente: `mejoras/comunidad-nfl-20261012`.
La integración de GitHub permitió leer, pero rechazó crear la rama remota con un error 403. Por tanto, esta entrega contiene los archivos para subirlos manualmente. No existe un PR creado por esta entrega.

## Qué encontré y qué cambié

| Área | Antes | Versión preparada |
|---|---|---|
| Publicaciones | Lectura/escritura Supabase y seis ejemplos incrustados en HTML | Un solo origen público en Supabase; migración de los seis ejemplos existentes sin sus métricas ni comentarios ficticios |
| Comentarios | Comentarios en Supabase; respuestas guardadas localmente | Comentarios y respuestas en Supabase; texto mostrado de forma segura |
| Votos | Contadores locales; al volver a cargar comentarios se ponían a cero | Un voto positivo o negativo por usuario y comentario, guardado y validado en Supabase |
| Compartir | Parámetro `?article=ID`, copiar enlace y `replaceState` | Enlace estable, compartir del dispositivo, copiar, alternativa visible si falla el portapapeles, Atrás/Adelante y estado de artículo ausente |
| Acceso | Dos formularios separados; cabecera pensada para administrador | Un solo acceso para lectores y administradores, sesión visible, registro y salida; se conservan las cuentas |
| Administración | Permiso comprobado en `editors`; faltaba un editor accesible para artículos existentes | Se conserva `editors`; edición de artículo e imagen por URL, con el mismo ID; políticas de backend preparadas |
| Más leído | Orden por «me gusta» del navegador | Lista conservada con aclaración visible: no mide lecturas reales |
| La comunidad opina | No existía | Más apoyado y más cuestionado, con votos reales, desempate por fecha y enlace al comentario |
| NFL | No existía ranking | Catálogo de 32 equipos, borrador por administrador y publicación atómica de diez equipos distintos |
| Estilos | Tailwind generaba estilos al abrir la página | CSS compilado incluido, manteniendo colores y diseño; ya no necesita cargar el compilador de Tailwind |

El archivo antiguo `Comentarios` se conserva sin modificar como referencia. La web sigue usando `index.html`.

### Conservación de datos y compatibilidad

- La API pública permitió confirmar que existe `comment_votes.value`. La migración revisada conserva la columna `value` y sus valores, y reutiliza la clave primaria existente. También admite instalaciones anteriores con `vote`, `direction` o `vote_value`; si hay ambigüedad, se detiene.
- La consulta pública de artículos no devolvió filas. Eso **no demuestra** que la tabla esté vacía: podría ser resultado de sus políticas. La revisión del esquema desde SQL Editor sigue siendo necesaria.
- Hay comentarios reales asociados al artículo antiguo `1`. Los seis ejemplos que estaban en HTML se importan como artículos normales, con UUID estable y `legacy_id`. Los comentarios conservan sus IDs y referencias originales. La vista de lectura resuelve esas referencias; no se reescriben ni borran comentarios.
- Los enlaces anteriores `?article=1` a `?article=6` siguen abriendo el artículo correspondiente. Los nuevos enlaces usan el UUID permanente.
- Si ya existe un artículo con el mismo título y otro ID, el SQL se detiene para evitar duplicarlo. Hay que revisar esa coincidencia antes de continuar.
- Los comentarios de publicaciones ausentes se conservan, pero no aparecen públicamente ni entre los destacados. Esto también se aplica a antiguas referencias como `pick-nfl-1` si no existe su publicación.
- Los seis artículos importados pueden editarse o eliminarse después con las herramientas de administrador. No reaparecerán desde el HTML.
- Los votos y comentarios ficticios de los ejemplos **no** se convierten en actividad de lectores. Tampoco se intenta importar los votos locales, porque no permiten verificar quién votó.

## Tu primer paso: inspeccionar Supabase sin cambiar nada

1. Abre https://supabase.com/dashboard y entra en el proyecto que utiliza tu web. Su identificador es `zahuhmvmqvxaunqebqaa`.
2. En el menú izquierdo, abre **SQL Editor**.
3. Crea una consulta nueva con **New query** o el botón **+**.
4. En el ZIP, abre `supabase/00_inspeccion_solo_lectura.sql` con el Bloc de notas.
5. Copia todo su contenido y pégalo en SQL Editor.
6. Pulsa **Run**.
7. Comparte el resultado o capturas de las tablas de resultados para revisar compatibilidad. Esa consulta obtiene nombres de columnas, restricciones, políticas y metadatos de funciones; no obtiene contraseñas ni claves. No envíes claves privadas.

**Actualización del 13 de octubre:** ya recibí la inspección y probé la migración con sus columnas, restricciones y políticas. No aparecieron triggers en ese resultado. La prueba se ejecutó en una base aislada; no en tu proyecto real. Primero prepara la rama de GitHub siguiendo el apartado siguiente y coordina después la migración con la actualización de la web. Consulta `REVISION-SUPABASE.md`. Las funciones privilegiadas no incluidas en el resultado y los permisos efectivos del proyecto siguen fuera de esta comprobación.

La migración ya se comprobó con el esquema que enviaste y con un segundo esquema de prueba compatible. También se detiene ante votos duplicados o inválidos, tipos incompatibles, un sistema de visibilidad desconocido, coincidencias de artículos o PostgreSQL anterior a 15. No borres datos para superar un error: comparte el mensaje y ajustaremos la migración.

## Subir los cambios a una rama de GitHub

Esto guarda código en una rama para revisión. No implica fusionarlo.

1. Descarga y extrae `RCM-Sports-mejoras-revisadas.zip`.
2. Abre https://github.com/A-maker-hue/RCM-Sports y entra en **Code**.
3. Pulsa el selector que muestra **main**.
4. Escribe `mejoras/comunidad-nfl-20261012` y elige **Create branch … from main**.
5. Comprueba que el selector muestra la rama nueva.
6. Pulsa **Add file → Upload files**.
7. Dentro de la carpeta extraída `RCM-Sports`, arrastra sus archivos y carpetas a GitHub. `index.html`, `assets`, `supabase`, `docs` y `tests` deben quedar directamente en la raíz del repositorio, **no dentro de otra carpeta RCM-Sports**. También se incluyen README, package.json, package-lock.json y tailwind.config.cjs.
8. Escribe como mensaje: `Añadir votos persistentes, comunidad y rankings NFL`.
9. Confirma el guardado con **Commit changes**, comprobando que el destino es la rama nueva.
10. Si aparece **Compare & pull request**, puedes abrir la comparación. Deja el PR en borrador si lo creas; no pulses **Merge pull request** todavía.

Si `main` recibió cambios después del commit base indicado arriba, no sobreescribas a ciegas `index.html`: hay que integrar esos cambios antes de subir esta versión. El ZIP incluye `cambios.patch` y un paquete Git para una revisión técnica.

En **Settings → Pages**, comprueba qué rama publica el sitio. No cambies la fuente de publicación a la rama de trabajo. Se comprobó que la URL pública responde desde GitHub Pages, pero no tuve acceso a su configuración privada.

## Ejecutar la migración después de revisar la inspección

**Orden de instalación:** prepara primero los archivos nuevos en la rama, sin publicarla. La migración importa a Supabase los seis ejemplos que hoy están en el HTML; la versión antigua puede mostrarlos duplicados durante el intervalo entre ejecutar SQL y actualizar la web. Por eso no ejecutes esta migración aisladamente varios días antes de cambiar el frontend. Ninguna de las dos acciones se ha hecho automáticamente.

1. Guarda una copia de los datos actuales de `articles`, `comments`, `comment_votes` y `editors` mediante las opciones de exportación o respaldo disponibles en tu proyecto. Conserva también el SQL de las políticas actuales obtenido en la inspección.
2. En SQL Editor, abre otra consulta nueva.
3. Copia todo `supabase/01_comunidad_y_rankings.sql` y pulsa **Run** una sola vez.
4. El archivo usa una transacción: si falla una comprobación, no se aplica la migración parcialmente. No elimines líneas ni datos para forzarla.
5. Si aparece **Success**, ejecuta `supabase/02_verificacion_solo_lectura.sql`.
6. La consulta de votos duplicados debe devolver cero filas. El catálogo debe contener 32 equipos. Que el ranking devuelva cero filas es correcto antes de publicar el primero.
7. Revisa la versión nueva y los casos manuales siguientes antes de decidir fusionar el PR.

No se necesita una clave `service_role` en el navegador, ni cambiar la clave pública ya existente. No se modifica ninguna cuenta ni se concede el rol de administrador a nuevos usuarios.

Las políticas nuevas son restrictivas para bloquear escrituras indebidas incluso si hay políticas permisivas antiguas. Conservan la tabla `editors` como única autoridad. Las operaciones de administrador deben seguir verificándose después en el proyecto real, incluidas las funciones privilegiadas antiguas que no se hayan revisado.

La migración es compatible con los IDs antiguos durante la transición. Los estilos y scripts nuevos requieren subir la carpeta `assets` completa junto con `index.html`.

## Cómo probar sin fusionar

Si tienes Python instalado:

1. En Windows, abre la carpeta extraída `RCM-Sports`.
2. Escribe `cmd` en la barra de dirección del Explorador y pulsa Enter.
3. Ejecuta `py -m http.server 8000`.
4. Abre http://localhost:8000 en el navegador.
5. Mantén esa ventana de comandos abierta mientras pruebas. Para detenerla, pulsa Ctrl+C.

Esto sirve la copia local sin publicarla. Después de ejecutar el SQL, esta copia utiliza tu Supabase real; cualquier comentario, voto o ranking que publiques allí sí se guarda en tu base de datos. Usa contenido claramente identificado como prueba.

Si no tienes Python, no hace falta instalar herramientas a ciegas: podemos seguir con la revisión de Supabase y escoger una forma de vista previa disponible en tu equipo. Abrir el HTML con doble clic no sirve para verificar correctamente URLs y funciones de compartir.

## Uso cotidiano

- **Lectores:** Iniciar sesión → crear cuenta o entrar. El mismo voto se retira al pulsarlo otra vez; el contrario lo reemplaza. Al fallar una solicitud, el contador no se incrementa de forma optimista.
- **Administradores con correo existente:** entrar por el mismo formulario utilizando su correo y contraseña habituales. La comprobación en `editors` conserva sus herramientas.
- **Editar una imagen:** abre el artículo → Editar publicación → cambia URL de Imagen → guarda. El enlace y los comentarios se conservan. Si no cambias el texto, se conserva también su HTML original. No se añadió un servicio nuevo de subida de archivos.
- **Ranking:** NFL → Editar ranking → escribe semana/edición → selecciona diez equipos. Las flechas suben o bajan posiciones. Guardar borrador no cambia lo que ve el público. Publicar las diez posiciones las cambia conjuntamente.
- Cada administrador tiene su borrador. Si otro administrador publica mientras editas, se detecta el conflicto y hay que abrir el editor otra vez para revisar la versión actual.
- En computadora, Pausar movimiento detiene la franja. Lista completa muestra la versión estática. En móvil o con movimiento reducido, la franja es manual y se recorre con el dedo.
- Los propios votos actualizan los destacados al terminar el guardado. Los cambios de otros visitantes se consultan cada 30 segundos mientras la pestaña está visible, sin recargar la página. La animación no consulta Supabase.

## Acceso sin correo y recuperación

Se reutiliza el mecanismo existente: el usuario escribe su nombre, y el código usa internamente `usuario@users.rcmsports.local` para Supabase Auth. Las contraseñas se gestionan con Supabase Auth; no se escriben en tablas públicas ni se guardan como texto plano por esta implementación.

Se verificó mediante la configuración pública de Auth que el registro está habilitado, el proveedor de contraseña/correo está activo y la confirmación por correo está desactivada. No se cambiaron esas opciones ni se crearon cuentas reales durante el trabajo.

**No existe recuperación automática de contraseña para esas direcciones ficticias.** La cuenta no debe entregarse a alguien que simplemente conozca el nombre de usuario. Queda una decisión pendiente antes de presentar una función de recuperación: códigos de recuperación de un solo uso, o correo real opcional y verificado. Recomiendo códigos de recuperación si quieres mantener estrictamente el registro sin correo. Implementarlos requiere una operación segura de backend y no forma parte de esta entrega.

Referencia oficial de autenticación: https://supabase.com/docs/guides/auth/passwords

## Enlaces y vistas previas sociales

Los enlaces usan el ID permanente en el parámetro `article`, manteniendo `/RCM-Sports/`. No requieren rutas de servidor ni un archivo 404 especial. Editar el título o la imagen no cambia el ID.

**No se implementaron vistas previas sociales específicas por artículo.** Todos los enlaces actuales cargan el mismo HTML inicial. Cambiar etiquetas mediante JavaScript no garantiza que los rastreadores las lean.

Propuesta compatible con GitHub Pages: generar archivos HTML individuales como `articulos/UUID/index.html`, con título, descripción, imagen, `og:url` y URL canónica escritos en el HTML. Habría que regenerarlos al publicar, editar u ocultar artículos, y enlazar esas páginas desde Compartir. Una acción de GitHub programada o un proceso de backend puede realizarlo; no conviene poner credenciales de escritura GitHub en el navegador. Alternativa: alojamiento que renderice cada artículo en el servidor. Ninguna de esas opciones se activó automáticamente.

GitHub Pages: https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages

## Logos y fuentes

El catálogo de 32 equipos se obtuvo de `teams_colors_logos.csv` de nflverse el 12 de octubre de 2026. Se excluyeron abreviaturas históricas y el alias duplicado de Rams. Los logos enlazan las URLs ESPN que incluye ese catálogo; ante un fallo se muestran las siglas y se mantiene el nombre.

- Catálogo: https://github.com/nflverse/nflverse-pbp/blob/master/teams_colors_logos.csv
- Documentación: https://nflreadr.nflverse.com/reference/load_teams.html
- Los logos y marcas pertenecen a sus respectivos titulares. Esta atribución no concede una licencia de uso. Su propósito aquí es identificar equipos en contenido editorial; no se presentan como marcas propias.

## Qué se comprobó

| Comprobación | Resultado y alcance |
|---|---|
| Migración sobre PostgreSQL PGlite | Pasó; también se volvió a ejecutar conservando datos |
| Columna existente `value` | Conservación probada sin renombrar ni borrar votos |
| Esquema proporcionado el 13 de octubre | Se reprodujeron sus columnas, restricciones y políticas; se confirmó el bloqueo previo de lectores y su corrección |
| Dos usuarios y conteos públicos | Pasó en SQL local y en navegador con transporte simulado |
| Cambiar, retirar y repetir petición de voto | Pasó; sin duplicados; error de guardado no cambia contador |
| Aislamiento por usuario | SQL local bloquea votos de otro usuario |
| Lector contra artículos, administradores y ranking | SQL local bloquea escrituras aunque se salte la interfaz y haya políticas permisivas antiguas |
| Destacados, empates y contenido oculto/eliminado | Pasó en SQL local |
| Comentarios antiguos y respuestas | Conservación de referencias antiguas y respuestas sobre esos comentarios probadas en SQL |
| Ranking | Borrador y publicación probados en navegador; permisos, validación atómica y conflictos probados en SQL |
| Enlaces, recarga, alias antiguos y Atrás/Adelante | Pasó en navegador local con una ruta de repositorio |
| Copiar, compartir y alternativa al portapapeles | Probados con APIs de dispositivo simuladas |
| Acceso encima del artículo | Pasó en navegador; un solo formulario y regreso al artículo |
| Edición de imagen | En navegador simulado conserva ID y HTML del artículo |
| Categorías y búsqueda | Pasaron en navegador |
| Texto malicioso en comentario/nombre | Se mostró como texto sin ejecutar código |
| Móvil y movimiento reducido | Revisados con Chromium, viewport de 390 px y preferencia de movimiento reducido |
| Página pública existente | Respondió HTTP 200 desde GitHub Pages |
| Tablas públicas y opciones de Auth | Lectura real, sin mutaciones; visibilidad privada y políticas pendientes |

**No se comprobó en producción:** migración sobre el esquema real, dos cuentas reales votando, usuarios administradores reales, posibles funciones privilegiadas anteriores, persistencia real del ranking nuevo, difusión en redes ni el menú nativo de compartir en un teléfono. Las pruebas de navegador emplearon un transporte Supabase simulado; no sustituyen esas comprobaciones. Las imágenes externas se bloquearon en las capturas de prueba para verificar el texto alternativo y evitar depender de la red.

La encuesta y el formulario de boletín existentes siguen siendo demostraciones locales. No se convirtieron en una encuesta compartida ni en una suscripción real. Los «me gusta» de artículos también siguen siendo locales; esta solicitud conectó los votos de comentarios.

## Comprobación manual antes de publicar

1. Abre la copia nueva en dos perfiles distintos de navegador y entra con dos cuentas lectoras de prueba.
2. Abre el mismo artículo, publica un comentario de prueba y dale un voto positivo desde cada cuenta. Ambas deben mostrar dos positivos tras la actualización.
3. Desde una cuenta cambia a negativo, retíralo y recarga. Comprueba los conteos y el voto seleccionado.
4. Cierra sesión y vuelve a entrar; los conteos públicos deben mantenerse.
5. Abre el enlace en una pestaña nueva, recárgalo y prueba Atrás/Adelante. Prueba también un artículo antiguo y uno eliminado.
6. Comprueba que La comunidad opina corresponde a los votos guardados y que su enlace enfoca el comentario.
7. Entra con un administrador, prepara el ranking, guarda borrador y comprueba desde el lector que aún no cambió. Luego publícalo y comprueba que aparecen las diez posiciones.
8. Confirma categorías, búsqueda, comentar, responder y editar imagen. Revisa también desde el móvil.
9. La revisión técnica de permisos debe incluir llamadas directas a Supabase como lector: ocultar los botones no basta. `tests/database.mjs` reproduce esos intentos en una base aislada.
10. Solo después de comprobarlo, decide si quieres fusionar el PR y publicar. Esta entrega no lo hace por ti.

## Archivos y reproducción técnica

- `index.html`: integración, acceso único, enlaces y edición.
- `assets/community.js`: votos, respuestas, destacados, compartir y rankings.
- `assets/community.css`: diseño y accesibilidad de las funciones nuevas.
- `assets/nfl-teams.js`: catálogo y URLs de logos.
- `assets/site.css`, `assets/styles-input.css`, `tailwind.config.cjs`: estilos compilados y sus fuentes.
- `supabase/00_inspeccion_solo_lectura.sql`, `01_comunidad_y_rankings.sql`, `02_verificacion_solo_lectura.sql`.
- `tests/database.mjs`, `tests/browser.cjs` y `tests/fixtures/observed-schema.sql`: pruebas aisladas; nunca utilizan tu Supabase de producción.
- `package.json`, `package-lock.json`, `.gitignore`, `README.md` y esta guía.

Para un revisor técnico: Node.js, `npm ci`, `npx playwright install chromium`, `npm test` y `npm run test:database:observed`. El test de navegador crea su propio servidor local en el puerto 8765. Los estilos se regeneran con `npm run build:css`. GitHub Pages sirve los archivos incluidos y no necesita ejecutar npm.

## Cinco mejoras para después — no implementadas

| Prioridad | Mejora | Impacto | Dificultad |
|---|---|---|---|
| 1 | Reportar comentarios y cola de moderación | Alto: proteger la comunidad al crecer | Media |
| 2 | Debates por partido con hora, estado y conversación | Alto: dar motivos para volver durante partidos | Media |
| 3 | Avisos de respuestas dentro de la web | Alto: facilitar conversaciones continuadas | Media |
| 4 | Encuestas deportivas reales con un voto por usuario | Medio-alto: participación rápida | Baja-media |
| 5 | Equipos favoritos y portada personalizada | Medio: contenido más relevante para cada lector | Media |
