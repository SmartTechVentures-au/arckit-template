#!/usr/bin/env bash
set -euo pipefail
image="${1:-arckit-template:test}"
workspace="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
temporary="$(mktemp -d)"
container=''
cleanup() {
  [[ -z "$container" ]] || docker rm -f "$container" >/dev/null
  rm -rf "$temporary"
}
trap cleanup EXIT
cat > "$temporary/test.env" <<'ENV'
ARCKIT_TEST_VALUE=literal value with spaces # and = and $HOME
GIT_USERNAME=Container Test
GIT_EMAIL=container@example.test
ENV
container="$(docker run -d --user vscode --env-file "$temporary/test.env" \
  --mount "type=bind,source=$workspace,target=/workspaces/renamed-template,readonly" \
  --workdir /workspaces/renamed-template "$image" sleep infinity)"
# Every exec is launched independently, not from an already-initialised shell.
for shell in bash sh zsh; do
  for mode in -c -lc -ic; do
    docker exec "$container" "$shell" "$mode" \
      'test "$ARCKIT_TEST_VALUE" = '\''literal value with spaces # and = and $HOME'\'' && command -v claude && command -v codex && command -v agent && case ":$PATH:" in *":$HOME/.npm-global/bin:"*) true ;; *) exit 1 ;; esac'
  done
done
docker exec "$container" bash .devcontainer/verify-tools.sh
docker exec "$container" bash .devcontainer/configure-git.sh
test "$(docker exec "$container" git config --global user.name)" = 'Container Test'
test "$(docker exec "$container" git config --global user.email)" = 'container@example.test'
docker exec "$container" python3 -m unittest discover -s tests -v
docker exec -d "$container" npm run serve
for _ in {1..20}; do
  if docker exec "$container" curl -fsS http://127.0.0.1:8080/README.md >/dev/null; then
    break
  fi
  sleep 1
done
docker exec "$container" curl -fsS http://127.0.0.1:8080/README.md >/dev/null
for path in .env .git/config %2eenv; do
  test "$(docker exec "$container" curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:8080/$path")" = 403
done
echo 'Container smoke tests passed.'
