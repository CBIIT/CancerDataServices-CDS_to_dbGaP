#!/usr/bin/env Rscript

#Cancer Data Services - CDS to dbGaP

#This script will take data from a CDS submission manifest, and create the Subject Consent, Subject Sample Mapping and Sample Attribute files specifically for a CDS project.

##################
#
# USAGE
#
##################

#Run the following command in a terminal where R is installed for help.

#Rscript --vanilla CDS_to_dbGaP.R --help


##################
#
# Env. Setup
#
##################

#List of needed packages
list_of_packages=c("dplyr","readr","stringi","readxl","xlsx","optparse","jsonlite","tools")

#Based on the packages that are present, install ones that are required.
new.packages <- list_of_packages[!(list_of_packages %in% installed.packages()[,"Package"])]
suppressMessages(if(length(new.packages)) install.packages(new.packages))

#Load libraries.
suppressMessages(library(dplyr,verbose = F))
suppressMessages(library(readr,verbose = F))
suppressMessages(library(xlsx,verbose = F))
suppressMessages(library(readxl,verbose = F))
suppressMessages(library(optparse,verbose = F))
suppressMessages(library(jsonlite,verbose = F))
suppressMessages(library(tools,verbose = F))
suppressMessages(library(stringi,verbose = F))

#remove objects that are no longer used.
rm(list_of_packages)
rm(new.packages)


##################
#
# Arg parse
#
##################

#Option list for arg parse
option_list = list(
  make_option(c("-f", "--file"), type="character", default=NULL, 
              help="A validated dataset file (.xlsx, .tsv, .csv) based on the template CDS_submission_metadata_template-v1.3.1.xlsx", metavar="character")
)

#create list of options and values for file input
opt_parser = OptionParser(option_list=option_list, description = "\nCDS-CDS_to_dbGaP v.1.3.1")
opt = parse_args(opt_parser)

#If no options are presented, return --help, stop and print the following message.
if (is.null(opt$file)){
  print_help(opt_parser)
  cat("Please supply the input file (-f).\n\n")
  suppressMessages(stop(call.=FALSE))
}


#Data file pathway
file_path=file_path_as_absolute(opt$file)

#A start message for the user that the manifest creation is underway.
cat("The dbGaP submission files are being made at this time.\n\n\n THIS SCRIPT IS ONLY MEANT FOR CDS AND ALL CONSENT IS ASSUMED TO BE GRU, CONSENT GROUP 1.\n\n")


###########
#
# File name rework
#
###########


#Rework the file path to obtain a file name, this will be used for the output file.
file_name=stri_split_fixed(basename(file_path),pattern = ".", n=2)[[1]][1]

ext=tolower(stri_reverse(stri_split_fixed(stri_reverse(basename(file_path)),pattern = ".", n=2)[[1]][1]))

path=paste(dirname(file_path),"/",sep = "")

#Output file name based on input file name and date/time stamped.
output_file=paste(file_name,
                  "_dbGaP_",
                  stri_replace_all_fixed(
                    str = Sys.Date(),
                    pattern = "-",
                    replacement = "_"),
                  sep="")
                  

#Read in metadata page/file to check against the expected/required properties. 
#Logic has been setup to accept the original XLSX as well as a TSV or CSV format.
if (ext == "tsv"){
  df=suppressMessages(read_tsv(file = file_path, guess_max = 1000000, col_types = cols(.default = col_character())))
}else if (ext == "csv"){
  df=suppressMessages(read_csv(file = file_path, guess_max = 1000000, col_types = cols(.default = col_character())))
}else if (ext == "xlsx"){
  df=suppressMessages(read_xlsx(path = file_path,sheet = "Metadata", guess_max = 1000000, col_types = "text"))
}else{
  stop("\n\nERROR: Please submit a data file that is in either xlsx, tsv or csv format.\n\n")
}

#################
#
# Data frame manipulation
#
#################

#Mutate the CDS template data frame into the two required dbGaP data frames
SubCon=mutate(df,SUBJECT_ID=participant_id,SEX=gender,CONSENT="1")%>%
  select(SUBJECT_ID,CONSENT,SEX)

#Convert sex from a string to a value
SubCon$SEX[!grepl(pattern = "ale",x = SubCon$SEX)]<-"UNK"
SubCon$SEX[grep(pattern = "Female",x = SubCon$SEX)]<-"2"
SubCon$SEX[grep(pattern = "Male",x = SubCon$SEX)]<-"1"

SSM = mutate(df, SUBJECT_ID=participant_id, SAMPLE_ID=sample_id)%>%
  select(SUBJECT_ID, SAMPLE_ID)

SA = mutate(df, SAMPLE_ID=sample_id, SAMPLE_TYPE=sample_type)%>%select(SAMPLE_ID,SAMPLE_TYPE)

#Ensure the rows are unique
SubCon=unique(SubCon)
SSM=unique(SSM)
SA=unique(SA)
                 
#Ensure that there are no NA's in id columns
SubCon=SubCon[!is.na(SubCon$SUBJECT_ID),]
SSM=SSM[!is.na(SSM$SUBJECT_ID),]
SSM=SSM[!is.na(SSM$SAMPLE_ID),]
SA=SA[!is.na(SA$SAMPLE_ID),]                 

# The two DD data frames that are needed with the data sets data frames.
df_sc_dd=data.frame(X1=c("VARNAME","SUBJECT_ID","CONSENT","SEX"),X2=c("VARDESC","Subject ID","Consent group as determined by DAC","Biological sex"),X3=c("TYPE","string","encoded value","encoded value"),X4=c("VALUES",NA,"1=General Research Use (GRU)","1=Male"),X5=c(NA,NA,NA,"2=Female"),X6=c(NA,NA,NA,"UNK=Unknown"))

df_ssm_dd=data.frame(X1=c("VARNAME","SUBJECT_ID","SAMPLE_ID"),X2=c("VARDESC","Subject ID","Sample ID"),X3=c("TYPE","string","string"),X4=c("VALUES",NA,NA))

df_sa_dd=data.frame(X1=c("VARNAME","SAMPLE_ID","SAMPLE_TYPE"),X2=c("VARDESC","Sample ID","Sample Type"),X3=c("TYPE","string","string"),X4=c("VALUES",NA,NA))


#Create Metadata JSON to use with gaptools
metadata_json=list(NAME=paste(unique(df$acl)[1],stri_replace_all_fixed(str = Sys.Date(), pattern = "-",replacement = "_"),sep = ""))
metadata_json$FILES=append(x = metadata_json$FILES, list(list(name=paste("SC_DS_",output_file,".txt",sep = ""),type="subject_consent_file")))
metadata_json$FILES=append(x = metadata_json$FILES, list(list(name="SC_DD.xlsx",type="subject_consent_data_dictionary_file")))
metadata_json$FILES=append(x = metadata_json$FILES, list(list(name=paste("SA_DS_",output_file,".txt",sep = ""),type="sample_attributes")))
metadata_json$FILES=append(x = metadata_json$FILES, list(list(name="SA_DD.xlsx",type="sample_attributes_dd")))
metadata_json$FILES=append(x = metadata_json$FILES, list(list(name=paste("SSM_DS_",output_file,".txt",sep = ""),type="subject_sample_mapping_file")))
metadata_json$FILES=append(x = metadata_json$FILES, list(list(name="SSM_DD.xlsx",type="subject_sample_mapping_data_dictionary_file")))

metadata_json=toJSON(metadata_json,pretty = F,auto_unbox = T)


################
#
# Write Out
#
################

#Create an output directory for all the files
new_dir=paste("dbGaP_submission_",stri_replace_all_fixed(str = Sys.Date(), pattern = "-",replacement = "_"),"/",sep = "")
dir.create(path = paste(path,new_dir,sep = ""))

path=paste(path,new_dir,sep = "")

#Write out the three DD and three DS data frames
write.xlsx(x = as.data.frame(df_sc_dd),file = paste(path,"SC_DD.xlsx",sep=""),col.names = FALSE, showNA = FALSE, row.names = FALSE)

write.xlsx(x = as.data.frame(df_ssm_dd),file = paste(path,"SSM_DD.xlsx",sep=""),col.names = FALSE, showNA = FALSE, row.names = FALSE)

write.xlsx(x = as.data.frame(df_sa_dd),file = paste(path,"SA_DD.xlsx",sep=""),col.names = FALSE, showNA = FALSE, row.names = FALSE)

write_tsv(x = SubCon,file = paste(path,"SC_DS_",output_file,".txt",sep = ""),na="")

write_tsv(x = SSM,file = paste(path,"SSM_DS_",output_file,".txt",sep = ""),na="")

write_tsv(x = SA,file = paste(path,"SA_DS_",output_file,".txt",sep = ""),na="")

write(x = metadata_json, file = paste(path,"metadata.json",sep = ""))
