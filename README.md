# SOLPSwg_matlab

MATLAB post-processing tools for unstructured SOLPS-ITER wide-grid (WG) runs.

The toolbox has three general-purpose editable driver scripts:

- `WG_2D_plots.m` — 2-D colour maps of B2/EIRENE quantities.
- `WG_profiles.m` — profiles along targets, labelled boundaries, or arbitrary R-Z lines.
- `WG_inspect_run.m` — quick inventory of available fields, dimensions, species, and face labels.

A fourth driver, `WG_experimental.m`, compares Thomson scattering and Langmuir-probe
measurements with SOLPS and provides interactive time sliders.

General WG implementation details are hidden in `private/wg_core.m`. The
experimental driver uses the same interface plus script-local GUI helpers.

---

## Contents

1. [Requirements](#requirements)
2. [Expected directory layout](#expected-directory-layout)
3. [Quick start](#quick-start)
4. [Repository layout](#repository-layout)
5. [Choosing quantities](#choosing-quantities)
6. [2-D plots](#2-d-plots)
7. [Profiles](#profiles)
8. [Experimental TS and LP comparisons](#experimental-ts-and-lp-comparisons)
9. [Run inspection](#run-inspection)
10. [Output files](#output-files)
11. [Data discovery](#data-discovery)
12. [Notes and limitations](#notes-and-limitations)

---

## Requirements

- MATLAB R2023a or newer is recommended.
- An unstructured SOLPS-ITER wide-grid run directory.
- The wide-grid MATLAB readers, including `IO/read_b2fgmtry_us.m` and the
  other `_us` readers used by `wg_core`. On lac3 these are bundled in
  `SOLPSwg_matlab/MatlabPostProcessing`; on viz06 they normally reside in the
  parent SOLPS-ITER working tree under `scripts/MatlabPostProcessing`.
  Ordinary structured-grid readers are not interchangeable.

No additional MATLAB toolboxes are required by the general WG drivers. The
experimental comparison also requires access to `get_edge_data` and
`LP_MDSdld`, MDSplus connectivity, and the bundled
`boundary_flux_density` helper. Its configuration is described below.

The experimental workflow has been exercised on lac3 with MATLAB R2019a Update 1.

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
stand-alone template rather than called as a function. To compare experimental
diagnostics, configure `shot`, `MDS`, and `experimentalTime` in
`WG_experimental.m`, then run:

```matlab
run('/path/to/SOLPSwg_matlab/WG_experimental.m');
```

---

## Repository layout

```text
SOLPSwg_matlab/
├── WG_2D_plots.m          % User-facing 2-D plot driver
├── WG_profiles.m          % User-facing target/line profile driver
├── WG_inspect_run.m       % User-facing run inspection driver
├── WG_experimental.m     % Interactive TS and LP comparison driver
├── MatlabPostProcessing/  % Bundled readers and geometry/flux helpers on lac3
└── private/
    └── wg_core.m          % Consolidated WG implementation and dispatcher
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

Branch construction uses a monotonic flux interval around the requested
separatrix crossing. A monotone reference line can be used as a complete
mapping branch even when it has no separatrix crossing. Separate valid sample
intervals are not joined across interpolation gaps. The returned
`mapping.selection` is either `separatrix crossing` or `monotonic region`.

This approach does not treat the location of maximum sampled magnetic flux as
a magnetic-axis estimate, avoiding a one-point branch when separatrix flux
occurs near the upstream line endpoint. `upstreamRsep` overrides the reference
radius but does not select a branch. `upstreamExtrapolate` determines whether
positions outside its flux range are linearly extrapolated or return NaN.
Check those extrapolated results particularly carefully.

Example for an outer-midplane reference:

```matlab
p.upstreamReferenceLine = [0.90,0,1.14,0];
p.upstreamSide = 'outer';
```

Each target component or line receives its own legend entry when
`p.showProfileLegend = true`.

---

## Experimental TS and LP comparisons

`WG_experimental.m` compares Thomson-scattering (TS) and Langmuir-probe (LP)
measurements with a stored SOLPS run. Contrary to a simple fixed-time plot, the
TS and LP figures have sliders that browse experimental time while retaining
the same SOLPS solution and equilibrium.

### Prerequisites and main settings

This workflow additionally requires access to `get_edge_data` and
`LP_MDSdld`, MDSplus diagnostics, and network permission to retrieve those
experimental records. These tools are not needed by the general WG drivers.
The local SOLPS data root is constructed as:

```matlab
solpsDirectory = fullfile(runConfig.shotRoot,num2str(MDS));
```

Edit the `USER`-marked parameters at the top of the script:

| Parameter | Purpose |
|-----------|---------|
| `shot` | Experimental shot number used to obtain TS and LP data. |
| `MDS` | Directory name under `runConfig.shotRoot` containing the SOLPS run. |
| `experimentalTime` | Requested initial time for both figures. |
| `maxLPTemperature` | Maximum accepted LP temperature (default 100 eV). |
| `refreshFromEFGW` | Enables optional SFTP transfer when true. |
| `efgwDirectory`, `efgwHost`, `efgwUser` | Viz06 source location and account configuration. |
| `quantities` | Remote files/globs transferred when refreshing. |
| `p.innerTargetLabels`, `p.outerTargetLabels` | Boundary `fcLbl` selections used for SOLPS target profiles. |
| `p.saveFigures`, `p.exportData` | Enable PNG or MAT output. |

`experimentalTime` is selected independently of `b2fstate.time`: an
experimental snapshot time is used to find the closest LP sample, and the
nearest actual TS sample is then used. It should not be confused with the B2
solver timestep, which is recorded separately as `comparison.b2StateTime`.

### Optional SFTP transfer

Set `refreshFromEFGW = true` to download the geometry, states, and requested
EIRENE files from viz06 into `<runConfig.shotRoot>/<MDS>`. With the default `false`, the
workflow reads the local directory without downloading anything.

SFTP uses `$HOME/.ssh/gw_key`, `BatchMode=yes`, and the configured host/user.
Therefore both a valid private key and authorized gateway access are required.
Authentication errors stop the transfer and report `WG:SFTP`; they are not
silently ignored. Retransferring replaces matching files in the destination
directory, so use refresh only when that is intended.

### Thomson scattering

The driver calls `get_edge_data` over the LP sampling-time range. It uses
`R_time` when available (otherwise `TS.R`) to obtain the median sightline
radius and obtains the Z sampling range from the TS channels. SOLPS `ne` and
`Te` are sampled on this vertical sightline, not reconstructed from a
midplane approximation.

Both panels display TS error bars (`dne` and `dte`) and the corresponding
SOLPS profile as a red curve:

1. Electron density against Z, scaled to `10^19 m^-3`.
2. Electron temperature against Z, in eV.

The initial LP and TS samples are chosen independently at the nearest
available sampling times. The slider label reports both times because they
need not be identical. The overall title reports the actual displayed TS
sample time and sightline radius.

### Separatrix crossing overlays

There are two independent sources of separatrix information along the TS
sightline: the experimental reconstruction and the SOLPS equilibrium.
`WG_experimental_crossings` performs a linear sign-change interpolation and
keeps up to two bounding crossings in each panel.

| Overlay | Meaning and appearance | Time dependence |
|---|---|---|
| Orange dashed lines | Crossings of `TS.rho - 1` along `TS.Z` | Recalculated from the selected experimental time. |
| Black dotted lines | Zero of mapped `drsep` along the SOLPS sightline | Fixed by the stored SOLPS equilibrium. |

These lines compare geometric separatrix positions, not SOLPS or experimental
sampling times. They make differences between the two equilibria visible
without moving any plasma profile to force agreement. If `TS.rho` is undefined,
experimental landmarks disappear instead of reusing an obsolete crossing;
SOLPS markers remain unchanged. The two crossings are displayed in each of
the density and temperature panels when they exist.

### Langmuir probes

LP data are read with `LP_MDSdld(shot)`. The script uses the matrix fields
`LP.FourParamsFit.dens`, `Te`, and `Jsat`, plus `LP.dsep_mid` and `LP.ang`.
The `FourParamsFit` fieldname is plural. For each valid fit, the outer target
uses probes satisfying

```matlab
LP.pos(:,1) > 0.66 & LP.pos(:,2) < -0.4
```

and the inner target uses `R<0.7`, `Z<0.7`, excluding that outer-probe mask.
These geometric probe-group selections are specific to this TCV probe layout;
adjust the masks for another installation. Fitted profiles are also filtered
at each selected time to require nonnegative density and
`0 <= Te <= maxLPTemperature` before comparison.

Two columns (inner and outer target) contain rows of:

1. LP `FourParamsFit.dens` versus SOLPS `ne`.
2. LP `FourParamsFit.Te` versus SOLPS `Te`.
3. LP projected saturation-current density versus SOLPS ion current density.

The abscissa is `LP.dsep_mid` for measurements and the WG upstream-mapped
`drsep` for SOLPS. LP points are black circles; SOLPS curves are red.
The comparison plots show selected samples at their own mapped radial
coordinates.

The experiment-side current is obtained by applying the LP angle projection:

```text
LP_current = abs(FourParamsFit.Jsat) .* sin(abs(LP.ang))
```

The SOLPS current is computed from ion fluxes, not by treating particle flux
as electric current. All B2 species (including bundled charge-state groups)
are retained:

```text
za_s = (zamin_s + zamax_s)/2
ionFlux_s = boundary_flux_density(gmtry, target.faces, fna(:,:,s))
SOLPS_current = abs(e * sum_s(za_s * ionFlux_s))
```

`boundary_flux_density` supplies the native boundary flux density.

Thus the displayed current densities have units `A/m^2`. The magnitude is
reported; a particle current in particles per second per square metre is not
directly comparable to `FourParamsFit.Jsat`.

### Sliders and experimental outputs

The slider index denotes an LP sample, not a value interpolated in seconds.
Arrow keys move one sample at a time when the control has focus. The callbacks
update only experimental points, fitted-sample selection, and experimental
separatrix markers. SOLPS target profiles, SOLPS sightline profiles, and
SOLPS separatrix markers do not change with experimental time.

No MDSplus request or B2 interpolation is performed on every slider event.
The LP record is loaded once, and TS data are obtained at startup before the
plots are drawn.

The experimental driver writes into `<solpsDirectory>/WG_experimental` when
saving is enabled:

```text
Thomson_comparison.png
Langmuir_comparison.png
experimental_comparison.mat
```

The PNG files are the displayed slider state when the save block runs.
For PNG export, UI controls are hidden during printing and restored afterwards;
the titles retain the selected time. The MAT export contains the initial
comparison structures constructed by the script, including `SourceFiles`,
TS sep-crossing and mapping data, and the initial selected LP region data.
It is not an automatically appended history of all slider changes.

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
the fallback spelling `bfgmtry`. Loaded runs retain cluster and path-selection
provenance in `run.cluster` and `run.setup`.

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
