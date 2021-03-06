# ------------------------- final plots ----------------------------------------
library(gemini)
library(lme4)
lib.pa()

cohort <- fread("C:/Users/guoyi/Desktop/to.adm/cohort.csv")
all.name <- fread("C:/Users/guoyi/Desktop/to.adm/all.name.csv")
cohort <- cohort[physician!="thp-m-708"]
# cohort[Institution.Number=="msh", Institution.Number:="A"]
# cohort[Institution.Number=="sbk", Institution.Number:="B"]
# cohort[Institution.Number=="smh", Institution.Number:="C"]
# cohort[Institution.Number=="thp-c", Institution.Number:="D"]
# cohort[Institution.Number=="thp-m", Institution.Number:="E"]
# cohort[Institution.Number=="uhn-general", Institution.Number:="F"]
# cohort[Institution.Number=="uhn-western", Institution.Number:="G"]
n.pat <- cohort[,.N, by = physician]
cohort <- cohort[physician%in%n.pat[N>=100, physician]]
cohort <- cohort[LOS.without.ALC<=30]




plot.phy.adj <- function(data, title, xlab = "physician", 
                     ylab, nextreme = 1,
                     ave.fun, xstart = -2){
  df <- ddply(data, ~physician, .fun = ave.fun) %>% data.table
  names(df)[5] <- "phy.ave"
  mod <- lm(phy.ave ~ ave.los, df)
  pred <- predict(mod, newdata = data.frame(ave.los = mean(df$ave.los))) + mod$residuals
  df$phy.ave <- pred
  site.mean <- ddply(df, ~site, summarize,
                     site.mean = mean(phy.ave))
  df <- merge(df, site.mean, by = "site")
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
               xm = max(phy),
               ymi = quantile(phy.ave, probs = 0.1),
               yma = quantile(phy.ave, probs = 0.9),
               yav = quantile(phy.ave, probs = 0.1)*0.5 + quantile(phy.ave, probs = 0.9)*0.5,
               ydiff = sprintf("%.1f", yma - ymi))
  ave.shift <- max(df$phy.ave) * 0.02
  p <- p + geom_errorbar(data = del, aes(x = xstart/2, y = NULL,ymin = ymi, ymax = yma), 
                         alpha = 0.3, width = 2) + 
    # plot the 10% - 90% range
    geom_rect(data = del, aes(x = NULL, y = NULL, xmin = xstart/2 - 1, xmax =  xstart/2 +1, 
                              ymin = yav-0.5*ave.shift, ymax = yav+0.5*ave.shift), fill = "#EEEEEE") + 
    geom_text(data = del, aes(x = xstart/2, y = yav, label = ydiff), size = 3) +
    # plot the label for average
    geom_text(data = del, aes(x = xm-2, y = site.ave + ave.shift, 
                              label = sprintf("%.1f", site.ave)),
              size = 3) 
  print(p)
}



setwd("C:/Users/guoyi/Desktop/to.adm/to.gemini.investigators")
## --------------------------- adjusted AKI ------------------------------------
inc <- fread("C:/Users/guoyi/Desktop/to.adm/kdigo.csv")
cohort$aki <- cohort$EncID.new%in%inc[KDIGO%in%c("2", "3"), EncID.new]
aki.rate <- function(x){
  data.frame(N = nrow(x),
             ave.los = mean(x$LOS.without.ALC),
             site = x$Institution.Number[1],
             ave = sum(x$aki, na.rm = T)/nrow(x)*100)
}
png("aki.rate.adjusted.by.los.png", res = 250, width = 2000, height = 1200)
plot.phy.adj(cohort[str_sub(EncID.new, 1, 2)%in%c("11","12","13", "14")],  
         "Proportion of Patients with Hospital-Acquired AKI per Doctor (%)", 
         ylab = "Proportion of Patients with Hospital-Acquired AKI per Doctor (%)", ave.fun = aki.rate)
dev.off()


# --------------------------- adjusted imaging ---------------------------------
ctmrius <- fread("C:/Users/guoyi/Desktop/to.adm/n.ctmrius.csv")
ctmrius$EncID.new <- as.character(ctmrius$EncID.new)
cohort$EncID.new <- as.character(cohort$EncID.new)
cohort <- merge(cohort, ctmrius, by = "EncID.new", all.x = T, all.y = F)
cohort[is.na(N.rad), N.rad:= 0]

n.rad <- function(x){
  data.frame(N = nrow(x),
             ave.los = mean(x$LOS.without.ALC), 
             site = x$Institution.Number[1],
             ave = sum(x$N.rad)/nrow(x))
}
png("n.ctmrius.adjusted.by.los.png", res = 250, width = 2000, height = 1200)
plot.phy.adj(cohort[str_sub(EncID.new, 1, 2)%in%c("11","12","13", "14")],  
         "Number of Radiology Tests (CT/MRI/Ultrasound) per Patient per Doctor", 
         ylab = "Number of Radiology Tests (CT/MRI/Ultrasound) \nper Patient per Doctor", ave.fun = n.rad)
dev.off()

getwd()
