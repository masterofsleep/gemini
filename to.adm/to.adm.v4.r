# --------------------------- To adm v4 ----------------------------------------
library(gemini)
lib.pa()
# a function to generate random labels for sites
hide_site <- function(data){
  ninst <- length(unique(data$Institution.Number))
  newcode <- data.frame(Institution.Number = unique(data$Institution.Number), 
                        new.inst = sample(c("A", "B", "C", "D", "E", "F", "G")[1:ninst]))
  data <- merge(data, newcode, by = "Institution.Number")
  data$Institution.Number <- data$new.inst
  return(data)
}

hide_site2 <- function(data){
  ninst <- length(unique(data$Institution.Number))
  newcode <- data.frame(Institution.Number = 
                          c("SHS", "SHSC", "SMH", "THP-C", "THP-M", "UHN-TG", "UHN-TW"), 
                        new.inst = c("A", "B", "C", "D", "E", "F", "G"))
  data <- merge(data, newcode, by = "Institution.Number")
  data$Institution.Number <- data$new.inst
  return(data)
}


find_cohort <- function(x){
  phy <- readg(gim, all.phy)
  dad <- fread("H:/GEMINI/Results/DesignPaper/design.paper.dad.v4.csv")
  cohort <- phy[(adm.code.new==dis.code.new&adm.code.new==mrp.code.new&
                   adm.code!=0&adm.GIM!="n")]
  cohort[,':='(mrp.code = NULL,
               adm.code = NULL,
               dis.code = NULL)]
  setwd("H:/GEMINI/Results/to.administrator")
  copd <- fread("qbp.copd.csv")
  cap <- fread("qbp.cap.csv")
  uti <- fread("qbp.uti.csv")
  stroke <- fread("qbp.stroke.csv")
  chf <- fread("qbp.chf.csv")
  
  cohort[,':='(copd = EncID.new%in%copd$EncID.new,
               cap = EncID.new%in%cap$EncID.new,
               chf = EncID.new%in%chf$EncID.new,
               stroke = EncID.new%in%stroke$EncID.new,
               uti = EncID.new%in%uti$EncID.new)]
  cohort <- merge(cohort, dad, by = "EncID.new")
  cohort[, physician:=paste(Institution.Number, mrp.code.new, sep = "-")]
  #cohort <- cohort[!GIM%in%c("Geriatrics", "u", "family.md")]
  n.pat <- cohort[,.N, by = physician]
  cohort <- cohort[physician%in%n.pat[N>=100, physician]]
  cohort <- cohort[Acute.LoS<=30]
  
  # 69558 hospitalizations, if select physicians first
  cohort <- cohort[LoS<=30]
  n.pat <- cohort[,.N, by = physician]
  cohort <- cohort[physician%in%n.pat[N>=100, physician]]
  
  # add number of advanced imaging
  ctmrius <- fread("C:/Users/guoyi/Desktop/to.adm/n.ctmrius.csv")
  cohort$EncID.new <- as.character(cohort$EncID.new)
  ctmrius$EncID.new <- as.character(ctmrius$EncID.new)
  cohort <- merge(cohort, ctmrius, by = "EncID.new", all.x = T, all.y = F)
  cohort[is.na(N.rad), N.rad:= 0]
  
  # CBC and Electrolyte Test
  hgb <- readg(lab, hgb)
  sod <- readg(lab, sodium)
  hgb[is.na(as.numeric(Result.Value))]
  sod[is.na(as.numeric(Result.Value))]
  n.blood.test <- data.table(table(c(hgb$EncID.new, sod$EncID.new)))
  names(n.blood.test) <- c("EncID.new", "n.bloodtest")
  cohort$EncID.new <- as.character(cohort$EncID.new)
  cohort <- merge(cohort, n.blood.test, by = "EncID.new", all.x = T)
  cohort[is.na(n.bloodtest), n.bloodtest:=0]
  
  # Transfusion with pre hgb > 80
  rbc.trans <- fread("H:/GEMINI/Results/to.administrator/rbc.trans.with.pre.hgb.csv")
  rbc.trans.70 <- rbc.trans[with.pre.hgb==T&pre.hgb>70]
  n.with.pre.trans.70 <- rbc.trans.70[,.N, by = EncID.new]
  n.with.pre.trans.70$EncID.new <- as.character(n.with.pre.trans.70$EncID.new)
  names(n.with.pre.trans.70)[2] <- "N.pre.tran.hgb.gt70"
  cohort <- merge(cohort, n.with.pre.trans.70, by = "EncID.new",
                  all.x = T, all.y = F)
  cohort[is.na(N.pre.tran.hgb.gt70), N.pre.tran.hgb.gt70 := 0]
  
  # AKI 
  inc <- fread("C:/Users/guoyi/Desktop/to.adm/kdigo.new.csv")
  cohort$aki <- cohort$EncID.new%in%inc[KDIGO%in%c("2", "3"), EncID.new]
  
  # mark ICU before adm as non ICU admission
  icu.before.adm.enc <- fread("C:/Users/guoyi/Desktop/to.adm/icu.before.adm.enc.csv")
  cohort[EncID.new%in%icu.before.adm.enc$EncID.new, SCU.adm := F]
  
  # find mortality (excluding palliative in diagnoses)
  ip.diag <- readg(gim, ip_diag)
  er.diag <- readg(gim, er_diag)
  palli <- c(ip.diag[startwith.any(Diagnosis.Code, "Z515"), EncID.new],
             er.diag[startwith.any(ER.Diagnosis.Code, "Z515"), EncID.new])
  cohort$death <- cohort$Discharge.Disposition==7
  cohort[EncID.new%in%palli, death:= F]
  cohort[, with.ALC := Number.of.ALC.Days>0]
  return(cohort)
}
cohort <- find_cohort()


fwrite(cohort, "C:/Users/guoyi/Desktop/to.adm/cohort.csv")
cohort[physician=="SMH-261"]
phy.sum <- ddply(cohort, ~physician, function(x)
  data.frame(N = nrow(x),
             code.new = x$mrp.code.new[1],
             GIM = x$mrp.GIM[1],
             site = x$Institution.Number[1],
             n.patient = nrow(x)/length(unique(x$physician)),
             ave.acute.los = mean(x$Acute.LoS, na.rm = T),
             ave.alc = mean(x$Number.of.ALC.Days, na.rm = T),
             read.rate = sum(x$read.in.30, na.rm = T)/sum(!is.na(x$read.in.30), na.rm = T)*100,
             mortality = mean(x$death==T, na.rm = T)*100,
             short.adm = mean(x$Acute.LoS < 2, na.rm = T)*100,
             icu.rate = mean(x$SCU.adm, na.rm = T)*100,
             cbc.per.patientday = sum(x$n.bloodtest)/sum(x$Acute.LoS),
             trans.with.prehgb80.per1000patient = sum(x$N.pre.tran.hgb.gt80)/nrow(x)*1000,
             aki.rate = sum(x$aki, na.rm = T)/nrow(x)*100,
             #weekday = mean(x$weekday, na.rm = T),
             #daytime = mean(x$daytime, na.rm = T),
             ave.cost = mean(x$Cost, na.rm = T)
  ))
all.name <- fread("H:/GEMINI/Results/DataSummary/physician_names/complete.name.list/gemini.phy.list.new2.csv")
phy.sum <- merge(phy.sum, all.name[!duplicated(code.new), .(code.new, first.name, last.name)], by.x = "code.new",
                 by.y = "code.new", all.x = T, all.y = F)
table(phy.sum$GIM)
phy.sum$phy.name <- paste(phy.sum$first.name, phy.sum$last.name)
fwrite(phy.sum, "C:/Users/guoyi/Desktop/to.adm/phy.summary.csv")

#add phy name to cohort
# all.name <- fread("H:/GEMINI/Results/DataSummary/physician_names/complete.name.list/gemini.phy.list.csv")
# cohort <- merge(cohort, all.name[!duplicated(code.new), .(code.new, first.name, last.name)], 
#                 by.x = "mrp.code.new", by.y = "code.new", all.x = T, all.y = F)
# table(cohort$GIM)
# cohort$phy.name <- paste(cohort$first.name, cohort$last.name)
# fwrite(cohort, "C:/Users/guoyi/Desktop/to.adm/cohort.new.withname.csv")
# 
exp(fit$residuals^2/(-2))[1]
check$read.in.30[1] - check$adj.read.in.30[1]

plot.phy <- function(data, title, xlab = "Physician", 
                     ylab, nextreme = 1,
                     ave.fun, xstart = -2, digit = 1){
 # data <- hide_site2(data)
  df <- ddply(data, ~physician, .fun = ave.fun) %>% data.table
  digitform <- paste("%.", digit, "f", sep = "")
  names(df)[4] <- "phy.ave"
  site.mean <- ddply(data[physician%in%df$physician], ~Institution.Number, .fun = ave.fun)
  names(site.mean)[4] <- "site.mean"
  df <- merge(df, site.mean[,c(1,4)], by.x = "site", by.y = "Institution.Number")
  for(i in unique(df$site)){
    df[site ==i, phy := as.numeric(factor(physician, levels = physician[order(phy.ave, decreasing = T)]))]
  }
  p <- ggplot(df, aes(phy, phy.ave, fill = site)) + 
    geom_bar(stat = "identity", width = 0.5) + 
    geom_line(aes(x = phy, y = site.mean), alpha = 0.5,
              linetype = 2, size = 0.5) + 
    facet_grid(.~site, scales = "free_x") + 
    ggtitle(title) +
    xlab(xlab) +
    ylab(ylab) +
    expand_limits(x = xstart) +
    theme(plot.title = element_text(hjust = 0.5),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(),
          legend.position="none")
  del <- ddply(df, ~site, summarise,
               site.ave = sum(phy.ave * N)/sum(N),
               #site.ave = mean(phy.ave), # for patient sum only
               xm = max(phy),
               ymi = quantile(phy.ave, probs = 0.1),
               yma = quantile(phy.ave, probs = 0.9),
               yav = quantile(phy.ave, probs = 0.5),
               ydiff = sprintf(digitform , yma - ymi))
  ave.shift <- max(df$phy.ave) * 0.02
  p <- p + geom_errorbar(data = del, aes(x = xstart/2, y = NULL,ymin = ymi, ymax = yma), 
                         alpha = 0.3, width = 2) + 
    # plot the 25% - 75% range
    geom_rect(data = del, aes(x = NULL, y = NULL, xmin = xstart/2 - 1, xmax =  xstart/2 +1, 
                              ymin = yav-0.5*ave.shift, ymax = yav+0.5*ave.shift), fill = "#EEEEEE") + 
    geom_text(data = del, aes(x = xstart/2, y = yav, label = ydiff), size = 3) +
    # plot the label for average
    geom_text(data = del, aes(x = xm-2, y = site.ave + ave.shift, 
                              label = sprintf(digitform , site.ave)),
              size = 3) 
  print(p)
}


setwd("C:/Users/guoyi/Desktop/to.adm/figures.v4/no_sitename")
setwd("C:/Users/guoyi/Desktop/to.adm/figures.v4/with_sitename")
N.patient <- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = nrow(x)/length(unique(x$physician)))
}
png("number.of.patient.png", res = 250, width = 2000, height = 1200)
plot.phy(cohort,  "Number of Patients", ylab = "Number of Patients", 
         ave.fun = N.patient, xstart = -4, digit = 0)
dev.off()


# ---------------------- average length-of-stay --------------------------------
ave.los <- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = mean(x$Acute.LoS, na.rm = T))
}
png("ave.los_overall.png", res = 250, width = 2000, height = 1200)
plot.phy(cohort,  "Average Acute Length-of-Stay (Days)", ylab = "Average Length-of-Stay (Days)", ave.fun = ave.los)
dev.off()

# ---------------------------average alc days ----------------------------------
ave.alc <- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = mean(x$Number.of.ALC.Days, na.rm = T))
}
png("ave.alc_overall.png", res = 250, width = 2000, height = 1200)
plot.phy(cohort, "Average ALC Days", ylab = "Average ALC Days", ave.fun = ave.alc)
dev.off()

# -------------------------------- with ALC ------------------------------------
alc.rate <- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = mean(x$with.ALC, na.rm = T)*100)
}
png("alc.rate.png", res = 250, width = 2000, height = 1200)
plot.phy(cohort, "ALC Rate (%)", ylab = "ALC Rate (%)", ave.fun = alc.rate, digit = 1)
dev.off()

# ----------------------------- readmission rate -------------------------------
read.rate <- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = sum(x$read.in.30, na.rm = T)/sum(!is.na(x$read.in.30), na.rm = T)*100)
}
png("re.admission.rate_overall.png", res = 250, width = 2000, height = 1200)
plot.phy(cohort, "Re-admission (within 30 days) Rate (%)", ylab = "Re-admission (within 30 days) Rate (%)", ave.fun = read.rate)
dev.off()

# ----------------------------- mortality rate ---------------------------------
mort <- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = mean(x$death==T, na.rm = T)*100)
}
png("inhospital.mortality_new.png", res = 250, width = 2000, height = 1200)
plot.phy(cohort, "In-hospital Mortality (%)", ylab = "In-hospital Mortality (%)", ave.fun = mort)
dev.off()

# ------------------------------ short admission rate --------------------------
shortadm <- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = mean(x$Acute.LoS < 2, na.rm = T)*100)
}
png("short.adm.rate_overall.png", res = 250, width = 2000, height = 1200)
plot.phy(cohort, "Short-Admission (<48h) Rate (%)", ylab = "Short-Admission (<48h) Rate (%)", ave.fun = shortadm, xstart = -4)
dev.off()

# ----------------------------- Rate of ICU admission --------------------------
icuadm<- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = mean(x$SCU.adm, na.rm = T)*100)
}
png("ICU.uti_overall.png", res = 250, width = 2000, height = 1200)
plot.phy(cohort[str_sub(EncID.new,1,2)!="15"], "ICU Utilization Rate(%)", 
         ylab = "ICU Utilization Rate(%)", ave.fun = icuadm, xstart = -4)
dev.off()
# ----------------------------CBC and Electrolyte Tests-------------------------
ave.bloodtest <- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = sum(x$n.bloodtest)/sum(x$Acute.LoS))
}
png("n.bloodtest_overall.png", res = 250, width = 2000, height = 1200)
plot.phy(cohort[str_sub(EncID.new, 1, 2)%in%c("11","12","13", "14")],  
         "Number of CBC and Electrolyte Tests \n per Patient Day", 
         ylab = "Number of CBC and Electrolyte Tests \n per Patient Day", ave.fun = ave.bloodtest)
dev.off()

# -------------------------Transfusion with pre hgb > 80 -----------------------
num.pre.trans.hgb70 <- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = sum(x$N.pre.tran.hgb.gt70)/nrow(x)*1000)
}
png("number.of.rbc.trans.with.prehbg.gt70.png", res = 250, width = 2000, height = 1200)
plot.phy(cohort[str_sub(EncID.new, 1, 2)%in%c("11","12","13", "14")], 
         "Number of RBC Transfusions \n with pre-Transfusion Hgb > 70 \n per 1000 Patient per Doctor", 
         ylab = "Number of RBC Transfusions \n with pre-Transfusion Hgb > 70 \n per 1000 Patient per Doctor", 
         ave.fun = num.pre.trans.hgb70, xstart = -3)
dev.off()

# ----------------------------------- AKI --------------------------------------
aki.rate <- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = sum(x$aki, na.rm = T)/nrow(x)*100)
}
png("aki.rate.overall.png", res = 250, width = 2000, height = 1200)
plot.phy(cohort[str_sub(EncID.new, 1, 2)%in%c("11","12","13", "14")],  
         "Proportion of Patients with Hospital-Acquired AKI (%)", 
         ylab = "Proportion of Patients with Hospital-Acquired AKI (%)", ave.fun = aki.rate)
dev.off()
# ----------------------Number of CT MRI US ------------------------------------
ctmrius <- fread("C:/Users/guoyi/Desktop/to.adm/n.ctmrius.csv")
ctmrius$EncID.new <- as.character(ctmrius$EncID.new)
cohort <- merge(cohort, ctmrius, by = "EncID.new", all.x = T, all.y = F)
cohort[is.na(N.rad), N.rad:= 0]

n.rad <- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = sum(x$N.rad)/nrow(x))
}
png("n.ctmrius.png", res = 250, width = 2000, height = 1200)
plot.phy(cohort[str_sub(EncID.new, 1, 2)%in%c("11","12","13", "14")],  
         "Number of Radiology Tests (CT/MRI/Ultrasound) per Patient per Doctor", 
         ylab = "Number of Radiology Tests (CT/MRI/Ultrasound) \nper Patient per Doctor", ave.fun = n.rad)
dev.off()

# --------------------------------- Adjusted LOS -------------------------------
library(lme4)
for(i in unique(cohort$Institution.Number)){
  fit.los <- lm(Acute.LoS ~ Age + Gender + Charlson.Comorbidity.Index, #+ fiscal.year, 
          data = cohort[Institution.Number==i])
  cohort$adj_acute_los[cohort$Institution.Number==i] <- predict(fit.los, newdata = data.frame(
    Age = median(cohort$Age),
    Gender = "F",
    Charlson.Comorbidity.Index = median(cohort$Charlson.Comorbidity.Index),
    fiscal.year = 2015
  )) + fit.los$residuals
  print(i)
}
cor.test(cohort$Acute.LoS, cohort$adj_acute_los, method = "spearman")
adj.los <- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = mean(x$adj_acute_los, na.rm = T))
}
png("adjusted_ave_acute_los.png", res = 250, width = 2000, height = 1200)
plot.phy(cohort,  "Average Adjusted Acute Length-of-Stay (Days)", 
         ylab = "Average Adjusted Length-of-Stay (Days)", ave.fun = adj.los)
dev.off()

# --------------------------------- Cost ---------------------------------------
ave.cost <- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = mean(x$Cost, na.rm = T))
}

png("ave.cost.png", res = 250, width = 2200, height = 1200)
plot.phy(cohort,  "Average Cost ($)", 
         ylab = "Average Cost ($)", ave.fun = ave.cost, xstart = -5, digit = 0)
dev.off()

# ------------------------------ Adjusted Cost ---------------------------------
library(lme4)
for(i in unique(cohort$Institution.Number)){
  fit <- lm(Cost ~ Age + Gender + Charlson.Comorbidity.Index + fiscal.year, 
            data = cohort[Institution.Number==i,])
  cohort$adj_cost[!is.na(cohort$Cost)&cohort$Institution.Number==i] <- 
    predict(fit, newdata = data.frame(
    Age = median(cohort$Age),
    Gender = "F",
    Charlson.Comorbidity.Index = median(cohort$Charlson.Comorbidity.Index),
    fiscal.year = 2015
  )) + fit$residuals
  print(i)
}
cor.test(cohort$Cost, cohort$adj_cost)
adj.cost <- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = mean(x$adj_cost, na.rm = T))
}
png("adjusted_cost.png", res = 250, width = 2200, height = 1200)
plot.phy(cohort,  "Average Adjusted Cost ($)", 
         ylab = "Average Adjusted Cost ($)", ave.fun = adj.cost, xstart = -5, digit = 0)
dev.off()


# Correlation between adjusted and unadjusted variables
phy.ave <- ddply(cohort, ~ physician, summarize, 
                 site = Institution.Number[1],
                 ave.los = mean(Acute.LoS),
                 ave.adj.los = mean(adj_acute_los),
                 ave.cost = mean(Cost, na.rm = T),
                 ave.adj.cost = mean(adj_cost, na.rm = T))
ddply(phy.ave, ~ site, summarise,
      los.corr = cor(ave.los, ave.adj.los),
      los.corr.p = cor.test(ave.los, ave.adj.los)$p.value,
      cost.corr = cor(ave.cost, ave.adj.cost),
      cost.corr.p = cor.test(ave.cost, ave.adj.cost)$p.value) %>%
  fwrite("C:/Users/guoyi/Desktop/to.adm/correlation.after.adjustment.csv")

setwd("C:/Users/guoyi/Desktop/to.adm/figures.v4/adjustment_comparison")
png("los_adjustement_comparison.png", res = 250, width = 2000, height = 1200)
ggplot(phy.ave, aes(ave.los, ave.adj.los, color = site)) + geom_point() +
  geom_smooth(method = "lm") + xlab("Average Acute Length-of-Stay (Days)") +
  ylab("Average Adjusted Acute Length-of-Stay (Days)") + theme_bw()
dev.off()

png("cost_adjustement_comparison.png", res = 250, width = 2000, height = 1200)
ggplot(phy.ave, aes(ave.cost, ave.adj.cost, color = site)) + geom_point() +
  geom_smooth(method = "lm") + xlab("Average Cost ($)") +
  ylab("Average Adjusted Cost ($)") + theme_bw()
dev.off()







ggplot(phy.sum, aes(x = ave.cost, y = mortality, color = site)) +
  geom_jitter() + theme_bw() +
  xlab("Average Cost ($)") + ylab("Mortality (%)")



# total direct cost instead of RIW cost
find_cost <- function(){
  smh.adm <- readg(smh, adm)
  sbk.adm <- readg(sbk, adm)
  uhn.adm <- readg(uhn, adm)
  msh.adm <- readg(msh, adm)
  thp.adm <- readg(thp, adm)
  TDC <- rbind(smh.adm[, .(EncID.new, Total.Direct.Cost)],
               sbk.adm[, .(EncID.new, Total.Direct.Cost)],
               uhn.adm[, .(EncID.new, Total.Direct.Cost)],
               thp.adm[, .(EncID.new, Total.Direct.Cost)])
  return(TDC)
}

cohort <- merge(cohort, find_cost(), by = "EncID.new", all.x = T, all.y = F)

# ------------------------------- Total Direct Cost ----------------------------
ave.tdc <- function(x){
  data.frame(N = nrow(x),
             site = x$Institution.Number[1],
             ave = mean(x$Total.Direct.Cost, na.rm = T))
}
cohort[, Total.Direct.Cost:= as.numeric(Total.Direct.Cost)]
png("ave.total.direct.cost.png", res = 250, width = 2200, height = 1200)
plot.phy(cohort[Institution.Number!="SHS"],  "Average Total Direct Cost ($)", 
         ylab = "Average Total Direct Cost ($)", ave.fun = ave.tdc, xstart = -5, digit = 0)
dev.off()

setwd("C:/Users/guoyi/Desktop/to.adm/figures.v4/no_sitename")
setwd("C:/Users/guoyi/Desktop/to.adm/figures.v4/with_sitename")
