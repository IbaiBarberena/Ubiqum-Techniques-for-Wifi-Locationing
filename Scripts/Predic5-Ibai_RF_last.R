## Prediction 5 out of 5: 
#  Combining trainset and validationset observations.
#  Stratified data: 9 observations per unique location.
#  Cascade approach: 1. Building, 2. Latitude & Longitude, 3. Floor
#  Predictive algorithm used: Random Forest.
#  Observations from Phone 13 included.

pacman::p_load(tibble, readr, tidyr, anytime, reshape2, corrplot, ggplot2, caret, highcharter,
               plotly, dplyr,plyr,imager,RColorBrewer,gdata,
               randomForest, tidyr, forecast, lubridate, scatterplot3d)


trainingData <- as_tibble(read.csv2("Data/trainingData.csv", sep= ",", stringsAsFactors=FALSE))
adding <- as_tibble(read.csv2("Data/validationData.csv", sep= ",", stringsAsFactors=FALSE))


## Pre-processing the data ##

# anyNA(trainingData)
# anyNA(adding)


ffeatures <-c("FLOOR", "BUILDINGID", "SPACEID", "RELATIVEPOSITION", "USERID", "PHONEID")

trainingData[,ffeatures] <- apply(trainingData[,ffeatures], 2, as.factor)
adding[,ffeatures] <- apply(adding[,ffeatures], 2, as.factor)

rm(ffeatures)

# Changing the TimeStamp from UNIX units to Date-Time units
trainingData$TIMESTAMP <- anytime(trainingData$TIMESTAMP)
adding$TIMESTAMP <- anytime(adding$TIMESTAMP)

zerovarianze <- apply(trainingData[,c(1:520)], 1, mean)

zerovarianze <- which(zerovarianze == 100)

trainingData <- trainingData[-zerovarianze,]


# ## Tracking different locations ##
# 
# locations <- trainingData %>% 
#   distinct(BUILDINGID, FLOOR, SPACEID, RELATIVEPOSITION)

join <- c("BUILDINGID","FLOOR")

trainingData$location <- apply(trainingData[, join], 1, paste, collapse= "-")
adding$location <- apply(adding[, join], 1, paste, collapse= "-")

rm(join)

## Removing duplicates ##

trainingData <- trainingData[!duplicated(trainingData), ]

# Removing User 14

# trainingData <- filter(trainingData, trainingData$USERID != 6)
trainingData <- filter(trainingData, trainingData$USERID != 14)


rows <- c()
column <- c()
for(i in 1:length(grep("WAP", names(trainingData)))){
  
  s <- which(trainingData[,i] > -30 & trainingData[,i] < 0)
  if (length(s) !=0) {
    rows <- c(rows,s)
    column <- c(column, i)
  }
}

rows <- unique(rows)


trainingData <- trainingData[-rows,]
range(trainingData[, grep("WAP", names(trainingData))])





##### DEALING WITH ALL THE NO SIGNAL VALUES ########


trainingData <- replace(trainingData, trainingData == 100, 0)
adding <- replace(adding, adding == 100, 0)

trainingData <- replace(trainingData, trainingData == -104, 0.001)
adding <- replace(adding, adding == -104, 0.001)


# All the WAP signal have been moved to positive
for(i in 1:length(grep("WAP", names(trainingData)))){
  l <- which(trainingData[,i] != 0)
  trainingData[l,i] <- trainingData[l,i] + 104
}

for(i in 1:length(grep("WAP", names(adding)))){
  l <- which(adding[,i] != 0)
  adding[l,i] <- adding[l,i] + 104
}

trainingData <- replace(trainingData, trainingData == 104.001, 0.001)
adding <- replace(adding, adding == 104.001, 0.001)

range(trainingData[,c(1:520)])
range(adding[,c(1:520)])


trainingData$FLOOR <- as.factor(trainingData$FLOOR)
trainingData$BUILDINGID <- as.factor(trainingData$BUILDINGID)


levels(trainingData$FLOOR)[1] <- '0'
levels(trainingData$FLOOR)[2] <- '1'
levels(trainingData$FLOOR)[3] <- '2'
levels(trainingData$FLOOR)[4] <- '3'
levels(trainingData$FLOOR)[5] <- '4'


levels(trainingData$BUILDINGID)[1] <- '0'
levels(trainingData$BUILDINGID)[2] <- '1'
levels(trainingData$BUILDINGID)[3] <- '2'

adding$FLOOR <- as.factor(adding$FLOOR)
adding$BUILDINGID <- as.factor(adding$BUILDINGID)

levels(adding$FLOOR)[1] <- '0'
levels(adding$FLOOR)[2] <- '1'
levels(adding$FLOOR)[3] <- '2'
levels(adding$FLOOR)[4] <- '3'
levels(adding$FLOOR)[5] <- '4'

levels(adding$BUILDINGID)[1] <- '0'
levels(adding$BUILDINGID)[2] <- '1'
levels(adding$BUILDINGID)[3] <- '2'

trainingData$LATITUDE <- as.numeric(trainingData$LATITUDE)
trainingData$LONGITUDE <- as.numeric(trainingData$LONGITUDE)

adding$LATITUDE <- as.numeric(adding$LATITUDE)
adding$LONGITUDE <- as.numeric(adding$LONGITUDE)


### BUILD 2 FLOOR 4: There are 8 conection sets from adding that can be use in the trainset, as these locations are now shown in the TrainingData

valid2_4 <- filter(adding, adding$location == "2-4")
train2_4 <- filter(trainingData, trainingData$location == "2-4")
valid2_4$numbers <- c(1:39)
train2_4$numbers <- c(1:529)
t2_4 <- gdata::combine(train2_4, valid2_4)

# plot_ly(t2_4, x = ~LONGITUDE, y = ~LATITUDE, z = ~FLOOR, color = ~source,
#         text= ~paste('number:', numbers, 'User:', USERID),
#         colors = c("#E69F00", "#56B4E9"), size = 0.01) %>%
#   add_markers() %>%
#   layout(scene= list(xaxis = list(title = "Longitude"),
#                        yaxis = list(title = "Latitude"),
#                       zaxis = list(title = "Floor")))

addtrain <- valid2_4[c(20,17,39,21,25,26,6,31,19),]

addtrain$numbers <- NULL

rm(valid2_4,train2_4, t2_4)

trainingData <- rbind(trainingData, addtrain)







# adding <- anti_join(adding, addtrain)
rm(addtrain)

### BUILD 1 FLOOR 1

valid1_1 <- filter(adding, adding$location == "1-1")
train1_1 <- filter(trainingData, trainingData$location == "1-1")
valid1_1$numbers <- c(1:143)
train1_1$numbers <- c(1:957)#957
t1_1 <- gdata::combine(train1_1, valid1_1)

# plot_ly(t1_1, x = ~LONGITUDE, y = ~LATITUDE, z = ~FLOOR, color = ~source,
#         text= ~paste('number:', numbers),
#         colors = c("#E69F00", "#56B4E9"), size = 0.01) %>%
#   add_markers() %>%
#   layout(scene= list(xaxis = list(title = "Longitude"),
#                      yaxis = list(title = "Latitude"),
#                      zaxis = list(title = "Floor")))

a�adir <- c(81,85,83,87,24,74,76,71,27,126,62,123,59,127,55,54,57,96,52,68,37,51,50,109,1,49,48,103,31,30,29,110,108,104,113,4,140,40,142,43)
addtrain2 <- valid1_1[a�adir,]

addtrain2$numbers <- NULL

rm(valid1_1,train1_1, t1_1)

trainingData <- rbind(trainingData, addtrain2)
rm(addtrain2)


### BUILD 1 FLOOR 2

valid1_2 <- filter(adding, adding$location == "1-2")
train1_2 <- filter(trainingData, trainingData$location == "1-2")
valid1_2$numbers <- c(1:87)
train1_2$numbers <- c(1:1396)
t1_2 <- gdata::combine(train1_2, valid1_2)

# plot_ly(t1_2, x = ~LONGITUDE, y = ~LATITUDE, z = ~FLOOR, color = ~source,
#         text= ~paste('number:', numbers),
#         colors = c("#E69F00", "#56B4E9"), size = 0.01) %>%
#   add_markers() %>%
#   layout(scene= list(xaxis = list(title = "Longitude"),
#                      yaxis = list(title = "Latitude"),
#                      zaxis = list(title = "Floor")))

addtrain3 <- valid1_2[c(62,53,60,64,49,16,85,6,8,47,23,43,35,44,63,65,77,51,37,24,30,75,2,3,4),]

addtrain3$numbers <- NULL

rm(valid1_2,train1_2, t1_2)

trainingData <- rbind(trainingData, addtrain3)

rm(addtrain3)

### BUILD 1 FLOOR 0

valid1_0 <- filter(adding, adding$location == "1-0")
train1_0 <- filter(trainingData, trainingData$location == "1-0")
valid1_0$numbers <- c(1:30)
train1_0$numbers <- c(1:1194)
t1_0 <- gdata::combine(train1_0, valid1_0)

# plot_ly(t1_0, x = ~LONGITUDE, y = ~LATITUDE, z = ~FLOOR, color = ~source,
#         text= ~paste('number:', numbers),
#         colors = c("#E69F00", "#56B4E9"), size = 0.01) %>%
#   add_markers() %>%
#   layout(scene= list(xaxis = list(title = "Longitude"),
#                      yaxis = list(title = "Latitude"),
#                      zaxis = list(title = "Floor")))

addtrain4 <- valid1_0[c(28,22,5,12,1,2,10,23,25,11),]

addtrain4$numbers <- NULL

rm(valid1_0,train1_0, t1_0)

trainingData <- rbind(trainingData, addtrain4)

rm(addtrain4)

### BUILD 1 FLOOR 3

valid1_3 <- filter(adding, adding$location == "1-3")
train1_3 <- filter(trainingData, trainingData$location == "1-3")
valid1_3$numbers <- c(1:47)
train1_3$numbers <- c(1:909)
t1_3 <- gdata::combine(train1_3, valid1_3)

# plot_ly(t1_3, x = ~LONGITUDE, y = ~LATITUDE, z = ~FLOOR, color = ~source,
#         text= ~paste('number:', numbers),
#         colors = c("#E69F00", "#56B4E9"), size = 0.01) %>%
#   add_markers() %>%
#   layout(scene= list(xaxis = list(title = "Longitude"),
#                      yaxis = list(title = "Latitude"),
#                      zaxis = list(title = "Floor")))

addtrain5 <- valid1_3[c(29, 30, 25, 27, 4, 44, 11, 41),]

addtrain5$numbers <- NULL

rm(valid1_3,train1_3, t1_3)

trainingData <- rbind(trainingData, addtrain5)

rm(addtrain5)

### BUILD 0 FLOOR 3

valid0_3 <- filter(adding, adding$location == "0-3")
train0_3 <- filter(trainingData, trainingData$location == "0-3")
valid0_3$numbers <- c(1:85)
train0_3$numbers <- c(1:1390)
t0_3 <- gdata::combine(train0_3, valid0_3)

# plot_ly(t0_3, x = ~LONGITUDE, y = ~LATITUDE, z = ~FLOOR, color = ~source,
#         text= ~paste('number:', numbers),
#         colors = c("#E69F00", "#56B4E9"), size = 0.01) %>%
#   add_markers() %>%
#   layout(scene= list(xaxis = list(title = "Longitude"),
#                      yaxis = list(title = "Latitude"),
#                      zaxis = list(title = "Floor")))

addtrain6 <- valid0_3[c(38,55,72,75),]

addtrain6$numbers <- NULL

rm(valid0_3,train0_3, t0_3)

trainingData <- rbind(trainingData, addtrain6)

rm(addtrain6)

### BUILD 0 FLOOR 2

valid0_2 <- filter(adding, adding$location == "0-2")
train0_2 <- filter(trainingData, trainingData$location == "0-2")
valid0_2$numbers <- c(1:165)
train0_2$numbers <- c(1:1443)
t0_2 <- gdata::combine(train0_2, valid0_2)

# plot_ly(t0_2, x = ~LONGITUDE, y = ~LATITUDE, z = ~FLOOR, color = ~source,
#         text= ~paste('number:', numbers),
#         colors = c("#E69F00", "#56B4E9"), size = 0.01) %>%
#   add_markers() %>%
#   layout(scene= list(xaxis = list(title = "Longitude"),
#                      yaxis = list(title = "Latitude"),
#                      zaxis = list(title = "Floor")))

addtrain7 <- valid0_2[c(23,22,60,4,79,27,66,165,121),]

addtrain7$numbers <- NULL

rm(valid0_2,train0_2, t0_2)

trainingData <- rbind(trainingData, addtrain7)

rm(addtrain7)

### BUILD 0 FLOOR 1

valid0_1 <- filter(adding, adding$location == "0-1")
train0_1 <- filter(trainingData, trainingData$location == "0-1")
valid0_1$numbers <- c(1:208)
train0_1$numbers <- c(1:1356)
t0_1 <- gdata::combine(train0_1, valid0_1)

# plot_ly(t0_1, x = ~LONGITUDE, y = ~LATITUDE, z = ~FLOOR, color = ~source,
#         text= ~paste('number:', numbers),
#         colors = c("#E69F00", "#56B4E9"), size = 0.01) %>%
#   add_markers() %>%
#   layout(scene= list(xaxis = list(title = "Longitude"),
#                      yaxis = list(title = "Latitude"),
#                      zaxis = list(title = "Floor")))

addtrain8 <- valid0_1[c(2,97,150,73,70,128,179,199,153,168,164),]

addtrain8$numbers <- NULL

rm(valid0_1,train0_1, t0_1)

trainingData <- rbind(trainingData, addtrain8)

rm(addtrain8)

### BUILD 0 FLOOR 0

valid0_0 <- filter(adding, adding$location == "0-0")
train0_0 <- filter(trainingData, trainingData$location == "0-0")
valid0_0$numbers <- c(1:78)
train0_0$numbers <- c(1:1055)
t0_0 <- gdata::combine(train0_0, valid0_0)

# plot_ly(t0_0, x = ~LONGITUDE, y = ~LATITUDE, z = ~FLOOR, color = ~source,
#         text= ~paste('number:', numbers),
#         colors = c("#E69F00", "#56B4E9"), size = 0.01) %>%
#   add_markers() %>%
#   layout(scene= list(xaxis = list(title = "Longitude"),
#                      yaxis = list(title = "Latitude"),
#                      zaxis = list(title = "Floor")))

addtrain9 <- valid0_0[c(55, 50, 51, 62, 68, 72, 43, 61, 74),]

addtrain9$numbers <- NULL

rm(valid0_0,train0_0, t0_0)

trainingData <- rbind(trainingData, addtrain9)

rm(addtrain9)

### BUILD 2 FLOOR 0

valid2_0 <- filter(adding, adding$location == "2-0")
train2_0 <- filter(trainingData, trainingData$location == "2-0")
valid2_0$numbers <- c(1:24)
train2_0$numbers <- c(1:1904)
t2_0 <- gdata::combine(train2_0, valid2_0)

# plot_ly(t2_0, x = ~LONGITUDE, y = ~LATITUDE, z = ~FLOOR, color = ~source,
#         text= ~paste('number:', numbers),
#         colors = c("#E69F00", "#56B4E9"), size = 0.01) %>%
#   add_markers() %>%
#   layout(scene= list(xaxis = list(title = "Longitude"),
#                      yaxis = list(title = "Latitude"),
#                      zaxis = list(title = "Floor")))

addtrain10 <- valid2_0[c(8,11,12),]

addtrain10$numbers <- NULL

rm(valid2_0,train2_0, t2_0)

trainingData <- rbind(trainingData, addtrain10)

rm(addtrain10)

### BUILD 2 FLOOR 1

valid2_1 <- filter(adding, adding$location == "2-1")
train2_1 <- filter(trainingData, trainingData$location == "2-1")
valid2_1$numbers <- c(1:111)
train2_1$numbers <- c(1:2159)
t2_1<- gdata::combine(train2_1, valid2_1)

# plot_ly(t2_1, x = ~LONGITUDE, y = ~LATITUDE, z = ~FLOOR, color = ~source,
#         text= ~paste('number:', numbers),
#         colors = c("#E69F00", "#56B4E9"), size = 0.01) %>%
#   add_markers() %>%
#   layout(scene= list(xaxis = list(title = "Longitude"),
#                      yaxis = list(title = "Latitude"),
#                      zaxis = list(title = "Floor")))

addtrain11 <- valid2_1[c(97,60,78,81,5,70,4),]

addtrain11$numbers <- NULL

rm(valid2_1,train2_1, t2_1)

trainingData <- rbind(trainingData, addtrain11)

rm(addtrain11)

### BUILD 2 FLOOR 2

valid2_2 <- filter(adding, adding$location == "2-2")
train2_2 <- filter(trainingData, trainingData$location == "2-2")
valid2_2$numbers <- c(1:54)
train2_2$numbers <- c(1:966)
t2_2<- gdata::combine(train2_2, valid2_2)

# plot_ly(t2_2, x = ~LONGITUDE, y = ~LATITUDE, z = ~FLOOR, color = ~source,
#         text= ~paste('number:', numbers),
#         colors = c("#E69F00", "#56B4E9"), size = 0.01) %>%
#   add_markers() %>%
#   layout(scene= list(xaxis = list(title = "Longitude"),
#                      yaxis = list(title = "Latitude"),
#                      zaxis = list(title = "Floor")))

addtrain12 <- valid2_2[c(53,48,20,6,39,49),]

addtrain12$numbers <- NULL

rm(valid2_2,train2_2, t2_2)

trainingData <- rbind(trainingData, addtrain12)

rm(addtrain12)

### BUILD 2 FLOOR 3

valid2_3 <- filter(adding, adding$location == "2-3")
train2_3 <- filter(trainingData, trainingData$location == "2-3")
valid2_3$numbers <- c(1:40)
train2_3$numbers <- c(1:1992)
t2_3<- gdata::combine(train2_3, valid2_3)

# plot_ly(t2_3, x = ~LONGITUDE, y = ~LATITUDE, z = ~FLOOR, color = ~source,
#         text= ~paste('number:', numbers),
#         colors = c("#E69F00", "#56B4E9"), size = 0.01) %>%
#   add_markers() %>%
#   layout(scene= list(xaxis = list(title = "Longitude"),
#                      yaxis = list(title = "Latitude"),
#                      zaxis = list(title = "Floor")))

addtrain13 <- valid2_3[c(),]

addtrain13$numbers <- NULL

rm(valid2_3,train2_3, t2_3)

trainingData <- rbind(trainingData, addtrain13)

rm(addtrain13)


notused <- c("SPACEID", "RELATIVEPOSITION", "USERID", "PHONEID", "TIMESTAMP")
trainingData[,notused] <- NULL
adding[,notused] <- NULL

WAPS <- colnames(trainingData[,grep("WAP", names(trainingData))])

order <- c(WAPS, "BUILDINGID", "FLOOR", "LATITUDE", "LONGITUDE")
order_total <- c(WAPS, "BUILDINGID", "FLOOR", "LATITUDE", "LONGITUDE", "source")

trainingData <- trainingData[,order]
adding <- adding[,order]

rm(order)
rm(order_total)

### SELECTING THE DATA FOR MODELLING ### There are in total 941 unique points in TrainingData. I will select 9 signs of each point and in the points with less than 9 signs, I will select all of them.

trainingData$uniques <- paste(trainingData$FLOOR, trainingData$LONGITUDE, trainingData$LATITUDE, sep="_")

uniques <- trainingData %>% group_by(uniques) %>% tally()

uniquesless9 <- uniques %>% filter(n < 9)

todelete <- which(!is.na(match(trainingData$uniques, uniquesless9$uniques)))

trainingData_2 <- trainingData[-todelete,]

# a <- trainingData_2 %>% group_by(uniques) %>% tally()

# trainmodel <- trainingData_2 %>% group_by(FLOOR, LONGITUDE, LATITUDE) %>% sample_n(9)
trainmodel <- trainingData_2 %>% group_by(uniques) %>% sample_n(9)
notfrequentsignals <- trainingData[todelete,]
trainmodel <- full_join(trainmodel, notfrequentsignals)

length(unique(paste(trainmodel$LONGITUDE, trainmodel$LATITUDE, trainmodel$FLOOR)))
anyNA(trainmodel)

rm(adding, trainingData, notfrequentsignals, uniques, uniquesless9, trainingData_2)



## PREDICTIONS ##

validationData <- as_tibble(read.csv2("Testing/validationData.csv", sep= ",", stringsAsFactors=FALSE))
validationData <- validationData[,c(1:520)]

anyNA(validationData)
range(validationData)

#### PREPROCESSING ####

validationData <- replace(validationData, validationData == 100, 0)
validationData <- replace(validationData, validationData == -100, 0.001)

for(i in 1:length(grep("WAP", names(validationData)))){
  l <- which(validationData[,i] != 0)
  validationData[l,i] <- validationData[l,i] + 100
}
validationData <- replace(validationData, validationData == 100.001, 0.001)

range(validationData[,c(1:520)])


#### MODELLING ####

## Finding the best mtry for each model:
WAPS <- grep("WAP", names(trainmodel), value = T)
WAPS_BUILD <- grep("WAP|BUILDING", names(trainmodel), value = T)
WAPS_BUILD_LONG <- grep("WAP|BUILDING|LONGITUDE", names(trainmodel), value = T)
WAPS_BUILD_LAT <- grep("WAP|BUILDING|LATITUDE", names(trainmodel), value = T)
WAPS_BUILD_LONG_LAT_FLOOR <- grep("WAP|BUILDING|LONGITUDE|LATITUDE|FLOOR", names(trainmodel), value = T)

# BUILDING #
rf5_building <- ranger(BUILDINGID~.,
                       data = trainmodel[,WAPS_BUILD],
                       mtry = 11)
saveRDS(rf5_building,"Models/Pred5_rf_building.rds")
# LATITUDE #
rf5_latitude <- ranger(LATITUDE~.,
                       data = trainmodel[,WAPS_BUILD_LAT],
                       mtry = 174)

saveRDS(rf5_latitude,"Models/Pred5_rf_latitude.rds")
# LONGITUDE #
rf5_longitude <- ranger(LONGITUDE~.,
                        data = trainmodel[,WAPS_BUILD_LONG],
                        mtry = 174)

saveRDS(rf5_longitude,"Models/Pred5_rf_longitude.rds")
# FLOOR #
rf5_floor <- ranger(FLOOR~.,
                    data = trainmodel[,WAPS_BUILD_LONG_LAT_FLOOR],
                    mtry = 44)

saveRDS(rf5_floor,"Models/Pred5_rf_floor.rds")
#### PREDICTIONS #####

# BUILDING #

pred1_building <- predict(rf5_building, data = validationData[WAPS])
validationData_1 <- validationData[WAPS]
validationData_1$BUILDINGID <- pred1_building[["predictions"]]

# LATITUDE #

pred1_latitude <- predict(rf5_latitude, data = validationData_1)

# LONGITUDE #

pred1_longitude <- predict(rf5_longitude, data = validationData_1)

validationData_1$LATITUDE <- pred1_latitude[["predictions"]]
validationData_1$LONGITUDE <- pred1_longitude[["predictions"]]

# FLOOR #
pred1_floor <- predict(rf5_floor, data = validationData_1)
validationData_1$FLOOR <- pred1_floor[["predictions"]]


# FINAL PREDICTIONS #

Ibai_RF_last <- validationData_1[,c(521:524)]
orden <- c("LATITUDE", "LONGITUDE", "FLOOR", "BUILDINGID")
Ibai_RF_last <- Ibai_RF_last[,orden]
rm(orden)

### If Building 0,1 and Floor 4, replacing them for Floor 3 ###

rows0 <- c()
for(i in 1:nrow(Ibai_RF_last)){
  yes0 <- which(Ibai_RF_last[i, "BUILDINGID"] == "0" & Ibai_RF_last[i, "FLOOR"] == "4")
  if (length(yes0) !=0) {
    rows0 <- c(rows0,i)
  }
}
Ibai_RF_last[rows0,"FLOOR"] <- "3"


rows1 <- c()
for(i in 1:nrow(Ibai_RF_last)){
  yes1 <- which(Ibai_RF_last[i, "BUILDINGID"] == "1" & Ibai_RF_last[i, "FLOOR"] == "4")
  if (length(yes1) !=0) {
    rows1 <- c(rows1,i)
  }
}
Ibai_RF_last[rows1,"FLOOR"] <- "3"


Ibai_RF_last$BUILDINGID <- NULL

Ibai_RF_last$FLOOR <- as.factor(Ibai_RF_last$FLOOR)

write.csv(Ibai_RF_last, file = "Testing/Ibai_RF_last.csv", row.names = FALSE, quote = FALSE)