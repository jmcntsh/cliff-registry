#!/usr/bin/env bash
# harlequin — SQL IDE for the terminal (DuckDB / Postgres / SQLite)
#
# Template 1 (scripted fake). The signature view is: schema browser
# left, query editor top-right, results grid bottom-right. We mirror
# that with a small DuckDB-flavored query and tabular result.

pause() { sleep "${1:-0.8}"; }
beat()  { sleep "${1:-0.3}"; }

type_line() {
  local s="$1" i
  for (( i=0; i<${#s}; i++ )); do
    printf '%s' "${s:$i:1}"
    sleep 0.03
  done
  printf '\n'
}

prompt() { printf '\033[2m$\033[0m '; }

clear
pause 0.5

prompt; type_line 'harlequin sales.duckdb'
beat
pause 0.3
clear

printf '\033[1;38;5;213m  Harlequin \033[0m\033[2m  duckdb · sales.duckdb · run F4 · format F8 · ? help \033[0m\n'
printf '┌─Catalog─────────────┬─Query─────────────────────────────────────────────┐\n'
printf '│ ▾ main              │ \033[38;5;81mSELECT\033[0m region,                                   │\n'
printf '│   ▾ tables          │        \033[38;5;81mSUM\033[0m(amount) \033[38;5;81mAS\033[0m revenue,                  │\n'
printf '│     • orders        │        \033[38;5;81mCOUNT\033[0m(*)    \033[38;5;81mAS\033[0m orders                    │\n'
printf '│     • customers     │ \033[38;5;81mFROM\033[0m   orders                                     │\n'
printf '│     • products      │ \033[38;5;81mWHERE\033[0m  ordered_at >= \033[38;5;215m'\''2026-01-01'\''\033[0m              │\n'
printf '│   ▾ views           │ \033[38;5;81mGROUP\033[0m  \033[38;5;81mBY\033[0m region                                 │\n'
printf '│     • daily_revenue │ \033[38;5;81mORDER\033[0m  \033[38;5;81mBY\033[0m revenue \033[38;5;81mDESC\033[0m;                          │\n'
printf '└─────────────────────┴───────────────────────────────────────────────────┘\n'
printf '┌─Results  \033[2m4 rows · 38 ms · DuckDB 1.1.0\033[0m ─────────────────────────────────┐\n'
printf '│ region        │ revenue       │ orders                                  │\n'
printf '│ \033[2m──────────────┼───────────────┼───────────────\033[0m                          │\n'
printf '│ EMEA          │ \033[38;5;120m  4,128,330\033[0m  │ 12,448                                  │\n'
printf '│ NA            │ \033[38;5;120m  3,602,114\033[0m  │ 10,910                                  │\n'
printf '│ APAC          │ \033[38;5;120m  2,011,876\033[0m  │  6,205                                  │\n'
printf '│ LATAM         │ \033[38;5;120m    540,228\033[0m  │  1,773                                  │\n'
printf '└──────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  F4 run    F8 format    ctrl+e edit    ctrl+s save    ?  help \033[0m\n'
pause 4.0

clear
