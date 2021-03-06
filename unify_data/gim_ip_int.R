library(gemini)
lib.pa()
#===================GIM_IP_Intervention ========================================
#------------available for SMH, SBK, UHN, THP, MSh -----------------------------
rm(list = ls())
smh <- readg(smh, ip_int)
sbk <- readg(sbk, ip_int)
uhn <- readg(uhn, ip_int)
msh <- readg(msh, ip_int)
thp <- readg(thp, ip_int)

names(smh)[5:8] <- c("Procedure.Location", "Intervention.Location.Attribute",
                     "Intervention.Status.Attribute", 
                     "Intervention.Extent.Attribute")

names(sbk)[1:8] <- names(smh)[1:8]
sbk <- sbk[!(is.na(EncID.new)&is.na(Intervention.Occurrence))]
names(uhn) <- names(smh)
names(msh)[1:9] <- names(smh)
names(thp) <- names(smh)

write.csv(smh, "H:/GEMINI/Data/SMH/CIHI/smh.ip_int.nophi.csv",
          row.names = F, na = "")
write.csv(sbk, "H:/GEMINI/Data/SBK/CIHI/sbk.ip_int.nophi.csv",
          row.names = F, na = "")
write.csv(uhn, "H:/GEMINI/Data/UHN/CIHI/uhn.ip_int.nophi.csv",
          row.names = F, na = "")
msh <- msh[!duplicated(msh)]
write.csv(msh, "H:/GEMINI/Data/MSH/CIHI/msh.ip_int.nophi.csv",
          row.names = F, na = "")
write.csv(thp, "H:/GEMINI/Data/THP/CIHI/thp.ip_int.nophi.csv",
          row.names = F, na = "")
names(smh)
names(sbk)
names(uhn)
names(msh)
names(thp)

apply(smh, MARGIN = 2, FUN = function(x)sum(is.na(x)))
apply(sbk, MARGIN = 2, FUN = function(x)sum(is.na(x)))
apply(uhn, MARGIN = 2, FUN = function(x)sum(is.na(x)))
apply(msh, MARGIN = 2, FUN = function(x)sum(is.na(x)))
apply(thp, MARGIN = 2, FUN = function(x)sum(is.na(x)))


sbk.check <- sbk[is.na(Intervention.Occurrence)]
apply(sbk.check, MARGIN = 2, FUN = function(x)sum(is.na(x)))

sbk.check.noenc <- sbk[is.na(EncID.new)]


uhn.check <- uhn[!is.na(Intervention.Occurrence)&is.na(Intervention.Code)]


msh.check <- msh[!is.na(Intervention.Occurrence)&is.na(Intervention.Code)]





#----------------Dec 1 2016 ----------------------------------------------------
#--------------- data format ---------------------------------------------------
rm(list = ls())
smh <- readg(smh, ip_int)
sbk <- readg(sbk, ip_int)
uhn <- readg(uhn, ip_int)
msh <- readg(msh, ip_int)
thp <- readg(thp, ip_int)

head(smh)
head(sbk)
head(uhn)
head(msh)
head(thp)

thp$Intervention.Code <- str_replace_all(thp$Intervention.Code, "[:punct:]", "")
write.csv(thp, "H:/GEMINI/Data/THP/CIHI/thp.ip_int.nophi.csv",
          row.names = F, na = "")


#------------------- Jan 13 2017 -----------------------------------------------
# ------------------------ create merged file ----------------------------------
rm(list = ls())

smh.intip <- readg(smh, ip_int)
sbk.intip <- readg(sbk, ip_int)
uhn.intip <- readg(uhn, ip_int)
msh.intip <- readg(msh, ip_int)
thp.intip <- readg(thp, ip_int)
msh.intip[,Site:=NULL]
int.ip <- rbind(smh.intip,
                sbk.intip,
                uhn.intip,
                msh.intip,
                thp.intip)
int.ip <- int.ip[!is.na(Intervention.Code)]
fwrite(int.ip, "H:/GEMINI/Data/GEMINI/gim.ip_int.csv")
msh.intip[is.na(Intervention.Code)&!is.na(Intervention.Occurrence)]
228/34245




# --------------- missingness of intervention date time ------------------------
msh.intip <- msh.intip %>% arrange(EncID.new, Intervention.Occurrence) %>% 
  select(EncID.new, Intervention.Occurrence, Intervention.Code,
         Intervention.Episode.Start.Date, Intervention.Episode.Start.Time) %>%
  filter(!is.na(Intervention.Occurrence)& (!is.na(Intervention.Code))) %>%
  data.table
ex <- readg(gim, notgim)
msh.intip <- msh.intip[!EncID.new%in%ex$EncID.new]

length(unique(msh.intip$EncID.new))
no.dt <- msh.intip[is.na(Intervention.Episode.Start.Date)]
with.dt <- msh.intip[!is.na(Intervention.Episode.Start.Date)]

no.dt[!EncID.new%in%with.dt$EncID.new, EncID.new] %>% unique %>% length 

ddply(msh.intip, ~EncID.new, summarize,
      n.int = length(Intervention.Code),
      n.missingdate = sum(is.na(Intervention.Episode.Start.Date)),
      n.no.date.before = min(c(min(which(!is.na(Intervention.Episode.Start.Date)))-1),
      length(Intervention.Episode.Start.Date)))-> count
sum(count$n.int==count$n.missingdate)
sum(count$n.no.date.before)/sum(count$n.int)




uhn.intip <- uhn.intip %>% arrange(EncID.new, Intervention.Occurrence) %>% 
  select(EncID.new, Intervention.Occurrence, Intervention.Code,
         Intervention.Episode.Start.Date, Intervention.Episode.Start.Time) %>%
  filter(!is.na(Intervention.Occurrence)& (!is.na(Intervention.Code))) %>%
  data.table
ex <- readg(gim, notgim)
uhn.intip <- uhn.intip[!EncID.new%in%ex$EncID.new]

length(unique(uhn.intip$EncID.new))
no.dt <- uhn.intip[is.na(Intervention.Episode.Start.Date)]
with.dt <- uhn.intip[!is.na(Intervention.Episode.Start.Date)]

no.dt[!EncID.new%in%with.dt$EncID.new, EncID.new] %>% unique %>% length 

ddply(uhn.intip, ~EncID.new, summarize,
      n.int = length(Intervention.Code),
      n.missingdate = sum(is.na(Intervention.Episode.Start.Date)),
      n.no.date.before = min(c(min(which(!is.na(Intervention.Episode.Start.Date)))-1),
                             length(Intervention.Episode.Start.Date)))-> count
sum(count$n.int==count$n.missingdate)
sum(count$n.no.date.before)/sum(count$n.int)



#------------------- 2017-04-19 ------------------------------------------------
# fix intervention date for uhn
uhn.intip <- readg(uhn, ip_int)[!is.na(Intervention.Occurrence)] %>% 
  arrange(EncID.new, as.integer(Intervention.Occurrence)) %>% data.table
uhn.intip.old <- uhn.intip
for(i in 2:48564){
  if(!is.na(uhn.intip$Intervention.Episode.Start.Date[i])){
    last.enc <- uhn.intip$EncID.new[i]
    last.date <- uhn.intip$Intervention.Episode.Start.Date[i]
  }else{
    if(uhn.intip$EncID.new[i]==last.enc)
      uhn.intip$Intervention.Episode.Start.Date[i] <- last.date
  }
}

fwrite(uhn.intip, "H:/GEMINI/Data/UHN/CIHI/uhn.ip_int.nophi.csv")
# ------------------------ create merged file ----------------------------------
rm(list = ls())

smh.intip <- readg(smh, ip_int)
sbk.intip <- readg(sbk, ip_int)[EncID.new!="12NA"]
uhn.intip <- readg(uhn, ip_int)
msh.intip <- readg(msh, ip_int)
thp.intip <- readg(thp, ip_int)
msh.intip[,Site:=NULL]
apply(smh.intip, MARGIN = 2, FUN = function(x)sum(is.na(x)))
apply(sbk.intip, MARGIN = 2, FUN = function(x)sum(is.na(x)))
apply(uhn.intip, MARGIN = 2, FUN = function(x)sum(is.na(x)))
apply(msh.intip, MARGIN = 2, FUN = function(x)sum(is.na(x)))
apply(thp.intip, MARGIN = 2, FUN = function(x)sum(is.na(x)))
smh.intip[, Intervention.Episode.Start.Date:= mdy(Intervention.Episode.Start.Date)]
sbk.intip[, Intervention.Episode.Start.Date := mdy(Intervention.Episode.Start.Date)]
sbk.intip[!is.na(Intervention.Episode.Start.Time), 
          Intervention.Episode.Start.Time := paste(Intervention.Episode.Start.Time, ":00", sep = "")]
uhn.intip[,Intervention.Episode.Start.Date:= ymd(Intervention.Episode.Start.Date)]
msh.intip[, Intervention.Episode.Start.Date:= mdy(Intervention.Episode.Start.Date)]
thp.intip[!is.na(Intervention.Episode.Start.Date)| !is.na(Intervention.Episode.Start.Time)] -> check
thp.intip[, Intervention.Episode.Start.Date:= ymd(Intervention.Episode.Start.Date)]
thp.intip[!is.na(Intervention.Episode.Start.Time), 
          Intervention.Episode.Start.Time:= 
            paste(str_sub(Intervention.Episode.Start.Time, 1, 
                          nchar(Intervention.Episode.Start.Time)-2),
                  ":", str_sub(Intervention.Episode.Start.Time, -2, -1), sep = "")]

int.ip <- rbind(smh.intip,
                sbk.intip,
                uhn.intip,
                msh.intip,
                thp.intip) %>% unique
int.ip <- int.ip[!(is.na(Intervention.Code)&is.na(Intervention.Occurrence))]
#ex <- readg(gim, notgim)
#int.ip <- int.ip[!EncID.new%in%ex$EncID.new]
int.ip <- int.ip %>% arrange(EncID.new, as.integer(Intervention.Occurrence)) %>% data.table
int.ip[EncID.new%in%int.ip[is.na(Intervention.Episode.Start.Date), EncID.new]] -> check
int.ip[duplicated(int.ip[,.(EncID.new, Intervention.Occurrence)])]
fwrite(int.ip, "H:/GEMINI/Data/GEMINI/gim.ip_int.csv")

library(DBI)
setwd("C:/Users/guoyi/sqlite")
con = dbConnect(RSQLite::SQLite(), dbname = "gemini.db")
dbWriteTable(con, "ip_int", int.ip)
dbDisconnect(con)
