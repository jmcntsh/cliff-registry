#!/usr/bin/env bash
# gum — glamorous shell script primitives
#
# Template 1 (scripted fake). We show gum's canonical README use case:
# building a conventional-commit prompt flow from choose/input/confirm.

pause() { sleep "${1:-0.8}"; }
beat()  { sleep "${1:-0.3}"; }

type_line() {
  local s="$1" i
  for (( i=0; i<${#s}; i++ )); do
    printf '%s' "${s:$i:1}"
    sleep 0.02
  done
  printf '\n'
}

prompt() { printf '\033[2m$\033[0m '; }

clear
pause 0.6

prompt; type_line 'gum choose "fix" "feat" "docs" "style" "refactor" "test" "chore"'
beat
printf '\033[38;5;212m❯ feat\033[0m\n'
printf '  fix\n'
printf '  docs\n'
printf '  style\n'
printf '  refactor\n'
printf '  test\n'
printf '  chore\n'
pause 0.7

prompt; type_line 'gum input --value "feat(ui): " --placeholder "Summary of this change"'
beat
printf '\033[2mfeat(ui): \033[0madd keyboard shortcuts to browse mode\n'
pause 0.6

prompt; type_line 'gum confirm "Commit changes?" && git commit -m "feat(ui): add keyboard shortcuts"'
beat
printf '\033[38;5;212m✔\033[0m Commit changes?\n'
pause 0.3
printf '[main 9f3a6e1] feat(ui): add keyboard shortcuts\n'
printf ' 3 files changed, 42 insertions(+), 8 deletions(-)\n'
pause 1.4

clear
