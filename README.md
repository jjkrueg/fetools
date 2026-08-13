# fedesc — Fixed-effect sample descriptives for Stata

`fedesc` shows how high-dimensional fixed effects change your estimation
sample. Adding fixed effects to a regression (e.g. with
[`reghdfe`](https://github.com/sergiocorreia/reghdfe)) drops **singleton**
observations — those alone in a fixed-effect cell — so the sample shrinks. When
a coefficient moves after adding fixed effects, it is often unclear whether that
is driven by the fixed effects or by the changing sample. `fedesc` makes the
sample change transparent.

No regression is estimated: you supply one or more sets of fixed effects, and
`fedesc` reports, for the no-fixed-effect baseline and each specification, the
surviving observation count, its share of the baseline, and optional descriptive
statistics and distinct-entity counts. The iterative singleton-dropping rule
reproduces the sample that `reghdfe` would use, and `reghdfe` does **not** need
to be installed.

## Installation

Install directly from GitHub (replace `jjkrueger` with your GitHub user/repo if
you fork it):

```stata
net install fedesc, ///
    from("https://raw.githubusercontent.com/jjkrueger/fedesc/main/") replace
```

Then read the help:

```stata
help fedesc
```

To update later, rerun the `net install ... , replace` command. To remove:

```stata
ado uninstall fedesc
```

## Syntax

```stata
fedesc [varlist] [if] [in] , feffects(string) ///
    [ report(totals|shares|both) stats(spec) distinct(varlist) by(varname) ]
```

| Option | Purpose |
| --- | --- |
| `feffects()` | **Required.** Up to 5 fixed-effect specifications separated by ```|```. Terms may be plain (firmid), interaction-only (firmid#year), or main+interaction (firmid##year). Max 5 terms per specification. |
| `report()` | `totals` (default), `shares` (% of baseline), or `both`. |
| `stats()` | Up to 3 `(statistic) variable` pairs. Statistic: `mean`, `median`, `sd`, `var`, `min`, `max`, `sum`, `count`, or any percentile `p#`. |
| `distinct()` | Up to 3 variables; reports distinct (non-missing) counts and the share retained vs. baseline. |
| `by()` | Repeat the whole analysis within each category (≤ 21) of a variable; a `Total` block is shown first. |

The optional `varlist` defines the baseline sample (observations non-missing on
those variables), mimicking the variables a later regression would use. Omit it
to use every observation selected by `if`/`in`.

## Examples

```stata
* Observation counts for three specifications
fedesc, feffects(firmid | firmid year | firmid##year bankid##year)

* Totals and shares
fedesc, feffects(firmid | firmid year | bankid firmid year) report(both)

* Restrict baseline to regression variables and add statistics
fedesc interest_rate ln_loan maturity, ///
    feffects(firmid | firmid##year bankid##year) report(both) ///
    stats((mean) interest_rate (p50) loan_amount (mean) default)

* Distinct firms and banks surviving each specification
fedesc, feffects(firmid | firmid##year | bankid firmid year) ///
    report(both) distinct(firmid bankid)

* Run within each region
fedesc, feffects(firmid | firmid##year) report(both) by(region)
```

## Stored results

Per-specification scalars are stored (in `r()`) only when `by()` is **not** used.
With `s = 1..nspec` indexing specifications (`s = 0` is the baseline) and `j`
indexing `distinct()` variables:

- `r(nspec)`, `r(N_noFE)`, `r(N_s)`, `r(share_s)`
- `r(dist{j}_s)`, `r(distshare{j}_s)`
- `r(nby)`, `r(byvar)` (with `by()`)
- `r(report)`

## Repository contents

| File | Purpose |
| --- | --- |
| `fedesc.ado` | The command |
| `fedesc.sthlp` | Help file (`help fedesc`) |
| `fedesc.pkg` | Package description for `net install` |
| `stata.toc` | Package list for `net from` |
| `anareg_testdata.do` | Generates a synthetic credit-registry panel to try the command |

## Author

Jan Jakob Krüger · info@jjkrueger.de

The singleton-dropping sample matches [`reghdfe`](https://github.com/sergiocorreia/reghdfe)
by Sergio Correia and coauthors.

## License

Released under the MIT License — see [LICENSE](LICENSE).
