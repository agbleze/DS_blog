

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {     
    ############################ MODEL UI  ##############
    output$dataset <- renderDataTable(
        task_data
    )
    
    output$ggnonparametrin <- renderPlot({
        data_grouped_demo_conversion <- task_data_convert %>%
            dplyr::select(demo_appointment_datetime, conversion, company_group, sales_script_type, is_signed)%>%
            tidyr::separate(col = demo_appointment_datetime, sep = ' ', into = c('demo_appointment_yyyymmdd','demo_appointment_hhmmss')) %>%
            dplyr::group_by(demo_appointment_yyyymmdd, sales_script_type)
        
        ## sum the total conversion for each script on each day
        df_grp_sum = data_grouped_demo_conversion %>% dplyr::summarize(total_conversion = sum(is_signed))
        
        
        ggbetweenstats(df_grp_sum, x = sales_script_type, y = total_conversion, plot.type = 'boxviolin',
                       type = 'nonparametric', p.adjust.method = 'bonferroni')
    })
    
    output$training_dataset <- renderPlotly({
        ggplot(data = train_data, aes(conversion)) + geom_bar() + 
            ggtitle("Training dataset") + xlab("")
    })
    
    output$test_dataset <- renderPlotly({
        ggplot(data = test_data, aes(conversion)) + geom_bar() + 
            ggtitle("Test dataset") +
             xlab("")
    })
    
    output$regression_result <- renderPlot(
        ggcoefstats(train_logit, output = 'plot', 
                    title = 'Result of logistic regression on training dataset') + theme_grey()
    )
    
    output$var_inf <- renderDataTable({
        var_influeunce
    })
    
    ################## Model metrics ###################
    output$sensitivity_result <- renderValueBox({
        valueBox(color = 'maroon',
            value = paste0(comma(sensitivity_result, digits = 2), '%'),
            subtitle = h4("Precision (Sensitivity)")
        )
        
    })

    output$specificity_result <- renderValueBox({
        valueBox(color = 'maroon',
            value = paste0(comma(specificity_result, digits = 2), '%'),
            subtitle = h4("Specificity")
        )
    })
    
    output$mcfaddenR2_result <- renderValueBox({
        valueBox(color = 'maroon',
            value = paste0(comma(mcfadden_r2, digits = 6)), 
                 subtitle = h4('McFadden’s pseudo R2'))
    })
    
    output$auc_perform <- renderPlot(
        # data.frame(fpr = fpr_tested_model, tpr = tpr_tested_model) %>%
        #     ggplot(aes(fpr, tpr)) + geom_line() + ggtitle(sprintf("AUC: %f", h2o.auc(test_model)))
        
        prediction(test.predicted.m1, test_data$is_signed) %>%
            performance(measure = "tpr", x.measure = "fpr") %>%
            plot() + title(main = paste0('AUC= ', comma(auc, digits = 2)))
    )
    
    
    
    ########################## Display actual class value of a firm from the testing dataset
    output$actual <- renderValueBox({
        client <- input$client
        
        actul <- prediction_data%>%
            dplyr::filter(request_id == client)%>%
            dplyr::select(conversion)
        
        valueBox(value = h3(actul), subtitle = h4("Actual conversion status"), color = "yellow",
                 width = 3)
    })
    
    output$predicted <- renderValueBox({
        client = input$client
        
        predicted <- prediction_data %>%
            dplyr::filter(request_id == client)%>%
            dplyr::select(model_prediction)
        valueBox(value = h3(predicted), subtitle = h4('Model Prediction'), color = 'yellow',
                 width = 3)
    })
    
    output$model_precision <- renderValueBox({
        client = input$client
        
        model_status <- prediction_data%>%
            dplyr::filter(request_id == client)%>%
            dplyr::select(predict_satus)
        
        color_model <- if(model_status == 'Wrong prediction') {
              color = 'red' 
            } else if(model_status == 'Correct prediction'){
              color = 'green'
            }
        
        
        ## create different icons for correcting and wrong prediction
        model_icon<- if(model_status == "Correct prediction"){
            correct = icon("check-circle")
        } else if (model_status == "Wrong prediction"){
            wrong = icon("times-circle")
        } 
        
        valueBox(value = h3(model_status), subtitle = h4('Model Accuracy'), width = 6, 
                 color = color_model, icon = model_icon)
    })
   

    ######################################  CONVERSION UI ############################################# 
    ########## Sales scripts  ######################
    output$scriptA_conv_rate <- renderValueBox({
        conv_rate_selectyear <- input$conv_rate_selectyear
        conv_rate_selectmonth <- input$conv_rate_selectmonth
        
        script_A_conversion <- task_data_convert%>%
            filter(request_created_year == conv_rate_selectyear & request_created_month == conv_rate_selectmonth,
                   sales_script_type == 'script_A')%>%
            count(conversion)
        
        scriptA_rate<- (script_A_conversion[1,2] / sum(script_A_conversion$n)) * 100
        
           
        
        valueBox(paste0(comma(scriptA_rate$n, digits = 2), '%'), 
                 paste0("Conversion rate ( Script A) ", conv_rate_selectmonth, ', ', conv_rate_selectyear ), 
                 width = 6, icon = icon("funnel-dollar"))
    })
    
    output$scriptB_conv_rate <- renderValueBox({
        conv_rate_selectyear <- input$conv_rate_selectyear
        conv_rate_selectmonth <- input$conv_rate_selectmonth
        
        script_B_conversion <- task_data_convert%>%
            filter(request_created_year == conv_rate_selectyear & request_created_month == conv_rate_selectmonth,
                   sales_script_type == 'script_B')%>%
            count(conversion)
        
        scriptB_rate<- (script_B_conversion[1,2] / sum(script_B_conversion$n)) * 100
        
        
        
        valueBox(paste0(comma(scriptB_rate$n, digits = 2), '%'), 
                 paste0("Conversion rate ( Script B) ", conv_rate_selectmonth, ', ', conv_rate_selectyear ), 
                 width = 6, icon = icon("funnel-dollar"))
    })
    
    
    output$scriptC_conv_rate <- renderValueBox({
        conv_rate_selectyear <- input$conv_rate_selectyear
        conv_rate_selectmonth <- input$conv_rate_selectmonth
        
        script_C_conversion <- task_data_convert%>%
            filter(request_created_year == conv_rate_selectyear & request_created_month == conv_rate_selectmonth,
                   sales_script_type == 'script_C')%>%
            count(conversion)
        
        scriptC_rate<- (script_C_conversion[1,2] / sum(script_C_conversion$n)) * 100
        
        
        
        valueBox(paste0(comma(scriptC_rate$n, digits = 2), '%'), 
                 paste0("Conversion rate ( Script C) ", conv_rate_selectmonth, ', ', conv_rate_selectyear ), 
                 width = 6, icon = icon("funnel-dollar"))
    })
    
    
    ############ marketing source conversion rate  #############
    output$marketing_source_conv_rate <- renderValueBox({
        conv_rate_selectyear <- input$conv_rate_selectyear
        conv_rate_selectmonth <- input$conv_rate_selectmonth
        conv_marketing_source <- input$marketing_source
        
        marketing_source_conversion <- task_data_convert%>%
            filter(request_created_year == conv_rate_selectyear & request_created_month == conv_rate_selectmonth,
                   source == conv_marketing_source)%>%
            count(conversion)
        
        marketing_source_conv_rate<- (marketing_source_conversion[1,2] / sum(marketing_source_conversion$n)) * 100
        
        
        
        valueBox(paste0(comma(marketing_source_conv_rate$n, digits = 2), '%'), 
                 paste0("Conversion rate (Marketing Source Lead) ", conv_rate_selectmonth, ', ', conv_rate_selectyear,
                        ', ', conv_marketing_source), 
                 width = 6, icon = icon("funnel-dollar"))
    })
    
    
    ############### sales group conversion rate  ####################
    output$sales_group_conv_rate <- renderValueBox({
        conv_rate_selectyear <- input$conv_rate_selectyear
        conv_rate_selectmonth <- input$conv_rate_selectmonth
        conv_sales_group <- input$sales_group
        
        sales_group_conversion <- task_data_convert%>%
            filter(request_created_year == conv_rate_selectyear & request_created_month == conv_rate_selectmonth,
                   sales_group_name == conv_sales_group)%>%
            count(conversion)
        
        sales_group_conv_rate<- (sales_group_conversion[1,2] / sum(sales_group_conversion$n)) * 100
        
        
        
        valueBox(paste0(comma(sales_group_conv_rate$n, digits = 2), '%'), 
                 paste0("Conversion rate (Sales group) ", conv_rate_selectmonth, ', ', conv_rate_selectyear,
                        ', ', conv_sales_group), 
                 width = 6, icon = icon("funnel-dollar"))
    })
    
    ###################### TIMESERIES CONVERSION ############################################
    output$accur_drift <- renderValueBox({
        valueBox(value = paste0(comma(accur_drift[2,2], digits = 2)), 
                 subtitle = "Drift method RMSE of conversion",
                 color = "yellow", icon = icon("square-root-alt"))
    })
    
    output$accur_meanf <- renderValueBox({
        valueBox(value = paste0(comma(accur_meanf[2,2], digits = 2)), 
                 subtitle = "Mean method RMSE of conversion",
                 color = "yellow", icon = icon("square-root-alt"))
    })
    
    output$accur_naive <- renderValueBox({
        valueBox(value = paste0(comma(accur_naive[2,2], digits = 2)), 
                 subtitle = "Naive method RMSE of conversion",
                 color = "yellow", icon = icon("square-root-alt"))
    })
    
    output$accur_rwf <- renderValueBox({
        valueBox(value = paste0(comma(accur_rwf[2,2], digits = 2)), 
                 subtitle = "RWF method RMSE of conversion",
                 color = "yellow", icon = icon("square-root-alt"))
    })
    
    
    output$avg_monthly_conversion <- renderPlot({   
        ggseasonplot(data_convert_transform_ts[,'avgmonthly_convert'], year.labels = T, year.label.left = T, year.label.right = T) + 
            ggtitle("Timeseries plot of Average Monthly Conversions") + ylab('Average monthly conversions')
    })
    
    output$polar_series <- renderPlot({   
        ggseasonplot(data_convert_transform_ts[,'avgmonthly_convert'], polar = T) + 
            ggtitle("Polar plot of Average Monthly Conversions") + ylab('Average monthly conversions')
    })
    
    output$conversion_forecast <- renderPlot({
        autoplot(train_data_convert_transform_forecast[,'avgmonthly_convert']) + theme_dark() +
            autolayer(data_convert_meanf, series = "Mean", PI = T, alpha = 0.1) +
            autolayer(data_convert_naive, series = "Naive", PI = T, alpha = 0.1) +
            #  autolayer(rev_snaive, series = "Seasonal Naive", PI = T, alpha = 0.3) +
            autolayer(data_convert_rwf, series = "rwf", PI = T, alpha = 0.1) +
            autolayer(data_convert_rwfdrift, series = "Drift", PI = T, alpha = 0.1) +
            ggtitle("Forecast for Conversion with various forecasting methods") +
            guides(colour = guide_legend(title = "Forecast")) + ylab("Average Monthly Revenue") +
            xlab('Years')
    })
    
    output$meanf_diagnostic <- renderPlot({
        checkresiduals(data_convert_meanf)
    })
    
    output$naive_diagnostic <- renderPlot({
        checkresiduals(data_convert_naive)
    })
    
    output$rwf_diagnostic <- renderPlot({
        checkresiduals(data_convert_rwfdrift)
    })
 
    
    ################ ANIMATIONS #########
    observe(addHoverAnim(session, "accur_rwf", "rubberBand"))
    observe(addHoverAnim(session, "accur_drift", "rubberBand"))
    observe(addHoverAnim(session, "avg_monthly_conversion", "swing"))
    # observe(addHoverAnim(session, "seas", "pulse"))
    observe(addHoverAnim(session, "dataset", "pulse"))
    observe(addHoverAnim(session, "ggnonparametrin", "pulse"))
    observe(addHoverAnim(session, "revenue_change_detect", "pulse"))
    observe(addHoverAnim(session, "revenue_stl_forecast", "pulse"))
    observe(addHoverAnim(session, "revenue_trendSeasonal_forecast", "pulse"))
    observe(addHoverAnim(session, "revenue_seasonality", "pulse"))
    observe(addHoverAnim(session, "revenue_seasonality", "pulse"))
    observe(addHoverAnim(session, "regress_model", "pulse"))
    observe(addHoverAnim(session, "seasonal_forecast", "pulse"))
    
    
    observe(addHoverAnim(session, "accur_meanf", "pulse"))
    observe(addHoverAnim(session, "accur_naive", "pulse"))
    observe(addHoverAnim(session, "sensitivity_result", "pulse"))
    observe(addHoverAnim(session, "specificity_result", "pulse"))
    
    observe(addHoverAnim(session, "mcfaddenR2_result", "pulse"))
    observe(addHoverAnim(session, "auc_perform", "pulse"))
    observe(addHoverAnim(session, "var_inf", "pulse"))
    observe(addHoverAnim(session, "regression_result", "pulse"))
    
    observe(addHoverAnim(session, "scriptA_conv_rate", "rubberBand"))
    observe(addHoverAnim(session, "scriptB_conv_rate", "rubberBand"))
    observe(addHoverAnim(session, "scriptC_conv_rate", "swing"))
    observe(addHoverAnim(session, "marketing_source_conv_rate", "swing"))
    observe(addHoverAnim(session, "sales_group_conv_rate", "swing"))
})

# output$accur_naive
# output$avg_monthly_conversion
