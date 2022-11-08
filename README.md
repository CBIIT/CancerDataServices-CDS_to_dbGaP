# CancerDataServices-CDS_to_dbGaP
This R Script takes a validated submission template for CDS v1.3.1 as input. It will output a set of files, SubjectConsent data set (DS) and data dictionary (dd) and SubjectSampleMapping (SSM) files.

To run the script on a complete [CDS v1.3.1 validated submission template](https://github.com/CBIIT/CancerDataServices-SubmissionValidationR), run the following command in a terminal where R is installed for help.

```
Rscript --vanilla CDS_to_dbGaP.R --help
```

```
Usage: CDS_to_dbGaP.R [options]

CDS-CDS_to_dbGaP v2.0.1

This script will take a validated CDS Submission Template and create a dbGaP submission for a consent 1 (GRU) study.

If a previous submission for the phs_id already exists, that file can be presented (-s) during the creation to make an updated file for that phs_id.


Options:
	-f CHARACTER, --file=CHARACTER
		A validated dataset file (.xlsx, .tsv, .csv) based on the template CDS_submission_metadata_template-v1.3.1.xlsx

	-s CHARACTER, --previous_submission=CHARACTER
		A previous dbGaP submission directory from the same phs_id study.

	-h, --help
		Show this help message and exit
```

A test file has been given for this script:

```
Rscript --vanilla CDS_to_dbGaP.R -f test_files/a_all_pass_validation-v1.3.1.xlsx
```

If you would like to use the concatenation portion of the script, supply the new manifest with the previous dbGaP directory for the same study.

```
Rscript --vanilla CDS_to_dbGaP.R -f test_files/a_all_pass_validation-v1.3.1.xlsx -s test_files/set_b/
The dbGaP submission files are being made at this time.


 THIS SCRIPT IS ONLY MEANT FOR CDS AND ALL CONSENT IS ASSUMED TO BE GRU, CONSENT GROUP 1.


Process Complete.

The output files can be found here: CancerDataServices-CDS_to_dbGaP/test_files/test1_dbGaP_submission_20221102/
