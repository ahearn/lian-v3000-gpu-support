# Interference check of the support (stl/parts_in_case.stl) against Lian Li's
# case model and the GPU envelopes (stl/gpus.stl). Needs lianli/case_standard.FCStd
# (made by import_case.py from Lian Li's STEP, which is not in this repo).
# Writes lianli/fit_check.txt and lianli/V3000_with_gpu_support.FCStd.
import os
import FreeCAD, Mesh, Part

base = os.environ.get("GPU_SUPPORT_REPO", os.getcwd())
lianli = os.path.join(base, "lianli")
doc = FreeCAD.openDocument(os.path.join(lianli, "case_standard.FCStd"))
log = open(os.path.join(lianli, "fit_check.txt"), "w", encoding="utf-8")

def solids_from_stl(path):
    m = Mesh.Mesh(path)
    sh = Part.Shape(); sh.makeShapeFromMesh(m.Topology, 0.05)
    return sh, [Part.Solid(s) for s in sh.Shells]

sup_sh, sup_solids = solids_from_stl(os.path.join(base, "stl", "parts_in_case.stl"))
_, gpu_solids = solids_from_stl(os.path.join(base, "stl", "gpus.stl"))
log.write(f"support solids: {len(sup_solids)} vol={[round(s.Volume) for s in sup_solids]}\n")

bb = sup_sh.BoundBox; bb.enlarge(1.0)
log.write(f"support bbox X[{bb.XMin:.1f},{bb.XMax:.1f}] Y[{bb.YMin:.1f},{bb.YMax:.1f}] Z[{bb.ZMin:.1f},{bb.ZMax:.1f}]\n")
hits = 0; checked = 0
for o in doc.Objects:
    if o.TypeId != "Part::Feature": continue
    try:
        s = o.Shape.copy(); s.Placement = o.getGlobalPlacement()
    except Exception: continue
    if s.isNull() or not s.BoundBox.intersect(bb): continue
    checked += 1
    for i, ss in enumerate(sup_solids):
        if not s.BoundBox.intersect(ss.BoundBox): continue
        try:
            v = ss.common(s).Volume
        except Exception as e:
            log.write(f"  ERR {o.Label}: {e}\n"); continue
        if v > 0.01:
            hits += 1; log.write(f"  INTERFERENCE part{i} vs {o.Label}: {v:.2f} mm3\n")
        else:
            log.write(f"  ok part{i} vs {o.Label}: min gap {ss.distToShape(s)[0]:.2f} mm\n")
log.write(f"case parts near support: {checked}, interferences: {hits}\n")
log.write("(the two M3X6_5 screws are the stock vent-plate screws that get replaced)\n")
for j, g in enumerate(gpu_solids):
    for i, ss in enumerate(sup_solids):
        log.write(f"  part{i} vs gpu solid {j} (Y {g.BoundBox.YMin:.1f}..{g.BoundBox.YMax:.1f}): "
                  f"overlap {ss.common(g).Volume:.1f} mm3, gap {ss.distToShape(g)[0]:.2f}\n")

for i, ss in enumerate(sup_solids):
    doc.addObject("Part::Feature", f"Support_{i}").Shape = ss
for j, g in enumerate(gpu_solids):
    doc.addObject("Part::Feature", f"GPU_envelope_{j}").Shape = g
doc.saveAs(os.path.join(lianli, "V3000_with_gpu_support.FCStd"))
log.close()
