# ---------------------- Sinai Lab Non-numeric Summary -------------------------
library(gemini)
lib.pa()

msh.lab <- readg(msh, lab, dt = T)
msh.lab <- msh.lab[,.(EncID.new, Test.Name = Name, Test.ID = TEST_ID, 
                      Collection.DtTm = ymd_hms(paste(DATE_COLLECT, TIME_COLLECT)),
                      Site = "MSH", Result.Value = RESULT, Result.Unit = UNITES,
                      Reference.Range = REFERANCE_LAB)]
msh.lab[str_sub(Result.Value,1,1)%in%c(0:9)&is.na(as.numeric(Result.Value))&
          !is.na(Result.Value),
        Result.Value := str_replace_all(Result.Value, "[@A-z!]","")]

msh.lab.list <- list(
  hgb.msh <- msh.lab[Test.ID%in%c("HGB")],
  wbc.msh <- msh.lab[Test.ID=="WBC"],
  plt.msh <- msh.lab[Test.ID=="PLT"],
  sodium.msh <- msh.lab[Test.Name%in%c("Sodium plasma", "Sodium blood", "Sodium serum",
                                       "Sodium, Venous")&Test.ID%in%
                          c("NAPL", "NAW", "NAS", "NAV")],
  potassium.msh <- msh.lab[Test.ID%in%c("KPL", "KW", "KS", "KV")],
  troponin.msh <- msh.lab[Test.ID%in%c("TNTP4", "TNTP3", "TNTS4", "TNTS3", "TNTQ4", "TNTQ3",
                                       "TRPQ3", "TNTPP")],
  lactate.msh <- msh.lab[Test.ID%in%c("LACW", "LACPL", "LACV")],
  albumin.msh <- msh.lab[Test.ID%in%c("ALBP","ALBS")],
  calcium.msh <- msh.lab[Test.ID%in%c("CATP", "CATS")],
  ast.msh <- msh.lab[Test.ID%in%c("ASTP", "AST")],
  alt.msh <- msh.lab[Test.ID%in%c("ALTSP", "ALTS")],
  mcv.msh <- msh.lab[Test.ID=="MCV"],
  alp.msh <- msh.lab[Test.ID%in%c("ALPP", "ALPS")],
  glucose.random.msh <- msh.lab[Test.ID%in%c("GLUW", "GLRP", "GLUS", "GLUV")],
  glucose.poc.msh <- msh.lab[Test.ID=="GLUM"],
  glucose.fasting.msh <- msh.lab[Test.ID%in%c("GLFP", "GLUF")])
names(msh.lab.list) <- c("Hemoglobin",
                         "White Blood Cell",
                         "Platelet",
                         "Sodium",
                         "Potassium",
                         "Troponin",
                         "Lactate",
                         "Albumin",
                         "Calcium",
                         "AST",
                         "ALT",
                         "MCV",
                         "ALP",
                         "Glucose Random",
                         "Glucose Point of Care",
                         "Glucose Fasting")

value_summary <- function(df){
  x <- df$Result.Value
  cat("### Summary of numbers\n")
  cat("Numeric Values (N, %): ", 
    paste(sum(!is.na(as.numeric(x))),
          " (", round(sum(!is.na(as.numeric(x)))/length(x)*100, 2),")\n", sep = ""))
  cat("Non-numeric Values (N, %): ", 
      paste(sum(is.na(as.numeric(x))),
            " (", round(sum(is.na(as.numeric(x)))/length(x)*100, 2),")\n", sep = ""))
  print(ktable(table(x[is.na(as.numeric(x))])))
}


for(i in 1:length(msh.lab.list)){
  cat("####", names(msh.lab.list)[i], "<br/>")
  value_summary(msh.lab.list[[i]])
  
  cat("\\newpage<br/>")
}
