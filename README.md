# CancerDataServices-CDS_to_dbGaP
This R Script takes a validated submission template for CDS v1.3.1 as input. It will output a set of files, SubjectConsent data set (DS) and data dictionary (dd) and SubjectSampleMapping (SSM) files.

To run the script on a complete [CDS v1.3.1 validated submission template](https://github.com/CBIIT/CancerDataServices-SubmissionValidationR), run the following command in a terminal where R is installed for help.

```
Rscript --vanilla CDS_to_dbGaP.R --help
```

```
Usage: CDS_to_dbGaP.R [options]

CDS-CDS_to_dbGaP v2.0.0

Options:
	-f CHARACTER, --file=CHARACTER
		A validated dataset file (.xlsx, .tsv, .csv) based on the template CDS_submission_metadata_template-v1.3.1.xlsx

	-h, --help
		Show this help message and exit
```

A test file has been given for this script:

```
Rscript --vanilla CDS_to_dbGaP.R -f test_files/a_all_pass_validation-v1.3.1.xlsx
```
