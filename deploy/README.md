# Despliegue de las simulaciones en `brusselator.carlosb.dev`

Las simulaciones (`web/`) son un sitio estático: no se compila, solo se copian archivos.
Se publican en el **mismo bucket y la misma distribución de CloudFront** que `carlosb.dev`, dentro del prefijo `brusselator/`, igual que MiniLLM.

```
brusselator.carlosb.dev ─┐
minillm.carlosb.dev ─────┼─► CloudFront E2DV1F1KKLSNTM ─► s3://caba-curriculum-vitae/
carlosb.dev ─────────────┘        │                          ├── index.html, css/, pages/ …  (CV)
                                  │                          ├── minillm/
                                  └─ carlosb-host-rewrite ──► └── brusselator/  (web/)
```

| Archivo | Ruta pública |
|---|---|
| `web/index.html` | https://brusselator.carlosb.dev/ |
| `web/cuda.html` | https://brusselator.carlosb.dev/cuda.html |
| `web/openmp.html` | https://brusselator.carlosb.dev/openmp.html |

## 1. Subir las simulaciones (cada vez que cambien)

Desde WSL o Git Bash, en la raíz del repo:

```bash
aws sso login --profile portfolio-deploy
deploy/deploy_web.sh --dry-run   # revisar qué cambiaría
deploy/deploy_web.sh             # subir + invalidar /brusselator/*
```

Sin el paso 2, el sitio igual queda en `https://carlosb.dev/brusselator/index.html`.

## 2. Activar el subdominio (una sola vez, en la consola de AWS)

CloudFront solo permite **una** función por evento, y `minillm-host-rewrite` ya está asociada en *Viewer request*. Por eso no se crea una función nueva: se reemplaza el código de la existente por [`cloudfront/carlosb-host-rewrite.js`](cloudfront/carlosb-host-rewrite.js), que conserva MiniLLM y agrega Brusselator.

El rol `portfolio-deploy` no puede modificar CloudFront, así que esto se hace con un usuario administrador:

1. **CloudFront → Functions → `minillm-host-rewrite`** → pestaña **Build**.
2. Pegar el contenido de `cloudfront/carlosb-host-rewrite.js` → **Save changes**.
3. Pestaña **Test** (opcional): evento *viewer request*, URL `/`, encabezado `host: brusselator.carlosb.dev` → la salida debe tener `uri: /brusselator/index.html`. Repetir con `host: minillm.carlosb.dev` → `/minillm/index.html`.
4. Pestaña **Publish** → **Publish function**. La asociación con el comportamiento por defecto se mantiene.
5. Esperar unos minutos y abrir `https://brusselator.carlosb.dev/`.

El DNS no necesita cambios: `*.carlosb.dev` ya apunta a esta distribución y su certificado ya cubre el comodín.

## 3. Comprobar

```bash
curl -sI https://brusselator.carlosb.dev/ | head -3                 # 200, text/html
curl -s  https://brusselator.carlosb.dev/ | grep -o '<title>[^<]*'  # "Brusselator · CUDA & OpenMP"
curl -s  https://minillm.carlosb.dev/ | grep -o '<title>[^<]*'      # MiniLLM sigue funcionando
```
