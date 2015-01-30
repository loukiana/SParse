/*create table 22_ro1_20017_io AS*/
select  
  TIMESTAMP(tin.tstamp) as tstamp,
  TIMESTAMP(tout.tstamp) as tstamp_out,     
  (UNIX_TIMESTAMP(tout.tstamp)- UNIX_TIMESTAMP(tin.tstamp)) duration,

  /* result size - count of AvailPackage nodes returned */  
  CAST(((LENGTH(tout.result) - LENGTH(REPLACE(tout.result, '<AvailPackage>', ''))) / LENGTH('<AvailPackage>')) AS UNSIGNED INTEGER) as avail_size,

/*
SearchParams:
*/

  /* count of ships in search criteria */
  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<Ship></Ship>', '')))), 
    0, CAST(((LENGTH(tin.param1) - LENGTH(REPLACE(tin.param1, '<Ship>', ''))) / LENGTH('<Ship>')) AS UNSIGNED INTEGER)) as search_ships,

  /* referral code */
  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<Referral>', '')))), 
		SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '</Code>', 1), '<Code>', -1), null) as search_referral,

  /* package type attribute */
  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<PackageTypeAttributes>', '')))), 
		SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '</PackageTypeAttribute>', 1), '<PackageTypeAttribute>', -1), null) as search_pkgTypeAttr,

  /* search date range */
  DATE(SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '</From>', 1), '<From>', -1)) as search_from,
  DATE(SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '</To>', 1), '<To>', -1)) as search_to,

  /* package length range */
  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<PackageLenRange>', ''))) AND (LENGTH(SUBSTRING_INDEX(tin.param1, '</PackageLenRange>', 1)) > LENGTH(REPLACE(SUBSTRING_INDEX(tin.param1, '</PackageLenRange>', 1), '<Min>', '')))),  
	CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '</PackageLenRange>', 1), '</Min>', 1), '<Min>', -1) AS UNSIGNED INTEGER),
    null) as search_pkgLenMin,

  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<PackageLenRange>', ''))) AND (LENGTH(SUBSTRING_INDEX(tin.param1, '</PackageLenRange>', 1)) > LENGTH(REPLACE(SUBSTRING_INDEX(tin.param1, '</PackageLenRange>', 1), '<Max>', '')))),  
	CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '</PackageLenRange>', 1), '</Max>', 1), '<Max>', -1) AS UNSIGNED INTEGER),
    null) as search_pkgLenMax,  

  /* price range */
  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<PriceRange>', ''))) AND (LENGTH(SUBSTRING_INDEX(tin.param1, '<PriceRange>', -1)) > LENGTH(REPLACE(SUBSTRING_INDEX(tin.param1, '<PriceRange>', -1), '<Min>', '')))), 
	CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '<PriceRange>', -1), '</Min>', 1), '<Min>', -1) AS UNSIGNED INTEGER),
    null) as search_priceMin,

  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<PriceRange>', ''))) AND (LENGTH(SUBSTRING_INDEX(tin.param1, '<PriceRange>', -1)) > LENGTH(REPLACE(SUBSTRING_INDEX(tin.param1, '<PriceRange>', -1), '<Max>', '')))), 
	CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '<PriceRange>', -1), '</Max>', 1), '<Max>', -1) AS UNSIGNED INTEGER),
    null) as search_priceMax,


/*
SearchOptions:
*/

  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<IncludeComponents>', '')))), 
	SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '</IncludeComponents>', 1), '<IncludeComponents>', -1),
    null) as IncludeComponents,

  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<CalcPrices>', '')))), 
	SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '</CalcPrices>', 1), '<CalcPrices>', -1),
    null) as CalcPrices,

  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<IncludeCategories>', '')))), 
	SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '</IncludeCategories>', 1), '<IncludeCategories>', -1),
    null) as IncludeCategories,

  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<PriceDetails>', '')))), 
	SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '</PriceDetails>', 1), '<PriceDetails>', -1),
    null) as PriceDetails,

  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<EstimateMode>', '')))), 
	SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '</EstimateMode>', 1), '<EstimateMode>', -1),
    null) as EstimateMode,

  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<GroupingCode>', '')))), 
	SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '</GroupingCode>', 1), '<GroupingCode>', -1),
    null) as GroupingCode,

  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<CombineGuests>', '')))), 
	SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '</CombineGuests>', 1), '<CombineGuests>', -1),
    null) as CombineGuests,

  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<CalcMandatoryAddons>', '')))), 
	SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '</CalcMandatoryAddons>', 1), '<CalcMandatoryAddons>', -1),
    null) as CalcMandatoryAddons,

  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<AllowCacheUsage>', '')))), 
	SUBSTRING_INDEX(SUBSTRING_INDEX(tin.param1, '</AllowCacheUsage>', 1), '<AllowCacheUsage>', -1),
    null) as AllowCacheUsage,

/*
   Big data fields:
*/

  /* param1 with ResShellRef repalced with XXX */
  IF(((LENGTH(tin.param1) > LENGTH(REPLACE(tin.param1, '<ResShellRef>', '')))), 
	CONCAT(SUBSTRING_INDEX(tin.param1, '<ResShellRef>', 1), '<ResShellRef>XXX</ResShellRef>', SUBSTRING_INDEX(tin.param1, '</ResShellRef>', -1)), 
	tin.param1) as param1,

  tout.result as result
from 
22_ro1_20017 tin join
22_ro1_20017 tout on tin.request_id = tout.request_id and tin.direction='In' and tout.direction<>'In'
