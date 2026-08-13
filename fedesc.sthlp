{smcl}
{* *! version 1.0.0  12aug2026}{...}
{vieweralsosee "reghdfe" "help reghdfe"}{...}
{vieweralsosee "areg" "help areg"}{...}
{vieweralsosee "tabulate" "help tabulate"}{...}
{viewerjumpto "Syntax" "fedesc##syntax"}{...}
{viewerjumpto "Description" "fedesc##description"}{...}
{viewerjumpto "Options" "fedesc##options"}{...}
{viewerjumpto "Remarks" "fedesc##remarks"}{...}
{viewerjumpto "Examples" "fedesc##examples"}{...}
{viewerjumpto "Stored results" "fedesc##results"}{...}
{viewerjumpto "Author" "fedesc##author"}{...}
{title:Title}

{phang}
{bf:fedesc} {hline 2} Fixed-effect sample descriptives

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:fedesc}
[{varlist}]
{ifin}
{cmd:,}
{opth fe:ffects(string)}
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{p2coldent:* {opth fe:ffects(string)}}up to 5 fixed-effect specifications to
compare, separated by {cmd:|}{p_end}
{synopt:{opt r:eport(what)}}output content: {cmd:totals} (default), {cmd:shares},
or {cmd:both}{p_end}
{synopt:{opt st:ats(spec)}}up to 3 {cmd:(}{it:statistic}{cmd:)} {it:variable}
pairs to display per sample{p_end}
{synopt:{opth d:istinct(varlist)}}up to 3 variables whose distinct-value counts
(and retained share) are shown{p_end}
{synopt:{opth by(varname)}}run the whole analysis within each category of
{it:varname} (max 21 categories){p_end}
{synoptline}
{p 4 6 2}* {opt feffects()} is required.{p_end}

{p 4 6 2}
{it:varlist} may contain factor variables only as plain variables here; the
fixed-effect interactions go inside {opt feffects()} (see below).{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:fedesc} reports how high-dimensional fixed effects change the estimation
sample. Adding fixed effects to a regression typically drops observations,
because {help reghdfe} and similar commands remove {it:singleton} groups
(observations that are alone in a fixed-effect cell). When a coefficient moves
after adding fixed effects it is often unclear whether this is driven by the
fixed effects themselves or by the change in the underlying sample. {cmd:fedesc}
makes that change transparent.

{pstd}
No regression is estimated. The user supplies one or more sets of fixed effects
in {opt feffects()}, and {cmd:fedesc} reports, for the {it:no-fixed-effect}
baseline and for each specification, the number of surviving observations, their
share of the baseline, and optionally descriptive statistics and distinct-entity
counts. The singleton-dropping rule is applied iteratively across all
fixed-effect dimensions until it converges, mirroring the sample that
{help reghdfe} would use.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opth feffects(string)} specifies up to five fixed-effect specifications to be
compared, separated by a vertical bar ({cmd:|}). Within a specification, list the
terms separated by spaces. A term may be a plain variable ({cmd:firmid}), an
interaction only ({cmd:firmid#year}, i.e. the firm-by-year cells), or an
interaction with its main effects ({cmd:firmid##year}, which expands to
{cmd:firmid}, {cmd:year} and {cmd:firmid#year}). Each specification may contain
at most five top-level terms. Example:
{cmd:feffects(firmid | firmid year | firmid##year bankid##year)}.

{phang}
{opt report(what)} controls what is printed for each sample. {cmd:totals}
(the default) prints the number of observations; {cmd:shares} prints the share
(%) of the baseline sample; {cmd:both} prints both.

{phang}
{opt stats(spec)} requests up to three descriptive statistics, printed underneath
each specification. {it:spec} is a sequence of {cmd:(}{it:statistic}{cmd:)}
{it:variable} pairs. {it:statistic} may be {cmd:mean}, {cmd:median}, {cmd:sd},
{cmd:var}, {cmd:min}, {cmd:max}, {cmd:sum}, {cmd:count}, or any percentile
{cmd:p}{it:#} (for example {cmd:p10}, {cmd:p50}, {cmd:p90}, {cmd:p99}). Example:
{cmd:stats((mean) interest_rate (p50) loan_amount (mean) default)}.

{phang}
{opth distinct(varlist)} lists up to three variables whose number of distinct
(non-missing) values is reported for every sample, together with the share
retained relative to the baseline distinct count. This shows, for instance, how
many firms or banks survive under a given set of fixed effects.

{phang}
{opth by(varname)} runs the complete analysis separately within each category of
{it:varname}, which may have at most 21 categories. A {cmd:Total} block covering
all categories is printed first, followed by one block per category; all
calculations, including singleton dropping, are performed within the category.


{marker remarks}{...}
{title:Remarks}

{pstd}
The optional {it:varlist} defines the baseline (no-fixed-effect) sample: only
observations that are non-missing on every listed variable are kept, exactly as
a regression on those variables would require. If {it:varlist} is omitted, the
baseline is every observation selected by {cmd:if}/{cmd:in}. Each specification
then additionally requires its fixed-effect variables to be non-missing before
singletons are dropped.

{pstd}
{cmd:fedesc} does not require {help reghdfe} to be installed; it reproduces the
iterative singleton-dropping logic internally. The dataset in memory is not
modified.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use credit_registry, clear}{p_end}

{pstd}Observation counts for three fixed-effect specifications{p_end}
{phang2}{cmd:. fedesc, feffects(firmid | firmid year | firmid##year bankid##year)}{p_end}

{pstd}Totals and shares of the no-fixed-effect baseline{p_end}
{phang2}{cmd:. fedesc, feffects(firmid | firmid year | bankid firmid year) report(both)}{p_end}

{pstd}Restrict the baseline to a regression's variables and add statistics{p_end}
{phang2}{cmd:. fedesc interest_rate ln_loan maturity,}{p_end}
{phang2}{cmd:        feffects(firmid | firmid##year bankid##year) report(both)}{p_end}
{phang2}{cmd:        stats((mean) interest_rate (p50) loan_amount (mean) default)}{p_end}

{pstd}Distinct firms and banks surviving each specification{p_end}
{phang2}{cmd:. fedesc, feffects(firmid | firmid##year | bankid firmid year)}{p_end}
{phang2}{cmd:        report(both) distinct(firmid bankid)}{p_end}

{pstd}Run the whole analysis within each region{p_end}
{phang2}{cmd:. fedesc, feffects(firmid | firmid##year) report(both) by(region)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:fedesc} stores the following in {cmd:r()}. Per-specification scalars are
stored only when {opt by()} is {it:not} specified (so that {cmd:r()} is
unambiguous); {it:s} = 1,...,{cmd:nspec} indexes specifications, {it:s} = 0 is
the baseline, and {it:j} indexes {opt distinct()} variables.

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(nspec)}}number of fixed-effect specifications{p_end}
{synopt:{cmd:r(N_noFE)}}baseline observations{p_end}
{synopt:{cmd:r(N_}{it:s}{cmd:)}}observations under specification {it:s}{p_end}
{synopt:{cmd:r(share_}{it:s}{cmd:)}}share (%) of baseline under specification {it:s}{p_end}
{synopt:{cmd:r(dist}{it:j}{cmd:_}{it:s}{cmd:)}}distinct count of the {it:j}-th {opt distinct()} variable, spec {it:s}{p_end}
{synopt:{cmd:r(distshare}{it:j}{cmd:_}{it:s}{cmd:)}}share (%) of the baseline distinct count retained{p_end}
{synopt:{cmd:r(nby)}}number of {opt by()} categories (only with {opt by()}){p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:r(report)}}the {opt report()} setting in effect{p_end}
{synopt:{cmd:r(byvar)}}the {opt by()} variable (only with {opt by()}){p_end}


{marker author}{...}
{title:Author}

{pstd}
Jan Jakob Krüger{break}
info@jjkrueger.de{break}
{browse "https://github.com/jjkrueger/fedesc":https://github.com/jjkrueger/fedesc}

{pstd}
The iterative singleton-dropping sample matches that of {cmd:reghdfe} by
Sergio Correia and coauthors.


{title:Also see}

{psee}
Online: {help reghdfe}, {help areg}, {help tabulate}
{p_end}
