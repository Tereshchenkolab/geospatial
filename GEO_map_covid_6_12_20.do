***prepared for analysis of geospatial data. Updated analysis with the Covid-19 data as of June 11, 2020
***by Larisa Tereshchenko <tereshch@ohsu.edu>
***I acknowledge the use of code provided by Chuck Huber (STATA) https://blog.stata.com/tag/covid-19/
***and https://blog.stata.com/2020/03/27/covid-19-time-series-data-from-johns-hopkins-university/


spshape2dta cb_2018_us_county_500k.shp, saving(usacounties) replace
use usacounties_shp.dta, clear
describe
list _ID _X _Y shape_order in 1/10, abbreviate(11)
use usacounties.dta, clear
describe
generate fips = real(GEOID)
list _ID GEOID fips NAME in 1/10, separator(0)
save "usacounties.dta", replace
clear

***import confirmed cases
clear
import delimited https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv
describe
list fips combined_key v120 v121 v122 v123 in 1/10
rename v123 confirmed
drop if missing(fips)
save covid19_county, replace

***import deaths 
clear
import delimited https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv
describe
list fips combined_key v120 v121 v122 v123 v124 in 1/10
drop if missing(fips)
rename v124 deaths
save covid19_deaths, replace




clear
import delimited https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv
describe state county stname ctyname census2010pop popestimate2019
list state county stname ctyname census2010pop popestimate2019  in 1/5, abbreviate(14) noobs
generate fips = state*1000 + county
list state county fips stname ctyname in 1/5, abbreviate(14) noobs
save census, replace
use _ID _CX _CY GEOID fips using usacounties.dta

merge 1:1 fips using covid19_county, keepusing(province_state combined_key confirmed)
list _ID GEOID fips combined_key confirmed if _merge==1, abbreviate(15)
count if _merge==1 & missing(confirmed)

**drop if _merge==1
list _ID GEOID fips combined_key confirmed  if _merge==2, abbreviate(15)
count if _merge==2 & confirmed==0
drop if _merge==2
drop _merge
describe

merge 1:1 fips using covid19_deaths, keepusing(deaths)
list _ID GEOID fips combined_key confirmed if _merge==1, abbreviate(15)
count if _merge==1 & missing(confirmed)
drop if _merge==2
drop _merge

merge 1:1 fips using census
list _ID GEOID fips deaths confirmed popestimate2019 if _merge==2, abbreviate(15)
list _ID GEOID fips deaths confirmed popestimate2019 if _merge==1, abbreviate(15)
keep if _merge==3
drop _merge


generate confirmed_adj = 100000*(confirmed/popestimate2019)
label var confirmed_adj "Cases per 100,000"
format %16.0fc confirmed_adj
generate deaths_adj = 100000*(deaths/popestimate2019)
label var deaths_adj "Deaths per 100,000"
format %16.0fc deaths_adj
gen GQ2019_adj = 100000*(gqestimates2019 / popestimate2019)
label var  GQ2019_adj "GQ population 2019 per 100,000"
format %16.0fc  GQ2019_adj
gen deaths2019_adj = 100000*( deaths2019 / popestimate2019)
label var  deaths2019_adj "deaths 2019 per 100,000"
format %16.0fc  deaths2019_adj
gen births2019_adj = 100000*( births2019 / popestimate2019)
format %16.0fc  births2019_adj
label var  births2019_adj "births 2019 per 100,000"
describe
save covid19_adj, replace

merge 1:1 fips using ACEI, keepusing(ACEI)
drop _merge
merge 1:1 fips using ARB, keepusing(ARB)
drop _merge
merge 1:1 fips using anti_arr_1, keepusing(AAD1)
drop _merge
merge 1:1 fips using anti_arr_3, keepusing(AAD3)
drop _merge
merge 1:1 fips using anti_arr_5, keepusing(AAD5)
drop if _merge==2
drop _merge
merge 1:1 fips using aldosterone_ant, keepusing(AA)
drop _merge
merge 1:1 fips using alpha_a1, keepusing(AB)
drop _merge
merge 1:1 fips using alpha_and_beta_blockers, keepusing(ABB)
drop _merge
merge 1:1 fips using beta_blockers, keepusing(BB)
drop _merge
merge 1:1 fips using anti_coag, keepusing(anticoag)
drop _merge
merge 1:1 fips using anti_platelet, keepusing(antiplatelet)
drop if _merge==2
drop _merge
merge 1:1 fips using central_acting, keepusing(central)
drop _merge
merge 1:1 fips using dihydro, keepusing(CCB_dih)
drop _merge
merge 1:1 fips using non_dihydro, keepusing(CCB_nondih)
drop if _merge==2
drop _merge
merge 1:1 fips using injectable_diabetic, keepusing(insulin)
drop _merge
merge 1:1 fips using oral_diabetic, keepusing(oral_diab)
drop if _merge==2
drop _merge
merge 1:1 fips using lipid_low, keepusing(LLD)
drop _merge
merge 1:1 fips using loop_diuretics, keepusing(loopd)
drop _merge
merge 1:1 fips using thiazide, keepusing(thiaz)
drop _merge
merge 1:1 fips using vasodilators, keepusing(vasodil)
drop if _merge==2
drop _merge

describe
save covid19_adj, replace

gen CVDmeds = ACEI + ARB + AAD1 + AAD3 + AAD5 + AA + AB + ABB + BB + anticoag + antiplatelet + central + CCB_dih + CCB_nondih + insulin + oral_diab + LLD + loopd + thiaz + vasodil


***plotting maps

grmap, activate
drop if inlist(stname, "Alaska", "Hawaii")
spset, modify shpfile(usacounties_shp)
spset, modify shpfile(usacounties_shp)
grmap confirmed_adj, clnumber(7)
grmap deaths_adj, clnumber(7)
graph save "Graph" "D:\Lora_new\Databases\GEO\log files\covid_19_confirmed_per100000.gph"
graph export "D:\Lora_new\Databases\GEO\log files\covid_19_confirmed_per100000.png", as(png) name("Graph")


***import deaths as a separate step and then re-merge
clear
import delimited https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv
describe
list fips combined_key v111 v112 v113 v114 v115 in 1/10
drop if missing(fips)
rename v115 deaths
save covid19_deaths, replace



generate rACEI = (ACEI+1)/popestimate2019
label var rACEI "ACEI total day supply rate"
format %16.0fc rACEI
generate rARB = (ARB+1)/popestimate2019
label var rARB "ARB total day supply rate"
format %16.0fc rARB
gen ACEI_ARB_ratio = rACEI/rARB
generate rARBpure = (ARBpure+1)/popestimate2019
label var rARBpure "ARB total day supply rate"
format %16.0fc rARBpure
generate rAAD1 = (AAD1+1)/popestimate2019
label var rAAD1 "AAD1 total day supply rate"
format %16.0fc rAAD1
generate rAAD3 = (AAD3+1)/popestimate2019
label var rAAD3 "AAD3 total day supply rate"
format %16.0fc rAAD3
generate rAAD5 = (AAD5+1)/popestimate2019
label var rAAD5 "AAD5 total day supply rate"
format %16.0fc rAAD5
generate rAA = (AA+1)/popestimate2019
label var rAA "AA total day supply rate"
format %16.0fc rAA
generate rAB = (AB+1)/popestimate2019
label var rAB "AB total day supply rate"
format %16.0fc rAB
generate rBB = (BB+1)/popestimate2019
label var rBB "BB total day supply rate"
format %16.0fc rBB
generate rABB = (ABB+1)/popestimate2019
label var rABB "ABB total day supply rate"
format %16.0fc rABB
generate rLLD = (LLD+1)/popestimate2019
label var rLLD "LLD total day supply rate"
format %16.0fc rLLD
generate ranticoag = (anticoag+1)/popestimate2019
label var ranticoag "anticoag total day supply rate"
format %16.0fc ranticoag
generate rantiplatelet = (antiplatelet+1)/popestimate2019
label var rantiplatelet "antiplatelet total day supply rate"
format %16.0fc rantiplatelet
generate rcentral = (central+1)/popestimate2019
label var rcentral "central total day supply rate"
format %16.0fc rcentral
generate rCCB_dih = (CCB_dih+1)/popestimate2019
label var rCCB_dih "CCB_dih total day supply rate"
format %16.0fc rCCB_dih
generate rCCB_nondih = (CCB_nondih+1)/popestimate2019
label var rCCB_nondih "CCB_nondih total day supply rate"
format %16.0fc rCCB_nondih
generate rinsulin = (insulin+1)/popestimate2019
label var rinsulin "insulin total day supply rate"
format %16.0fc rinsulin
generate roral_diab = (oral_diab+1)/popestimate2019
label var roral_diab "oral_diab total day supply rate"
format %16.0fc roral_diab
generate rloopd = (loopd+1)/popestimate2019
label var rloopd "loopd total day supply rate"
format %16.0fc rloopd
generate rthiaz = (thiaz+1)/popestimate2019
label var rthiaz "thiaz total day supply rate"
format %16.0fc rthiaz
generate rvasodil = (vasodil+1)/popestimate2019
label var rvasodil "vasodil total day supply rate"
format %16.0fc rvasodil
generate rCVDmeds = (CVDmeds+1)/popestimate2019
label var rCVDmeds "All CV meds total day supply rate"
format %16.0fc rCVDmeds


gen logrAAD1 = log(rAAD1)
gen logrAAD3 = log(rAAD3)
gen logrAAD5 = log(rAAD5)
gen logrAA=log(rAA)
gen logrAB=log(rAB)
gen logrBB=log(rBB)
gen logrABB=log(rABB)
gen logrLLD=log(rLLD)
gen logranticoag =log(ranticoag)
gen lograntiplatelet =log( rantiplatelet )
gen logrcentral =log( rcentral )
gen logrCCB_dih =log( rCCB_dih )
gen logrCCB_nondih =log( rCCB_nondih )
gen logrinsulin =log( rinsulin )
gen logroral_diab =log( roral_diab )
gen logrloopd =log( rloopd )
gen logrthiaz =log( rthiaz )
gen logrvasodil =log( rvasodil )
gen logrCVDmeds=log(rCVDmeds)
gen logrACEI = log(rACEI)
gen logrARB = log(rARB)
gen logrARBpure = log(rARBpure)


gen deathplus1 = deaths_adj+1
gen caseplus1 = confirmed_adj+1
gen logdeaths = log( deathplus1)
gen logcases = log( caseplus1)
label var logdeaths "Covid-19 death rate"
format %16.0fc logdeaths
label var logcases "Covid-19 confirmed case rate"
format %16.0fc logcases

spmatrix dir
spmatrix create contiguity W

***models with ACEI use outcome
spregress logrACEI logbirths , heteroskedastic dvarlag(Widist) ivarlag(Widist: logbirths )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI logdead , heteroskedastic dvarlag(Widist) ivarlag(Widist: logdead )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI logGQ , heteroskedastic dvarlag(Widist) ivarlag(Widist: logGQ)  errorlag(Widist) gs2sls
estat impact
spregress logrACEI pctpovall_2018 , heteroskedastic dvarlag(Widist) ivarlag(Widist: pctpovall_2018 )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI health , heteroskedastic dvarlag(Widist) ivarlag(Widist: health )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI smoking , heteroskedastic dvarlag(Widist) ivarlag(Widist: smoking )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI obesity , heteroskedastic dvarlag(Widist) ivarlag(Widist: obesity )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI PAinactivity , heteroskedastic dvarlag(Widist) ivarlag(Widist: PAinactivity )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI drinking, heteroskedastic dvarlag(Widist) ivarlag(Widist: drinking )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI uninsured , heteroskedastic dvarlag(Widist) ivarlag(Widist: uninsured )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI somecollege , heteroskedastic dvarlag(Widist) ivarlag(Widist: somecollege )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI childpoverty , heteroskedastic dvarlag(Widist) ivarlag(Widist: childpoverty )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI social, heteroskedastic dvarlag(Widist) ivarlag(Widist: social )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI air, heteroskedastic dvarlag(Widist) ivarlag(Widist: air )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI  Housing, heteroskedastic dvarlag(Widist) ivarlag(Widist:  Housing )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI severehousing, heteroskedastic dvarlag(Widist) ivarlag(Widist: severehousing )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI food, heteroskedastic dvarlag(Widist) ivarlag(Widist: food )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI sleep, heteroskedastic dvarlag(Widist) ivarlag(Widist: sleep )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI unins_adults, heteroskedastic dvarlag(Widist) ivarlag(Widist: unins_adults )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI below18, heteroskedastic dvarlag(Widist) ivarlag(Widist: below18 )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI older65, heteroskedastic dvarlag(Widist) ivarlag(Widist: older65 )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI NHBlack, heteroskedastic dvarlag(Widist) ivarlag(Widist: NHBlack )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI Indian, heteroskedastic dvarlag(Widist) ivarlag(Widist: Indian )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI Asian, heteroskedastic dvarlag(Widist) ivarlag(Widist: Asian )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI Pacific, heteroskedastic dvarlag(Widist) ivarlag(Widist: Pacific )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI Hispanic, heteroskedastic dvarlag(Widist) ivarlag(Widist: Hispanic )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI NHWhite, heteroskedastic dvarlag(Widist) ivarlag(Widist: NHWhite )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI female, heteroskedastic dvarlag(Widist) ivarlag(Widist: female )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI CVDhosp, heteroskedastic dvarlag(Widist) ivarlag(Widist: CVDhosp )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI CVDdeath, heteroskedastic dvarlag(Widist) ivarlag(Widist: CVDdeath )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI HFhosp, heteroskedastic dvarlag(Widist) ivarlag(Widist: HFhosp )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI HFdeath, heteroskedastic dvarlag(Widist) ivarlag(Widist: HFdeath )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI CHDhosp, heteroskedastic dvarlag(Widist) ivarlag(Widist: CHDhosp)  errorlag(Widist) gs2sls
estat impact
spregress logrACEI CHDdeath, heteroskedastic dvarlag(Widist) ivarlag(Widist: CHDdeath )  errorlag(Widist) gs2sls
estat impact
spregress logrACEI DM_older20, heteroskedastic dvarlag(Widist) ivarlag(Widist: DM_older20 )  errorlag(Widist) gs2sls
estat impact


***models with ARB use outcome
spregress logrARB logbirths , heteroskedastic dvarlag(Widist) ivarlag(Widist: logbirths )  errorlag(Widist) gs2sls
estat impact
spregress logrARB logdead , heteroskedastic dvarlag(Widist) ivarlag(Widist: logdead )  errorlag(Widist) gs2sls
estat impact
spregress logrARB logGQ , heteroskedastic dvarlag(Widist) ivarlag(Widist: logGQ)  errorlag(Widist) gs2sls
estat impact
spregress logrARB pctpovall_2018 , heteroskedastic dvarlag(Widist) ivarlag(Widist: pctpovall_2018 )  errorlag(Widist) gs2sls
estat impact
spregress logrARB med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logrARB health , heteroskedastic dvarlag(Widist) ivarlag(Widist: health )  errorlag(Widist) gs2sls
estat impact
spregress logrARB smoking , heteroskedastic dvarlag(Widist) ivarlag(Widist: smoking )  errorlag(Widist) gs2sls
estat impact
spregress logrARB obesity , heteroskedastic dvarlag(Widist) ivarlag(Widist: obesity )  errorlag(Widist) gs2sls
estat impact
spregress logrARB PAinactivity , heteroskedastic dvarlag(Widist) ivarlag(Widist: PAinactivity )  errorlag(Widist) gs2sls
estat impact
spregress logrARB drinking, heteroskedastic dvarlag(Widist) ivarlag(Widist: drinking )  errorlag(Widist) gs2sls
estat impact
spregress logrARB uninsured , heteroskedastic dvarlag(Widist) ivarlag(Widist: uninsured )  errorlag(Widist) gs2sls
estat impact
spregress logrARB somecollege , heteroskedastic dvarlag(Widist) ivarlag(Widist: somecollege )  errorlag(Widist) gs2sls
estat impact
spregress logrARB childpoverty , heteroskedastic dvarlag(Widist) ivarlag(Widist: childpoverty )  errorlag(Widist) gs2sls
estat impact
spregress logrARB social, heteroskedastic dvarlag(Widist) ivarlag(Widist: social )  errorlag(Widist) gs2sls
estat impact
spregress logrARB air, heteroskedastic dvarlag(Widist) ivarlag(Widist: air )  errorlag(Widist) gs2sls
estat impact
spregress logrARB  Housing, heteroskedastic dvarlag(Widist) ivarlag(Widist:  Housing )  errorlag(Widist) gs2sls
estat impact
spregress logrARB severehousing, heteroskedastic dvarlag(Widist) ivarlag(Widist: severehousing )  errorlag(Widist) gs2sls
estat impact
spregress logrARB food, heteroskedastic dvarlag(Widist) ivarlag(Widist: food )  errorlag(Widist) gs2sls
estat impact
spregress logrARB sleep, heteroskedastic dvarlag(Widist) ivarlag(Widist: sleep )  errorlag(Widist) gs2sls
estat impact
spregress logrARB unins_adults, heteroskedastic dvarlag(Widist) ivarlag(Widist: unins_adults )  errorlag(Widist) gs2sls
estat impact
spregress logrARB below18, heteroskedastic dvarlag(Widist) ivarlag(Widist: below18 )  errorlag(Widist) gs2sls
estat impact
spregress logrARB older65, heteroskedastic dvarlag(Widist) ivarlag(Widist: older65 )  errorlag(Widist) gs2sls
estat impact
spregress logrARB NHBlack, heteroskedastic dvarlag(Widist) ivarlag(Widist: NHBlack )  errorlag(Widist) gs2sls
estat impact
spregress logrARB Indian, heteroskedastic dvarlag(Widist) ivarlag(Widist: Indian )  errorlag(Widist) gs2sls
estat impact
spregress logrARB Asian, heteroskedastic dvarlag(Widist) ivarlag(Widist: Asian )  errorlag(Widist) gs2sls
estat impact
spregress logrARB Pacific, heteroskedastic dvarlag(Widist) ivarlag(Widist: Pacific )  errorlag(Widist) gs2sls
estat impact
spregress logrARB Hispanic, heteroskedastic dvarlag(Widist) ivarlag(Widist: Hispanic )  errorlag(Widist) gs2sls
estat impact
spregress logrARB NHWhite, heteroskedastic dvarlag(Widist) ivarlag(Widist: NHWhite )  errorlag(Widist) gs2sls
estat impact
spregress logrARB female, heteroskedastic dvarlag(Widist) ivarlag(Widist: female )  errorlag(Widist) gs2sls
estat impact
spregress logrARB CVDhosp, heteroskedastic dvarlag(Widist) ivarlag(Widist: CVDhosp )  errorlag(Widist) gs2sls
estat impact
spregress logrARB CVDdeath, heteroskedastic dvarlag(Widist) ivarlag(Widist: CVDdeath )  errorlag(Widist) gs2sls
estat impact
spregress logrARB HFhosp, heteroskedastic dvarlag(Widist) ivarlag(Widist: HFhosp )  errorlag(Widist) gs2sls
estat impact
spregress logrARB HFdeath, heteroskedastic dvarlag(Widist) ivarlag(Widist: HFdeath )  errorlag(Widist) gs2sls
estat impact
spregress logrARB CHDhosp, heteroskedastic dvarlag(Widist) ivarlag(Widist: CHDhosp)  errorlag(Widist) gs2sls
estat impact
spregress logrARB CHDdeath, heteroskedastic dvarlag(Widist) ivarlag(Widist: CHDdeath )  errorlag(Widist) gs2sls
estat impact
spregress logrARB DM_older20, heteroskedastic dvarlag(Widist) ivarlag(Widist: DM_older20 )  errorlag(Widist) gs2sls
estat impact





***models with covid incidence

spregress logcases logbirths , heteroskedastic dvarlag(Widist) ivarlag(Widist: logbirths )  errorlag(Widist) gs2sls
estat impact
spregress logcases logdead , heteroskedastic dvarlag(Widist) ivarlag(Widist: logdead )  errorlag(Widist) gs2sls
estat impact

spregress logcases logGQ , heteroskedastic dvarlag(Widist) ivarlag(Widist: logGQ)  errorlag(Widist) gs2sls
estat impact

spregress logcases pctpovall_2018 , heteroskedastic dvarlag(Widist) ivarlag(Widist: pctpovall_2018 )  errorlag(Widist) gs2sls
estat impact
spregress logcases med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases health , heteroskedastic dvarlag(Widist) ivarlag(Widist: health )  errorlag(Widist) gs2sls
estat impact
spregress logcases smoking , heteroskedastic dvarlag(Widist) ivarlag(Widist: smoking )  errorlag(Widist) gs2sls
estat impact
spregress logcases obesity , heteroskedastic dvarlag(Widist) ivarlag(Widist: obesity )  errorlag(Widist) gs2sls
estat impact
spregress logcases PAinactivity , heteroskedastic dvarlag(Widist) ivarlag(Widist: PAinactivity )  errorlag(Widist) gs2sls
estat impact
spregress logcases drinking, heteroskedastic dvarlag(Widist) ivarlag(Widist: drinking )  errorlag(Widist) gs2sls
estat impact
spregress logcases uninsured , heteroskedastic dvarlag(Widist) ivarlag(Widist: uninsured )  errorlag(Widist) gs2sls
estat impact
spregress logcases somecollege , heteroskedastic dvarlag(Widist) ivarlag(Widist: somecollege )  errorlag(Widist) gs2sls
estat impact
spregress logcases childpoverty , heteroskedastic dvarlag(Widist) ivarlag(Widist: childpoverty )  errorlag(Widist) gs2sls
estat impact
spregress logcases social, heteroskedastic dvarlag(Widist) ivarlag(Widist: social )  errorlag(Widist) gs2sls
estat impact
spregress logcases air, heteroskedastic dvarlag(Widist) ivarlag(Widist: air )  errorlag(Widist) gs2sls
estat impact
spregress logcases  Housing, heteroskedastic dvarlag(Widist) ivarlag(Widist:  Housing )  errorlag(Widist) gs2sls
estat impact
spregress logcases severehousing, heteroskedastic dvarlag(Widist) ivarlag(Widist: severehousing )  errorlag(Widist) gs2sls
estat impact
spregress logcases food, heteroskedastic dvarlag(Widist) ivarlag(Widist: food )  errorlag(Widist) gs2sls
estat impact
spregress logcases sleep, heteroskedastic dvarlag(Widist) ivarlag(Widist: sleep )  errorlag(Widist) gs2sls
estat impact
spregress logcases unins_adults, heteroskedastic dvarlag(Widist) ivarlag(Widist: unins_adults )  errorlag(Widist) gs2sls
estat impact
spregress logcases below18, heteroskedastic dvarlag(Widist) ivarlag(Widist: below18 )  errorlag(Widist) gs2sls
estat impact
spregress logcases older65, heteroskedastic dvarlag(Widist) ivarlag(Widist: older65 )  errorlag(Widist) gs2sls
estat impact
spregress logcases NHBlack, heteroskedastic dvarlag(Widist) ivarlag(Widist: NHBlack )  errorlag(Widist) gs2sls
estat impact
spregress logcases Indian, heteroskedastic dvarlag(Widist) ivarlag(Widist: Indian )  errorlag(Widist) gs2sls
estat impact
spregress logcases Asian, heteroskedastic dvarlag(Widist) ivarlag(Widist: Asian )  errorlag(Widist) gs2sls
estat impact
spregress logcases Pacific, heteroskedastic dvarlag(Widist) ivarlag(Widist: Pacific )  errorlag(Widist) gs2sls
estat impact
spregress logcases Hispanic, heteroskedastic dvarlag(Widist) ivarlag(Widist: Hispanic )  errorlag(Widist) gs2sls
estat impact
spregress logcases NHWhite, heteroskedastic dvarlag(Widist) ivarlag(Widist: NHWhite )  errorlag(Widist) gs2sls
estat impact
spregress logcases female, heteroskedastic dvarlag(Widist) ivarlag(Widist: female )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrCVD, heteroskedastic dvarlag(Widist) ivarlag(Widist: logrCVD )  errorlag(Widist) gs2sls
estat impact
spregress logcases CVDhosp, heteroskedastic dvarlag(Widist) ivarlag(Widist: CVDhosp )  errorlag(Widist) gs2sls
estat impact
spregress logcases CVDdeath, heteroskedastic dvarlag(Widist) ivarlag(Widist: CVDdeath )  errorlag(Widist) gs2sls
estat impact
spregress logcases HFhosp, heteroskedastic dvarlag(Widist) ivarlag(Widist: HFhosp )  errorlag(Widist) gs2sls
estat impact
spregress logcases HFdeath, heteroskedastic dvarlag(Widist) ivarlag(Widist: HFdeath )  errorlag(Widist) gs2sls
estat impact
spregress logcases CHDhosp, heteroskedastic dvarlag(Widist) ivarlag(Widist: CHDhosp)  errorlag(Widist) gs2sls
estat impact
spregress logcases CHDdeath, heteroskedastic dvarlag(Widist) ivarlag(Widist: CHDdeath )  errorlag(Widist) gs2sls
estat impact
spregress logcases DM_older20, heteroskedastic dvarlag(Widist) ivarlag(Widist: DM_older20 )  errorlag(Widist) gs2sls
estat impact









***models with covid mortality

spregress logdeaths logbirths , heteroskedastic dvarlag(Widist) ivarlag(Widist: logbirths )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logdead , heteroskedastic dvarlag(Widist) ivarlag(Widist: logdead )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logGQ , heteroskedastic dvarlag(Widist) ivarlag(Widist: logGQ)  errorlag(Widist) gs2sls
estat impact
spregress logdeaths pctpovall_2018 , heteroskedastic dvarlag(Widist) ivarlag(Widist: pctpovall_2018 )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths health , heteroskedastic dvarlag(Widist) ivarlag(Widist: health )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths smoking , heteroskedastic dvarlag(Widist) ivarlag(Widist: smoking )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths obesity , heteroskedastic dvarlag(Widist) ivarlag(Widist: obesity )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths PAinactivity , heteroskedastic dvarlag(Widist) ivarlag(Widist: PAinactivity )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths drinking, heteroskedastic dvarlag(Widist) ivarlag(Widist: drinking )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths uninsured , heteroskedastic dvarlag(Widist) ivarlag(Widist: uninsured )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths somecollege , heteroskedastic dvarlag(Widist) ivarlag(Widist: somecollege )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths air, heteroskedastic dvarlag(Widist) ivarlag(Widist: air )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths  Housing, heteroskedastic dvarlag(Widist) ivarlag(Widist:  Housing )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths food, heteroskedastic dvarlag(Widist) ivarlag(Widist: food )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths sleep, heteroskedastic dvarlag(Widist) ivarlag(Widist: sleep )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths below18, heteroskedastic dvarlag(Widist) ivarlag(Widist: below18 )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths older65, heteroskedastic dvarlag(Widist) ivarlag(Widist: older65 )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths NHBlack, heteroskedastic dvarlag(Widist) ivarlag(Widist: NHBlack )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths Indian, heteroskedastic dvarlag(Widist) ivarlag(Widist: Indian )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths Asian, heteroskedastic dvarlag(Widist) ivarlag(Widist: Asian )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths Pacific, heteroskedastic dvarlag(Widist) ivarlag(Widist: Pacific )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths Hispanic, heteroskedastic dvarlag(Widist) ivarlag(Widist: Hispanic )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths NHWhite, heteroskedastic dvarlag(Widist) ivarlag(Widist: NHWhite )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths female, heteroskedastic dvarlag(Widist) ivarlag(Widist: female )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrCVD, heteroskedastic dvarlag(Widist) ivarlag(Widist: logrCVD )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths CVDhosp, heteroskedastic dvarlag(Widist) ivarlag(Widist: CVDhosp )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths CVDdeath, heteroskedastic dvarlag(Widist) ivarlag(Widist: CVDdeath )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths HFhosp, heteroskedastic dvarlag(Widist) ivarlag(Widist: HFhosp )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths HFdeath, heteroskedastic dvarlag(Widist) ivarlag(Widist: HFdeath )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths CHDhosp, heteroskedastic dvarlag(Widist) ivarlag(Widist: CHDhosp)  errorlag(Widist) gs2sls
estat impact
spregress logdeaths CHDdeath, heteroskedastic dvarlag(Widist) ivarlag(Widist: CHDdeath )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths DM_older20, heteroskedastic dvarlag(Widist) ivarlag(Widist: DM_older20 )  errorlag(Widist) gs2sls
estat impact



*** unadjusted models for COVID-19 incidence
spregress logcases logrACEI , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrACEI  )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrARB  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrARB )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrARBpure  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrARBpure )  errorlag(Widist) gs2sls
estat impact
spregress logcases ACEI_ARB_ratio  , heteroskedastic dvarlag(Widist) ivarlag(Widist: ACEI_ARB_ratio )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrLLD  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrLLD  )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrCCB_di , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrCCB_dih  )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrCCB_nondih , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrCCB_nondih  )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrBB , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrBB  )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrAB  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAB )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrAA , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAA  )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrABB  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrABB  )  errorlag(Widist) gs2sls
estat impact
spregress logcases logranticoag  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logranticoag  )  errorlag(Widist) gs2sls
estat impact
spregress logcases lograntiplatelet , heteroskedastic dvarlag(Widist) ivarlag(Widist: lograntiplatelet  )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrAAD1  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAAD1  )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrAAD3  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAAD3 )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrAAD5  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAAD5  )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrvasodil  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrvasodil )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrcentral  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrcentral  )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrloopd , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrloopd  )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrthiaz , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrthiaz  )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrinsulin  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrinsulin   )  errorlag(Widist) gs2sls
estat impact
spregress logcases logroral_diab  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logroral_diab  )  errorlag(Widist) gs2sls
estat impact



*** unadjusted models for COVID-19 mortality
spregress logdeaths logrACEI  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrACEI  )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrARB , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrARB )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrARBpure , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrARBpure )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrLLD  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrLLD  )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrCCB_dih  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrCCB_dih  )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrCCB_nondih  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrCCB_nondih  )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrBB  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrBB  )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrAB  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAB )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrAA , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAA )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrABB  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrABB  )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logranticoag , heteroskedastic dvarlag(Widist) ivarlag(Widist: logranticoag )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths lograntiplatelet , heteroskedastic dvarlag(Widist) ivarlag(Widist: lograntiplatelet  )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrAAD1 , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAAD1 )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrAAD3 , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAAD3 )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrAAD5 , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAAD5 )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrvasodil , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrvasodil )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrcentral , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrcentral )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrloopd  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrloopd )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrthiaz , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrthiaz )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrinsulin  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrinsulin )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logroral_diab  , heteroskedastic dvarlag(Widist) ivarlag(Widist: logroral_diab )  errorlag(Widist) gs2sls
estat impact



***final fully adjusted models for COVID-19 incidence
spregress logcases logrACEI CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrACEI CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
margins, at(logrACEI=generate(logrACEI-0.6))  at(logrACEI=generate(logrACEI-0.4))  at(logrACEI=generate(logrACEI-0.2)) at(logrACEI=generate(logrACEI))  at(logrACEI=generate(logrACEI+0.2)) at(logrACEI=generate(logrACEI+0.4)) at(logrACEI=generate(logrACEI+0.6)) 
marginsplot

spregress logcases logrARB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrARB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
margins, at(logrARB=generate(logrARB-0.6)) at(logrARB=generate(logrARB-0.4)) at(logrARB=generate(logrARB-0.2)) at(logrARB=generate(logrARB))   at(logrARB=generate(logrARB+0.2))  at(logrARB=generate(logrARB+0.4))  at(logrARB=generate(logrARB+0.6))
marginsplot


spregress logcases logrLLD CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrLLD CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrCCB_dih CVDhosp CVDdeath  NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrCCB_dih CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrCCB_nondih CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrCCB_nondih CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrBB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrBB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrAB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrAA CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAA CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrABB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrABB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logranticoag CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logranticoag CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases lograntiplatelet CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: lograntiplatelet CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrAAD1 CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAAD1 CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrAAD3 CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAAD3 CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrAAD5 CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAAD5 CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrvasodil CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrvasodil CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrcentral CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrcentral CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrloopd CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrloopd CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrthiaz CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrthiaz CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logrinsulin CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrinsulin CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logcases logroral_diab CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logroral_diab CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact



*** fully adjusted models for COVID-19 mortality
spregress logdeaths logrACEI CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrACEI CVDhosp CVDdeath  NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact

margins, at(logrACEI=generate(logrACEI-0.6))  at(logrACEI=generate(logrACEI-0.4))  at(logrACEI=generate(logrACEI-0.2))  at(logrACEI=generate(logrACEI))  at(logrACEI=generate(logrACEI+0.2))  at(logrACEI=generate(logrACEI+0.4)) at(logrACEI=generate(logrACEI+0.6)) 
marginsplot 

spregress logdeaths logrARB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrARB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
margins, at(logrARB=generate(logrARB-0.6)) at(logrARB=generate(logrARB-0.4))  at(logrARB=generate(logrARB-0.2))  at(logrARB=generate(logrARB))   at(logrARB=generate(logrARB+0.2))  at(logrARB=generate(logrARB+0.4))  at(logrARB=generate(logrARB+0.6))
marginsplot


spregress logdeaths logrLLD CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrLLD CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrCCB_dih CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrCCB_dih CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrCCB_nondih CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrCCB_nondih CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrBB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrBB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrAB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrAA CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAA CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrABB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrABB CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logranticoag CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logranticoag CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths lograntiplatelet CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: lograntiplatelet CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrAAD1 CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAAD1 CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrAAD3 CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAAD3 CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrAAD5 CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrAAD5 CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrvasodil CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrvasodil CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrcentral CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrcentral CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrloopd CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrloopd CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrthiaz CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrthiaz CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logrinsulin CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrinsulin CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact
spregress logdeaths logroral_diab CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logroral_diab CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact

***sensitivity analysis with pure ARB group
spregress logcases logrARBpure CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrARBpure CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact

spregress logdeaths logrARBpure CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t , heteroskedastic dvarlag(Widist) ivarlag(Widist: logrARBpure CVDhosp CVDdeath NHBlack below18 air somecollege med_hh_income_percent_of_state_t )  errorlag(Widist) gs2sls
estat impact















***plotting US map
cd "D:\Lora_new\Databases\GEO\cb_2018_us_county_500k"
grmap, activate
drop if inlist(stname, "Alaska", "Hawaii")
spset, modify shpfile(usacounties_shp)
grmap rACEI, clnumber(7)
grmap rARB, clnumber(7)
grmap ACEI_ARB_ratio, clnumber(7)
grmap confirmed_adj, clnumber(7)
grmap deaths_adj, clnumber(7)



*** check SP settings
spset

spmatrix dir
***contiguity matrix W for first-order and V for second-order neighbors
spmatrix create contiguity W
spmatrix note W: first-order contiguity matrix
spmatrix save W using W

spmatrix use W using W
spmatrix use W using wme.stswm

spmatrix create contiguity V, second
spmatrix note V: second-order contiguity matrix
spmatrix save V using V


***inverse distance matrix
spmatrix create idistance Widist
spmatrix note Widist: first-order inverse distance matrix
spmatrix save Widist using Widist
spmatrix summarize Widist


*** Moran test for spatial dependence

regress rACEI
estat moran, errorlag(Widist)
regress rARB
estat moran, errorlag(Widist)
regress ACEI_ARB_ratio
estat moran, errorlag(Widist)
regress rCVD
estat moran, errorlag(Widist)
regress logcases
estat moran, errorlag(Widist)
regress logdeaths
estat moran, errorlag(Widist)



grmap y_diff, clnumber(7)
