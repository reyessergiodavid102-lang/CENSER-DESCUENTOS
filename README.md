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

## Información laboral del trabajador

Desde el portal privado, el trabajador autenticado puede consultar:

- Trabajo diario, desde la colección Firestore `trabajoDiario`. Cargue un Excel o CSV con las columnas `fecha, cedula, nombre, labor, cantidad`.
- Préstamos y cuotas pendientes, desde la colección `prestamos`. Cargue `fecha, cedula, nombre, concepto, monto, cuota, cuotasPagadas, totalCuotas`.
- Un certificado laboral sencillo generado en el navegador, con nombre, cédula, fecha de ingreso y tipo de contrato. El certificado no incluye sueldo.

Los cargues se realizan desde el panel de administrador y reemplazan los registros anteriores de su respectiva colección.

## Robot financiero con Gemini

El portal de empleados incluye un chat de orientación financiera. El servidor
valida la sesión del trabajador y consulta sus préstamos, descuentos, volantes
de pago, registros de rodamiento y trabajo en Firestore. Envía a Gemini solo
un resumen agregado, sin nombre ni cédula. De los volantes usa totales
disponibles y de rodamiento conteos y montos cargados, nunca documentos
completos. Incluye todos los periodos disponibles y permite respuestas largas
en el chat. Los registros de trabajo no contienen salarios; el asistente no los
estima y puede pedir al trabajador que comparta montos aproximados
voluntariamente. Sus respuestas son orientación general y no reemplazan
asesoría contable o financiera profesional.

Para que el robot pueda separar correctamente los descuentos de un mismo mes
en años distintos, incluye el año en la columna `mes` del archivo, por ejemplo
`septiembre 2026` o `2026-09`. Los montos escritos como texto pueden usar
separadores colombianos, como `$ 1.234.567,89`.

Para activarlo:

1. Crea una clave de Gemini en [Google AI Studio](https://aistudio.google.com/app/apikey).
2. En Google Cloud Console, abre el proyecto `censer-descuentos`, crea una
   cuenta de servicio y asígnale el rol de solo lectura **Cloud Datastore Viewer**.
   Genera una clave JSON para esa cuenta. Firebase Authentication valida los
   tokens; esta cuenta solo permite que el servidor consulte Firestore.
3. En Render, abre el servicio web `censer-descuentos`, entra en **Environment**
   y agrega:
   - `GEMINI_API_KEY`: la clave creada en Google AI Studio.
   - `FIREBASE_SERVICE_ACCOUNT_JSON`: el contenido completo del archivo JSON de
     la cuenta de servicio.
4. Guarda las variables y despliega la versión más reciente del servicio Docker
   (manual deploy en Render o push al repositorio si tienes despliegue automático).

No pegues ninguna de esas claves en el HTML ni las subas al repositorio. Render
puede suspender sus servicios gratuitos cuando no reciben tráfico; la primera
consulta después de una pausa puede tardar. Google AI Studio también aplica sus
propios límites de uso para Gemini.