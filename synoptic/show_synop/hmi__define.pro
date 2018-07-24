;+
; Project     : SDO
;
; Name        : HMI__DEFINE
;
; Purpose     : Class definition for SDO/HMI
;
; Category    : Objects
;
; History     : Written 15 June 2010, D. Zarro (ADNET)
;
; Contact     : dzarro@solar.stanford.edu
;
; Modifications:
;             19-May-2014, Kim Tolbert, enable reading multiple files in read method
;             13-Aug-2014, Kim Tolbert. If image is rotated (index
;             .crota2), then rotate back to 0.
;             15-Aug-2014, Zarro (ADNET)
;              - use built-in ROTATE function to correct 180 roll.
;              - replace WCS2MAP by INDEX2MAP as HMI headers not fully
;                WCS compliant.
;             23-Dec-2014, Zarro (ADNET)
;              - removed deletion of RICE-decompressed file
;             9-Sep-2015, Zarro (ADNET)
;              - added call to HMI_PREP
;             3-Dec-2015, Zarro (ADNET) - restored /NO_PREP option
;             16-Mar-2017, Zarro (ADNET) 
;             - added call to instrument-specific IDL_STARTUP
;
; Contact     : dzarro@solar.stanford.edu
;-

function hmi::init,_ref_extra=extra

if ~self->sdo::init(_extra=extra) then return,0

;-- setup environment

self->setenv,_extra=extra

return,1 & end

;-------------------------------------------------------------------------

pro hmi::read,file,_ref_extra=extra

self->sdo::read,file,_extra=extra,instrument='hmi'

return & end

;--------------------------------------------------------------

function hmi::search,tstart,tend,_ref_extra=extra

return,self->sdo::search(tstart,tend,inst='hmi',_extra=extra)

end

;-------------------------------------------------------------
pro hmi::prep,index,data,_ref_extra=extra,verbose=verbose,no_prep=no_prep

no_prep=keyword_set(no_prep)

prepped=self->is_prepped(index)

if ~have_tag(index,'crota2') then index=add_tag(index,0.,'crota2')

if ~no_prep && ~prepped && self->hmi::have_path(verbose=verbose,_extra=extra) then begin
 hmi_prep,index,data,oindex,odata,_extra=extra,/quiet,/use_ref,/nearest
 data=temporary(odata)
 index=oindex
endif

;-- correct for 180 degree roll (in case not corrected by hmi_prep)

have_roll=have_tag(index,'crota',/start,pindex)
if have_roll then begin
 tol=2.
 for j=0,n_elements(pindex)-1 do begin
  diff=abs(float(index.(pindex[j]))-180.)
  chk=where(diff le tol, count)
  if count gt 0 then begin
   if keyword_set(verbose) then mprint,'Correcting for 180 degree roll.'
   data=rotate(temporary(data),2)
   index=rot_fits_head(index) 
   break
  endif  
 endfor
endif

return & end

;------------------------------------------------------------------
;-- check for AIA and HMI branches in !path

function hmi::have_path,err=err,verbose=verbose

err=''

if ~have_proc('hmi_prep') then begin
 ssw_path,/aia,/hmi,/quiet
 if ~have_proc('hmi_prep') then begin
  err='SDO/HMI branch of SSW not installed.'
  if keyword_set(verbose) then mprint,err
  return,0b
 endif
endif

return,1b
end

;------------------------------------------------------------------------
;-- setup HMI environment variables

pro hmi::setenv,_extra=extra

if is_string(chklog('SSW_ONTOLOGY_DATA')) then return

mklog,'$SSW_HMI','$SSW/sdo/hmi',/local

idl_startup=local_name('$SSW/sdo/hmi/setup/IDL_STARTUP')
if file_test(idl_startup,/reg) then main_execute,idl_startup

file_env=local_name('$SSW/sdo/hmi/setup/setup.hmi_env')
file_setenv,file_env,_extra=extra
return & end

;------------------------------------------------------
pro hmi__define,void                 

void={hmi, inherits sdo}

return & end
