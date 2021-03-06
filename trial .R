```{r}

#rm(list = ls()) this command clears your environment
#setwd('C:/Users/Chris/Documents/GitHub/final_project')
#setwd('C:/Users/Chris/Documents/R/col_soc_science')

# calling appropriate packages 

library(foreign) 
library(survey)
library(rockchalk)

# R will crash if a primary sampling unit (psu) has a single observation
# so we set R to produce conservative standard errors instead of crashing
options( survey.lonely.psu = "adjust" )

#import data from the ANES
anes <- read.dta("anes_timeseries_2012_Stata12.dta")

# to delete ages that do not fit into any of our generations, we delete the unnecesary ages
#table(anes$dem_age_r_x) #age
anes <- anes[!(anes$dem_age_r_x <= -2 | anes$dem_age_r_x >= 88),] 

#We renamed the levels pertaining to if someone voted and then we coded them to be binary, keeping only Yes/no, changes the variable to a numeric dummy, with 1 as "Yes"
#table(anes$postvote_rvote)
levels(anes$postvote_rvote) <- c("Refused", "Don't know", "Incomplete", "Nonresponsive", "Missing", "Inapplicable", "No", "No", "No", "Yes")
anes <- anes[(anes$postvote_rvote == "Yes" | anes$postvote_rvote == "No"),] 
anes$postvote_rvote <-  droplevels(anes$postvote_rvote)
anes$postvote_rvote <- as.numeric(anes$postvote_rvote) 
anes$postvote_rvote[anes$postvote_rvote == 1] <- 0
anes$postvote_rvote[anes$postvote_rvote == 2] <- 1

#We renamed the levels pertaining to education and recoded them as numeric ranging from 
#1-5 (1 being below high school) and 5 (graduate education)
#table(anes$dem_edugroup_x) #education
levels(anes$dem_edugroup_x) <- c("Refused", "Don't know", "Data missing", "Below high school", "High school", "Some post-high", "Bachelor", "Graduate") 
anes <- anes[(anes$dem_edugroup_x == "Below high school" | 
                anes$dem_edugroup_x == "High school" | 
                anes$dem_edugroup_x == "Some post-high" | 
                anes$dem_edugroup_x == "Bachelor" |
                anes$dem_edugroup_x == "Graduate"),] #keeps only these groups
anes$dem_edugroup_x <-  droplevels(anes$dem_edugroup_x)
anes$dem_edugroup_x <- as.numeric(anes$dem_edugroup_x)

#We renamed the labels pertaining to race, removed all missing data, and created dummies of black
#and hispanic
#table(anes$dem_raceeth_x) #race
levels(anes$dem_raceeth_x) <- c("Data missing", "White", "Black", "Asian" , "Native American or Alaska Native", "Hispanic","Other") 
anes <- anes[!(anes$dem_raceeth_x == "Data missing"),] 
anes$black <- anes$dem_raceeth_x == "Black"
anes$black <- as.numeric(anes$black)
anes$hispanic <- anes$dem_raceeth_x == "Hispanic"
anes$hispanic <- as.numeric(anes$hispanic)


#We renamed the labels pertaining to voting in the 2008 election, dropped NA ones, and recoded #the remaining yes and no to be 1 or 0. 
#table(anes$interest_voted2008) #voting in past election (2008)
levels(anes$interest_voted2008) <- c("Refused", "Don't know", "Yes", "No")
anes <- anes[(anes$interest_voted2008 == "Yes" | anes$interest_voted2008 == "No"),] 
anes$interest_voted2008 <-  droplevels(anes$interest_voted2008)
anes$interest_voted2008 <- as.numeric(anes$interest_voted2008) 
anes$interest_voted2008[anes$interest_voted2008 == 2] <- 0

#We created a dummy variable for gender, with 1 as "female"
#table(anes$gender_respondent_x) #gender
anes$female <- anes$gender_respondent_x == "2. Female" #creates dummy gender #variable
anes$female <- as.numeric(anes$female) 

#table(anes$inc_incgroup_pre) #income groups
anes <- anes[!(anes$inc_incgroup_pre == "-9. Refused"),] 
anes <- anes[!(anes$inc_incgroup_pre == "-8. Don't know"),] 
anes <- anes[!(anes$inc_incgroup_pre == "-2. Missing; IWR mistakenly entered '2' in place of DK code for total income"),] 
anes$inc_incgroup_pre <- combineLevels(anes$inc_incgroup_pre, c("01. Under $5,000", "02. $5,000-$9,999", "03. $10,000-$12,499", "04. $12,500-$14,999", "05. $15,000-$17,499", "06. $17,500-$19,999"), "Under 20k")
anes$inc_incgroup_pre <- combineLevels(anes$inc_incgroup_pre, c("07. $20,000-$22,499", "08. $22,500-$24,999", "09. $25,000-$27,499", "10. $27,500-$29,999", "11. $30,000-$34,999", "12. $35,000-$39,999", "13. $40,000-$44,999"), "20k-45k")
anes$inc_incgroup_pre <- combineLevels(anes$inc_incgroup_pre, c("14. $45,000-$49,999", "15. $50,000-$54,999", "16. $55,000-$59,999", "17. $60,000-$64,999"), "45k-65k")
anes$inc_incgroup_pre <- combineLevels(anes$inc_incgroup_pre, c("18. $65,000-$69,999", "19. $70,000-$74,999", "20. $75,000-$79,999", "21. $80,000-$89,999"), "65k-90k")
anes$inc_incgroup_pre <- combineLevels(anes$inc_incgroup_pre, c("22. $90,000-$99,999", "23. $100,000-$109,999", "24. $110,000-$124,999"), "90k-125k")
anes$inc_incgroup_pre <- combineLevels(anes$inc_incgroup_pre, c("25. $125,000-$149,999", "26. $150,000-$174,999", "27. $175,000-$249,999"), "125-250k")
levels(anes$inc_incgroup_pre) <- c("Under 20k", "20k-45k", "45k-65k", "65k-90k", "90k-125k", "125-250k", "28. $250,000 or more")
anes$income <- as.numeric(anes$inc_incgroup_pre)


#To simplify our task we create a smaller data set that includes all relevant variables
#, which are listed below the code. 

anes_small <- data.frame(anes$caseid, anes$dem_age_r_x, anes$dem_edugroup_x, anes$black, anes$hispanic, anes$income, anes$female, anes$interest_voted2008, anes$postvote_rvote, anes$weight_full, anes$psu_full, anes$strata_full)

# We named the variables so they are very easy to understand 
colnames(anes_small) <- c("caseID", "age", "education", "black","hispanic", "income", "female", "vote_2008", "vote_2012", "weights", "psu", "strata" )

```

Creating the age-band subsets from the smaller ANES data set that contains only 
variables of interest.

```{r}

anes_genY <- subset(anes_small, anes$dem_age_r_x > 17 & anes$dem_age_r_x < 33) 
#creates Millennial subset 
anes_genX <- subset(anes_small, anes$dem_age_r_x > 32 & anes$dem_age_r_x < 48) 
#creates Generation X subset 
anes_boomer <- subset(anes_small, anes$dem_age_r_x > 47 & anes$dem_age_r_x < 67) 
#creates Baby Boomer subset 
anes_silent <- subset(anes_small, anes$dem_age_r_x > 66 & anes$dem_age_r_x < 88) 
#creates Silent Generation subset

#set up an objects to run with the logit models that allow for results to be 
#statistically representative of the population through weighting 

ANESdesign_genY <- svydesign(~psu ,  strata = ~strata , data = anes_genY , weights = ~weights, variables = NULL, nest = TRUE)

ANESdesign_genX <- svydesign(~psu ,  strata = ~strata , data = anes_genX , weights = ~weights, variables = NULL, nest = TRUE)

ANESdesign_boomer <- svydesign(~psu ,  strata = ~strata , data = anes_boomer, weights = ~weights, variables = NULL, nest = TRUE)

ANESdesign_silent <- svydesign(~psu ,  strata = ~strata , data = anes_silent, weights = ~weights, variables = NULL, nest = TRUE)

ANESdesign_overall <- svydesign(~psu ,  strata = ~strata , data = anes_small, weights = ~weights, variables = NULL, nest = TRUE)
```

Running logistic regression model with confidence intervals

```{r}

#Running a logit, generation by generation. Then looking at a summary of the results, follows by looking at and creating an object for the coeffs of the results. Then converting those results to probabilities by exp(ing) them 

#Millennials
M_genY <- svyglm(vote_2012 ~ education + female + vote_2008 + black + hispanic + income, design = ANESdesign_genY, family = "quasibinomial") 
summary(M_genY)
genY_coef <- coef(M_genY)
exp(genY_coef)

#Gen X
M_genX <- svyglm(vote_2012 ~ education + female + vote_2008 + black + hispanic + income, design = ANESdesign_genX, family = "quasibinomial") 
summary(M_genX)
genX_coef <- coef(M_genX)
exp(genX_coef)

#Baby Boomers
M_boomer <- svyglm(vote_2012 ~ education + female + vote_2008 + black + hispanic + income, design = ANESdesign_boomer, family = "quasibinomial") 
summary(M_boomer)
boomer_coef <- coef(M_boomer)
exp(boomer_coef)

#Silent
M_silent <- svyglm(vote_2012 ~ education + female + vote_2008 + black + hispanic + income, design = ANESdesign_silent, family = "quasibinomial") 
summary(M_silent)
silent_coef <- coef(M_silent)
exp(silent_coef)

#overall data set
M <- svyglm(vote_2012 ~ education + female + vote_2008 + black + hispanic + income, design = ANESdesign_overall, family = "quasibinomial") 
summary(M)


newdata1 <- with(anes_small, data.frame(education = 1:5, black = 0, hispanic = 0, income = 4, female = 0, vote_2008 = 1))



#Looking at confidence intervals of parameter point estimates 

confint(M_genY)
confint(M_boomer)
confint(M_genX)

#Giving odds ratios with confidence intervals in a table 

exp(cbind(OR = coef(M_genY), confint(M_genY)))

#For presentation... because stargazer doesn't output to presenation 

Millennials <- exp(cbind(OR = coef(M_genY), confint(M_genY)))
Mill <- data.frame(Millennials)
colnames(Mill) <- c("Predicted Probabilites", "Lower Bound", "Upper Bound") 
library(knitr)

kable(Mill)
kable(Mill, align = 'c', digits = 2, caption = 'Predicted Probabilities for Millennials')

```

Code for stargazer table comparing odds-ratios of coefficients across models. 
Not finished with it yet, though. 
```{r}
library(stargazer)