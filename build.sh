#!/usr/bin/env bash
# Re-export STLs, renders and STEP files; run the FreeCAD fit check if Lian Li's
# case model has been imported into lianli/ (see README).
set -e
cd "$(dirname "$0")"
OS="${OPENSCAD:-/c/Program Files/OpenSCAD/openscad.com}"
FC="${FREECADCMD:-/c/Program Files/FreeCAD 1.1/bin/freecadcmd.exe}"
export GPU_SUPPORT_REPO="$(cygpath -w "$PWD" 2>/dev/null || pwd)"
mkdir -p stl renders step

for p in rail column finger1 finger2 finger3 plate parts_in_case gpus; do
  "$OS" -o "stl/$p.stl" -D "part=\"$p\"" gpu_support.scad >/dev/null 2>&1 || echo "warning: $p export failed"
done
render() { "$OS" -o "renders/$1.png" --imgsize=1600,1200 --colorscheme=Tomorrow "${@:2}" gpu_support.scad >/dev/null 2>&1 || echo "warning: $1 render failed"; }
render view_iso    -D 'part="assembly"' --camera=-520,-380,560,-20,150,280
render view_front  -D 'part="assembly"' --camera=-20,-700,290,-20,150,290 --projection=ortho
render view_top    -D 'part="assembly"' --camera=-20,150,900,-20,150,200 --projection=ortho
render print_plate -D 'part="plate"'    --camera=112,-160,420,112,110,0

run_fc() { "$FC" -c "import os; exec(open(os.path.join(os.environ['GPU_SUPPORT_REPO'], 'scripts', '$1')).read())"; }
run_fc export_step.py
if [ -f lianli/case_standard.FCStd ]; then
  run_fc fit_check.py >/dev/null 2>&1
  cat lianli/fit_check.txt
else
  echo "lianli/case_standard.FCStd not found - skipping fit check (see README)"
fi
