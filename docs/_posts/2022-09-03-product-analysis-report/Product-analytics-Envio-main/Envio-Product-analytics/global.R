library(readr)
library(ggplot2)
library(tidyverse)
library(lubridate)
library(forecast)
library(fpp2)
library(GGally)
library(caret)
library(dplyr)
library(DT)
library(formattable)
library(fontawesome)
library(shiny)
library(shinydashboard)
library(devtools)
library(ggplot2)
library(magrittr)
library(plotly)
library(purrr)
library(shinyWidgets)
library(tibble)
library(utils)
library(bslib)
library(shiny)
library(shinydashboard)
library(shinycssloaders)
library(shinyanimate)
library(shinydashboardPlus)
library(shinyEffects)
library(shinybusy)
library(shinyBS)
library(ggstatsplot)
library(bfast)
library(broom)
library(MASS)
library(yarrr)
library(modelr)
library(ROCR)



applicant_task <- read_csv("applicant_task.csv")
task_data = applicant_task

#### add conversion column
task_data_convert <- task_data %>%
  mutate(conversion = case_when(
    is_signed == 1 ~ 'convert',
    is_signed == 0 ~ 'not_convert'
  ),
  sales_script_type = case_when(
    sales_script_variant == "a170e8b5b0085420fa52f9f9e1d546f9" ~ 'script_A',
    sales_script_variant == "e908f62885515872936a2bf07e5960a0" ~ 'script_B',
    sales_script_variant == "21790c97eeb6336e5f0fdb9ef4de636f" ~ 'script_C'
  ),
  company_group = case_when(
    company_type == 0 ~ 'company_A',
    company_type == 1 ~ 'company_B',
    company_type == NA ~ 'company_others'
  )) %>%
  mutate(request_created_date = as_datetime(request_created_at),
         first_call_date = as_datetime(first_call),
         first_reach_date = as_datetime(first_reach),
         request_created_year = year(request_created_date),
         request_created_month = month(request_created_date, label = TRUE, abbr = FALSE),
         request_to_1stcall_interval = interval(start = request_created_date, end = first_call_date),
         request_to_1streach_interval = interval(start = request_created_date, end = first_reach_date),
         first_call_to_1streach_interval = interval(start = first_call_date, end = first_reach_date),
         #   request_to_1stcall_timediff = as.period(request_to_1stcall_interval),
         request_to_1stcall_timelength_minutes_ = time_length(request_to_1stcall_interval, unit = 'minute'),
         request_to_1streach_timelength_minutes_ = time_length(request_to_1streach_interval, unit = 'minute'),
         first_call_to_1streach_timelength_minutes_ = time_length(first_call_to_1streach_interval,
                                                                  unit = 'minute'))#%>%



data_convert_date <- task_data_convert%>%
  group_by(request_created_year, request_created_month)%>%
  filter(conversion == 'convert')%>%
  count(conversion)

############################## transform and adjust data  ###############################
############## calendar adjustment
data_convert_ts <- ts(data_convert_date, start = c(2019,12), frequency = 12)
data_convert_transform_ts <- cbind(data_convert_ts,
                                   avgmonthly_convert = data_convert_ts[, 'n'] / monthdays(data_convert_ts[,'request_created_month']))


season_data_convert_transform <- ggseasonplot(data_convert_transform_ts[,'avgmonthly_convert'], year.labels = T, year.label.left = T, year.label.right = T)
# the seasonal plots shows revenue is at its maximum of the year in December
season_data_convert_transform_polar <- ggseasonplot(data_convert_transform_ts[,'avgmonthly_convert'], polar = T)

autocorplot_data_convert_transform <- ggAcf(data_convert_transform_ts[,'avgmonthly_convert']) ## plots of autocorrelation

######### forecasting   #############
## Partition data into training and testing set
train_data_convert_transform_forecast <- window(data_convert_transform_ts, start = c(2019, 12), end = c(2020, 8))
test_data_convert_transform_forecast <- window(data_convert_transform_ts, start = c(2020, 9))

### forecasting method of meanf(), naive(), snaive(), rwf()
data_convert_meanf <- meanf(train_data_convert_transform_forecast[,'avgmonthly_convert'], h = 10)
data_convert_naive <- naive(train_data_convert_transform_forecast[,'avgmonthly_convert'], h = 10)
#(data_convert_snaive <- snaive(train_data_convert_transform_forecast[,'avgmonthly_convert'], h = 10))
data_convert_rwfdrift <- rwf(train_data_convert_transform_forecast[,'avgmonthly_convert'], h = 10, drift = TRUE)
data_convert_rwf <- rwf(train_data_convert_transform_forecast[,'avgmonthly_convert'], h = 10, drift = FALSE)


# plot naive forecast
autoplot(train_data_convert_transform_forecast[,'avgmonthly_convert'], series = "Data") + theme_dark() +
  autolayer(data_convert_naive, series = "Naive", PI = T, alpha = 0.1)

## plot forecast
autoplot(train_data_convert_transform_forecast[,'avgmonthly_convert']) + theme_dark() +
  autolayer(data_convert_meanf, series = "Mean", PI = T, alpha = 0.1) +
  autolayer(data_convert_naive, series = "Naive", PI = T, alpha = 0.1) +
  #  autolayer(rev_snaive, series = "Seasonal Naive", PI = T, alpha = 0.3) +
  autolayer(data_convert_rwf, series = "rwf", PI = T, alpha = 0.1) +
  autolayer(data_convert_rwfdrift, series = "Drift", PI = T, alpha = 0.1) +
  ggtitle("Forecast for Conversion with various forecasting methods") +
  guides(colour = guide_legend(title = "Forecast")) + ylab("Average Monthly Revenue") 

  
##### evaluate forecast accurancy
accur_meanf <- accuracy(data_convert_meanf, test_data_convert_transform_forecast[,'avgmonthly_convert'])
accur_naive <- accuracy(data_convert_naive, test_data_convert_transform_forecast[,'avgmonthly_convert']) ## have a better accuracy compared to other methods
#(accur_snaive <- accuracy(rev_snaive, test_revtransform_forecast[,4]))
accur_rwf <- accuracy(data_convert_rwf, test_data_convert_transform_forecast[, 'avgmonthly_convert'])
accur_drift <- accuracy(data_convert_rwfdrift, test_data_convert_transform_forecast[, 'avgmonthly_convert'])

#### cal residuals for various forecasts
res_meanf <- residuals(data_convert_meanf)
res_naivef <- residuals(data_convert_naive)
#residuals(rev_rwf)
res_drift <- residuals(data_convert_rwfdrift)
#(res_snaive <- residuals(rev_snaive))




## results of residuals
summary(res_meanf)
summary(res_naivef)
#summary(res_snaive)
summary(res_drift)

## checkresiduals for portmanteau test
(data_convert_meanf_checkresiduals <- checkresiduals(data_convert_meanf)) ##  mean model shows an 
## apparent pattern in the residual time series plot, the ACF plot shows several lags exceeding 
## the 95% confidence interval, and the Ljung-Box test has a statistically significant p-value 
## suggesting the residuals are not purely white noise. Thus, not all signals in the data are adequately 
## captured in this model 


data_convert_naive_checkresiduals <- checkresiduals(data_convert_naive)
data_convert_rwfdrift_checkresiduals <- checkresiduals(data_convert_rwfdrift)

# (rev_snaive_checkresiduals <- checkresiduals(rev_snaive))  ## better model than others
# residuals from seasonal naive plot appear to be white noise with no clear pattern
# the lagplot has only a couple of lags that exceeding the 95% confidence interval, 
# residual histogram plot shows approximately normally residuals distribution
# Ljung-Box test results give a p-value of 0.1296 hence residuals have no statistically significant 
# difference at 0.01 and 0.05 sig level compared to white noise. This model captures all (or most) of the available signal in the data.


### time series cross validation 
(error_naive <- tsCV(data_convert_transform_ts[,'avgmonthly_convert'], forecastfunction = naive, h = 10))
(RMSE_naive <- sqrt(mean(error_naive^2, na.rm = T))) ## Naive forecast model has least RMSE hence better accuracy compared to others

# (error_snaive <- tsCV(data_convert_transform_ts[,'avgmonthly_convert'], foarecastfunction = snaive, h = 10))
# (RMSE_snaive <- sqrt(mean(error_snaive^2, na.rm = TRUE)))

error_meanf <- tsCV(data_convert_transform_ts[,'avgmonthly_convert'], forecastfunction = meanf, h = 10)
RMSE_meanf <- sqrt(mean(error_meanf^2, na.rm = TRUE))

summary(RMSE_naive)
#summary(RMSE_snaive)


## for demonstration purposes, we realized that RMSE  of residuals in naive forecast are > RMSE of tsCV with naive forecast
allData_naive_residual <- residuals(naive(data_convert_transform_ts[,'avgmonthly_convert']))
RMSE_naive_allData <- sqrt(mean(allData_naive_residual^2, na.rm = T))

####### Conclusion of models   #####
### snaive forecast model captures all variation in the data hence not statistically diff from white noise
## contary to naive which is does not capture the variability in the data
## Nonetheless, naive forecast has a better accuracy for prediction compared to snaive



########################################################################################################
train_data <- read_csv("train_data.csv")

test_data <- read_csv("test_data.csv")

table(train_data$conversion)
table(test_data$conversion)

train_data$company_group  = factor(x = train_data$company_group, levels = c("Others", "company_A", "company_B"))
levels(train_data$company_group)


train_logit = glm(is_signed ~ company_group + sales_script_type, data = train_data, family = 'binomial')
#summary(train_logit)
#tidy(train_logit)
#exp(coef(train_logit))

#varImp(train_logit)  ## determine which variable is more influencial in determining conversion

#predict(train_logit, test_data, type = 'response')

mcfadden_r2 <- pscl::pR2(train_logit)["McFadden"] ### With McFadden pseudo-r2 value of 0.0005871432, the model has
## very low predictive power which suggest the need to consider inclusion of serveral other better predictors

model1_data <- augment(train_logit) %>% 
  mutate(index = 1:n())

# # ggplot(model1_data, aes(index, .std.resid, color = is_signed)) + 
#   geom_point(alpha = .5) +
#   geom_ref_line(h = 3)

test.predicted.m1 <- predict(train_logit, newdata = test_data, type = "response")

model1 = table(test_data$is_signed, test.predicted.m1 > 0.5) %>% prop.table() %>% round(3)

prediction_data <- test_data %>%
  mutate(model_prediction = ifelse(test.predicted.m1 > 0.5, "convert", "not_convert"))%>%
  mutate(predict_satus = ifelse(conversion == model_prediction, 'Correct prediction', 'Wrong prediction'))

## confusion matrix
confusion_matrix <- table(test_data$conversion, test.predicted.m1 > 0.5)

## The confusion matrix indicated that the model correctly predicted 858 conversions out of a total of 2017,
## which a precision rate of 42.5384% (sensitivity). Also, the model correctly predicted 1119 non-conversions
## out of a total of 1983 non-conversions which is a specificity rate of 56.429%. Given that we are more
## interested in successfully prediction conversion, the predictors in the model are not optimal hence
## the need for better predictors to improve the model. The model needs to be tuned to improve
## sensitivity.
sensitivity_result = (confusion_matrix[1,2] / (confusion_matrix[1,1] + confusion_matrix[1,2])) *100
specificity_result = (confusion_matrix[2,1] / (confusion_matrix[2,1] + confusion_matrix[2,2])) * 100

### AUC is measured on a scale of 0.5 to 1.0 with higher value indicate better classifying model
auc <- prediction(test.predicted.m1, test_data$is_signed) %>%
  performance(measure = "auc") %>%
  .@y.values
auc
### the model has AUC of 0.5012221 hence a poor classifying model


prediction(test.predicted.m1, test_data$is_signed) %>%
  performance(measure = "tpr", x.measure = "fpr") %>%
  plot() + title(main = paste0('AUC= ', comma(auc, digits = 2)))
#ggcoefstats(train_logit, output = 'plot') + theme_grey()






var_influeunce <- varImp(train_logit)  ## determine which variable is more influencial in determining conversion
