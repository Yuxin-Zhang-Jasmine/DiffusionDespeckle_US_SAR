# Third-party software notices

The repository-level MIT license applies only to code authored for this
project. The following bundled components retain their own licenses and
copyright notices.

| Component | Location | License |
| --- | --- | --- |
| ADMSS | `PostAnalysis/src/ADMSS/` | BSD 2-Clause; see `license.txt` |
| SCUNet | `PostAnalysis/src/SOTApython/SCUNet-main/` | Apache License 2.0; see `LICENSE` |
| deepdespeckling | `PostAnalysis/src/SOTApython/deepdespeckling/` | MIT; see `LICENSE` |
| Speckle2Speckle inference source | `PostAnalysis/src/SOTApython/Speckle2Speckle/src/` | MIT; see `LICENSE` |
| USTB | `PostAnalysis/src/USTB-master/` | MIT; see `LICENSE` |
| export_fig | `PostAnalysis/src/altmany-export_fig-3.47.0.0/` | BSD 3-Clause; see `LICENSE` |
| MATLAB `gif` utility | `PostAnalysis/src/gif/` | BSD 3-Clause; see `license.txt` |

Pretrained models, datasets, images, and other non-code assets are not
automatically covered by the repository-level MIT license. Consult the
corresponding upstream project or dataset terms before reuse.

## Components intentionally not redistributed

- **FANS** is omitted because its license restricts use to nonprofit purposes.
- **OBNLM** is omitted because the bundled material does not provide clear
  redistribution permission and describes patent/licensing restrictions.
- **DNN-lambda** is omitted because no redistribution license was found.
- **Speckle2Speckle `network.pt`** is omitted because the upstream repository
  licenses only its `src` directory under MIT and labels other content for
  research use.

The MATLAB runners detect these optional components and skip them when they
are unavailable.
