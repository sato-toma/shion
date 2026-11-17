# Universal 3D Data Engine --- GitHub Development Plan

> **Project status:** Planning\
> **Document version:** 0.1\
> **Last updated:** 2026-11-17\
> **Working name:** `universal-3d-engine`

## 1. Project vision

Build a cross-platform 3D spatial-data engine that can import, inspect,
transform, optimize, validate, and export data from urban environments,
factories, CAD systems, and real-world scans.

The engine should preserve the meaning and structure of source data
wherever possible, rather than flattening every input into a polygon
mesh.

The project is not a Unity-only SDK or a Rust port of PLATEAU SDK. It is
an engine-independent foundation that can be used by:

-   MCP clients and AI agents
-   Command-line tools and future desktop applications
-   Unity, Unreal Engine, Godot, and Blender
-   NVIDIA Omniverse and other OpenUSD-based workflows
-   Other applications through stable APIs and file formats

### 1.1 Primary goals

1.  Integrate heterogeneous 3D and spatial data.
2.  Preserve source semantics, topology, hierarchy, coordinate systems,
    and metadata.
3.  Support large datasets through indexing, tiling, streaming, and lazy
    loading.
4.  Provide repeatable conversion and optimization pipelines.
5.  Validate output quality and target-application compatibility.
6.  Expose capabilities through a local-first MCP server and CLI.
7.  Build and test on Windows, Linux, and macOS.

### 1.2 Non-goals for the initial releases

-   Replacing mature CAD kernels or 3D rendering engines.
-   Implementing every format and conversion direction at once.
-   Reconstructing every Gaussian Splatting scene as an exact mesh.
-   Making OpenUSD the mandatory internal representation.
-   Requiring a hosted server or cloud service.
-   Guaranteeing bit-identical floating-point output across all
    operating systems and CPU architectures.

## 2. Design principles

### 2.1 C#-first, native code when justified

Use C# and modern .NET for the main engine, orchestration, data model,
pipeline, CLI, and MCP server.

Use native libraries behind narrow interfaces when they provide mature
or essential capabilities:

-   C++ / Open CASCADE Technology (OCCT) for CAD and B-Rep operations.
-   C++ / OpenUSD libraries for USD workflows where a suitable .NET
    implementation is unavailable.
-   Native or GPU libraries for measured performance bottlenecks.

Rust is optional. Introduce it only when a specific module benefits from
it and benchmarks or safety requirements justify the additional language
and build complexity.

### 2.2 Engine-independent core

The core must not depend on Unity, Unreal, Godot, Blender, or Omniverse
APIs.

Engine-specific adapters translate between the engine-independent model
and the target application's concepts.

### 2.3 Preserve meaning; make losses explicit

Do not silently convert every input into a mesh.

Keep source-specific representations where possible:

-   CAD: B-Rep, NURBS, topology, assemblies, units, tolerances.
-   Polygon data: vertices, faces, normals, UVs, materials.
-   Point clouds: positions, attributes, classification, coordinate
    reference system.
-   Gaussian Splatting: position, scale, rotation, opacity,
    spherical-harmonic coefficients, and source metadata.
-   GIS / city data: feature identity, attributes, hierarchy, semantic
    classes, and CRS.

Every conversion should declare: - What was preserved. - What was
transformed. - What was approximated. - What was discarded. - What
validation was performed.

### 2.4 Local-first operation

The default workflow should run locally:

-   MCP over stdio.
-   Local CLI and libraries.
-   Local files and cache.
-   No mandatory account, hosted service, or telemetry.
-   Explicitly scoped input/output directories.

### 2.5 Reproducible processing

A conversion should be representable as a recipe with explicit
parameters, tool versions, input fingerprints, and output artifacts.

## 3. High-level architecture

``` mermaid
flowchart TB
    Client["MCP Client / AI Agent"]
    CLI["CLI"]
    Apps["Unity / Unreal / Godot / Blender"]
    Omni["NVIDIA Omniverse"]

    MCP["MCP Server"]
    API["Public .NET API"]
    Adapters["Engine Adapters"]

    Core["C# Core Engine"]
    Model["Spatial Data Model"]
    Pipeline["Conversion Pipeline"]
    Index["Spatial Index / Streaming"]
    Validate["Validation / Optimization"]

    Native["Native Interop Layer"]
    OCCT["OCCT Adapter (C++)"]
    USD["OpenUSD Adapter (C++)"]
    GPU["Optional GPU / Native Modules"]

    Formats["Format Modules"]
    Artifacts["Local Dataset / Cache / Export Artifacts"]

    Client --> MCP
    CLI --> API
    Apps --> Adapters
    Omni --> Adapters
    MCP --> API
    Adapters --> API
    API --> Core
    Core --> Model
    Core --> Pipeline
    Core --> Index
    Core --> Validate
    Core --> Native
    Native --> OCCT
    Native --> USD
    Native --> GPU
    Core --> Formats
    Formats --> Artifacts
    Pipeline --> Artifacts
```

### 3.1 Main layers

  -----------------------------------------------------------------------
  Layer                   Responsibility          Initial implementation
  ----------------------- ----------------------- -----------------------
  Public API              Stable entry points for .NET
                          applications            

  MCP Server              AI-agent tools and      C# / .NET
                          resources               

  CLI                     Scriptable local        C# / .NET
                          workflows               

  Core                    Data model,             C# / .NET
                          orchestration,          
                          processing              

  Format modules          Importers and exporters C# first; native
                                                  bindings where needed

  Native interop          Isolate C/C++           C ABI + P/Invoke
                          dependencies            

  Engine adapters         Application-specific    Separate projects
                          integration             

  Artifact store          Local datasets, cache,  Filesystem
                          outputs, reports        
  -----------------------------------------------------------------------

## 4. Technology strategy

Technology choices below are initial candidates, not permanent
commitments. Confirm package health, supported platforms, licenses, and
maintenance status before adoption.

  -----------------------------------------------------------------------
  Area                    Preferred approach      Notes
  ----------------------- ----------------------- -----------------------
  Main language           C# / modern .NET        Core, API, CLI, MCP

  Native boundary         C ABI + P/Invoke        Avoid exposing C++
                                                  classes directly

  CAD kernel              OCCT                    Preserve B-Rep and
                                                  assembly data

  Scene interchange       OpenUSD                 Scene composition,
                                                  hierarchy, references

  Lightweight interchange glTF                    Runtime-oriented model
                                                  delivery

  Geospatial streaming    3D Tiles                Large spatial datasets
                                                  and tiled delivery

  Mesh optimization       meshoptimizer and       Benchmark before
                          compatible tools        integration

  Texture delivery        KTX2 / Basis Universal  Target-specific GPU
                                                  formats may be produced
                                                  later

  Spatial indexing        R-tree or equivalent    Evaluate with
                                                  representative datasets

  CI                      GitHub Actions          Windows, Linux, macOS

  Tests                   .NET test framework     Unit, integration,
                                                  compatibility,
                                                  performance

  Packaging               NuGet and native        Add only when API
                          artifacts               boundaries stabilize
  -----------------------------------------------------------------------

### 4.1 Native interop rules

-   Keep native dependencies behind small, versioned interfaces.
-   Prefer an opaque handle and C-compatible functions over C++ ABI
    exposure.
-   Define ownership, lifetime, error handling, threading, and
    cancellation rules.
-   Avoid copying large meshes or point clouds repeatedly across the
    boundary.
-   Use file-backed or memory-mapped artifacts for large transfers where
    appropriate.
-   Build and test native binaries independently for each supported OS
    and architecture.
-   Make optional native capabilities discoverable at runtime.
-   Do not make C++/CLI a core dependency because it is
    Windows-specific.

Example conceptual boundary:

``` c
typedef struct CadDocumentHandle CadDocumentHandle;

int cad_open_step(
    const char* path_utf8,
    CadDocumentHandle** out_document);

int cad_export_mesh(
    CadDocumentHandle* document,
    const char* output_path_utf8,
    const char* options_json_utf8);

void cad_close_document(CadDocumentHandle* document);
```

The final ABI should be designed only after the required operations and
data ownership model are understood.

## 5. Supported data domains and formats

The project should grow by vertical slices: complete a useful
import-to-export workflow for one domain before adding many incomplete
format readers.

  -----------------------------------------------------------------------
  Domain                  Candidate formats /     Important information
                          technologies            to preserve
  ----------------------- ----------------------- -----------------------
  Urban / city            CityGML, PLATEAU, 3D    Feature IDs, semantics,
                          Tiles                   LOD, CRS, attributes

  CAD / factory           STEP, B-Rep, NURBS, IFC Topology, assemblies,
                                                  units, tolerances,
                                                  properties

  Point cloud             LAS, LAZ, PLY           Coordinates,
                                                  classification, color,
                                                  intensity, CRS

  Gaussian Splatting      PLY-based 3DGS, SPZ     Splat parameters, SH
                          where supported         coefficients,
                                                  transforms

  Scene / model           OpenUSD, glTF, OBJ, FBX Hierarchy, transforms,
                                                  materials, animation
                                                  where supported

  Spatial metadata        CRS definitions and     Units, provenance,
                          domain-specific         coordinate
                          metadata                transformations
  -----------------------------------------------------------------------

### 5.1 Format support levels

Use explicit support levels instead of a binary supported/unsupported
label:

-   **Level 0 --- Detect:** identify the format and report basic
    metadata.
-   **Level 1 --- Inspect:** read metadata, hierarchy, bounds, and
    statistics.
-   **Level 2 --- Import:** construct the corresponding internal
    representation.
-   **Level 3 --- Transform:** support selected processing operations.
-   **Level 4 --- Export:** write the format with documented
    preservation/loss behavior.
-   **Level 5 --- Production validated:** pass representative
    real-world, large-data, and compatibility tests.

Publish a capability matrix for each format and release.

## 6. Internal spatial data model

The internal model is the most important architectural decision. It
should represent multiple geometry families without forcing them into
one lowest-common-denominator mesh.

### 6.1 Proposed model families

``` text
SpatialDataset
├── DatasetMetadata
├── CoordinateReferenceSystem
├── Units
├── FeatureCollection
│   ├── FeatureIdentity
│   ├── SemanticAttributes
│   ├── Relationships
│   └── Geometry
│       ├── ParametricGeometry
│       │   ├── BRep
│       │   ├── NURBS
│       │   └── CADAssembly
│       ├── PolygonGeometry
│       │   ├── Mesh
│       │   └── MaterialAssignments
│       ├── PointGeometry
│       │   └── PointCloud
│       ├── GaussianGeometry
│       │   └── GaussianSplatSet
│       └── SpatialGeometry
│           ├── Bounds
│           └── SpatialReference
└── Provenance
```

This is a conceptual schema, not a requirement to implement every type
immediately.

### 6.2 Shared concepts

Every suitable object should be able to carry:

-   Stable identity.
-   Parent/child and other relationships.
-   Local and world transforms.
-   Coordinate reference system and units.
-   Bounding volumes.
-   Semantic attributes.
-   Source provenance.
-   Version and schema information.
-   Optional references to original source data.

### 6.3 Coordinate-system policy

-   Never assume all inputs use the same coordinate system or unit.
-   Store the source CRS and units explicitly.
-   Make coordinate transformations explicit pipeline steps.
-   Record the transformation definition and relevant library/version.
-   Test axis order, vertical datum, georeferencing, and
    large-coordinate precision.
-   Consider local-origin or floating-origin techniques for rendering
    large geospatial scenes.

### 6.4 Conversion loss report

Each conversion should generate a machine-readable report similar to:

``` json
{
  "source_format": "STEP",
  "target_format": "glTF",
  "preserved": ["assembly_names", "transforms", "material_assignments"],
  "approximated": ["curved_surfaces_as_triangles"],
  "discarded": ["editable_brep_topology", "manufacturing_tolerances"],
  "warnings": ["mesh_deflection_tolerance_applied"]
}
```

The exact schema should be versioned and documented.

## 7. OpenUSD and 3D Tiles responsibilities

These formats serve different purposes and should coexist.

  -----------------------------------------------------------------------
  Technology                          Primary responsibility
  ----------------------------------- -----------------------------------
  OpenUSD                             Scene composition, hierarchy,
                                      references, variants, assemblies,
                                      interoperability

  3D Tiles                            Spatial tiling, hierarchical level
                                      of detail, streaming large
                                      geospatial scenes

  glTF                                Compact model interchange and
                                      rendering-oriented delivery
  -----------------------------------------------------------------------

Do not make OpenUSD the only internal representation. Preserve
source-specific geometry and semantics in the engine model, then export
to USD or 3D Tiles according to the use case.

## 8. Processing pipeline

Represent processing as a graph or ordered recipe of typed operations.

``` mermaid
flowchart LR
    Input["Source Dataset"]
    Detect["Detect / Inspect"]
    Import["Import"]
    Select["Select Features"]
    Transform["Transform / Convert"]
    Optimize["Optimize / Tile"]
    Validate["Validate"]
    Export["Export Artifacts"]
    Report["Report / Provenance"]

    Input --> Detect --> Import --> Select --> Transform
    Transform --> Optimize --> Validate --> Export
    Export --> Report
```

### 8.1 Pipeline requirements

-   Dry-run mode where practical.
-   Cancellation and progress reporting.
-   Bounded memory use and configurable memory budgets.
-   Resumable or restartable stages for long-running jobs.
-   Deterministic parameters and recorded tool versions.
-   Clear intermediate artifacts and cleanup policies.
-   Per-stage logs and structured diagnostics.
-   Validation before publishing final outputs.
-   No destructive modification of source datasets by default.

### 8.2 Recipe example

``` yaml
name: factory-step-to-usd
version: 1
input:
  path: ./input/factory.step
  format: step
steps:
  - operation: inspect
  - operation: import_step
  - operation: preserve_assembly_hierarchy
  - operation: generate_display_mesh
    parameters:
      linear_deflection: 0.1
  - operation: export_usd
    parameters:
      output: ./output/factory.usd
  - operation: validate_conversion
output:
  report: ./output/conversion-report.json
```

This is illustrative. Define a formal schema and validation rules before
treating recipes as a stable public interface.

## 9. Large-data performance

Large urban datasets and factory scans must not require loading the
entire source into memory.

### 9.1 Required capabilities

-   Initial indexing and reusable metadata caches.
-   Spatial index for feature and tile lookup.
-   Lazy loading and streaming.
-   Spatial clipping and feature filtering.
-   Chunked processing with bounded memory.
-   LOD generation and selection.
-   Cache eviction and configurable memory budgets.
-   Parallel processing where operations are safely independent.
-   Progress, cancellation, and performance metrics.

### 9.2 CityGML indexing

CityGML is XML-based and may require a first-pass scan to build useful
indexes.

A practical workflow:

1.  Scan the source and extract feature IDs, types, bounds, and
    offsets/references where feasible.
2.  Build a persistent index.
3.  Store reusable metadata separately from derived geometry caches.
4.  Load only the features or regions required by a query.
5.  Invalidate or rebuild indexes when source fingerprints change.

Do not promise arbitrary constant-time random access to every CityGML
source.

### 9.3 Texture and geometry optimization

-   Keep source textures when possible.
-   Consider KTX2/Basis Universal for portable texture delivery.
-   Produce platform-specific GPU texture formats only when the target
    requires them.
-   Support mesh simplification, deduplication, index/vertex
    optimization, and LOD.
-   Measure quality loss and size/performance trade-offs.
-   Keep optimization settings in named profiles.

### 9.4 Optimization profiles

Examples:

-   `generic-preview`
-   `unity-runtime`
-   `unreal-runtime`
-   `godot-runtime`
-   `blender-editing`
-   `omniverse-scene`
-   `geospatial-streaming`

Profiles should be versioned and should expose their effective settings
in reports.

## 10. MCP and CLI design

MCP is an interface to the engine, not the engine itself. MCP tools and
CLI commands should call the same application services.

### 10.5 Initial MCP tool groups

**Discovery and inspection** - `detect_format` - `inspect_dataset` -
`list_features` - `search_features` - `get_feature_attributes` -
`get_geometry_summary`

**Conversion** - `convert_dataset` - `export_gltf` - `export_usd` -
`export_3dtiles` - `export_point_cloud`

**Spatial processing** - `clip_by_bounds` - `filter_features` -
`transform_coordinates` - `simplify_geometry` - `generate_lod`

**CAD and factory** - `inspect_step` - `inspect_assembly` -
`generate_display_mesh` - `check_collision` - `analyze_clearance` -
`compare_scan_to_cad`

**Gaussian Splatting** - `inspect_gaussian_splats` -
`transform_gaussian_splats` - `compress_gaussian_splats` -
`convert_gaussian_splats`

**Validation** - `validate_conversion` - `compare_source_and_output` -
`validate_target_profile`

Start with a small set of reliable tools. Add operations only when the
underlying engine capability and error behavior are well-defined.

### 10.6 MCP safety and usability

-   Use stdio for the initial local MCP server.
-   Restrict access to explicitly configured input and output roots.
-   Require explicit output paths or safe defaults.
-   Do not overwrite source data.
-   Validate paths and reject traversal outside allowed roots.
-   Set size, time, and memory limits where practical.
-   Return job IDs and concise summaries for long-running tasks.
-   Store detailed logs and reports as local artifacts instead of
    returning huge geometry payloads.
-   Treat input files and embedded metadata as untrusted data.

### 10.3 CLI

The CLI should expose the same operations for scripts, CI, and
debugging.

Illustrative commands:

``` bash
u3d inspect ./data/city.gml
u3d index build ./data/city/
u3d convert ./data/factory.step --to usd --out ./out/factory.usd
u3d validate ./out/factory.usd
u3d benchmark ./data/large-city/
```

Command names and flags are provisional.

## 11. Engine and application adapters

Adapters must remain separate from the core.

  -----------------------------------------------------------------------
  Adapter                 Purpose                 Initial scope
  ----------------------- ----------------------- -----------------------
  Unity                   Import results into     glTF or engine-neutral
                          Unity projects          artifact import,
                                                  validation

  Blender                 Modeling and inspection Import/export and
                          workflow                metadata preservation
                                                  tests

  Unreal                  Runtime and             USD/glTF delivery tests
                          visualization           

  Godot                   Runtime and             glTF delivery tests
                          visualization           

  Omniverse               USD-based scene         USD export/import and
                          workflows               metadata tests
  -----------------------------------------------------------------------

Do not build all adapters in the first milestone. Start with file-based
interoperability, then add application-specific APIs only when needed.

## 12. Cross-platform strategy

### 12.1 Initial target matrix

  ------------------------------------------------------------------------
  Platform                                  Priority Initial target
  --------------------- ---------------------------- ---------------------
  Windows x64                                     P0 Core, CLI, MCP,
                                                     native adapters

  Linux x64                                       P0 Core, CLI, MCP,
                                                     native adapters

  macOS Apple Silicon                             P1 Core, CLI, MCP;
                                                     native support as
                                                     dependencies permit

  Windows ARM64                                   P2 Evaluate after x64
                                                     stability

  Linux ARM64                                     P2 Evaluate after x64
                                                     stability

  macOS Intel                                     P3 Support based on
                                                     demand and dependency
                                                     availability
  ------------------------------------------------------------------------

### 12.2 CI requirements

Use GitHub Actions to run:

-   Formatting and static analysis.
-   Unit tests.
-   Integration tests.
-   Native interop tests.
-   Cross-platform builds.
-   Package and artifact checks.
-   Dependency and license checks.
-   Representative performance tests on controlled runners.

Do not compare raw performance numbers across different hosted runner
types as if they were equivalent.

### 12.3 Numerical correctness

Floating-point results may vary across OS, CPU, compiler, and native
dependency versions.

Use: - Geometric tolerances. - Bounds and topology checks. - Attribute
and feature-count checks. - Conversion-loss reports. - Golden datasets
with documented expected ranges.

Do not require bit-for-bit identical geometry unless a specific
operation can genuinely guarantee it.

## 13. Testing and quality strategy

### 13.1 Test layers

1.  **Unit tests:** coordinate math, transforms, model invariants,
    serialization.
2.  **Format tests:** known-good samples, malformed inputs, edge cases.
3.  **Integration tests:** import → process → export.
4.  **Interop tests:** C# ↔ native library ownership, errors,
    cancellation, threading.
5.  **Compatibility tests:** import into target applications and inspect
    expected properties.
6.  **Performance tests:** memory, throughput, latency, cache
    effectiveness.
7.  **Regression tests:** compare output metrics against approved
    baselines.

### 13.2 Test-data policy

Maintain small, redistributable fixtures in the repository and larger
opt-in datasets outside normal CI.

For each fixture, record: - Source and license. - Expected
format/version. - Coordinate system and units. - Expected feature counts
and bounds. - Known limitations. - Expected conversion behavior.

Do not commit large or unlicensed real-world datasets.

### 13.3 Quality gates

A format module should not be called production-ready until it has: -
Documented supported features. - Error and warning behavior. - Tests for
malformed and representative inputs. - Memory and performance
measurements. - Conversion-loss documentation. - Cross-platform
status. - License and dependency review.

## 14. Repository structure

A starting monorepo layout:

``` text
universal-3d-engine/
├── Universal3D.sln
├── src/
│   ├── Universal3D.Core/
│   ├── Universal3D.SpatialModel/
│   ├── Universal3D.Coordinates/
│   ├── Universal3D.Pipeline/
│   ├── Universal3D.SpatialIndex/
│   ├── Universal3D.Streaming/
│   ├── Universal3D.Optimization/
│   ├── Universal3D.Validation/
│   ├── Universal3D.Metadata/
│   ├── Universal3D.Formats.CityGML/
│   ├── Universal3D.Formats.Gltf/
│   ├── Universal3D.Formats.PointCloud/
│   ├── Universal3D.Formats.GaussianSplat/
│   ├── Universal3D.Formats.Usd/
│   ├── Universal3D.NativeInterop/
│   ├── Universal3D.McpServer/
│   ├── Universal3D.HttpApi/          # Optional, opt-in
│   └── Universal3D.Cli/
├── python/
│   └── universal3d/                  # Python SDK package
├── native/
│   ├── OcctAdapter/
│   └── OpenUsdAdapter/
├── adapters/
│   ├── Unity/
│   ├── Unreal/
│   ├── Godot/
│   ├── Blender/
│   └── Omniverse/
├── schemas/
├── docs/
│   ├── architecture/
│   ├── formats/
│   ├── decisions/
│   └── workflows/
├── test/
│   ├── Unit/
│   ├── Integration/
│   ├── Interop/
│   ├── Compatibility/
│   └── Fixtures/
├── benchmarks/
├── samples/
├── scripts/
└── .github/
    ├── ISSUE_TEMPLATE/
    ├── workflows/
    ├── PULL_REQUEST_TEMPLATE.md
    └── CODEOWNERS
```

Keep projects small enough to test independently. Do not create empty
projects for every future format on day one.

## 15. Development roadmap

The roadmap is milestone-based. Dates should be assigned after the first
technical spikes establish realistic effort.

### Milestone 0 --- Project foundation

**Goal:** Make the repository buildable, testable, and understandable.

Tasks: - \[ \] Choose repository name and license after dependency
review. - \[ \] Create solution and initial project structure. - \[ \]
Define supported .NET SDK and target frameworks. - \[ \] Add formatting,
analyzers, and unit-test projects. - \[ \] Add GitHub Actions for
Windows, Linux, and macOS builds. - \[ \] Add contribution guide and
code of conduct if accepting external contributions. - \[ \] Create
architecture decision record (ADR) template. - \[ \] Document local
build and test instructions.

**Exit criteria:** - Clean checkout builds on the supported CI matrix. -
Tests run on all P0 platforms. - Architecture and contribution
documentation exists.

### Milestone 1 --- Spatial model and coordinate foundations

**Goal:** Establish the stable concepts shared by all format modules.

Tasks: - \[ \] Define dataset, feature, geometry, metadata, and
provenance abstractions. - \[ \] Define geometry-family interfaces
without forcing all data into meshes. - \[ \] Define coordinate
reference system and unit abstractions. - \[ \] Define transforms and
bounding-volume types. - \[ \] Define stable IDs and relationship
representation. - \[ \] Define serialization and schema-versioning
strategy. - \[ \] Add representative model fixtures and invariant
tests. - \[ \] Write ADRs for internal model and coordinate policy.

**Exit criteria:** - A dataset can represent more than one geometry
family. - CRS, units, transforms, identity, and provenance are
explicit. - Model serialization round-trips within documented
tolerances.

### Milestone 2 --- First end-to-end vertical slice

**Goal:** Prove that the architecture can import, process, export, and
validate a real dataset.

Recommended initial slice: - STEP → OCCT → internal CAD/assembly
representation → display mesh → glTF or USD.

Alternative if urban data is the immediate priority: - CityGML / PLATEAU
→ feature model → spatial filtering → glTF or 3D Tiles.

Tasks: - \[ \] Select one small, redistributable fixture. - \[ \]
Implement format detection and inspection. - \[ \] Implement importer
and required native boundary if applicable. - \[ \] Preserve IDs,
hierarchy, units, and metadata that the target supports. - \[ \]
Implement one useful transformation. - \[ \] Implement one exporter. -
\[ \] Generate a conversion-loss report. - \[ \] Add integration and
benchmark tests.

**Exit criteria:** - One complete, repeatable conversion works on
Windows and Linux. - The output is independently inspectable in a target
application. - Losses and unsupported source features are reported.

### Milestone 3 --- Native interop and CAD foundation

**Goal:** Make C++ dependencies maintainable and safe to call from C#.

Tasks: - \[ \] Define C ABI conventions and versioning. - \[ \]
Implement opaque handles and explicit lifetime management. - \[ \]
Define native error codes and C# exception mapping. - \[ \] Test
repeated open/close and failure paths. - \[ \] Test cancellation and
thread-safety assumptions. - \[ \] Build native dependencies on Windows
and Linux. - \[ \] Add macOS support where dependency builds are
viable. - \[ \] Document third-party licenses and redistribution
constraints.

**Exit criteria:** - Native modules can be loaded and used without
leaking handles or memory. - Errors cross the boundary predictably. - CI
builds and tests the supported native matrix.

### Milestone 4 --- City data and spatial indexing

**Goal:** Support useful processing of large urban datasets without
loading everything into memory.

Tasks: - \[ \] Implement CityGML/PLATEAU inspection. - \[ \] Extract
feature IDs, types, bounds, and selected attributes. - \[ \] Build a
persistent metadata and spatial index. - \[ \] Add spatial queries and
clipping. - \[ \] Add lazy loading and bounded-memory processing. - \[
\] Add coordinate transformation workflows. - \[ \] Add a first 3D Tiles
export or integration path. - \[ \] Benchmark against representative
city data.

**Exit criteria:** - A region or feature subset can be processed without
loading the full dataset. - Index creation and reuse are measured. - CRS
and feature identity are validated through the pipeline.

### Milestone 5 --- Scene interchange and OpenUSD

**Goal:** Support scene-level interchange while preserving hierarchy and
references.

Tasks: - \[ \] Define USD mapping for internal geometry families. - \[
\] Implement or integrate OpenUSD through an isolated native adapter. -
\[ \] Export transforms, hierarchy, names, and supported metadata. - \[
\] Test assemblies and instancing where supported. - \[ \] Document
unsupported or lossy mappings. - \[ \] Test in an OpenUSD-compatible
application, including Omniverse where available.

**Exit criteria:** - Representative scenes export and reopen with
expected hierarchy and transforms. - Metadata preservation and losses
are documented. - Native USD dependencies are isolated from the core.

### Milestone 6 --- Point clouds and Gaussian Splatting

**Goal:** Add real-world scan data without treating it as ordinary mesh
data.

Tasks: - \[ \] Add point-cloud inspection and import. - \[ \] Preserve
coordinates, attributes, and CRS. - \[ \] Add chunked processing and
spatial filtering. - \[ \] Add Gaussian Splatting inspection and native
representation. - \[ \] Preserve splat parameters and spherical-harmonic
data where supported. - \[ \] Evaluate compression and interchange
formats such as SPZ. - \[ \] Add USD or other target export paths where
supported. - \[ \] Document the limits of Gaussian-to-mesh
reconstruction. - \[ \] Benchmark file size, memory, and
rendering-oriented output.

**Exit criteria:** - Point clouds and Gaussian data have distinct
internal representations. - Supported transformations preserve the
relevant source attributes. - Lossy conversions are explicit and tested.

### Milestone 7 --- Optimization and target profiles

**Goal:** Make outputs practical for real-time and large-scene
applications.

Tasks: - \[ \] Implement mesh optimization and LOD pipeline. - \[ \]
Evaluate meshoptimizer integration. - \[ \] Evaluate KTX2/Basis
Universal texture pipeline. - \[ \] Add configurable memory and
output-size budgets. - \[ \] Define target profiles for Unity, Unreal,
Godot, Blender, and Omniverse. - \[ \] Add profile validation and
reports. - \[ \] Benchmark quality versus file size and processing time.

**Exit criteria:** - Profiles are versioned and reproducible. - Output
validation reports profile-specific results. - Optimization does not
silently remove semantic data.

### Milestone 8 --- MCP and CLI public workflows

**Goal:** Make the engine usable by people, scripts, and AI agents.

Tasks: - \[ \] Implement CLI commands for inspect, convert, validate,
and benchmark. - \[ \] Implement local stdio MCP server. - \[ \] Add a
small, stable set of MCP tools. - \[ \] Add job progress, cancellation,
and artifact references. - \[ \] Add path restrictions and safe
overwrite behavior. - \[ \] Add structured logs and machine-readable
reports. - \[ \] Write MCP usage examples and agent instructions. - \[
\] Test with at least one MCP client.

**Exit criteria:** - CLI and MCP invoke the same application services. -
Long-running jobs return useful progress and artifact information. -
Local execution does not require a hosted service.

### Milestone 9 --- Application adapters and release readiness

**Goal:** Validate the engine in real application workflows.

Tasks: - \[ \] Create a Unity adapter or sample package. - \[ \]
Validate import and runtime constraints relevant to Cluster workflows. -
\[ \] Add Blender workflow tests. - \[ \] Add Unreal and Godot adapters
when justified by demand. - \[ \] Validate Omniverse USD workflows. - \[
\] Publish format capability matrix. - \[ \] Publish performance and
memory benchmarks. - \[ \] Review API stability, licensing, security,
and packaging. - \[ \] Prepare release notes and migration policy.

**Exit criteria:** - At least two independent applications consume
generated artifacts successfully. - Supported OS and format matrices are
published. - Known limitations and compatibility results are documented.

## 16. GitHub project management

### 16.1 Recommended labels

  Label                  Meaning
  ---------------------- -------------------------------
  `type:feature`         New capability
  `type:bug`             Incorrect behavior
  `type:performance`     Speed or memory improvement
  `type:docs`            Documentation
  `type:refactor`        Internal restructuring
  `area:core`            Core engine
  `area:spatial-model`   Internal model
  `area:format`          Format importer/exporter
  `area:native`          Native interop
  `area:mcp`             MCP server
  `area:cli`             CLI
  `area:adapter`         Application adapter
  `platform:windows`     Windows-specific
  `platform:linux`       Linux-specific
  `platform:macos`       macOS-specific
  `priority:p0`          Blocking
  `priority:p1`          High
  `priority:p2`          Normal
  `good first issue`     Suitable for new contributors

### 16.2 Issue templates

Create templates for: - Bug report. - Feature proposal. - New format
support. - Performance report. - Compatibility report.

A new format-support issue should ask for: - Source format and
version. - Target format and use case. - Required semantics and
geometry. - Expected data sizes. - Sample files and redistribution
rights. - Required platforms. - Expected conversion losses. - Existing
libraries considered.

### 16.3 Pull request checklist

-   [ ] Scope and motivation are clear.
-   [ ] Tests cover the behavior.
-   [ ] No source data is modified unexpectedly.
-   [ ] Large-data memory behavior is considered.
-   [ ] Native ownership and error paths are safe, if applicable.
-   [ ] Cross-platform impact is documented.
-   [ ] Format losses and limitations are documented.
-   [ ] Dependencies and licenses are reviewed.
-   [ ] Public API changes include documentation and migration notes.

### 16.4 Architecture Decision Records

Create an ADR for decisions that are expensive to reverse, including: -
C# and .NET target strategy. - Internal geometry model. -
Coordinate-system representation. - Native ABI and memory ownership. -
OpenUSD and 3D Tiles responsibilities. - Cache/index format and
compatibility. - Recipe schema and versioning. - Package and plugin
model.

## 17. Risks and mitigations

  -----------------------------------------------------------------------
  Risk                    Impact                  Mitigation
  ----------------------- ----------------------- -----------------------
  Scope becomes too broad No complete workflow    Build vertical slices;
                          ships                   defer formats

  Internal model becomes  CAD/GIS/3DGS meaning is Separate geometry
  a lowest common         lost                    families and semantic
  denominator                                     layers

  Native dependencies     Fragile releases        Isolate native adapters
  complicate                                      and test early
  cross-platform builds                           

  Large data exhausts     Crashes and poor        Indexing, streaming,
  memory                  usability               chunking, memory
                                                  budgets

  Coordinate mistakes     Spatially incorrect     Explicit CRS/units and
                          output                  geospatial test
                                                  fixtures

  Lossy conversion is     Users trust invalid     Conversion-loss reports
  hidden                  outputs                 and validation

  Dependency licenses     Distribution            License inventory and
  conflict                restrictions            release review

  MCP tools expose unsafe Local data risk         Root restrictions,
  file access                                     validation, no implicit
                                                  overwrite

  Format standards evolve Compatibility           Versioned capability
                          regressions             matrix and fixtures

  Too many adapters too   Maintenance burden      Start with file-based
  early                                           interchange
  -----------------------------------------------------------------------

## 18. First 30-day implementation plan

This is a suggested sequence, not a deadline commitment.

### Week 1 --- Repository and build foundation

-   [ ] Create repository and solution.
-   [ ] Choose .NET SDK and initial target frameworks.
-   [ ] Add CI for Windows and Linux; add macOS build where feasible.
-   [ ] Add test projects, formatting, analyzers, and basic
    documentation.
-   [ ] Write ADR-001: C#-first architecture and native-module policy.

### Week 2 --- Model prototype

-   [ ] Define dataset, feature, transform, bounds, CRS, units, and
    provenance.
-   [ ] Define distinct CAD, mesh, point-cloud, and Gaussian geometry
    abstractions.
-   [ ] Add serialization prototype.
-   [ ] Add round-trip and invariant tests.
-   [ ] Write ADR-002: internal spatial data model.

### Week 3 --- Choose and spike the first vertical slice

-   [ ] Compare STEP → USD/glTF and CityGML → 3D Tiles as initial
    workflows.
-   [ ] Select a small redistributable fixture.
-   [ ] Test candidate libraries and their licenses/platform support.
-   [ ] Measure import time, memory, output quality, and conversion
    losses.
-   [ ] Write ADR-003: first format workflow and native dependencies.

### Week 4 --- Deliver a minimal end-to-end prototype

-   [ ] Implement inspect and import for the chosen source format.
-   [ ] Implement one transformation.
-   [ ] Export one target format.
-   [ ] Generate a conversion report.
-   [ ] Add integration tests and a reproducible sample command.
-   [ ] Publish the first architecture and benchmark notes.

**30-day success criterion:** one small but real dataset can be
imported, inspected, transformed, exported, and validated on at least
Windows and Linux. A narrow working pipeline is more valuable than many
empty format modules.

## 19. Immediate decisions to record

Before substantial implementation, resolve these decisions as ADRs:

1.  **First vertical slice:** STEP → USD/glTF, or CityGML/PLATEAU → 3D
    Tiles?
2.  **.NET target:** Which .NET versions must the standalone core
    support, and what compatibility constraints apply to Unity adapters?
3.  **Native packaging:** Ship native libraries alongside the
    application, or discover them as optional plugins?
4.  **Internal persistence:** Use a versioned project/dataset format, or
    keep the first release file-and-cache based?
5.  **Public API stability:** Which interfaces are internal until the
    first stable release?

Recommended defaults: - C# / .NET for the standalone engine. - C ABI +
P/Invoke for native modules. - OCCT for CAD rather than implementing a
CAD kernel from scratch. - OpenUSD and 3D Tiles as complementary
export/integration formats. - Local files and caches before introducing
a custom database. - One complete vertical slice before broad format
coverage.

## 20. Definition of success

The project is successful when a user can take data from different
domains, inspect its structure and meaning, perform a documented
processing recipe, and produce validated artifacts for a target
application---without needing a cloud service or surrendering all source
information to a single mesh representation.

The key differentiator should be **reliable, explainable conversion of
heterogeneous 3D spatial data**, not simply the number of supported file
extensions.
