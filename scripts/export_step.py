# Convert the print-oriented STLs in stl/ to STEP files in step/.
import os
import FreeCAD, Mesh, Part

base = os.environ.get("GPU_SUPPORT_REPO", os.getcwd())
for p in ["rail", "column", "finger1", "finger2", "finger3"]:
    m = Mesh.Mesh(os.path.join(base, "stl", f"{p}.stl"))
    sh = Part.Shape(); sh.makeShapeFromMesh(m.Topology, 0.05)
    so = Part.Solid(Part.Shell(sh.Faces)).removeSplitter()
    so.exportStep(os.path.join(base, "step", f"{p}.step"))
    print(f"{p}: valid={so.isValid()} vol={so.Volume:.0f} mm3 "
          f"bbox {so.BoundBox.XLength:.1f} x {so.BoundBox.YLength:.1f} x {so.BoundBox.ZLength:.1f}")
