#Revisar categorias edad. Revisar variables que no fueron significativas. 


library(readr)
library(tidyverse)
Datos <- read_csv("sip_varsdef_df_c.csv")

Datos <- Datos[which(Datos$Edad_gest <= 42 & Datos$Edad_gest >= 21),]
Datos <- Datos[which(Datos$Consult_prenat <= 30),]

#Filtro
Datos <- Datos[which(Datos$Edad_gest != 0),]
Datos <- Datos[which(Datos$Apgar5 != 0),]
Datos <- Datos[which(!is.na(Datos$Apgar5)),]

#Transformo
Datos$Edad_mat <- case_when(Datos$Edad_mat %in% c(1,2) ~ "Menor a 20",
                            Datos$Edad_mat %in% c(3:5) ~ "20 a 34",
                            Datos$Edad_mat %in% c(6:10) ~ "35 o mas")

Datos$Edad_mat <- factor(Datos$Edad_mat, levels=c("20 a 34","Menor a 20","35 o mas"))
Datos$Peso_al_nacer <- Datos$Peso_al_nacer/1000
Datos$Ttornos_hipert <- ifelse(Datos$Ttornos_hipert == TRUE,1,ifelse(is.na(Datos$Ttornos_hipert),NA,0))
Datos$Pre_ecl <- ifelse(Datos$Pre_ecl == TRUE,1,ifelse(is.na(Datos$Pre_ecl),NA,0))
Datos$Ecl <- ifelse(Datos$Ecl == TRUE,1,ifelse(is.na(Datos$Ecl),NA,0))
Datos$ID <- NULL
#Genero variable dicot APGAR

Datos$Condicion <- ifelse(Datos$Apgar5 >= 7,0,1)
Datos$Apgar5 <- NULL

set.seed(56793)
n <- nrow(Datos)
ntrain <- n*0.8
itrain <- sample(1:n, ntrain)
itest <- -itrain
datostrain <- Datos[itrain,]
datostest <- Datos[itest, ]

datosglm <- glm(Condicion ~ Edad_mat+Consult_prenat+Edad_gest+Ttornos_hipert+Peso_al_nacer,
                family = binomial(link="logit"), data = datostrain)

confint(datosglm)

newdata <- datostest[,names(datostest) != "Condicion"]
predicciones <- predict(datosglm, newdata, type = "response")
clasi2 <- ifelse(predicciones>0.005797137, 1, 0)

table(clasi2, datostest$Condicion)

mean(clasi2 != datostest$Condicion)

#install.packages("caret")
#install.packages("e1071")

library(caret)
library(e1071)

clasificacionf <- factor(clasi2, levels=1:0)
predictf <- factor(datostest$Condicion, levels=1:0)
confMat <- confusionMatrix(clasificacionf,predictf)

confMat$byClass[1]
confMat$byClass[2]
confMat$overall[1]

#install.packages("pROC")
library(pROC)

roc1 <- roc(datostest$Condicion,predicciones)
plot(roc1)
auc(roc1)
ci.auc(datostest$Condicion,predicciones)
sqrt(var(auc(roc1)))

coords(roc(datostest$Condicion,predicciones), x="best",
       input="threshold", best.method="youden")
coords(roc(datostest$Condicion,predicciones), x="best",
       input="threshold", best.method="closest.topleft")

data_graficos <- datostest
data_graficos$Probabilidad <- predicciones

data_graficos$"Consultas prenatales" <- case_when(data_graficos$Consult_prenat > -1 & data_graficos$Consult_prenat < 4 ~ "0 a 4",
                                                  data_graficos$Consult_prenat > 3 & data_graficos$Consult_prenat < 15 ~ "5 a 14",
                                                  data_graficos$Consult_prenat > 14  ~ "Mas de 15")

library(ggplot2)

ggplot(data_graficos,aes(x=Consult_prenat,y=Probabilidad))+
  geom_point()+xlab("Numero de consultas prenatales")+ylab("Probabilidad de APGAR bajo calculada")

ggplot(data_graficos,aes(x=Edad_gest,y=Probabilidad))+
  geom_point()+xlab("Edad gestacional (semanas)")+ylab("Probabilidad de APGAR bajo calculada")

ggplot(data_graficos,aes(x=Peso_al_nacer,y=Probabilidad))+
  geom_point()+xlab("Peso al nacer (Kg)")+ylab("Probabilidad de APGAR bajo calculada")


