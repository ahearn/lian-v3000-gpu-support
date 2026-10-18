# Convert Lian Li's V3000 PLUS STEP (Standard layout) into a FreeCAD document
# that fit_check.py uses. Lian Li's model is not part of this repo: download
# it from lian-li.com and extract it to lianli/20230207_V3000 PLUS_3D/.
#
# Run: freecadcmd -c "exec(open(r'<repo>/scripts/import_case.py').read())"
import os
import FreeCAD
import Import

repo = os.environ.get("GPU_SUPPORT_REPO", os.getcwd())
step = os.path.join(repo, "lianli", "20230207_V3000 PLUS_3D", "V3000 PLUS_Standard.stp")
doc = FreeCAD.newDocument("case")
Import.insert(step, doc.Name)
doc.saveAs(os.path.join(repo, "lianli", "case_standard.FCStd"))
