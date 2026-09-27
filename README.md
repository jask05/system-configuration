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
| `herdr` | Copia la config de [herdr](https://herdr.dev) (tema, keybindings) y registra su integración con Claude Code |
