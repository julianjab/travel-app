---
name: take
description: >
  Tomar una issue del backlog de Vamos y arrancar a trabajarla en un worktree
  aislado. Lee la issue de GitHub, crea el worktree con branch siguiendo la
  convención `<ID>-<slug>`, mueve la card del Project a "In progress", y deja
  el cuerpo de la issue como contexto en el worktree para el agente que sigue.
  Triggers: "/take 14", "/take F1-06", "tomar issue 14", "arrancar la 14",
  "vamos por F1-06". NO mergea ni abre PR — para eso usá /pr o /ship.
argument-hint: "<issue-number-o-ID> [--base main]"
disable-model-invocation: false
---

## /take — Arrancar a trabajar una issue

Toma una issue del repo `julianjab/travel-app`, crea un worktree aislado y deja todo listo para que el agente siguiente trabaje sin perder contexto.

**Repo:** `julianjab/travel-app`
**Project:** `Vamos MVP` (#1, owner `julianjab`)
**Convención de branch:** `<ID>-<slug>` — ej. `F1-06-onboarding-miembro`

---

## Argumentos

`$ARGUMENTS` puede ser:

| Forma | Ejemplo | Comportamiento |
|---|---|---|
| Número de issue | `14` | `gh issue view 14` |
| ID del backlog | `F1-06` | Buscar issue cuyo título empiece con `[F1-06]` |
| Vacío | _(nada)_ | Listar issues `Todo` del milestone `MVP Caso 0` y pedir cuál |

Flag opcional: `--base main` (default).

---

## Pasos

Ejecutar en orden, abortar si alguno falla.

### 1. Resolver la issue

```bash
unset GH_TOKEN GITHUB_TOKEN
```

- Si `$ARGUMENTS` es un número → `ISSUE_NUM=$ARGUMENTS`.
- Si matchea `^[A-Z]+[0-9]*-[0-9]+$` (ej. `F1-06`):
  ```bash
  ISSUE_NUM=$(gh issue list --repo julianjab/travel-app --state all \
    --search "[$ID]" --json number,title \
    --jq ".[] | select(.title | startswith(\"[$ID]\")) | .number" | head -1)
  ```
- Si está vacío → mostrar `gh issue list --repo julianjab/travel-app --milestone "MVP Caso 0" --state open --label mvp` y preguntar cuál.

Validar: `ISSUE_NUM` no vacío. Si no, abortar con mensaje claro.

### 2. Leer la issue

```bash
gh issue view $ISSUE_NUM --repo julianjab/travel-app \
  --json number,title,body,labels,milestone,assignees,url > /tmp/take-issue.json
```

Extraer:
- `TITLE` (incluye `[ID]` al inicio)
- `ID` — primera ocurrencia de `\[([A-Z0-9-]+)\]` en el título
- `SLUG` — slugificar el resto del título (lowercase, sin acentos, espacios → `-`, max 40 chars)
- `BRANCH` = `$ID-$SLUG` (ej. `F1-06-onboarding-miembro`)

### 3. Crear worktree

Reusar el skill existente:

```
/worktree init $BRANCH --base main
```

(O ejecutar directo con `git worktree add ../.worktrees/$BRANCH -b $BRANCH origin/main` si `/worktree` no está disponible.)

### 4. Inyectar contexto en el worktree

Escribir `.claude/CONTEXT.md` dentro del worktree con:

```markdown
# Contexto de trabajo — [$ID] $TITLE

**Issue:** $URL
**Branch:** $BRANCH
**Milestone:** MVP Caso 0

## Cuerpo de la issue

<contenido del campo body>

## Convenciones del flujo

- Commit: `<type>(<ID>): <descripción>` — ej. `feat(F1-06): persistir tags del miembro`.
- PR: incluir `Closes #$ISSUE_NUM` en el body para auto-cerrar.
- Antes de PR: correr `/review` (lint + tests).
- Para abrir PR: `/pr` o `/ship`.

## Cuándo terminar

Criterio de hecho está en el cuerpo de la issue (línea **Done:**).
```

### 5. Mover la card a "In progress" en el Project

```bash
PROJECT_ID="PVT_kwHOAIgSic4BWXD0"  # Vamos MVP
ITEM_ID=$(gh project item-list 1 --owner julianjab --format json \
  --jq ".items[] | select(.content.number == $ISSUE_NUM) | .id")

STATUS_FIELD_ID=$(gh project field-list 1 --owner julianjab --format json \
  --jq '.fields[] | select(.name=="Status") | .id')

IN_PROGRESS_OPT=$(gh project field-list 1 --owner julianjab --format json \
  --jq '.fields[] | select(.name=="Status") | .options[] | select(.name=="In progress") | .id')

gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_ID" \
  --field-id "$STATUS_FIELD_ID" --single-select-option-id "$IN_PROGRESS_OPT"
```

Si falla (campo Status no existe aún) → log warning, no abortar. La auto-asignación de status se puede activar después en el Project.

### 6. Asignarse la issue (si no está)

```bash
gh issue edit $ISSUE_NUM --repo julianjab/travel-app --add-assignee @me
```

### 7. Reportar al usuario

Imprimir:

```
✓ Tomada issue #$ISSUE_NUM — [$ID] $TITLE
  Branch:   $BRANCH
  Worktree: <path>
  Project:  In progress
  Contexto: <path>/.claude/CONTEXT.md

Próximo paso: cd <path> && empezar a trabajar.
Cuando termines: /pr (auto-infiere `Closes #$ISSUE_NUM`).
```

---

## Reglas duras

- **No tocar el repo principal.** Todo trabajo de la issue va en el worktree.
- **No mergear desde acá.** El skill solo abre el flujo; cerrar es trabajo de `/pr` + merge en GitHub.
- **No crear branches sin ID.** Si la issue no tiene `[ID]` en el título → abortar y avisar al usuario que arregle el título primero.
- **No saltarse el `unset GH_TOKEN GITHUB_TOKEN`** al inicio: el token del entorno no tiene scope `project` y rompe el paso 5.

## Cuándo NO usar /take

- Hotfix sin issue → crear issue primero (1 línea, label `mvp`), luego `/take`.
- Refactor genérico que toca varios items → no encaja en una sola issue. Mejor `/worktree init` directo.
- Spike / exploración → `/worktree init spike-<tema>`.
