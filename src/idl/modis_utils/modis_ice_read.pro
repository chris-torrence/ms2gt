PRO MODIS_ICE_READ, FILENAME, BAND, IMAGE, $
                    LATITUDE=LATITUDE, LONGITUDE=LONGITUDE
  
;+
; NAME:
;    MODIS_ICE_READ
;
; PURPOSE:
;    Read a single band from a MOD29 modis ice product file at
;    1km resolution.
;
;    This procedure uses only HDF calls (it does *not* use HDF-EOS),
;    and only reads from SDS and Vdata arrays (it does *not* read ECS metadata).
;
; CATEGORY:
;    MODIS utilities.
;
; CALLING SEQUENCE:
;    MODIS_ICE_READ, FILENAME, BAND, IMAGE
;
; INPUTS:
;    FILENAME       Name of MODIS Level 1B HDF file
;    BAND           Band number to be read:
;              1: Sea Ice by Reflectance - 8-bit unsigned
;              2: Sea Ice by Reflectance PixelQA - 8-bit unsigned
;              3: Ice Surface Temperature - 16-bit unsigned (Kelvin * 100)
;              4: Ice Surface Temperature PixelQA - 8-bit unsigned
;              5: Sea Ice by IST - 8-bit unsigned
;              6: Combined Sea Ice - 8-bit unsigned
;
; OPTIONAL INPUTS:
;    None.
;
; KEYWORD PARAMETERS:
;    LATITUDE       On return, an array containing the reduced resolution latitude
;                   data for the entire granule (5km resolution).
;    LONGITUDE      On return, an array containing the reduced resolution longitude
;                   data for the entire granule (5km resolution).
;    
; OUTPUTS:
;    IMAGE          A two dimensional byte or uint (band=3) array of image data.
;
; OPTIONAL OUTPUTS:
;    None.
;
; COMMON BLOCKS:
;    None
;
; SIDE EFFECTS:
;    When an entire MOD29 swath scene is dark, then channels 1, 2, and 6 may
;    not be present in the hdf file. If channel 1, 2, or 6 is requested for
;    such a file, then channel 5 is read instead to determine the proper
;    size, and an array filled the fill value of that size is returned.
;
; RESTRICTIONS:
;    Requires IDL 5.0 or higher (square bracket array syntax).
;
;    Requires the following HDF procedures by Liam.Gumley@ssec.wisc.edu:
;    HDF_SD_ATTINFO      Get information about an attribute
;    HDF_SD_ATTLIST      Get list of attribute names
;    HDF_SD_VARINFO      Get information about an SDS variable
;    HDF_SD_VARLIST      Get a list of SDS variable names
;    HDF_SD_VARREAD      Read an SDS variable
;    HDF_VD_VDATAINFO    Get information about a Vdata
;    HDF_VD_VDATALIST    Get list of Vdata names
;    HDF_VD_VDATAREAD    Read a Vdata field
;
; EXAMPLES:
;
; REFERENCE:
;    Based on modis_level1b_read from 
;-

rcs_id = '$Id: modis_ice_read.pro,v 1.1 2001/01/29 23:54:27 haran Exp haran $'

;-------------------------------------------------------------------------------
;- CHECK INPUT
;-------------------------------------------------------------------------------

;- Check arguments
if (n_params() ne 3) then $
  message, 'Usage: MODIS_ICE_READ, FILENAME, BAND, IMAGE'

if (n_elements(filename) eq 0) then $
  message, 'Argument FILENAME is undefined'

if (n_elements(band) eq 0) then $
  message, 'Argument BAND is undefined'

if (arg_present(image) ne 1) then $
  message, 'Argument IMAGE cannot be modified'

;-------------------------------------------------------------------------------
;- CHECK FOR VALID MODIS ICE HDF FILE
;-------------------------------------------------------------------------------

;- Check that file exists
if ((findfile(filename))[0] eq '') then $
  message, 'FILENAME was not found => ' + filename
  
;- Get expanded filename
openr, lun, filename, /get_lun
fileinfo = fstat(lun)
free_lun, lun

;- Check that file is HDF
if (hdf_ishdf(fileinfo.name) ne 1) then $
  message, 'FILENAME is not HDF => ' + fileinfo.name

;- Get list of SDS arrays
sd_id = hdf_sd_start(fileinfo.name)
varlist = hdf_sd_varlist(sd_id)
hdf_sd_end, sd_id

;- Locate image arrays
index = where(varlist.varnames eq 'Ice Surface Temperature', count_temp)
index = where(varlist.varnames eq 'Ice Surface Temperature PixelQA', count_tqa)
index = where(varlist.varnames eq 'Sea Ice by IST', count_ice)
if (count_temp ne 1) or (count_tqa ne 1) or (count_ice ne 1) then $
  message, 'FILENAME is not MODIS Sea Ice HDF => ' + fileinfo.name

;-------------------------------------------------------------------------------
;- CHECK BAND NUMBER, AND KEYWORDS WHICH DEPEND ON BAND NUMBER
;-------------------------------------------------------------------------------

;- Check band number

if (band lt 1) or (band gt 6) then $
    message, 'BAND range is 1-6 for this MODIS type => ' + filetype

;-------------------------------------------------------------------------------
;- SET VARIABLE NAME FOR IMAGE DATA
;-------------------------------------------------------------------------------
case band of
  1: sds_name = 'Sea Ice by Reflectance'
  2: sds_name = 'Sea Ice by Reflectance PixelQA'
  3: sds_name = 'Ice Surface Temperature'
  4: sds_name = 'Ice Surface Temperature PixelQA'
  5: sds_name = 'Sea Ice by IST'
  6: sds_name = 'Combined Sea Ice'
endcase

;-------------------------------------------------------------------------------
;- OPEN THE FILE IN SDS MODE
;-------------------------------------------------------------------------------

sd_id = hdf_sd_start(fileinfo.name)

;- Check to see that the sds exists
index = where(varlist.varnames eq sds_name, count_exists)
if count_exists eq 0 then begin

;- If the sds doesn't exist, then use channel 5 as a proxy to get the fill
;  value and the size, print a message, and set the image to the fill value.
    sds_name_fake = 'Sea Ice by IST'
    fill_struct = hdf_sd_attinfo(sd_id, sds_name_fake, '_FillValue')
    fill = fill_struct.data
    message, /informational, 'channel ' + string(band, format='(I1)') + $
      ': ' + sds_name + ' does not exist -- returning fill value: ' + $
      string(fill, format='(I3)') + ' => ' + filename
    hdf_sd_varread, sd_id, sds_name_fake, image
    image[*,*] = byte(fill)
endif else begin

;- If the sds exists, then read the image array
    hdf_sd_varread, sd_id, sds_name, image
endelse

;- Read latitude and longitude arrays
if arg_present(latitude) then hdf_sd_varread, sd_id, 'Latitude', latitude
if arg_present(longitude) then hdf_sd_varread, sd_id, 'Longitude', longitude

;-------------------------------------------------------------------------------
;- CLOSE THE FILE IN SDS MODE
;-------------------------------------------------------------------------------

hdf_sd_end, sd_id

END
