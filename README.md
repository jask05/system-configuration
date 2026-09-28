# system-configuration

Configuración personal (dotfiles y setup de herramientas) para replicar mi
entorno en cualquier máquina nueva, en lugar de copiar ficheros a mano o
reexplicárselo a un agente cada vez.

## Uso

```bash
git clone git@github.com:jask05/system-configuration.git
cd system-configuration
./install.sh
```

Sin argumentos, `install.sh` muestra un menú con los módulos disponibles y
tú eliges cuáles aplicar en esta máquina. También se puede ir directo:

```bash
./install.sh herdr claude-statusline   # instala solo estos módulos
./install.sh --dry-run                 # simula, no toca nada
./install.sh --list                    # lista módulos y sale
./install.sh -y herdr                  # sin confirmaciones interactivas
```

## Estructura

```
system-configuration/
├── install.sh              ← entry point, menú interactivo
├── lib/common.sh            ← helpers compartidos (backup, merge json, logs)
└── modules/
    ├── <módulo>/
    │   ├── MODULE.md        ← una línea de descripción (la lee el menú)
    │   ├── install.sh       ← lógica idempotente de instalación
    │   └── <ficheros de config que se copian>
    └── ...
```

Cada módulo es autocontenido. Añadir algo nuevo = crear una carpeta en
`modules/` con su `install.sh` — no hay que tocar nada más.

## Reglas comunes

- **Backup automático**: cualquier fichero existente que un módulo vaya a
  sobrescribir se copia antes a `~/.system-configuration-backups/<fecha>_<módulo>/`.
- **JSON se fusiona, no se pisa**: por ejemplo `~/.claude/settings.json` se
  actualiza clave a clave (via `jq`, o `python3` si no hay `jq`), así no se
  pierden plugins o permisos que ya tenga la máquina.
- **Idempotente**: volver a ejecutar un módulo no debe romper nada.

## Módulos actuales

| Módulo | Qué hace |
| --- | --- |
| `claude-statusline` | Instala la statusline de dos líneas de Claude Code (modelo, contexto, uso 5h/7d, git, coste) |
| `herdr` | Instala [herdr](https://herdr.dev) (instalador oficial), copia su config (tema, keybindings) y registra su integración con Claude Code. Pregunta si quieres instalar, configurar o ambos tras comprobar si ya está instalado |
| `atuin` | Instala [atuin](https://atuin.sh) (historial de shell sincronizado) vía su instalador oficial |
| `vim` | Instala mi config de vim (la del Mac con ajustes para VPS) y crea `~/.vim/{undo,swap,backup}`. Si vim no está, ofrece instalarlo con `apt-get`, `dnf` o `brew` |

## Atajos de herdr

Definidos en [`modules/herdr/config.toml`](modules/herdr/config.toml). Todos
empiezan por el **prefijo `Ctrl+Space`**: se pulsa el prefijo, se suelta y
luego la tecla.

| Atajo | Acción |
| --- | --- |
| `Ctrl+Space` `?` | Ayuda (lista todos los atajos) |
| `Ctrl+Space` `q` | Recargar la configuración |
| `Ctrl+Space` `d` | Desconectarse (detach) sin cerrar la sesión |
| **Paneles** | |
| `Ctrl+Space` `h` | Dividir en horizontal |
| `Ctrl+Space` `v` | Dividir en vertical |
| `Ctrl+Space` `x` | Cerrar el panel actual |
| `Ctrl+Space` `z` | Maximizar / restaurar el panel (zoom) |
| `Ctrl+Space` `;` | Volver al último panel |
| **Agentes** | |
| `Ctrl+Space` `Ctrl+P` | Agente anterior |
| `Ctrl+Space` `Ctrl+N` | Agente siguiente |
| `Ctrl+Space` `Ctrl+1`…`Ctrl+9` | Ir al agente N |

Los atajos que no aparecen aquí conservan el valor por defecto de herdr
(consúltalos con `Ctrl+Space` `?`).

## Vim

El módulo `vim` copia [`modules/vim/vimrc`](modules/vim/vimrc) a `~/.vimrc`,
pensado sobre todo para los VPS donde se despliega este repo. Lo que conviene
saber:

- **Deshacer persistente**: el historial de deshacer sobrevive al cerrar el
  fichero (`~/.vim/undo`). Swap y backups van a `~/.vim/swap` y
  `~/.vim/backup`, no a la carpeta de trabajo. El propio vimrc crea estos
  directorios si no existen, así que funciona aunque se copie suelto.
- **Portapapeles**: `clipboard=unnamed` solo funciona si vim tiene
  `+clipboard` (en macOS sí). En un VPS normalmente no: la opción no da error,
  simplemente yank/put se quedan dentro de vim.
- **Atajos propios**:
  - `Ctrl+L` — quita el resaltado de la última búsqueda.
  - `j` / `k` — se mueven por línea visual en texto con wrap (con número
    delante, p. ej. `5j`, se mueven por línea real).
- Al reabrir un fichero vuelve a la última posición del cursor.
- Sangrado de 4 espacios; 2 en YAML, JSON, HTML, CSS y JavaScript.
- `Esc` sin retardo (`ttimeoutlen=50`), algo que se nota dentro de herdr y por SSH.
- Muestra tabuladores (`»·`) y espacios al final de línea (`·`), salvo en Markdown y texto.
- Autocompletado con menú en la línea de comandos (`wildmenu`).
- `:vsplit` abre a la derecha y `:split` abajo (`splitright`, `splitbelow`).
- No guarda historial de deshacer para `/tmp`, `/dev/shm` ni ficheros `.env`,
  porque ese fichero contiene una copia del contenido.
- Para editar ficheros de root usa `sudoedit <fichero>`: `sudo vim` no carga
  este vimrc.

Esta copia parte de mi `~/.vimrc` del Mac pero tiene ajustes para VPS: no la
sobrescribas con `cp ~/.vimrc` sin revisar el diff.
