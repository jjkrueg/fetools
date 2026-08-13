*! fedesc version 1.0.0  12aug2026
*! Fixed-effect sample descriptives
*! Jan Jakob Krüger - info@jjkrueger.de
*! https://github.com/jjkrueger/fedesc
/*
================================================================================
fedesc  -  Fixed-Effect Sample Descriptives

Show how high-dimensional fixed effects change the estimation sample, and give
researchers descriptive statistics about that change. No regression needs to be
specified - the user only supplies the sets of fixed effects to compare.

The output always contains the "No fixed effects" baseline plus up to 5 reference
specifications. For each block the observation count (and/or share) is shown,
followed by any requested statistics and distinct-value counts underneath.

See the accompanying help file (help fedesc) for the full documentation.
================================================================================
*/

program define fedesc, rclass
    version 14.0

    syntax [varlist] [if] [in] , ///
        Feffects(string)          ///
        [ Report(string)          ///
          STats(string)           ///
          Distinct(varlist)       ///
          BY(varname) ]

    * ---------------------------------------------------------------------
    * 0) Option defaults and validation
    * ---------------------------------------------------------------------
    if "`report'" == "" local report "totals"
    if !inlist("`report'","totals","shares","both") {
        di as error "Report() must be one of: totals, shares, both"
        exit 198
    }
    local wantN = inlist("`report'","totals","both")
    local wantS = inlist("`report'","shares","both")

    * ---- parse STats() into up to 3 (stat, var) pairs -------------------
    local nstat = 0
    local work `"`stats'"'
    while regexm(`"`work'"', "^[ ]*\(([a-zA-Z0-9]+)\)[ ]+([a-zA-Z_][a-zA-Z0-9_]*)(.*)$") {
        local ++nstat
        if `nstat' > 3 {
            di as error "at most 3 statistics may be requested in STats()"
            exit 198
        }
        local stat`nstat' = regexs(1)
        local svar`nstat' = regexs(2)
        local work        = regexs(3)
        confirm numeric variable `svar`nstat''
    }
    if `"`stats'"' != "" & `nstat' == 0 {
        di as error `"could not parse STats(); use e.g. stats((mean) x (p50) y)"'
        exit 198
    }

    * ---- distinct() variables (max 3) -----------------------------------
    local ndist : word count `distinct'
    if `ndist' > 3 {
        di as error "at most 3 variables may be requested in Distinct()"
        exit 198
    }

    * ---- split Feffects() into specifications on "|" --------------------
    local nspec = 0
    local rest `"`feffects'"'
    while `"`rest'"' != "" {
        gettoken one rest : rest, parse("|")
        if `"`one'"' == "|" continue
        local one = trim(`"`one'"')
        if `"`one'"' == "" continue
        local ++nspec
        local spec`nspec' `"`one'"'
    }
    if `nspec' == 0 {
        di as error "Feffects() must contain at least one specification"
        exit 198
    }
    if `nspec' > 5 {
        di as error "at most 5 fixed-effect specifications are allowed (you gave `nspec')"
        exit 198
    }

    * ---------------------------------------------------------------------
    * 1) Baseline mask (varlist + if/in) and by() categories
    * ---------------------------------------------------------------------
    marksample touse, novarlist
    if "`varlist'" != "" {
        markout `touse' `varlist'
    }
    quietly count if `touse'
    if r(N) == 0 {
        di as error "no observations in the baseline sample"
        exit 2000
    }

    * ---- by() categorical variable (at most 21 categories) --------------
    local isstr = 0
    if "`by'" != "" {
        capture confirm string variable `by'
        if !_rc local isstr = 1
        quietly levelsof `by' if `touse', local(bylevels)
        local nby : word count `bylevels'
        if `nby' > 21 {
            di as error "By() variable `by' has `nby' categories; the maximum allowed is 21"
            exit 198
        }
        * a "Total" block (all categories combined) is shown first
        local bylevels "__total__ `bylevels'"
    }
    else {
        local bylevels "__all__"
        local nby 1
    }

    * ---------------------------------------------------------------------
    * 2) Pre-parse each specification once (independent of by-category)
    * ---------------------------------------------------------------------
    forvalues s = 1/`nspec' {

        local thespec `"`spec`s''"'
        local nterm : word count `thespec'
        if `nterm' > 5 {
            di as error "specification `s' has `nterm' terms; the maximum is 5"
            exit 198
        }

        local dims ""
        local basevars ""
        foreach term of local thespec {
            if strpos("`term'","##") {
                local vars : subinstr local term "##" " ", all
                local basevars `basevars' `vars'
                local k : word count `vars'
                local nsub = 2^`k' - 1
                forvalues m = 1/`nsub' {
                    local sub ""
                    forvalues b = 1/`k' {
                        if mod(int(`m'/(2^(`b'-1))),2) == 1 {
                            local w : word `b' of `vars'
                            local sub "`sub'~`w'"
                        }
                    }
                    local sub = substr("`sub'",2,.)
                    local dims `dims' `sub'
                }
            }
            else if strpos("`term'","#") {
                local vars : subinstr local term "#" " ", all
                local basevars `basevars' `vars'
                local sub : subinstr local vars " " "~", all
                local dims `dims' `sub'
            }
            else {
                local basevars `basevars' `term'
                local dims `dims' `term'
            }
        }
        local ubase`s' : list uniq basevars
        confirm variable `ubase`s''

        local udims ""
        foreach d of local dims {
            local found 0
            foreach u of local udims {
                if "`u'" == "`d'" local found 1
            }
            if !`found' local udims `udims' `d'
        }
        local udims`s' "`udims'"
    }

    * ---------------------------------------------------------------------
    * 3) Work variables and display width
    * ---------------------------------------------------------------------
    tempvar base grpsize
    quietly gen byte `base' = 0
    forvalues s = 1/`nspec' {
        tempvar samp`s'
        quietly gen byte `samp`s'' = 0
    }

    * Slim layout: N and share sit on the specification line. The label /
    * descriptor field is sized to the longest specification label.
    local ILW = length("No fixed effects")
    forvalues s = 1/`nspec' {
        local h "Spec `s':  `spec`s''"
        if length("`h'") > `ILW' local ILW = length("`h'")
    }
    local ILW = `ILW' + 2
    local SP = "                "   // 16 spaces for indentation

    * width of the by-mode rules (specifications are indented 4 in by-mode)
    local widthby = `ILW' + 4 + `wantN'*14 + `wantS'*11

    * ---------------------------------------------------------------------
    * 4) Loop over by-categories (single pass when by() not specified)
    *    All calculations - missing FE, singleton dropping, statistics and
    *    distinct counts - are performed within each category.
    * ---------------------------------------------------------------------
    if "`by'" != "" di as text "{hline `widthby'}"
    foreach lev of local bylevels {

        * ---- base sample for this category ------------------------------
        if "`by'" == "" | "`lev'" == "__total__" {
            quietly replace `base' = `touse'
        }
        else if `isstr' {
            quietly replace `base' = `touse' & (`by' == "`lev'")
        }
        else {
            quietly replace `base' = `touse' & (`by' == `lev')
        }
        quietly count if `base'
        local N_noFE = r(N)

        * ---- build each specification's sample within this category -----
        forvalues s = 1/`nspec' {
            quietly replace `samp`s'' = `base'
            foreach v of local ubase`s' {
                quietly replace `samp`s'' = 0 if missing(`v')
            }
            local dropped = 1
            while `dropped' > 0 {
                local dropped = 0
                foreach d of local udims`s' {
                    local dvars : subinstr local d "~" " ", all
                    quietly bysort `samp`s'' `dvars': gen long `grpsize' = _N if `samp`s'' == 1
                    quietly count if `samp`s'' == 1 & `grpsize' == 1
                    local thisdrop = r(N)
                    if `thisdrop' > 0 {
                        quietly replace `samp`s'' = 0 if `samp`s'' == 1 & `grpsize' == 1
                        local dropped = `dropped' + `thisdrop'
                    }
                    drop `grpsize'
                }
            }
        }

        * ================================================================
        * Display  (slim indented layout, identical for by and non-by)
        *   specind : indent of each specification line
        *   subind  : indent of the statistics / distinct lines beneath it
        * ================================================================
        local specind = 0
        if "`by'" != "" local specind = 4
        local subind = `specind' + 4
        local LW = `ILW' + `specind'
        local pad1 = substr("`SP'",1,`specind')
        local pad2 = substr("`SP'",1,`subind')
        local sepw = `LW' + `wantN'*14 + `wantS'*11

        * ---- category header (by-mode only) -----------------------------
        if "`by'" != "" {
            if "`lev'" == "__total__" {
                di as text _n as result "Total" as text " (all categories)"
            }
            else {
                local levlab "`lev'"
                if !`isstr' {
                    local vl : value label `by'
                    if "`vl'" != "" {
                        local vtxt : label `vl' `lev'
                        if "`vtxt'" != "" & "`vtxt'" != "`lev'" local levlab "`lev' (`vtxt')"
                    }
                }
                di as text _n "`by' = " as result "`levlab'"
            }
        }

        * top rule (non-by layout only)
        if "`by'" == "" di as text "{hline `sepw'}"

        * ---- baseline then each specification ---------------------------
        forvalues r = 0/`nspec' {

            if `r' == 0 {
                local head "No fixed effects"
                local cond `base'
            }
            else {
                local head "Spec `r':  `spec`r''"
                local cond `samp`r''
            }
            quietly count if `cond'
            local Nrow = r(N)
            local shrow = 100 * `Nrow' / `N_noFE'

            * specification line with observations / share inline
            di as text %-`LW's "`pad1'`head'" _c
            if `wantN' di as result %14.0fc `Nrow' _c
            if `wantS' di as text "  (" as result %6.2f `shrow' as text "%)" _c
            di ""

            * statistics (value only), indented
            forvalues j = 1/`nstat' {
                _fedesc_stat "`stat`j''" `svar`j'' "`cond'"
                local val = r(val)
                local d "`pad2'`stat`j''(`svar`j'')"
                if length("`d'") > `LW' local d = substr("`d'",1,`LW')
                di as text %-`LW's "`d'" as result %14.4g `val'
            }

            * distinct counts with share of the baseline distinct count
            forvalues j = 1/`ndist' {
                local dv : word `j' of `distinct'
                _fedesc_distinct `dv' "`cond'"
                local cnt = r(val)
                if `r' == 0 local basedist`j' = `cnt'
                local dsh = .
                if `basedist`j'' > 0 local dsh = 100 * `cnt' / `basedist`j''
                local d "`pad2'distinct `dv'"
                if length("`d'") > `LW' local d = substr("`d'",1,`LW')
                di as text %-`LW's "`d'" _c
                if `wantN' di as result %14.0fc `cnt' _c
                if `wantS' di as text "  (" as result %6.2f `dsh' as text "%)" _c
                di ""
                if "`by'" == "" {
                    return scalar dist`j'_`r'      = `cnt'
                    return scalar distshare`j'_`r' = `dsh'
                }
            }

            * returns (single-pass only, to keep r() unambiguous)
            if "`by'" == "" {
                if `r' == 0 {
                    return scalar N_noFE = `N_noFE'
                }
                else {
                    return scalar N_`r'     = `Nrow'
                    return scalar share_`r' = `shrow'
                }
            }

            * simple separator between specifications (non-by layout only)
            if "`by'" == "" & `r' < `nspec' di as text "{hline `sepw'}"
        }

        * bottom rule (non-by layout only)
        if "`by'" == "" di as text "{hline `sepw'}"
    }
    if "`by'" != "" di as text _n "{hline `widthby'}"

    return scalar nspec = `nspec'
    return local  report "`report'"
    if "`by'" != "" {
        return scalar nby = `nby'
        return local  byvar "`by'"
    }

end


* --------------------------------------------------------------------------
* helper: one statistic of `var' over the 0/1 condition `cond' -> r(val)
* --------------------------------------------------------------------------
program define _fedesc_stat, rclass
    args stat var cond
    if regexm("`stat'","^[pP]([0-9]+)$") {
        local pnum = regexs(1)
        if `pnum' == 50 {
            quietly summarize `var' if `cond', detail
            return scalar val = r(p50)
        }
        else {
            quietly _pctile `var' if `cond', p(`pnum')
            return scalar val = r(r1)
        }
    }
    else {
        quietly summarize `var' if `cond', detail
        if      "`stat'" == "mean"                    return scalar val = r(mean)
        else if "`stat'" == "sd"                      return scalar val = r(sd)
        else if "`stat'" == "var"                     return scalar val = r(Var)
        else if "`stat'" == "min"                     return scalar val = r(min)
        else if "`stat'" == "max"                     return scalar val = r(max)
        else if "`stat'" == "sum"                     return scalar val = r(sum)
        else if inlist("`stat'","count","n","N")      return scalar val = r(N)
        else if inlist("`stat'","median","p50")       return scalar val = r(p50)
        else {
            di as error "unknown statistic in STats(): `stat'"
            exit 198
        }
    }
end


* --------------------------------------------------------------------------
* helper: number of distinct non-missing values of `var' over `cond' -> r(val)
* --------------------------------------------------------------------------
program define _fedesc_distinct, rclass
    args var cond
    tempvar tag
    quietly bysort `cond' `var': gen byte `tag' = (_n == 1)
    quietly count if `cond' & `tag' & !missing(`var')
    return scalar val = r(N)
end
