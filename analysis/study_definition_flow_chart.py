## IMPORT STATEMENTS

# This imports the cohort extractor package. This can be downloaded via pip
from cohortextractor import (
    StudyDefinition,
    patients,
    codelist_from_csv,
    codelist,
    combine_codelists,
    filter_codes_by_category,
)

# IMPORT CODELIST DEFINITIONS FROM CODELIST.PY (WHICH PULLS THEM FROM
# CODELIST FOLDER
from codelists import *


#########################
##   STUDY POPULATION   #
#########################


study = StudyDefinition(
    index_date="2020-03-01",
    default_expectations={
        "date": {"earliest": "1970-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.2,
    },

    # STUDY POPULATION: Start with everyone
    population=patients.all(),

    ## Include: Registered at index date
    alive_at_cohort_start=patients.registered_with_one_practice_between(
        "index_date - 1 day", "index_date", return_expectations={"incidence": 0.9},
    ),

    ## Exclude: dead prior to index date  (late de-registrations)
    died_date_ons=patients.died_from_any_cause(
        returning="date_of_death",
        include_month=True,
        include_day=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),

    ## Exclude: Patients missing STP
    stp=patients.registered_practice_as_of(
        "index_date",
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "E54000005": 0.04,
                    "E54000006": 0.04,
                    "E54000007": 0.04,
                    "E54000008": 0.04,
                    "E54000009": 0.04,
                    "E54000010": 0.04,
                    "E54000012": 0.04,
                    "E54000013": 0.03,
                    "E54000014": 0.03,
                    "E54000015": 0.03,
                    "E54000016": 0.03,
                    "E54000017": 0.03,
                    "E54000020": 0.03,
                    "E54000021": 0.03,
                    "E54000022": 0.03,
                    "E54000023": 0.03,
                    "E54000024": 0.03,
                    "E54000025": 0.03,
                    "E54000026": 0.03,
                    "E54000027": 0.03,
                    "E54000029": 0.03,
                    "E54000033": 0.03,
                    "E54000035": 0.03,
                    "E54000036": 0.03,
                    "E54000037": 0.03,
                    "E54000040": 0.03,
                    "E54000041": 0.03,
                    "E54000042": 0.03,
                    "E54000044": 0.03,
                    "E54000043": 0.03,
                    "E54000049": 0.03,
                }
            },
            "incidence": 0.9,
        },
    ),
    # Exclude: patients missing IMD
    imd=patients.address_as_of(
        "index_date",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"100": 0.2, "200": 0.2, "300": 0.2, "400": 0.2, "500": 0.2}},
            "incidence": 0.9,
            },
    ),

    # Exclude: Age between 0 and 105
    age=patients.age_as_of(
        "index_date",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
            "incidence": 0.99,
            },
    ),
    # Exclude: missing sex
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
            "incidence": 0.98,
        }
    ),
    # CC analysis: exclude missing ethnicity
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        on_or_before="index_date",
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.2, "2": 0.2, "3": 0.2, "4": 0.2, "5": 0.2,}},
            "incidence": 0.75,
        },
    ),
)
