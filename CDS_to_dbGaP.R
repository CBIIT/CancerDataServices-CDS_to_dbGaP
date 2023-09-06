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
list_of_packages=c("dplyr","readr","stringi","readxl","openxlsx","optparse","jsonlite","tools")

#Based on the packages that are present, install ones that are required.
new.packages <- list_of_packages[!(list_of_packages %in% installed.packages()[,"Package"])]
suppressMessages(if(length(new.packages)) install.packages(new.packages, repos = "http://cran.us.r-project.org"))

#Load libraries.
suppressMessages(library(dplyr,verbose = F))
suppressMessages(library(readr,verbose = F))
suppressMessages(library(readxl,verbose = F))
suppressMessages(library(openxlsx,verbose = F))
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
              help="A validated dataset file (.xlsx, .tsv, .csv) based on the template CDS_submission_metadata_template-v1.3.1.xlsx", metavar="character"),
  make_option(c("-s", "--previous_submission"), type="character", default=NULL, 
              help="A previous dbGaP submission directory from the same phs_id study.", metavar="character")
)

#create list of options and values for file input
opt_parser = OptionParser(option_list=option_list, description = "\nCDS-CDS_to_dbGaP v2.0.1\n\nThis script will take a validated CDS Submission Template and create a dbGaP submission for a consent 1 (GRU) study.\n\nIf a previous submission for the phs_id already exists, that file can be presented (-s) during the creation to make an updated file for that phs_id.\n")
opt = parse_args(opt_parser)

#If no options are presented, return --help, stop and print the following message.
if (is.null(opt$file)){
  print_help(opt_parser)
  cat("Please supply the input file (-f).\n\n")
  suppressMessages(stop(call.=FALSE))
}


#Data file pathway
file_path=file_path_as_absolute(opt$file)

if (!is.null(opt$previous_submission)){
  previous_submission_path=file_path_as_absolute(opt$previous_submission)
}

#A start message for the user that the manifest creation is underway.
cat("The dbGaP submission files are being made at this time.\n\n\n THIS SCRIPT IS ONLY MEANT FOR CDS AND ALL CONSENT IS ASSUMED TO BE GRU, CONSENT GROUP 1.\n\n")


###########
#
# File name rework
#
###########


#Rework the file path to obtain a file extension, this will be used to read in the file.
ext=tolower(stri_reverse(stri_split_fixed(stri_reverse(basename(file_path)),pattern = ".", n=2)[[1]][1]))

path=paste(dirname(file_path),"/",sep = "")

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
SC=mutate(df,SUBJECT_ID=participant_id,SEX=gender,CONSENT="1")%>%
  select(SUBJECT_ID,CONSENT,SEX)

#Convert sex from a string to a value
SC$SEX[!grepl(pattern = "ale",x = SC$SEX)]<-"UNK"
SC$SEX[grep(pattern = "Female",x = SC$SEX)]<-"2"
SC$SEX[grep(pattern = "Male",x = SC$SEX)]<-"1"

SSM = mutate(df, SUBJECT_ID=participant_id, SAMPLE_ID=sample_id)%>%
  select(SUBJECT_ID, SAMPLE_ID)

SA = mutate(df, SAMPLE_ID=sample_id, SAMPLE_TYPE=sample_type)%>%select(SAMPLE_ID,SAMPLE_TYPE)

#Ensure the rows are unique
SC=unique(SC)
SSM=unique(SSM)
SA=unique(SA)
                 
#Ensure that there are no NA's in id columns
SC=SC[!is.na(SC$SUBJECT_ID),]
SSM=SSM[!is.na(SSM$SUBJECT_ID),]
SSM=SSM[!is.na(SSM$SAMPLE_ID),]
SA=SA[!is.na(SA$SAMPLE_ID),]                 

# The two DD data frames that are needed with the data sets data frames.
df_sc_dd=data.frame(X1=c("VARNAME","SUBJECT_ID","CONSENT","SEX"),X2=c("VARDESC","Subject ID","Consent group as determined by DAC","Biological sex"),X3=c("TYPE","string","encoded value","encoded value"),X4=c("VALUES",NA,"1=General Research Use (GRU)","1=Male"),X5=c(NA,NA,NA,"2=Female"),X6=c(NA,NA,NA,"UNK=Unknown"))

df_ssm_dd=data.frame(X1=c("VARNAME","SUBJECT_ID","SAMPLE_ID"),X2=c("VARDESC","Subject ID","Sample ID"),X3=c("TYPE","string","string"),X4=c("VALUES",NA,NA))

df_sa_dd=data.frame(X1=c("VARNAME","SAMPLE_ID","SAMPLE_TYPE"),X2=c("VARDESC","Sample ID","Sample Type"),X3=c("TYPE","string","string"),X4=c("VALUES",NA,NA))


################
#
# Concatenate previous dbGaP submission.
#
################

if (!is.null(opt$previous_submission)){

  file_list=list.files(path = previous_submission_path,full.names = TRUE)

  file_list=file_list[!grepl(pattern = "DD", x = file_list)]
  file_list=file_list[!grepl(pattern = "json", x = file_list)]
  
  listed_files=list()
  for (files in file_list){
    df_old=suppressMessages(read_tsv(file = files))
    file_name=basename(files)
    df_file_list=list(df_old)
    names(df_file_list)<-file_name
    listed_files=append(listed_files,df_file_list)
  }
  
  #SA_DS
  loc=grep(pattern = "SA_DS_", x = names(listed_files))
  SA=unique(rbind(listed_files[[loc]], SA))
  
  #SSM_DS
  loc=grep(pattern = "SSM_DS_", x = names(listed_files))
  SSM=unique(rbind(listed_files[[loc]], SSM))
  
  #SC_DS
  loc=grep(pattern = "SC_DS_", x = names(listed_files))
  SC=unique(rbind(listed_files[[loc]], SC))
  
}


################
#
# Write Out
#
################

#Create an output directory for all the files
phs_id=unique(df$phs_accession)[1]

output_file=paste(phs_id,"_dbGaP_submission",sep="")

#Create Metadata JSON to use with gaptools
metadata_json=list(NAME=paste(phs_id,stri_replace_all_fixed(str = Sys.Date(), pattern = "-",replacement = "_"),sep = ""))
metadata_json$FILES=append(x = metadata_json$FILES, list(list(name=paste("SC_DS_",output_file,".txt",sep = ""),type="subject_consent_file")))
metadata_json$FILES=append(x = metadata_json$FILES, list(list(name="SC_DD.xlsx",type="subject_consent_data_dictionary_file")))
metadata_json$FILES=append(x = metadata_json$FILES, list(list(name=paste("SA_DS_",output_file,".txt",sep = ""),type="sample_attributes")))
metadata_json$FILES=append(x = metadata_json$FILES, list(list(name="SA_DD.xlsx",type="sample_attributes_dd")))
metadata_json$FILES=append(x = metadata_json$FILES, list(list(name=paste("SSM_DS_",output_file,".txt",sep = ""),type="subject_sample_mapping_file")))
metadata_json$FILES=append(x = metadata_json$FILES, list(list(name="SSM_DD.xlsx",type="subject_sample_mapping_data_dictionary_file")))

metadata_json=toJSON(metadata_json,pretty = F,auto_unbox = T)

#Create new output directory
new_dir=paste(phs_id,"_dbGaP_submission_",stri_replace_all_fixed(str = Sys.Date(), pattern = "-",replacement = ""),"/",sep = "")
dir.create(path = paste(path,new_dir,sep = ""), showWarnings = FALSE)

path=paste(path,new_dir,sep = "")

#Write out the three DD and three DS data frames
write.xlsx(x = as.data.frame(df_sc_dd),file = paste(path,"SC_DD.xlsx",sep=""), colNames = FALSE, showNA = FALSE, rowNames = FALSE)

write.xlsx(x = as.data.frame(df_ssm_dd),file = paste(path,"SSM_DD.xlsx",sep=""),colNames = FALSE, showNA = FALSE, rowNames = FALSE)

write.xlsx(x = as.data.frame(df_sa_dd),file = paste(path,"SA_DD.xlsx",sep=""),colNames = FALSE, showNA = FALSE, rowNames = FALSE)

write_tsv(x = SC,file = paste(path,"SC_DS_",output_file,".txt",sep = ""),na="")

write_tsv(x = SSM,file = paste(path,"SSM_DS_",output_file,".txt",sep = ""),na="")

write_tsv(x = SA,file = paste(path,"SA_DS_",output_file,".txt",sep = ""),na="")

write(x = metadata_json, file = paste(path,"metadata.json",sep = ""))

cat(paste("\n\nProcess Complete.\n\nThe output files can be found here: ",path,"\n\n",sep = "")) 
