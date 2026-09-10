# CENSER-DESCUENTOS

## Configurar Supabase para volantes

El cargue de PDFs usa el bucket `volantes` y la tabla `volantes_pdf` de Supabase.
En `index.html`, completa `window.__SUPABASE_CONFIG__` con la URL del proyecto y
la clave pública `anon` de Supabase. No uses una clave `service_role` en el
navegador.

Ejecuta este SQL en el editor de Supabase:

```sql
insert into storage.buckets (id, name, public)
values ('volantes', 'volantes', true)
on conflict (id) do update set public = true;

create table if not exists public.volantes_pdf (
	cedula text not null,
	periodo text not null,
	"nombreArchivo" text not null,
	url text not null,
	storage_path text not null,
	actualizado_en timestamptz not null default now(),
	primary key (periodo, cedula)
);

alter table public.volantes_pdf enable row level security;

create policy "Consultar volantes"
on public.volantes_pdf for select
using (true);

create policy "Cargar volantes desde el panel"
on public.volantes_pdf for insert
with check (true);

create policy "Actualizar volantes desde el panel"
on public.volantes_pdf for update
using (true)
with check (true);

create policy "Leer PDFs de volantes"
on storage.objects for select
using (bucket_id = 'volantes');

create policy "Cargar PDFs de volantes"
on storage.objects for insert
with check (bucket_id = 'volantes' and (storage.extension(name) = 'pdf'));

create policy "Actualizar PDFs de volantes"
on storage.objects for update
using (bucket_id = 'volantes')
with check (bucket_id = 'volantes' and (storage.extension(name) = 'pdf'));
```

El login visible del panel continúa siendo Firebase Auth. Las políticas `insert`
y `update` de Supabase deben endurecerse antes de un entorno público, idealmente
con Supabase Auth o una Edge Function que valide la sesión de Firebase, porque
Supabase no puede evaluar directamente el usuario autenticado en Firebase.