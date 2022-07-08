*Merge*
/*
clear all
cd "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\BDD"
use "demo.dta", clear
sort w_id year
save "demo.dta", replace

/*
label var w_id "Code commune"
label var year "Année"
rename population pop
rename nb_logements nb_log
label var nb_log "Nombre de logements"
rename nb_logvacants nb_logvac
label var nb_logvac "Nombre de logements vacants"
rename pop_bacbac2_weird pop_bac2
label var pop_bac2 "Population de bac à bac+2"
label var pop_bacsup "Population au-dessus de bac+2"
label var pop_actifocc "Population active occupée (15-64 ans)"
label var pop_actifremote "Population active travaillant dans une autre commune"
label var superf "Superficie en km2"

encode w_id, gen(W_ID)
sort W_ID year
gen ID_merge=(W_ID*1000000)+year
sort ID_merge
save "demo.dta", replace
*/
clear all
use ent.dta, clear
/*
label var w_id "Code commune"
label var year "Année"
label var ca_total "Chiffre d'affaires total (K EUR) des entreprises"
rename wages2008 salaires
label var salaires "Salaires totaux versés (K EUR) par les entreprises"
rename nb_commerces nb_comm
label var nb_comm "Nombre d'entreprises de commerce"
label var nb_restos "Nombre de restaurants"
label var nb_publics "Nombre d'entreprises publiques"
rename sumofloisirs2008 nb_lois
label var nb_lois "Nombre d'entreprises de loisirs et culture"

encode w_id, gen(W_ID)
sort W_ID year
gen ID_merge=(W_ID*1000000)+year
sort ID_merge
save "ent.dta", replace
*/
drop W_ID
drop ID_merge
sort w_id year
save ent.dta, replace
merge w_id year using "demo.dta"
drop _m
save "demoent.dta", replace
*/
/*
clear all
use "demoent.dta", clear
sort w_id year
save "demoent.dta", replace

clear all
use "transports.dta", clear
/*
label var w_id "Code commune"
label var year "Année"
encode w_id, gen(W_ID)
rename part_transportcommun transport
label var transport "Part des citoyens utilisant des transports en commun"

sort W_ID year

gen ID_merge=(W_ID*1000000)+year
*/
drop ID_merge
drop W_ID
sort w_id year
save "transports.dta", replace
merge w_id year using "demoent.dta"
drop if ca_total==.
sort ca_total
drop _m
save "BDD_FE.dta", replace
*/
/*
clear all
use "prix.dta", clear
rename insee w_id
sort w_id year
merge w_id year using "BDD_FE.dta"
drop if _m!=3
sort w_id year
save "BDD_FE.dta", replace
*/
/*
clear all
use "CO2.dta", clear
sort w_id year
rename w_id W_ID
tostring W_ID, gen(w_id)
sort w_id year
merge w_id year using "BDD_FE.dta"
drop _m W_ID */
****Génération des variables****

ssc install psmatch2, replace
set more off, permanently
cd "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\BDD"
clear all
set maxvar 32767
set matsize 11000
use "BDD_FE_2.dta", clear
sort ville year

sort W_ID year
xtset W_ID year
drop if ca_total==.

*Densité
gen densite=pop/superf
label var densite "Densité (pop/km2)"

*Salaire moyen
gen salmoy=salaires/pop
label var salmoy "Salaire moyen (K EUR/personne)

gen camoy=ca_total/pop
label var camoy "Chiffre d'affaires moyen (KEUR/personne)"

*Education
gen moybac2=pop_bac2/pop
label var moybac2 "Part de la population ayant bac-bac+2"
gen moybacsup=pop_bacsup/pop
label var moybacsup "Part de la population ayant bac-bac+8"
gen ln_moybacsup=ln(moybacsup)
label var ln_moybacsup "Part de la population ayant bac-bac+8 (ln)"

*Services et restos
gen nb_serv=(nb_comm+nb_restos+nb_loi)
gen ln_nbserv=ln(nb_serv)
label var nb_serv "Nombre de commerces, restos, loisirs par personne"
label var ln_nbserv "Nombre de commerces, restos, loisirs par personne(ln)"

*Transports
gen ln_trans=ln(transport)
label var ln_trans "Part de la pop utilisant les transports en commun (ln)"

*Logements
gen ln_logvac=ln(nb_logvac)
label var ln_logvac "Nombre de logements vacants (ln)"

gen ln_log=ln(nb_log)
gen ln_log2=ln_log^2
label var ln_log "Nombre de logements (ln)"
label var ln_log2 "Carré du nombre de logements (ln)"

*Prix
gen partlogvac=nb_logvac/nb_log
reg loypredm2 pop moybacsup partlogvac nb_log densite salmoy, robust
predict loypredm2_pred, xb
label var loypredm2_pred "Indice des prix au m2 (loyer/mensuel)"
drop loypredm2

*CO2
xtreg co2 densite transport nb_log pop moybacsup partlogvac salmoy, robust
predict co2_pred, xb
label var co2_pred "Prévision des émissions de CO2 (kg eq. CO2)"
drop co2

*Logs et formes fonctionnelles
gen ln_dens=ln(densite)
label var ln_dens "Log de densité"

gen ln_salmoy=ln(salmoy)
label var ln_salmoy "Log du salaire moyen"

gen dens2=densite^2
gen ln_dens2=(ln_dens)^2
label var dens2 "Carré de la densité"
label var ln_dens2 "Ln du carré de la densité"

gen ln_dens3=ln_dens^3
gen ln_log3=ln_log^3

gen ln_pop=ln(pop)
label var ln_pop "Population (ln)"

****Régressions avec densité

*Revenu moyen
xtreg salmoy ln_dens ln_dens2 ln_moybacsup pop c.year, fe robust cluster(W_ID)

*Services
xtreg nb_serv ln_dens ln_dens2 ln_dens3 ln_moybacsup pop c.year, fe robust cluster(W_ID)

*Transports
xtreg transport ln_dens ln_dens2 ln_dens3 ln_moybacsup pop c.year, fe robust cluster(W_ID)


****Régressions avec nombre de logements

*Revenu moyen
xtreg salmoy ln_log ln_log2 ln_log3 ln_moybacsup pop c.year, fe robust cluster(W_ID)

*Services
xtreg nb_serv ln_log ln_log2 ln_moybacsup pop c.year, fe robust cluster(W_ID)

*Transports
xtreg transport ln_log ln_log2 ln_log3 ln_moybacsup pop c.year, fe robust cluster(W_ID)


***************INDICATEURS FINAUX****************

*Indicateur qualité
gen indic_services=((nb_serv/0.0714286))
gen indic_transport=transport/(67.6)
gen indic_nonnormal=indic_services+indic_transport
su indic_nonnormal
gen indic_qualite=indic_nonnormal/1.014949
su indic_qualite
gen ln_indicqualite=ln(indic_qualite)
label var indic_qualite "Indicateur de qualité de vie (50% services 50% transports)"

*Summary

eststo sumstats: quietly estpost sum nb_log salmoy loypredm2_pred nb_serv transport co2_pred moybac2 pop_actifocc pop_actifremote , detail
esttab sumstats, cells("mean(fmt(%8.2f))" "p50(fmt(%8.2f))" "min(fmt(%8.2f))" "max(fmt(%8.2f))" "sd(fmt(%8.2f))") nonumbers label
esttab sumstats using "C:\Users\marcy\Documents\Dauphine\Mémoire\Stata\Output\sum_section4.tex", tex label nonumbers cells("mean p50 min max sd") replace 


*Revenu réel

gen revenureel_loc=camoy/(indice_prix)
gen revenureel_prop=camoy*indice_prix
gen revenureel=(revenureel_loc*0.4)+(revenureel_prop*0.6)
gen ln_rreel=ln(revenureel)
gen ln_prix=ln(loypredm2_pred)
label var ln_prix "Prix des loyers, ln"
label var revenureel "Revenu réel déflaté des prix du logement"
label var ln_rreel "ln du revenu réel déflaté des prix du logement"

*CO2

gen ln_CO2=ln(co2_pred)
label var ln_CO2 "ln de la prévision des émissions de CO2"


**Régressions revenus
gen ln_moyactif=ln(pop_actifocc/pop)
gen ln_moybac2=ln(moybac2)
gen ln_camoy=ln(camoy)
gen ln_rreel_loc=ln(revenureel_loc)
gen ln_rreel_prop=ln(revenureel_prop)

xtreg ln_salmoy ln_log ln_log2  ln_moybac2 c.year, fe robust cluster(W_ID)
outreg2 using "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\Output\table1.ascii", ctitle(Panel data (Fishing yields)) addtext(Time FE, Yes, Country FE, Yes) label nocons dec(3) se replace

xtreg ln_prix ln_log ln_log2  ln_moyactif ln_moybac2 c.year, fe robust cluster(W_ID)
outreg2 using "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\Output\table1.ascii", ctitle(Panel data (Fishing yields)) addtext(Time FE, Yes, Country FE, Yes) label nocons dec(3) se append tex



gen ln_moybacsq=ln_moybac2^2
gen ln_moybac23=ln_moybac2^3
xtreg ln_moybac2 ln_log c.year, fe robust cluster(W_ID)

**Régressions qualité

xtreg ln_indicqualite ln_log ln_log2 ln_moyactif ln_moybac2 c.year, fe robust cluster(W_ID)

xtreg ln_nbserv ln_log ln_log2 ln_moyactif ln_moybac2 c.year, fe robust cluster(W_ID)
outreg2 using "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\Output\table2.ascii", ctitle(Panel data (Part des transports en commun dans les trajets quotidiens)) addtext(FE Année, Oui, FE Ville, Oui) label nocons dec(3) se replace

xtreg ln_trans ln_log ln_log2 ln_moyactif ln_moybac2 c.year, fe robust cluster(W_ID)
outreg2 using "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\Output\table2.ascii", ctitle(Panel data (Part des transports en commun dans les trajets quotidiens)) addtext(FE Année, Oui, FE Ville, Oui) label nocons dec(3) se append tex

**Régressions CO2
gen ln_co2pop=ln(co2_pred/pop)
xtreg ln_co2pop ln_log ln_log2 ln_moyactif ln_moybac2 c.year, fe robust cluster(W_ID)
outreg2 using "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\Output\table3.ascii", ctitle(CO2 par habitant) addtext(FE Année, Oui, FE Ville, Oui) label nocons dec(3) se replace tex


**Test Paris

gen dpt=substr(w_id,1,2)
xtreg ln_salmoy ln_log ln_log2  ln_moybac2 c.year if dpt=="94" | dpt=="92" | dpt=="93" , fe robust cluster(W_ID)

xtreg ln_nbserv ln_log ln_log2 ln_moyactif ln_moybac2 c.year if dpt=="94" | dpt=="92" | dpt=="93", fe robust cluster(W_ID)
xtreg ln_trans ln_log ln_log2 ln_moyactif ln_moybac2 c.year if dpt=="94" | dpt=="92" | dpt=="93", fe robust cluster(W_ID)

xtreg ln_co2pop ln_log ln_log2 ln_moyactif ln_moybac2 c.year if dpt=="94" | dpt=="92" | dpt=="93", fe robust cluster(W_ID)

**Test toutes agglos

xtreg ln_salmoy ln_log ln_log2  ln_moybac2 c.year if dpt=="94" | dpt=="92" | dpt=="93" | dpt=="69" | dpt=="13", fe robust cluster(W_ID)
outreg2 using "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\Output\FE_paris_revenus", ctitle(Salaire moyen) addtext(FE année, oui, FE ville, oui) label nocons dec(3) se replace

xtreg ln_prix ln_log ln_log2  ln_moybac2 c.year if dpt=="94" | dpt=="92" | dpt=="93" | dpt=="69" | dpt=="13", fe robust cluster(W_ID)
outreg2 using "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\Output\FE_paris_revenus", ctitle(Loyers) addtext(FE année, oui, FE ville, oui) label nocons dec(3) se append tex

xtreg ln_moybac2 ln_log ln_log2 ln_prix c.year if dpt=="94" | dpt=="92" | dpt=="93" | dpt=="69" | dpt=="13", fe robust cluster(W_ID)

xtreg ln_nbserv ln_log ln_log2 ln_moyactif ln_moybac2 c.year if dpt=="94" | dpt=="92" | dpt=="93"| dpt=="69" | dpt=="13", fe robust cluster(W_ID)
outreg2 using "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\Output\FE_paris_serv", ctitle(Services) addtext(FE année, oui, FE ville, oui) label nocons dec(3) se replace 

xtreg ln_trans ln_log ln_log2 ln_moyactif ln_moybac2 c.year if dpt=="94" | dpt=="92" | dpt=="93"| dpt=="69" | dpt=="13", fe robust cluster(W_ID)
outreg2 using "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\Output\FE_paris_serv", ctitle(Transports) addtext(FE année, oui, FE ville, oui) label nocons dec(3) se append tex


xtreg ln_co2pop ln_log ln_log2 ln_moyactif ln_moybac2 c.year if dpt=="94" | dpt=="92" | dpt=="93"| dpt=="69" | dpt=="13", fe robust cluster(W_ID)
outreg2 using "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\Output\FE_paris_co2", ctitle(CO2) addtext(FE année, oui, FE ville, oui) label nocons dec(3) se replace tex



**Graphs

twoway (scatter ln_rreel ln_log ) (lfit ln_rreel ln_log ) , xtitle(Nombre de logements (ln)) ytitle(Revenu réel (ln)) legend(label(1 "Valeurs réelles")) legend(label(2 "Ligne de régression"))




STOP

*********************************Modèle Ecoquartiers**********************
drop if year==2008
egen exactmatch=group(pop) if year==2018
replace ecoquartier=0 if ecoquartier==.
logit ecoquartier pop camoy superf
predict propscore
order ecoquartier, last
su propscore, d

eststo sumprop1: quietly estpost sum propscore, detail
esttab sumprop1, cells("mean(fmt(%8.2f))" "p50(fmt(%8.2f))" "min(fmt(%8.2f))" "max(fmt(%8.2f))" "sd(fmt(%8.2f))") nonumbers label
esttab sumprop1 using "C:\Users\marcy\Documents\Dauphine\Mémoire\Stata\Output\sumprop1.tex", tex label nonumbers cells("mean p50 min max sd") replace 


keep if propscore>0.0179| ecoquartier==1
codebook ecoquartier
replace ecoquartier=0 if year==2013
eststo sumprop2: quietly estpost sum propscore, detail
esttab sumprop2, cells("mean(fmt(%8.2f))" "p50(fmt(%8.2f))" "min(fmt(%8.2f))" "max(fmt(%8.2f))" "sd(fmt(%8.2f))") nonumbers label
esttab sumprop2 using "C:\Users\marcy\Documents\Dauphine\Mémoire\Stata\Output\sumprop2.tex", tex label nonumbers cells("mean p50 min max sd") replace 





*IV revenus
sort w_id year

xtivreg ln_salmoy ln_moyactif ln_moybac2 (ln_log = ecoquartier) c.year, fe first
outreg2 using "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\Output\IV_revenus.ascii", ctitle(Salaire moyen) addtext(FE Année, Oui, FE Ville, Oui) label nocons dec(3) se replace
xtivreg ln_prix ln_moyactif ln_moybac2 (ln_log = ecoquartier) c.year , fe first
outreg2 using "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\Output\IV_revenus.ascii", ctitle(Loyers moyens) addtext(FE Année, Oui, FE Ville, Oui) label nocons dec(3) se append tex




xtivreg ln_rreel ln_moyactif ln_moybac2 (ln_log = ecoquartier) c.year , fe first
xtivreg ln_rreel ln_moyactif (ln_log = ecoquartier) c.year , fe first
xtivreg ln_prix ln_moyactif ln_moybac2 (ln_log = ecoquartier) c.year , fe first

*IV qualité
xtivreg ln_trans ln_moyactif ln_moybac2 (ln_log = ecoquartier) c.year , fe first
outreg2 using "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\Output\IV_qualite.ascii", ctitle(Part des transports en commun) addtext(FE Année, Oui, FE Ville, Oui) label nocons dec(3) se replace tex
xtivreg ln_nbserv ln_moyactif ln_moybac2 (ln_log = ecoquartier) c.year , fe first

*IV CO2
xtivreg ln_co2pop ln_moyactif ln_moybac2 (ln_log = ecoquartier) c.year , fe first
outreg2 using "C:\Users\marcy\Documents\Asteres\Asteres FPI\STATA\Output\IV_CO2.ascii", ctitle(Panel data (Part des transports en commun dans les trajets quotidiens)) addtext(FE Année, Oui, FE Ville, Oui) label nocons dec(3) se replace tex



*DID (test, non concluant)*
gen time=1 if year==2018
replace time=0 if year<2018

egen treated=total(ecoquartier), by(w_id)

gen did=time*treated

reg ln_salmoy time treated did ln_moybac2 if pop<100000, robust
