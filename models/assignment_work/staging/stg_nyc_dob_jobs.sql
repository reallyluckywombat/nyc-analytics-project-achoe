-- Clean and standardize DOB job data
-- One row per job filling

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_dob_job_apps') }}
),

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
           job_filing_number, 
           filing_status,
           house_no,
           street_name,
           borough,
           block,
           lot,
           bin,
           bbl,
           census_tract,
           nta,
           longitude,
           latitude,
           zip,
           first_permit_date,
           filing_date,
           current_status_date,
           approved_date,
           signoff_date,
           job_type,
           building_type,
           boiler_equipment_work_type_,
           earth_work_work_type_,
           foundation_work_type_,
           general_construction_work_type_,
           mechanical_systems_work_type_,
           place_of_assembly_work_type_,
           protection_mechanical_methods_work_type_,
           sidewalk_shed_work_type_,
           structural_work_type_,
           support_of_excavation_work_type_,
           temporary_place_of_assembly_work_type_,
           green_roof_work_type_,
           solar_work_type_,
           full_demolition_work_type_,
           suspended_scaffold_work_type_
       ),

       -- Identifiers --
       CAST(job_filing_number AS STRING) AS job_filing_number,
       CAST(filing_status AS STRING) AS filing_status,

       -- Date/Time --
       CAST(first_permit_date AS TIMESTAMP) AS first_permit_date,
       CAST(filing_date AS TIMESTAMP) AS filing_date,
       CAST(current_status_date AS TIMESTAMP) AS current_status_date,
       CAST(approved_date AS TIMESTAMP) AS approved_date,
       CAST(signoff_date AS TIMESTAMP) AS signoff_date,

       -- job details
       CAST(job_type AS STRING) AS job_type,
       CAST(building_type AS STRING) AS building_type,

       -- Location - clean zip code, handling several common zip code data problems
       CASE
           WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
           WHEN UPPER(TRIM(CAST(zip AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
           WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 10
               AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}')
           THEN CAST(zip AS STRING)
           ELSE NULL
       END AS zip,

       CAST(borough AS STRING) AS borough,
       CAST(bbl AS STRING) AS bbl,
       CAST(bin AS STRING) AS bin,
       CAST(block AS STRING) AS block,
       CAST(lot AS STRING) AS lot,
       CAST(house_no AS STRING) AS house_no,
       CAST(street_name AS STRING) AS street_name,
       CAST(census_tract AS STRING) AS census_tract,
       CAST(nta AS STRING) AS nta,
       CAST(latitude AS DECIMAL) AS latitude,
       CAST(longitude AS DECIMAL) AS longitude,

       -- cleaning colummn name of work type details
       CAST(boiler_equipment_work_type_ AS STRING) AS boiler_equipment,
       CAST(earth_work_work_type_ AS STRING) AS earth_work,
       CAST(foundation_work_type_ AS STRING) AS foundation,
       CAST(general_construction_work_type_ AS STRING) AS general_construction,
       CAST(mechanical_systems_work_type_ AS STRING) AS mechanical_systems,
       CAST(place_of_assembly_work_type_ AS STRING) AS place_of_assembly,
       CAST(protection_mechanical_methods_work_type_ AS STRING) AS protection_mechanical_methods,
       CAST(sidewalk_shed_work_type_ AS STRING) AS sidewalk_shed,
       CAST(structural_work_type_ AS STRING) AS structural,
       CAST(support_of_excavation_work_type_ AS STRING) AS support_of_excavation,
       CAST(temporary_place_of_assembly_work_type_ AS STRING) AS temporary_place_of_assembly,
       CAST(green_roof_work_type_ AS STRING) AS green_roof,
       CAST(solar_work_type_ AS STRING) AS solar,
       CAST(full_demolition_work_type_ AS STRING) AS full_demolition,
       CAST(suspended_scaffold_work_type_ AS STRING) AS suspended_scaffold,

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
   WHERE job_filing_number IS NOT NULL
   AND filing_status IS NOT NULL
   AND CAST(filing_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)
   AND borough IS NOT NULL

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY job_filing_number ORDER BY filing_date DESC) = 1
)

SELECT * FROM cleaned
-- All should be part of this table after running: stg_nyc_dob_job_filings