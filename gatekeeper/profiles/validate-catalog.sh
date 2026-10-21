#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
catalog="${1:-${HERE}/catalog.json}"

command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 2; }
[[ -f "$catalog" ]] || { echo "catalog not found: $catalog" >&2; exit 2; }

jq -e '
  .apiVersion == "project-matrix.redhat.com/v1alpha1" and
  .kind == "GatekeeperProfileCatalog" and
  .layer == "Gateway" and
  .codeName == "Gatekeeper" and
  (.sources | length > 0) and
  (.capabilities | length > 0) and
  (.releaseContract | type == "string" and length > 0) and
  ([.sources[].id] | length == (unique | length)) and
  ([.capabilities[].id] | length == (unique | length)) and
  ([.profiles[].name] | length == (unique | length)) and
  ([.profiles[].name] | sort) == ["gateway-evaluation", "gateway-production"] and
  (. as $catalog |
    all($catalog.profiles[];
      . as $profile |
      all(($profile.requiredCapabilityIds + $profile.optionalCapabilityIds)[];
        . as $id | any($catalog.capabilities[]; .id == $id)
      )
    ) and
    all($catalog.profiles[];
      . as $profile |
      all($profile.requiredSources[];
        . as $id | any($catalog.sources[]; .id == $id)
      )
    ) and
    (.profiles[] | select(.lane == "innovation") | .previewSource == "upstream" and (.previewReleaseContract | type == "string" and length > 0))
  )
' "$catalog" >/dev/null

printf 'Gatekeeper profile catalog valid: %s\n' "$catalog"
