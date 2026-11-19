# SOLPSwg_matlab

MATLAB post-processing tools for unstructured SOLPS-ITER wide-grid (WG) runs.

The toolbox is built around three editable driver scripts:

- `WG_2D_plots.m` — 2-D colour maps of B2/EIRENE quantities.
- `WG_profiles.m` — profiles along targets, labelled boundaries, or arbitrary R-Z lines.
- `WG_inspect_run.m` — quick inventory of available fields, dimensions, species, and face labels.

All implementation details are hidden in `private/wg_core.m`. The three driver
scripts are the intended user entry points.

---

## Contents

1. [Requirements](#requirements)
2. [Expected directory layout](#expected-directory-layout)
3. [Quick start](#quick-start)
4. [Repository layout](#repository-layout)
5. [Choosing quantities](#choosing-quantities)
6. [2-D plots](#2-d-plots)
7. [Profiles](#profiles)
8. [Run inspection](#run-inspection)
9. [Output files](#output-files)
10. [Data discovery](#data-discovery)
11. [Notes and limitations](#notes-and-limitations)

---

## Requirements

- MATLAB R2023a or newer is recommended.
- An unstructured SOLPS-ITER wide-grid run directory.
- The wide-grid MATLAB readers, including `IO/read_b2fgmtry_us.m` and the
  other `_us` readers used by `wg_core`. On lac3 these are bundled in
  `SOLPSwg_matlab/MatlabPostProcessing`; on viz06 they normally reside in the
  parent SOLPS-ITER working tree under `scripts/MatlabPostProcessing`.
  Ordinary structured-grid readers are not interchangeable.

No additional MATLAB toolboxes are required.

---

## Expected directory layout

### viz06.efgw.cineca.it (original layout)

The original setup remains supported. The toolbox lives under `scripts.local/`
in a SOLPS-ITER working tree, for example:

```text
solps-iter_wg/
├── scripts/
│   └── MatlabPostProcessing/
├── scripts.local/
│   └── SOLPSwg_matlab/
│       ├── WG_2D_plots.m
│       ├── WG_profiles.m
│       ├── WG_inspect_run.m
│       └── private/
│           └── wg_core.m
└── runs/
    └── <machine>/<case>/<run>/
```

On viz06, setup derives the reader path from this layout exactly as before.

### lac3.epfl.ch

The expected lac3 layout is:

```text
/NoTivoli/<username>/
├── GIT/
│   └── SOLPSwg_matlab/
│       └── MatlabPostProcessing/
└── solps_ssh/
    └── <MDS_number>/
        ├── b2fgmtry
        ├── b2fstate
        ├── b2fstati
        ├── b2fplasmf
        ├── fort.33
        ├── fort.34
        ├── fort.35
        ├── fort.44
        └── fort.46
```

The standard geometry filename is `b2fgmtry`; `bfgmtry` is also accepted as a
fallback. Only files needed by the selected quantities must be present.

### Cluster detection and path configuration

The driver scripts call setup with an output so the selected paths can be
inspected:

```matlab
runConfig = wg_core('setup');
disp(runConfig);
```

The returned structure contains `cluster`, `clusterSource`, `hostName`,
`toolkitRoot`, `readerDir`, and `shotRoot`. `shotRoot` is the lac3 MDS data root,
and is empty for the original viz06 run-directory layout.

Automatic selection uses the following rules, in order:

1. An explicit cluster argument or `SOLPSWG_CLUSTER` selects `lac3` or `viz06`.
2. Otherwise, hostnames `lac3`/`lac3.*` and `viz06`/`viz06.*` select the
   corresponding cluster.
3. If the hostname is unavailable or unrecognised, `solps_ssh` together with
   bundled `MatlabPostProcessing` readers (or a sibling `GIT/SOLPS-ITER`
   checkout) selects lac3.
4. If neither test matches, setup uses the original viz06-compatible reader
   path. Select the cluster explicitly on other installations.

For manual selection, change the setup call near the top of a driver script:

```matlab
runConfig = wg_core('setup','lac3');  % Also use: wg_core('setup','viz06')
% Use wg_core('setup','auto') for automatic/environment selection.
```

Because `wg_core` is a private implementation function, call it from the
provided parent-directory driver scripts rather than from a different working
directory. A manual selection is retained by subsequent setup/load calls in
the same MATLAB session until `setup('auto')` is called from a driver. It can
instead be selected from the MATLAB command window before running a driver:

```matlab
setenv('SOLPSWG_CLUSTER','lac3');  % 'viz06' and 'auto' are also accepted
run('/path/to/SOLPSwg_matlab/WG_2D_plots.m');
```

On lac3, the three driver scripts construct `p.runDir` as
`fullfile(runConfig.shotRoot,'186317')`. Replace the example MDS number
`186317` with the desired directory name. On viz06, they retain their original
example `p.runDir` paths. A custom `p.runDir` can always be assigned directly,
regardless of cluster.

The reader directory is selected as follows:

- On viz06, the original `<working-tree>/scripts/MatlabPostProcessing` path is
  preserved.
- On lac3, the default is the bundled
  `/NoTivoli/<username>/GIT/SOLPSwg_matlab/MatlabPostProcessing` directory. If
  it is absent, setup tries the sibling
  `GIT/SOLPS-ITER/scripts/MatlabPostProcessing`, then
  `$SOLPSTOP/scripts/MatlabPostProcessing`.
- On either cluster, `SOLPSWG_MATLAB_POSTPROCESSING` overrides the selected
  reader directory. Set it to the `MatlabPostProcessing` directory itself, not
  to the SOLPS-ITER root:

```matlab
setenv('SOLPSWG_MATLAB_POSTPROCESSING', ...
    '/path/to/SOLPS-ITER/scripts/MatlabPostProcessing');
% Now run any of the three driver scripts.
```

The lac3 defaults assume the toolkit is exactly at
`/NoTivoli/<username>/GIT/SOLPSwg_matlab`, because `shotRoot` is derived from
that location. For a relocated toolkit, set `p.runDir` explicitly and use the
reader override as needed. The selected reader directory must contain the
wide-grid `_us` implementations; `wg_core('load_run',p)` reports a
`WG:MissingReaders` error if its geometry reader is unavailable.

`wg_core('setup')` adds the toolkit and all `MatlabPostProcessing`
subdirectories to the MATLAB path automatically.

---

## Quick start

1. Open one of the three driver scripts.
2. Edit the parameters in the `User parameters` section, especially `p.runDir`.
3. Run the script from MATLAB, for example:

```matlab
run('/path/to/SOLPSwg_matlab/WG_2D_plots.m')
```

For batch or headless use:

```matlab
set(0,'DefaultFigureVisible','off');
run('/path/to/SOLPSwg_matlab/WG_profiles.m');
close all;
```

Each script starts with `clearvars`, so it is intended to be run as a
stand-alone template rather than called as a function.

---

## Repository layout

```text
SOLPSwg_matlab/
├── WG_2D_plots.m       % User-facing 2-D plot driver
├── WG_profiles.m       % User-facing target/line profile driver
├── WG_inspect_run.m    % User-facing run inspection driver
└── private/
    └── wg_core.m       % Consolidated internal routines and dispatcher
```

The `private/` folder keeps implementation functions out of the normal user
workspace. The driver scripts call it through actions such as:

```matlab
wg_core('setup')
p = wg_core('defaults');
run = wg_core('load_run',p);
```

---

## Choosing quantities

A quantity is described by a specification created with:

```matlab
wg_core('spec',source,field,indices)
```

### Supported sources

| Source         | File                        | Typical use                         |
|----------------|-----------------------------|-------------------------------------|
| `b2fstate`     | `b2fstate`                  | Final B2 plasma state               |
| `b2fstati`     | `b2fstati`                  | Initial B2 plasma state             |
| `b2fplasmf`    | formatted `b2fplasmf`       | Additional B2 plasma fields         |
| `ft44`         | `fort.44`                   | EIRENE neutral fields on B2 cells   |
| `ft46`         | `fort.46` + `fort.33/34/35` | EIRENE triangle data                |
| `b2fgmtry`     | `b2fgmtry`                  | Geometry fields such as `fcS`       |

### Examples

```matlab
% Electron density from the final state.
wg_core('spec','b2fstate','ne')

% B2 species 2; MATLAB indices are one-based.
wg_core('spec','b2fstate','na',2)

% First face-flux component.
wg_core('spec','b2fstate','fhi',{':',1})

% First EIRENE atomic density.
wg_core('spec','ft44','dab2',1)

% First EIRENE triangle density.
wg_core('spec','ft46','pdena',1)
```

A numeric index selects the final array dimension. Use a cell array such as
`{':',1}` for explicit subscript control.

### Useful specification fields

After creating a specification, its display and handling can be customised:

```matlab
s = wg_core('spec','b2fstate','na',2);
s.label = 'n_{D^+}';
s.unit  = 'm^{-3}';
s.scale = 1e19;

s.reduce = 'sum';              % 'none', 'sum', or 'mean'
s.location = 'auto';           % 'cell', 'face', 'vertex', or 'triangle'
s.colorScale = 'log';          % 'auto', 'linear', or 'log'
s.clim = [1e14,1e20];
s.transform = @abs;
```

The `transform` field is applied after normal scaling and unit conversion.

### Derived quantities

For `ft44`, these names are available in addition to the raw fields:

| Derived field              | Definition                         |
|----------------------------|------------------------------------|
| `total_D_density`         | `dab2(:,1,1) + 2*dmb2(:,1,1)`      |
| `total_atom_density`       | Sum over all atom densities        |
| `total_molecule_density`   | Sum over all molecule densities    |
| `total_test_ion_density`   | Sum over all test-ion densities    |

Common B2 and EIRENE temperature fields are converted to eV automatically.
Densities are reported in `m^-3`. Unknown fields are shown in file units.

---

## 2-D plots

`WG_2D_plots.m` creates one figure per requested quantity.

Main controls:

```matlab
p.runDir = '/path/to/run';
p.quantities = {
    wg_core('spec','ft44','total_D_density')
    wg_core('spec','b2fstate','te')
};

p.colorScale = 'log';          % 'auto', 'linear', or 'log'
p.colorLimits = [];            % [] for automatic limits
p.zoom = [];                   % [Rmin,Rmax,Zmin,Zmax]
p.includeGuardCells = false;
p.showMesh = false;
p.showTargets = false;
p.targetLabels = [1,2];
```

Rendering follows the native data location:

- Cell fields are drawn as cell patches.
- Triangle fields are drawn directly on the EIRENE triangle mesh.
- Vertex fields use interpolated vertex colours.
- Face fields are drawn as coloured face segments.

Non-positive values are masked with a warning when a logarithmic colour scale
is requested.

---

## Profiles

`WG_profiles.m` can plot along targets, labelled boundaries, and arbitrary
lines. Each requested quantity becomes one panel. Multiple profile locations
can be overlaid in the same panel.

### Profile modes

A single mode or a cell array of modes can be used:

```matlab
p.profileMode = 'inner';

% Overlay both inner and outer targets.
p.profileMode = {'inner','outer'};

% Add an arbitrary line as well.
p.profileMode = {'inner','outer','line'};
```

Available modes are:

| Mode      | Meaning                                              |
|-----------|------------------------------------------------------|
| `inner`   | Faces listed in `p.innerTargetLabels`                |
| `outer`   | Faces listed in `p.outerTargetLabels`                |
| `labels`  | Faces listed in `p.customTargetLabels`               |
| `line`    | Straight segment `p.lineEndpoints = [R1,Z1,R2,Z2]`   |

When `line` is combined with target modes, `p.targetX` and `p.profileX` must
describe the same coordinate type, such as both using `drsep`, `R`, `Z`, or
`s`.

### Target selection

Target face labels are case-dependent. Run `WG_inspect_run.m` first to identify
the labels in a particular geometry.

```matlab
p.innerTargetLabels = [1,2];
p.outerTargetLabels = [3,4];

% Restrict to a spatial region.
p.targetRzBox = [0.7,0.9,-0.75,-0.70];

% Select one connected component, or choose the one nearest a point.
p.targetComponent = 0;             % 0, integer component, or 'nearest'
p.targetSeed = [0.78,-0.73];

% Choose which adjacent cell value to use.
p.targetCellSide = 'physical';     % 'physical', 'guard', 'first', or 'second'

% Divide face-integrated quantities by face area.
p.targetFaceAreaNormalize = false;
```

### Profile coordinates

Target profiles support:

```matlab
p.targetX = 's';       % Geometric face-centre arc length, in metres
p.targetX = 'R';
p.targetX = 'Z';
p.targetX = 'psi';
p.targetX = 'index';
p.targetX = 'drsep';   % Upstream-mapped distance from separatrix
```

Line profiles support:

```matlab
p.profileX = 'auto';   % R or Z for horizontal/vertical cuts, otherwise s
p.profileX = 's';
p.profileX = 'R';
p.profileX = 'Z';
p.profileX = 'drsep';
```

For arbitrary lines:

```matlab
p.lineEndpoints = [0.65,0.0,1.05,0.0];
p.lineSamples = 400;
p.profileMethod = 'native';       % 'native', 'linear', or 'nearest'
```

- `native` preserves native cell/triangle data and direct face crossings.
- `linear` and `nearest` interpolate onto the requested line.
- Samples outside the physical mesh are returned as `NaN`.

### Upstream `drsep` mapping

`drsep` is computed as

```text
drsep = R_upstream(psi) - R_upstream(psi_sep)
```

where `R_upstream(psi)` is sampled from `vxFpsi` along a user-configurable
reference cut.

Controls:

```matlab
p.upstreamReferenceLine = [];          % [] uses a horizontal Z=0 cut
p.upstreamPsiSep = [];                 % [] chooses fsPsi nearest zero
p.upstreamRsep = [];                   % Optional explicit separatrix radius
p.upstreamSide = 'outer';              % 'outer' or 'inner'
p.upstreamSamples = 1000;
p.upstreamExtrapolate = true;          % false returns NaN outside the sampled range
```

Example for an outer-midplane reference:

```matlab
p.upstreamReferenceLine = [0.90,0,1.14,0];
p.upstreamSide = 'outer';
```

Each target component or line receives its own legend entry when
`p.showProfileLegend = true`.

---

## Run inspection

`WG_inspect_run.m` prints:

- Discovered geometry and data files.
- `nCi`, `nCg`, `nCv`, `nFc`, and `nVx`.
- Field names and array dimensions for each requested source.
- B2 species metadata where available.
- Nonzero face labels with face counts, connected components, and R-Z extents.

Useful when choosing target labels and R-Z boxes:

```matlab
p.runDir = '/path/to/run';
p.sources = {'b2fstate','b2fplasmf','ft44','ft46'};
```

A missing formatted `b2fplasmf` file is reported without stopping the
inspection.

---

## Output files

Saving is disabled by default. Enable it with:

```matlab
p.saveFigures = true;
p.exportData = true;
p.outputDir = '';    % Empty uses <runDir>/WG_postprocessing
p.dpi = 250;
```

Typical output names are:

```text
2D_ft44_total_D_density.png
2D_ft44_total_D_density.mat
profiles_inner_outer.png
profiles_inner_outer.mat
location_inner_outer.png
```

MAT files contain computed values, native element IDs, metadata, parameters,
and source-file paths.

---

## Data discovery

For each required file, `wg_core` searches in this order:

1. `runDir`
2. `runDir/b2mn.exe.dir`
3. `runDir/../baserun`
4. `runDir/baserun`

For geometry, these directories are searched for `b2fgmtry` first and then for
the fallback spelling `bfgmtry`.

Individual paths can be overridden explicitly:

```matlab
p.geometryFile = fullfile(p.runDir,'../baserun/b2fgmtry');

p.files.b2fstate = '/path/to/b2fstate';
p.files.fort44   = '/path/to/fort.44';
```

---

## Notes and limitations

- Only unstructured wide-grid geometries are supported.
- Target labels are not universal; inspect each geometry before plotting.
- The requested `b2fplasmf` support is for formatted files. Runs containing
  only unformatted `b2fplasma` files are not read.
- Face-integrated quantities are plotted as face segments rather than being
  silently converted to cell-centred values.
- `fort.46` profiles on B2 targets are mapped through `triangles.plasma_cell`.
- Upstream `drsep` mapping depends on the quality and range of `vxFpsi` along
  the selected reference cut.
