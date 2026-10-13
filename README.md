# RCM Sports

Noticias deportivas y una comunidad de lectores que comentan, responden y votan.

La web se sirve con GitHub Pages. Las publicaciones, comentarios, votos y NFL Power Rankings utilizan Supabase. El ranking se prepara como borrador y se publica como un conjunto de diez posiciones. Las cuentas lectoras no reciben permisos de administración.

**Esta rama necesita revisar y ejecutar la migración de Supabase antes de publicarse.**

Lee [la guía de entrega e instalación en español](docs/ENTREGA.md). Empieza por `supabase/00_inspeccion_solo_lectura.sql`; no ejecutes la migración sin revisar la estructura y los permisos existentes.

No incluyas claves privadas ni claves `service_role` en esta web estática. La clave publicable identifica el proyecto; la protección de los datos depende de Auth, RLS y las funciones SQL.

Desarrollo: `npm ci`, `npm run build:css`, `npx playwright install chromium`, `npm test`.
La hoja de estilos compilada ya está incluida: GitHub Pages no requiere npm para servir el sitio.
