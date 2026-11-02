# XC2S15 FPGA support (PLATFORM=PM3XC2S15)

Date: 2026-11-01

## Problem

A Proxmark3 Easy style clone ships with a Xilinx Spartan-II XC2S15 in the
VQ100 package instead of the usual XC2S30. The board is otherwise a standard
PM3 generic layout (AT91SAM7S MCU, same FPGA pin map). Stock firmware fails
on it because the embedded bitstreams are built for the XC2S30: the XC2S15
expects 24712 configuration bytes, the XC2S30 image carries 42096, so the
chip never asserts DONE and every FPGA mode is dead.

The XC2S15 is also much smaller: 96 CLBs and 4 block RAMs against the
XC2S30's 216 CLBs and 6 block RAMs. Not every existing image will fit.

## Scope

- New firmware platform `PM3XC2S15`, mirroring how `PM3ULTIMATE` (XC2S50)
  was added.
- New FPGA build targets producing XC2S15 bitstreams from the unchanged
  common HDL.
- Bitstreams synthesized through the repo's existing GitHub Actions ISE
  workflow (no local ISE available).
- Documentation updates.

Out of scope: HDL changes beyond conditional module exclusion, any new
client command, runtime chip detection.

## Design

### FPGA build (`fpga/proxmark3_fpga.mk`)

Add targets 10 to 13:

| Target | Name | Modules |
|---|---|---|
| 10 | `fpga_pm3_s15_lf` | same as TARGET1 (LF) |
| 11 | `fpga_pm3_s15_hf` | same as TARGET2 (HF) |
| 12 | `fpga_pm3_s15_hf_15` | same as TARGET3 (HF ISO15693) |
| 13 | `fpga_pm3_s15_felica` | same as TARGET4 (FeliCa) |

All use part `xc2s15-5-vq100`, pin constraints `pm3/xc2s30-5-vq100.ucf`
(the VQ100 pinout is identical across XC2S15/XC2S30), `XST_OPTS_AREA`, and
the TARGET1 file list. Targets are appended to `TARGETS`.

`fpga/Makefile` help comment and `.github/workflows/fpga-pm3.yml` size check
list gain the new names. Placeholder 0 byte `.bit` files are not used; the
real bitstreams are committed once synthesized.

### Fit fallback

If MAP reports the design does not fit:

- `hf`: drop `WITH_HF5` (get trace) first, then `WITH_HF3` (sniff). Each
  drop is a recorded feature loss for this platform.
- `hf_15`: same order.
- `felica`: expected not to fit (needs 6 block RAMs). If it fails after the
  same trimming, the target stays defined but the bitstream is left out of
  the platform's `FPGA_BITSTREAMS`, and `SKIP_FELICA` behaviour is forced.
- `lf`: expected to fit; if not, drop `WITH_LF2` (passthrough) last resort.

### Firmware and host build

- `common_fpga/fpga.h`: `#elif defined XC2S15` with `FPGA_TYPE "2s15vq100"`
  and `FPGA_CONFIG_SIZE` = largest XC2S15 `.bit` size rounded up to a
  multiple of `FPGA_INTERLEAVE_SIZE` (288). Expected 25056.
- `common_arm/Makefile.hal`: `PLATFORM=PM3XC2S15` block. Bitstream list
  `fpga_pm3_s15_*.bit` honouring `SKIP_LF`, `SKIP_FELICA`, `SKIP_ISO15693`.
  `PLATFORM_DEFS = -DXC2S15 -DCHIP_AT91SAM7S`, plus `-DLED_ORDER_PM3EASY`
  when `LED_ORDER=PM3EASY`. `PLTNAME = Proxmark3 generic target with XC2S15`,
  `PLATFORM_FPGA = xc2s15`. Row in the `KNOWN_PLATFORM_DEFINITIONS` table.
- `common_arm/Hal.cmake`: equivalent block.
- `tools/fpga_compress/Makefile`: `MYDEFS = -DXC2S15` for the platform.
- Client: `cmdhw.c` (`hw version`) compares the reported version string
  against `FPGA_TYPE` and prints "chip mismatch" otherwise. The client build
  only ever receives `-DICOPYX` today, so iCopy-X and Ultimate already get a
  false mismatch (pre-existing, not fixed here). For `PM3XC2S15` add
  `-DXC2S15` in `client/Makefile`, `client/CMakeLists.txt` and
  `client/experimental_lib/CMakeLists.txt` when `PLATFORM=PM3XC2S15`.

### Documentation

- `Makefile.platform.sample`: commented `PLATFORM=PM3XC2S15` entry.
- `doc/md/Use_of_Proxmark/4_Advanced-compilation-parameters.md` platform
  table.
- `doc/md/Development/Makefile-vs-CMake.md` platform value list.
- `fpga/pm3/fpga_pm3_top.v` reference define comment.
- `CHANGELOG.md` entry.

### Synthesis loop

1. Fork `RfidResearchGroup/proxmark3` under the user's GitHub account with
   `gh`, add it as remote `fork`.
2. Push `feature/xc2s15-support`.
3. `gh workflow run fpga-pm3.yml` on the fork, wait, download the
   `fpga-pm3-bitstreams` artifact.
4. On a fit failure, apply the fallback order above, push, rerun.
5. Commit the resulting `fpga_pm3_s15_*.bit` files and set
   `FPGA_CONFIG_SIZE` from their real size.

### Testing

- `make PLATFORM=PM3XC2S15` warning free with gcc, with and without
  `LED_ORDER=PM3EASY`.
- `make PLATFORM=PM3RDV4` and `make PLATFORM=PM5` still build.
- CMake firmware build for `PM3XC2S15`.
- `make check`.
- `fpga_compress` accepts the XC2S15 bitstream set without the "too big"
  error.
- On device: flash, `hw status` shows FPGA image strings containing
  `2s15vq100`, `lf search` / `hf search` exercised by the user.

## Outcome of synthesis (2026-11-01)

Measured on CI (XC2S15 = 192 slices, 384 LUTs, 4 block RAMs):

| Image / module | Slices |
|---|---|
| stock LF | 328 |
| stock HF / HF_15 / FeliCa | 749 to 778 |
| `lo_edge_detect` alone | 297 |
| LF reader + passthru + ADC | 56 |
| `hi_reader` + `hi_sniffer` | 169 |
| `hi_iso14443a` alone | 194 |
| `hi_flite` alone | 178 |

Decision: ship two images, `fpga_pm3_s15_lf` (LF0, LF2, LF3) and
`fpga_pm3_s15_hf` (HF0, HF3). The platform forces `SKIP_HITAG`,
`SKIP_EM4x50`, `SKIP_FELICA` and `SKIP_HFPLOT`. ISO15693 keeps the basic
reader through the HF image (a missing `HF_15` bitstream maps to index 0).
Possible follow-ups: a trimmed `hi_iso14443a` image with ARM side image
switching by major mode, and a FeliCa only image.
