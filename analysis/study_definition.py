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
    # STUDY POPULATION: Eligibility (0-105 yrs, alive at 1 Mar 2020)
    population=patients.satisfying(
        """
        (age >=0 AND age <= 105)
        AND alive_at_cohort_start
        """,
        alive_at_cohort_start=patients.registered_with_one_practice_between(
            "index_date - 1 day", "index_date"
        ),
    ),
    #### OUTCOMES ###
    # OUTCOME: Death and whether or not due to COVID
    died_ons_covid_flag_any=patients.with_these_codes_on_death_certificate(
        covid_codelist,
        on_or_after="index_date",
        match_only_underlying_cause=False,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    died_date_ons=patients.died_from_any_cause(
        returning="date_of_death",
        include_month=True,
        include_day=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    covid_admission_date=patients.admitted_to_hospital(
        returning= "date_admitted" ,
        with_these_diagnoses=covid_codelist,
        on_or_after="index_date",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    sgss_first_positive_test_date=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    covid_positive_test=patients.with_these_clinical_events(
        covid_positive_test_codes,
        returning="category",
        find_first_match_in_period=True,
        include_date_of_match=True,
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "index_date"},
            "category": {"ratios": {"XaLTE":0.5, "Y20d1":0.5}},
            },
    ),

    ### GEOGRAPHICAL AREA AND DEPRIVATION
    # RURAL/URBAN
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/37
    rural_urban=patients.address_as_of(
        "index_date",
        returning="rural_urban_classification",
                return_expectations={
                    "rate": "universal",
                    "category": {
                        "ratios": {
                            "0": 0.025,
                            "1": 0.2,
                            "2": 0.05,
                            "3": 0.5,
                            "4": 0.05,
                            "5": 0.1,
                            "6": 0.025,
                            "7": 0.025,
                            "8": 0.025,
                        }
                    },
                },

    ),
    # GEOGRAPHICAL AREA - SUSTAINABILITY AND TRANSFORMATION PARTNERSHIP
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/54
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
        },
    ),
    # GEOGRAPHICAL AREA - NHS England 9 regions
    region=patients.registered_practice_as_of(
        "index_date",
        returning="nuts1_region_name",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "North East": 0.1,
                    "North West": 0.1,
                    "Yorkshire and The Humber": 0.1,
                    "East Midlands": 0.2,
                    "West Midlands": 0.1,
                    "East": 0.1,
                    "London": 0.2,
                    "South East": 0.1,
                },
            },
        },
    ),
    # DEPRIVATION
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/52
    imd=patients.address_as_of(
        "index_date",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"100": 0.1, "200": 0.2, "300": 0.7}},
        },
    ),
    ### HOUSEHOLD INFORMATION
    # HOUSEHOLD ID (available only 1 Feb 2020)
    household_id=patients.household_as_of(
        "2020-02-01",
        returning="pseudo_id",
        return_expectations={
            "int": {"distribution": "normal", "mean": 1000, "stddev": 200},
            "incidence": 1,
        },
    ),
    # HOUSEHOLD SIZE (available only 1 Feb 2020)
    household_size=patients.household_as_of(
        "2020-02-01",
        returning="household_size",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 1},
            "incidence": 1,
        },
    ),
    ### DEMOGRAPHIC COVARIATES
    # AGE
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/33
    age=patients.age_as_of(
        "index_date",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),
    # SEX
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/46
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),
    # ETHNICITY
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/27
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        on_or_before="index_date",
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.8, "5": 0.1, "3": 0.1}},
            "incidence": 0.75,
        },
    ),
    ethnicity_16=patients.with_these_clinical_events(
        ethnicity_codes_16,
        returning="category",
        find_last_match_in_period=True,
        on_or_before="index_date",
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.8, "5": 0.1, "3": 0.1}},
            "incidence": 0.75,
        },
    ),
    # SMOKING STATUS
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/6
    smoking_status=patients.categorised_as(
        {
            "S": "most_recent_smoking_code = 'S' OR smoked_last_18_months",
            "E": """
                 (most_recent_smoking_code = 'E' OR (
                   most_recent_smoking_code = 'N' AND ever_smoked
                   )
                 ) AND NOT smoked_last_18_months
            """,
            "N": "most_recent_smoking_code = 'N' AND NOT ever_smoked",
            "M": "DEFAULT",
        },
        return_expectations={
            "category": {"ratios": {"S": 0.6, "E": 0.1, "N": 0.2, "M": 0.1}}
        },
        most_recent_smoking_code=patients.with_these_clinical_events(
            clear_smoking_codes,
            find_last_match_in_period=True,
            on_or_before="index_date",
            returning="category",
        ),
        ever_smoked=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
            on_or_before="index_date",
        ),
        smoked_last_18_months=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S"]),
            between=["index_date - 18 months", "index_date"],
        ),
    ),
    ### CLINICAL MEASUREMENTS
    # BMI
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/10
    bmi_adult=patients.most_recent_bmi(
        on_or_before="index_date",
        minimum_age_at_measurement=16,
        include_measurement_date=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 35, "stddev": 10},
            "incidence": 0.95,
        },
    ),
    bmi_child=patients.most_recent_bmi(
            on_or_before="index_date",
            minimum_age_at_measurement=0,
            include_measurement_date=True,
            include_month=True,
            return_expectations={
                "float": {"distribution": "normal", "mean": 35, "stddev": 10},
                "date": {"latest": "index_date"},
                "incidence": 0.95,
            },
    ),

    # Chronic kidney disease (as measured by creatinine)
    # Most recent creatinine within 5 years (not inc. last fortnight)
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/17
    creatinine=patients.with_these_clinical_events(
        creatinine_codes,
        find_last_match_in_period=True,
        between=["index_date - 5 years", "index_date - 14 days"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 60.0, "stddev": 15},
            "incidence": 0.95,
        },
    ),

    # Blood pressure
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/35
    bp_sys=patients.mean_recorded_value(
        systolic_blood_pressure_codes,
        on_most_recent_day_of_measurement=True,
        on_or_before="index_date - 14 days",
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "float": {"distribution": "normal", "mean": 80, "stddev": 10},
            "date": {"latest": "index_date - 14 days"},
            "incidence": 0.95,
        },
    ),
    bp_dias=patients.mean_recorded_value(
        diastolic_blood_pressure_codes,
        on_most_recent_day_of_measurement=True,
        on_or_before="index_date - 14 days",
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "float": {"distribution": "normal", "mean": 120, "stddev": 10},
            "date": {"latest": "index_date - 14 days"},
            "incidence": 0.95,
        },
    ),
    # Hba1c - most recent measurement within 15 months - mmol/mol or %
    hba1c_mmol_per_mol=patients.with_these_clinical_events(
        hba1c_new_codes,
        find_last_match_in_period=True,
        between=["index_date - 15 months", "index_date"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),
    hba1c_percentage=patients.with_these_clinical_events(
        hba1c_old_codes,
        find_last_match_in_period=True,
        between=["index_date - 15 months", "index_date"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 5, "stddev": 2},
            "incidence": 0.95,
        },
    ),

    # ASTHMA  (diagnosis and medication)
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/55
    asthma_severity=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """
                (
                  recent_asthma_code OR (
                    asthma_code_ever AND NOT
                    copd_code_ever
                  )
                ) AND (
                  prednisolone_last_year < 2
                )
            """,
            "2": """
                (
                  recent_asthma_code OR (
                    asthma_code_ever AND NOT
                    copd_code_ever
                  )
                ) AND
                prednisolone_last_year >= 2

            """,
        },
        return_expectations={"category": {"ratios": {"0": 0.8, "1": 0.1, "2": 0.1}},},
        recent_asthma_code=patients.with_these_clinical_events(
            asthma_codes, between=["index_date - 3 years", "index_date"],
        ),
        asthma_code_ever=patients.with_these_clinical_events(
            asthma_codes, on_or_before="index_date",
        ),
        copd_code_ever=patients.with_these_clinical_events(
            other_respiratory_codes, on_or_before="index_date",
        ),
        prednisolone_last_year=patients.with_these_medications(
            pred_codes,
            between=["index_date - 1 year", "index_date"],
            returning="number_of_matches_in_period",
        ),
    ),
    ### COMORBIDITIES - FIRST DIAGNOSIS DATE
    # RESPIRATORY - ASTHMA, CYSTIC FIBROSIS, OTHER (largely COPD)
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/55
    cf=patients.with_these_clinical_events(
        cf_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    respiratory=patients.with_these_clinical_events(
        other_respiratory_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    # CARDIAC - CARDIAC DISEASE, DIABETES
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/7
    cardiac=patients.with_these_clinical_events(
        chronic_cardiac_disease_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    # ATRIAL FIBRILLATION
    af=patients.with_these_clinical_events(
        af_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),

    # Deep vein thrombosis / pulmonary embolism
    dvt_pe=patients.with_these_clinical_events(
            dvt_pe_codes,
            return_first_date_in_period=True,
            on_or_before="index_date - 1 day",
            include_month=True,
    ),
    # PAD surgery
    pad_surg=patients.with_these_clinical_events(
        pad_surg_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    # Amputation (limb)
    amputate=patients.with_these_clinical_events(
        amputate_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),

    # Diabetes
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/30
    diabetes=patients.with_these_clinical_events(
        diabetes_codes,
        on_or_before="index_date - 1 day",
        return_first_date_in_period=True,
        include_month=True,
    ),
    # Hypertension
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/23
    hypertension=patients.with_these_clinical_events(
        hypertension_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    # STROKE, DEMENTIA, OTHER NEUROLOGICAL
    stroke=patients.with_these_clinical_events(
        stroke,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    dementia=patients.with_these_clinical_events(
        dementia,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/14
    neuro=patients.with_these_clinical_events(
        other_neuro,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    tia=patients.with_these_clinical_events(
            tia,
            return_first_date_in_period=True,
            on_or_before="index_date - 1 day",
            include_month=True,
    ),
    # CANCER
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/32
    lung_cancer=patients.with_these_clinical_events(
        lung_cancer_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    haem_cancer=patients.with_these_clinical_events(
        haem_cancer_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    other_cancer=patients.with_these_clinical_events(
        other_cancer_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    #  KIDNEY TRANSPLANT AND DIALYSIS (most recent)
    #  https://github.com/ebmdatalab/tpp-sql-notebook/issues/31
    transplant_kidney=patients.with_these_clinical_events(
        transplant_kidney_codes,
        return_last_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    dialysis=patients.with_these_clinical_events(
        dialysis_codes,
        return_last_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    # LIVER DISEASE, DIALYSIS AND TRANSPLANT
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/12
    liver=patients.with_these_clinical_events(
        chronic_liver_disease_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    transplant_notkidney=patients.with_these_clinical_events(
        transplant_notkidney_codes,
        return_first_date_in_period=True,
        on_or_before="2020-02-29",
        include_month=True,
    ),
    # SPLEEN PROBLEMS, HIV, IMMUNODEFICIENCY
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/13
    dysplenia=patients.with_these_clinical_events(
        spleen_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    sickle_cell=patients.with_these_clinical_events(
        sickle_cell_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    hiv=patients.with_these_clinical_events(
        hiv_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    perm_immuno=patients.with_these_clinical_events(
        permanent_immune_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    # Aplastic anaemia and temporary immunosuppression
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/36
    temp_immuno=patients.with_these_clinical_events(
        temp_immune_codes,
        return_last_date_in_period=True,
        between=["index_date - 1 year", "index_date"],
        include_month=True,
    ),
    aplastic_anaemia=patients.with_these_clinical_events(
        aplastic_codes,
        return_last_date_in_period=True,
        between=["index_date - 1 year", "index_date"],
        include_month=True,
    ),

    # # https://github.com/ebmdatalab/tpp-sql-notebook/issues/49
    autoimmune=patients.with_these_clinical_events(
        ra_sle_psoriasis_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    # Inflammatory bowel disease
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/50
    ibd=patients.with_these_clinical_events(
        inflammatory_bowel_disease_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    # Severe Mental Illness
    smi=patients.with_these_clinical_events(
        smi_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    # Fragility fracture in two years
    fracture=patients.with_these_clinical_events(
        fracture_codes,
        return_last_date_in_period=True,
        between=["index_date - 2 years", "index_date"],
        include_month=True,
    ),



    ### Learning disability codes

    # Learning disability (excluding Down's Syndrome)
    ldr=patients.with_these_clinical_events(
        ldr_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    ld_profound=patients.with_these_clinical_events(
        ld_profound_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    # Down's Syndrome
    ds=patients.with_these_clinical_events(
        ds_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
    # Cerebral Palsy
    cp=patients.with_these_clinical_events(
        cp_codes,
        return_first_date_in_period=True,
        on_or_before="index_date - 1 day",
        include_month=True,
    ),
)
