# Publishing & registering LOBPCG.jl

This package was extracted from [DFTK.jl](https://github.com/JuliaMolSim/DFTK.jl).
Everything below is what a maintainer needs to do to get it onto GitHub under the
JuliaMolSim organisation and into the General registry. Steps that require your
GitHub account / org permissions are marked **(you)**.

## 1. Create the GitHub repository **(you)**

```bash
# From this directory (~/.julia/dev/LOBPCG), with the git history already initialised:
gh repo create JuliaMolSim/LOBPCG.jl --public --source=. --remote=origin \
    --description "Stability-focused LOBPCG eigensolver (extracted from DFTK.jl)"
git branch -M master
git push -u origin master
```

(Or create the repo in the web UI and `git remote add origin git@github.com:JuliaMolSim/LOBPCG.jl.git`.)

The package `uuid` is already fixed in `Project.toml`:
`87a0849e-8492-4fcc-8734-ba6a5d902784`. Keep it — the DFTK dependency refers to it.

## 2. Set up repository secrets / settings **(you)**

- **TagBot / Documenter key** (only needed if you later add a docs site): add a
  `DOCUMENTER_KEY` secret. Not required for the current setup.
- **Codecov**: add `CODECOV_TOKEN` if you want coverage uploads (CI is configured to
  not fail without it).
- Enable GitHub Actions if the org requires opt-in.

The CI (`.github/workflows/CI.yml`) runs the test suite on Julia 1.10 (LTS) and
`1` (latest) on Ubuntu. Confirm it goes green on `master` before registering.

## 3. Register in the General registry **(you)**

Two equivalent options:

**A. JuliaRegistrator bot (recommended)**
1. Install the [JuliaRegistrator](https://github.com/JuliaRegistries/Registrator.jl)
   GitHub app on the JuliaMolSim org (one-time).
2. Push the commit you want to release to `master`.
3. Comment `@JuliaRegistrator register` on that commit (or on a release PR).
4. The bot opens a PR against `General`. Once its automerge checks pass (new
   packages have a ~3-day waiting period), it merges automatically.

**B. Manual** via the web UI at <https://juliahub.com/ui/registrator> — paste the
repo URL and follow the prompts.

After the registry PR merges, **TagBot** (`.github/workflows/TagBot.yml`) will
automatically create the `v0.1.0` git tag and GitHub release. Nothing else to do.

## 4. Switch DFTK.jl over to the registered package **(you)**

The DFTK working tree currently `dev`s this package locally. Before opening the DFTK
PR, undo the local dev so DFTK depends on the *registered* version:

```bash
cd /home/antoine/.julia/dev/DFTK
# remove the local [sources] override that `Pkg.develop` added to Project.toml,
# then:
julia --project -e 'using Pkg; Pkg.free("LOBPCG"); Pkg.resolve()'
```

Concretely, the DFTK `Project.toml` must end up with **only**:
- `LOBPCG = "87a0849e-8492-4fcc-8734-ba6a5d902784"` under `[deps]`
- `LOBPCG = "0.1"` under `[compat]`

and **no** `[sources]` entry for LOBPCG. (Registration must happen first, otherwise
`Pkg.resolve` can't find LOBPCG 0.1 in the registry.)

The DFTK PR can then be opened as usual. CI on that PR will only pass once LOBPCG.jl
is registered.

## Notes carried over from the extraction

- The generalized eigenproblem (`lobpcg(A, X, B, …)` with an SPD metric `B`) works and
  is tested. During extraction a pre-existing latent bug on that path was fixed
  (`new_BP` was used before assignment); DFTK itself only ever calls with `B = I`.
- The AMDGPU `LinearAlgebra` workarounds (Cholesky / gesdd! / 5-arg mul!) moved here
  from DFTK's AMDGPU extension; they load via `LOBPCGAMDGPUExt` whenever AMDGPU is
  present.
