# CancerDataServices-CDS_to_dbGaP
This script will take a validated CDS submission template and create the submission input needed for dbGaP.

This R Script takes a validated submission template for CDS v1.3.1 as input. It will output a set of files, SubjectConsent data set (DS) and data dictionary (dd) and SubjectSampleMapping (SSM) files.

To run the script on a CDS v1.3.1 template, run the following command in a terminal where R is installed for help.

```
Rscript --vanilla CDS-Submission_ValidationR.R --help
```

```
Usage: CDS_to_dbGaP.R [options]

CDS-CDS_to_dbGaP v.1.3.1

Options:
	-f CHARACTER, --file=CHARACTER
		A validated dataset file (.xlsx, .tsv, .csv) based on the template CDS_submission_metadata_template-v1.3.1.xlsx

	-h, --help
		Show this help message and exit
```

A test file has been given for this script:

```
Rscript --vanilla CDS-Submission_ValidationR.R -f test_files/a_all_pass-v1.3.1.xlsx
```
