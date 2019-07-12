;+
; NAME:
;		MAKE_PSP_DATA
; PURPOSE: 
;
; EXPLANATION:
;
; CALLING SEQUENCE:
;		psp_makedata
; INPUTS:
;
; OUTPUTS:
;
; OPTIONAL OUTPUT:
;
; OPTIONAL INPUT KEYWORDS:
;
; OPTIONAL OUTPUT KEYWORDS:
;
; EXAMPLES:
;
; RESTRICTIONS:
;
; NOTES:
;		See readme for information
; PROCEDURES USED:
;
;-



pro psp_makedata

; ---------- Setup potential model ----------
scpot = [10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -25.0, -85.0] 
lambdas = [1.0, 1.0, 1.0, 0.15, 0.15, 0.15, 0.15, 0.15]
emnames = ['v10','v5','v0','vm5','vm10','vm15','vm25','vm85']
emfullnames = 'efield_'+emnames+'.fits'
;;
; Goto setup folder and make efield array
cd, 'setup', current=topdir

; Make Efield array
for i=0,n_elements(emnames)-1 do $
	psp_efieldmake, scpot[i],lambdas[i],fname=emfullnames[i]

; Bfield 
; -- Parameters are loaded by the tracing program (PSP_TRACING) using 
; -- PSP_MAGS and the Bfield is calculated at each simulation step

cd, topdir






; ----------  Running the tracing, post processing, and dq flagging ----------

ens0 = (indgen(20)*5)+15. ; Electron kinetic energies to run
ens1 = (indgen(10)*20)+130. ; Spread out at higher energies 
ens2 = (indgen(4)*50)+360. 
ens = [ens0,ens1,ens2]

; names of simulation results (for folders) and potential models 
emnames2=['v10','v5','v0','v0b0','v0b0sc0','vm5','vm10','vm15','vm25','vm85']
emnames0=['v10','v5','v0','v0','v0','vm5','vm10','vm15','vm25','vm85'] 
emfullnames2 = emnames0+'.fits'
nobarr = [0,0,0,1,1,0,0,0,0,0] ; do not use B-field in the 'v0b0' or 'v0b0sc0' model
noscarr =  [0,0,0,0,1,0,0,0,0,0] ; no s/c for 'v0b0sc0' model

cd, 'results'
for i=0, n_elements(emnames2)-1 do begin

	; ----- Particle tracing -----
	; Create directory
	if ~file_test(emnames2[i],/dir) then spawn, 'mkdir '+strtrim(emnames2[i],2)
	cd, emnames2[i], current=resultsdir
	if ~file_test(data, /dir) then spawn, 'mkdir data'
	cd, data
	; SPAN-Ae
	for j=0,33 do psp_tracing,emfullnames2[i],/spana,energy=ens[j],nob=nobarr[i], $
		fname='trac_'+strtrim(emnames2[i],2)+'_K'+strtrim(ens[j],2)+'_spana.fits', $
		nosc=noscarr[i]

	; SPAN-B
	for j=0,33 do psp_tracing,emfullnames2[i],energy=ens[j],nob=nobarr[i], $
		fname='trac_'+strtrim(emnames2[i],2)+'_K'+strtrim(ens[j],2)+'_spanb.fits', $
		nosc=noscarr[i]

	; ----- Post-processing and DQ Flagging ------
	files=file_search('*.fits',count=nfiles)
	for j=0, nfiles-1 do psp_procdata, files[j]

	cd, resultsdir
endfor
cd, topdir



; ---------- Create the synthetic VDF and measurement sets ----------

; ----- Synthetic VDF -----
cd, 'vdf'
temperatures = [40.d,120.d,120.d]	; Tx, Ty, Tz (eV)
velocities = [400.d,0.d,0.d]		; Vx, Vy, Vz (km/s)
psp_makevdf, 'psp_vdf.fits',temper=temperatures,vi=velocities,/plot,/save

; Create synthetic VDF in same format as result from psp_interp for 
;	checking moment measurements
psp_makevdfinterpfile, 'psp_vdf_interp.fits',temper=temperatures,vi=velocities

cd, topdir

; ----- Measurement set, correction, interpolated set, and reinterpolated set -----

; First do the no SC set for default coordinates/no correction
; Create measurement set
cd, resultsdir+'/v0b0sc0'
vdffile = topdir+'/vdf/psp_vdf.fits'
psp_distr, 0.0, dffile=vdffile,datadir='data',$
	outfile='v0b0nosc_distr.fits',/plot,/save
; Create correction file
psp_corr,outfile='v0b0nosc_corr.fits',datadir='data',/plot,/save,penergy=30.0
; Interpolate+combine Ae and B
psp_interp, 0.0,'v0b0nosc_distr.fits', 'v0b0nosc_corr.fits',$
	outfile='v0b0nosc_interp.fits',/plot,/save,penergy=30.0
; Reinterpolate combined maps
psp_reinterp,'v0b0nosc_interp.fits',outfile='v0b0nosc_reinterp.fits',/plot,$
	/save,penergy=30.0
cd, resultsdir

;--- Then do the rest of the data
emnames3=['v10','v5','v0','v0b0','vm5','vm10','vm15','vm25','vm85']
naivecorrfile = resultsdir+'/v0b0sc0/v0b0nosc_corr.fits'
scpot2 = [10.0, 5.0, 0.0, 0.0, -5.0, -10.0, -15.0, -25.0, -85.0]
emdirnames = resultsdir+'/'+emnames3

for i=0,n_elements(emnames3)-1 do begin
	cd, emdirnames[i]

	; Measurement set
	dfile = strtrim(emnames3[i],2)+'_distr.fits'
 	psp_distr, scpot2[i], dffile=vdffile, datadir='data',$
		outfile=dfile,/plot,/save
	; Correction file
	cfile = strtrim(emnames3[i],2)+'_corr.fits'
	psp_corr, outfile=cfile,datadir='data',/plot,/save,penergy=30.

	; Interpolate and combine
	ifile = strtrim(emnames3[i],2)+'_interp.fits'
	psp_interp, scpot2[i], dfile, cfile,outfile=ifile,/plot,/save,penergy=30.0
	; Reinterpolate combined 
	rifile = strtrim(emnames3[i],2)+'_reinterp.fits'
	psp_reinterp, ifile,outfile=rifile,/plot,/save,penergy=30.0

	; Interpolate and combine without correction (using v0b0sc0 correction)
	nifile = strtrim(emnames3[i],2)+'_interpn.fits'
	psp_interp, scpot2[i], dfile, naivecorrfile, outfile=nifile,/plot,/save,penergy=30.0
	; Reinterpolate combined with no correction
	rnifile = strtrim(emnames3[i],2)+'_reinterpn.fits'
	psp_reinterp, nifile, outfile=rnifile, /plot,/save,penergy=30.0

endfor


; ------- Measure the moments with/without correction, before/after reinterpolation
emnames4=['v10','v5','v0','v0b0','v0b0nosc','vm5','vm10','vm15','vm25','vm85']
scpot3 = [10.0,5.0,0.000000001,0.0000000001,0.000000001,-5.0,-10.0,-15.0,-25.0,-85.0]
emdirnames = resultsdir+'/'+emnames4

;c: corrected, cr: corrected reinterpolated, n:no correction, nr: no corr reinterpolated
cdens = fltarr(10)
crdens = fltarr(10)
ndens = fltarr(10)
nrdens = fltarr(10)

ctemp = fltarr(4,10)
crtemp = fltarr(4,10)
ntemp = fltarr(4,10)
nrtemp = fltarr(4,10)

cvel = fltarr(3,10)
crvel = fltarr(3,10)
nvel = fltarr(3,10)
nrvel = fltarr(3,10)

for i=0,n_elements(emnames4)-1 do begin 
	cd, emdirnames[i]
	; corrected and reinterpolated filenames
	ifile = strtrim(emnames4[i],2)+'_interp.fits'
	rifile = strtrim(emnames4[i],2)+'_reinterp.fits'
	; no correction and no correction reinterpolated filenames
	; 	if v0b0sc0 model, use same file as 'corrected'
	if i eq 4 then nifile = ifile $ 
		else nifile = strtrim(emnames4[i],2)+'_interpn.fits'
	if i eq 4 then rnifile = rifile $
		else rnifile = strtrim(emnames4[i],2)+'_reinterpn.fits'

	cdens[i] = psp_n3di(ifile, scpot=scpot3[i])
	crdens[i] = psp_n3di(rifile, scpot=scpot3[i])
	ndens[i] = psp_n3di(nifile, scpot=scpot3[i])
	nrdens[i] = psp_n3di(rnifile, scpot=scpot3[i])

	ctemp[*,i] = psp_t3di(ifile, scpot=scpot3[i])
	crtemp[*,i] = psp_t3di(rifile, scpot=scpot3[i])
	ntemp[*,i] = psp_t3di(nifile, scpot=scpot3[i])
	nrtemp[*,i] = psp_t3di(rnifile, scpot=scpot3[i])

	cvel[*,i] = psp_v3di(ifile, scpot=scpot3[i])
	crvel[*,i] = psp_v3di(rifile, scpot=scpot3[i])
	nvel[*,i] = psp_v3di(nifile, scpot=scpot3[i])
	nrvel[*,i] = psp_v3di(rnifile, scpot=scpot3[i])

endfor

cd, resultsdir
; Write structure to FITS file
data = create_struct('names',emnames4,$
	'cdens', cdens,$
	'crdens',crdens, $
	'ndens', ndens, $
	'nrdens',nrdens, $
	'ctemp', ctemp, $
	'crtemp',crtemp, $
	'ntemp', ntemp, $
	'nrtemp',nrtemp, $
	'cvel',  cvel, $
	'crvel', crvel, $
	'nvel',  nvel, $
	'nrvel', nrvel)
mwrfits, data, 'psp_meas.fits'

; Write to text file for tabular format
datanames = strarr(40)
datatags = ['c','cr','n','nr']
for i=0, 39 do datanames[i]= emnames4[i mod 10 ]  + datatags[ floor(i/10)]

namesall = strarr(40)
densall = fltarr(40)
densall0 = [cdens,crdens,ndens,nrdens]
tempall = fltarr(4,40)
tempall0 = [[ctemp],[crtemp],[ntemp],[nrtemp]]
velall = fltarr(3,40)
velall0 = [[cvel],[crvel],[nvel],[nrvel]]

ti = indgen(10)

for i=0,39 do begin
	namesall[i] = datanames[ ((i mod 4)*10) + (floor(i/4))]
	densall[i] = densall0[ ((i mod 4)*10) + (floor(i/4))]
	tempall[*,i] = tempall0[ *, ((i mod 4)*10) + (floor(i/4))]
	velall[*,i] = velall0[*, ((i mod 4)*10) + (floor(i/4))]
endfor


openw, 1, 'psp_meas.txt',width=90.
titfmt = '(A12,2x,A6,2x,4(A7,2x),2(A8,2x),A8)'
fmt = '(A12,2x,F6.2,2x,4(F7.2,2x),2(F8.2,2x),F8.2)'

printf, 1, 'NAME', 'Dens', 'Tx','Ty','Tz','Tavg','Vx','Vy','Vz',format=titfmt
for i=0,39 do printf,1, namesall[i],densall[i],tempall[*,i],velall[*,i],format=fmt
close,1


end

