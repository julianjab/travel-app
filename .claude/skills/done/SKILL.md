---
name: done
description: >
  Cerrar el ciclo de una issue del backlog de Vamos. Corre el quality gate
  (`/review`), abre PR con `Closes #N` autoinferido del nombre del branch
  (`<ID>-<slug>`), y deja la card del Project en "In review". El cierre del
  issue + paso a "Done" lo hace GitHub automáticamente al mergear el PR.
  Triggers: "/done", "terminé la tarea", "abrir PR", "estoy listo para PR".
  NO mergea solo — el merge es decisión humana en GitHub.
argument-hint: "[--draft] [--no-review]"
disable-model-invocation: false
---

## /done — Cerrar el ciclo de la issue

Pensado para correr **dentro del worktree** creado por `/take`. Toma el branch actual, infiere la issue asociada, corre el quality gate y abre el PR.

---

## Pasos

### 1. Validar contexto

```bash
unset GH_TOKEN GITHUB_TOKEN
BRANCH=$(git branch --show-current)
```

- Si `BRANCH` == `main` → abortar. `/done` no se corre en main.
- Extraer `ID` del nombre: regex `^([A-Z]+[0-9]*-[0-9]+)-`. Ej. `F1-06-onboarding-miembro` → `F1-06`.
- Si no matchea → abortar y avisar: el branch no sigue la convención.

### 2. Buscar la issue asociada

```bash
ISSUE_NUM=$(gh issue list --repo julianjab/travel-app --state all \
  --search "[$ID]" --json number,title \
  --jq ".[] | select(.title | startswith(\"[$ID]\")) | .number" | head -1)
```

Si no encuentra → abortar. El branch debe nacer de una issue.

### 3. Quality gate

A menos que se pase `--no-review`:

```
/review
```

Si hay errores de lint, tests, o type-check → abortar y mostrar al usuario qué arreglar. NO seguir con el PR.

### 4. Push + abrir PR

```bash
git push -u origin "$BRANCH"

# Tomar título de la issue como base del PR title
ISSUE_TITLE=$(gh issue view $ISSUE_NUM --repo julianjab/travel-app --json title --jq .title)

PR_BODY=$(cat <<EOF
## Resumen

<rellenar con cambios principales — 2-3 bullets>

## Issue

Closes #$ISSUE_NUM

## Checklist

- [ ] Tests verdes (\`flutter test\` o equivalente)
- [ ] Lint limpio
- [ ] Criterio de hecho de la issue cubierto
- [ ] Microcopy revisada (si aplica)
EOF
)

DRAFT_FLAG=""
if [[ "$ARGUMENTS" == *"--draft"* ]]; then DRAFT_FLAG="--draft"; fi

gh pr create --repo julianjab/travel-app \
  --base main --head "$BRANCH" \
  --title "$ISSUE_TITLE" \
  --body "$PR_BODY" \
  $DRAFT_FLAG
```

### 5. Mover card del Project a "In review"

Si el campo `Status` del Project tiene opción `In review`:

```bash
ITEM_ID=$(gh project item-list 1 --owner julianjab --format json \
  --jq ".items[] | select(.content.number == $ISSUE_NUM) | .id")
STATUS_FIELD_ID=$(gh project field-list 1 --owner julianjab --format json \
  --jq '.fields[] | select(.name=="Status") | .id')
IN_REVIEW_OPT=$(gh project field-list 1 --owner julianjab --format json \
  --jq '.fields[] | select(.name=="Status") | .options[] | select(.name=="In review") | .id')
[ -n "$IN_REVIEW_OPT" ] && gh project item-edit --id "$ITEM_ID" \
  --project-id "PVT_kwHOAIgSic4BWXD0" \
  --field-id "$STATUS_FIELD_ID" --single-select-option-id "$IN_REVIEW_OPT"
```

Si no existe la opción → seguir, no es bloqueante.

### 6. Reportar

```
✓ PR abierto: <URL>
  Branch:   $BRANCH
  Closes:   #$ISSUE_NUM
  Status:   In review

Cuando se mergee, GitHub cierra la issue automáticamente y la card pasa a Done.
```

---

## Reglas duras

- **No mergear desde acá.** El merge es decisión humana en la UI de GitHub.
- **No saltarse `/review`** salvo flag explícito `--no-review` (y solo en hotfix urgente).
- **No abrir PR sin issue asociada.** Si el branch no tiene ID válido → abortar.
- **`Closes #N`** siempre va en el body del PR. Es lo que dispara el cierre automático.

## Cuándo NO usar /done

- Querés solo pushear sin abrir PR → `git push` directo.
- Trabajo en progreso sin estar listo para review → seguí trabajando, no abras PR todavía. `--draft` es para PRs ya formados pero pendientes de detalle.
