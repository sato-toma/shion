# CityGML test fixture

The fixture is downloaded on demand and is not stored in Git. From the repository root, run in Windows PowerShell:

```powershell
.\scripts\fetch-citygml-fixture.ps1
```

On Linux or macOS, run the script with PowerShell 7:

```powershell
pwsh -File scripts/fetch-citygml-fixture.ps1
```

The verified file is placed under `.local/test-data/citygml/`. The fetch script records its source, usage terms, attribution, and whether the file is modified.

## Initial fixture observations

- One approximately 1 km mesh of building data; the downloaded GML is about 640 KB.
- XML root: `CityModel`.
- 91 building features; all have a `gml:id`.
- Each feature has an LOD0 footprint and an LOD1 solid.
- Every feature has `measuredHeight`, `usage`, and `yearOfConstruction` fields.
- The coordinate reference identifier in the source is EPSG:6697.

This fixture is suitable for validating acquisition, XML reading, feature IDs, and basic geometry selection. It is not representative of a large city and cannot establish production-scale import performance.

## Initial import-granularity needs

- Select at least a spatial mesh and feature type.
- Select an available LOD without discarding the source feature ID.
- Keep logical feature identity and attributes separate from render-mesh batching.
- Measure import performance separately with a larger representative dataset.
