# ------------------ HGB Physician Level Variability ---------------------------
# -------------------------- 2017-05-24 ----------------------------------------
library(gemini)
lib.pa()

# ---------------------- NEW Cohort selection ----------------------------------
all.phy <- readg(gim, all.phy)
los.cohort <- all.phy[adm.code.new==dis.code.new&mrp.GIM=="y"]
dad <- fread("H:/GEMINI/Results/DesignPaper/design.paper.dad.v4.csv") # update 2017-05-18

los.cohort <- merge(los.cohort[,.(EncID.new, mrp.code.new, GIM= mrp.GIM)], 
                    unique(dad[,.(EncID.new, Age, Gender, CMG, 
                                  Charlson.Comorbidity.Index)]),
                    by = "EncID.new")

site.map <- data.table(
  code = c("11", "12","13","14","15"),
  site = c("smh", "sbk", "uhn", "msh", "thp")
)
los.cohort$code <- str_sub(los.cohort$EncID.new, 1, 2)
los.cohort <- merge(los.cohort, site.map, by = "code")

los.cohort$mrp.code <- paste(los.cohort$site, los.cohort$mrp.code.new, sep = "-")

# find RBC Transfusion
smh.bb <- readg(smh, bb)
sbk.bb <- readg(sbk, bb)
uhn.bb <- rbind(readg(uhn, txm_er),
                readg(uhn, txm_ip))
msh.bb <- readg(msh, bb)
# fix several with time in hh:mm:ss
uhn.bb[nchar(Time_Component_Issued_from_Lab)==8, Time_Component_Issued_from_Lab:=str_sub(
  Time_Component_Issued_from_Lab, 1,5
)]
rbc.trans <- 
  rbind(smh.bb[Selected_product_code=="RCB", .(Trans.Dt = mdy_hm(UseDtTm),
                                               EncID.new)],
        sbk.bb[Product.Group.Code=="RBC", .(Trans.Dt = ymd_hms(paste(Issue.Date, Issue.Time)),
                                            EncID.new)],
        uhn.bb[Blood_Component == "RBC", .(Trans.Dt = mdy_hm(paste(Date_Component_Issued_from_Lab, 
                                                                   Time_Component_Issued_from_Lab)),
                                           EncID.new)],
        msh.bb[POPROD=="Red Blood Cells Concentrate", 
               .(Trans.Dt = ymd_hm(paste(DATE, TIME.new)),EncID.new)])

rbc.trans <- rbc.trans %>% arrange(EncID.new, Trans.Dt) %>% 
  filter(!duplicated(EncID.new)) %>%data.table
# find HGB prior to RBC trans
hgb <- readg(lab, hgb, colClasses = list(character = "EncID.new"))
hgb <- merge(hgb, rbc.trans, by = "EncID.new")
hgb <- hgb %>% arrange(EncID.new, desc(ymd_hms(Collection.DtTm))) %>%
  filter(!duplicated(EncID.new)) %>% data.table
los.cohort$EncID.new <- as.character(los.cohort$EncID.new)
hgb.cohort <- merge(los.cohort, hgb[,.(EncID.new, hgb = Result.Value,
                                       Collection.DtTm, 
                                       RBC.Trans.DtTm = Trans.Dt)],
                    by = "EncID.new")



hgb.cohort[, hgb_in_20_grps := 
             cut(hgb, breaks=quantile(hgb, probs=seq(0,1, by=0.05), na.rm=TRUE), 
                 include.lowest=TRUE,
                 labels = 1:20)]
hgb.cohort[, hgb_in_10_grps := 
             cut(hgb, breaks=quantile(hgb, probs=seq(0,1, by=0.1), na.rm=TRUE), 
                 include.lowest=TRUE,
                 labels = 1:10)]
#hgb.cohort[, Group_by_10hrs := ceiling((hgb-min(hgb))/10)]
#hgb.cohort[, Group_by_20hrs := ceiling((hgb-min(hgb))/20)]
hgb.cohort[, mrp.code.new:=NULL]

fwrite(hgb.cohort[,.(EncID.new, Age, Gender, Charlson.Comorbidity.Index, CMG, mrp.code, mrp.GIM = GIM, site,
                     hgb, hgb_in_10_grps, hgb_in_20_grps)],
       "H:/GEMINI/Results/LengthofStay/hgb/cohort.hgb.may24.csv")
fwrite(data.table(table(hgb.cohort[,mrp.code])),
       "H:/GEMINI/Results/LengthofStay/hgb/mrp.freq.may24.csv")

table(hgb.cohort$site)
table(hgb.cohort$hgb_in_10_grps)
