# Proyecto de R BEDU --- Equipo 12
# Parte del an�lisis de trafico, viajes por tiempo

# Librer�as utilizadas
library(dplyr)
library(xts)
library(ggplot2)
library(lubridate)

# Espacio de trabajo
setwd("../../1. Bases de datos")

# Preparaci�n de los datos
data <- read.csv("cdmx_transporte_clean.csv")
data <- mutate(data, pickup_date = as.Date(pickup_date, "%d/%m/%Y"))
data <- filter(data, wait_sec <= 3600)
n <- as.integer(count(data))
unos <- rep(1,n)
data <- select(data,Transporte,pickup_date,pickup_time,wait_sec,municipios_origen,municipios_destino,dist_meters,trip_duration)
data <- cbind(data,unos)
names(data)
uNames = c("UberX","UberBlack","UberXL","UberSUV")
tNames = c("Taxi de Sitio","Taxi Libre","Radio Taxi")

# Serie de tiempo de viajes por mes hechos por transportes Uber
# Es mensual ya que solo se tienen pocos datos de ellos, pero se espera
# ver una tendencia alcista debido a la creciente popularidad de esta aplicaci�n

ubers <- data[which(data$Transporte %in% uNames),]
ubers <- mutate(ubers, pickup_date = format(pickup_date, "%Y-%m"))

tsUber <- ubers %>% group_by(pickup_date) %>% summarise(cuenta = sum(unos))
tsUber <- mutate(tsUber, date = as.Date(paste(pickup_date,"-1",sep=""),"%Y-%m-%d"))
#tsUber <- ts(tsUber$cuenta, st = c(2016,8), end = c(2017,7),fr=12)
ggplot(tsUber, aes(date,cuenta))+
  geom_line()+
  theme_minimal()+
  labs(title = "Viajes Por Mes - Uber",
        subtitle = "Junio 2016 - Julio 2017",
        x="Fecha",
        y="Viajes")
  

tsUber <- ts(tsUber$cuenta, st = c(2016,8), end = c(2017,7),fr=12)
ts.decomposed <- decompose(tsUber)
plot (ts.decomposed)

# Serie del tiempo de viajes diarios por todos los transportes
# Se espera ver una tendencia a la alsa.
taxis <- data[which(data$Transporte %in% tNames),]
tsData <- mutate(taxis, pickup_date = format(pickup_date, "%Y-%m-%d"))

tsData <- tsData %>% group_by(pickup_date) %>% summarise(cuenta = sum(unos))
tsData <- mutate(tsData, date = as.Date(pickup_date,"%Y-%m-%d"))
#tsData <- ts(tsData$cuenta, st = c(2016,250), fr = 365)
ggplot(tsData,aes(date,cuenta))+
  geom_line()+
  theme_minimal()+
  labs(title = "Viajes Por D�a - Taxis",
       subtitle = "Junio 2016 - Julio 2017",
       x="Fecha",
       y="Viajes")



# Dado que los datos recopilados son del 24 de junio del 2016 al 20 de julio del 2017
# y el los periodos necesarios para descomponer una serie de tiempo son dos (dos a�os)
# no se p�do descomponer ninguna de las series de tiempo

# Ahora se elaborar�n dos series de tiempo, pero graficando el promedio de la columna
# wait_sec. Esta variable mide el tiempo que estuvo el transporte parado en el viaje,
# por eso se toma como una medida del tr�fico

tsUber <- ubers %>% group_by(pickup_date) %>% summarise(wait_sec = mean(wait_sec))
tsUber <- mutate(tsUber, date = as.Date(paste(pickup_date,"-1",sep=""),"%Y-%m-%d"))
#tsUber <- ts(tsUber$wait_sec, st = c(2016,8), end = c(2017,7),fr=12)
ggplot(tsUber, aes(date,wait_sec))+
  geom_line()+
  theme_minimal()+
  labs(title = "Tiempo de Espera - Uber",
       subtitle = "Junio 2016 - Julio 2017",
       x="Fecha",
       y="Segundos por D�a")

# En la gr�fica se ve una gr�n disminuci�n del tiempo de espera durante el viaje,
# Especulamos que esto se deba a un cambio en el sistema que calcula la mejor ruta
# que usan los choferes de uber. Sin embargo, para investigar m�s esto se necesitan
# m�s datos de viajes de Uber en ese periodo

# Serie de tiempo del promedio del tiempo de espera de todos los transportes

tsData <- mutate(taxis, pickup_date = format(pickup_date, "%Y-%m-%d"))

tsData <- tsData %>% group_by(pickup_date) %>% summarise(wait_sec = mean(wait_sec))
tsData <- mutate(tsData, date = as.Date(pickup_date,"%Y-%m-%d"))
#tsData <- ts(tsData$wait_sec, st = c(2016,175), fr = 365)
ggplot(tsData,aes(date,wait_sec))+
  geom_line()+
  theme_minimal()+
  labs(title = "Tiempo de Espera - Taxis",
       subtitle = "Junio 2016 - Julio 2017",
       x="Segundos por D�a",
       y="Viajes")

# Se generar� una tabla con los dias de la semana para si estos afectan en el 
# n�mero de viajes realizados por dia

week <- mutate(data, day = format(pickup_date, "%a"), date = format(pickup_date, "%Y-%m-%d"))
week <- week %>% group_by(date,day) %>% summarise(cuenta = sum(unos))
week <- week %>% group_by(day) %>% summarise (viajes = sum(cuenta))
week$day <- factor(week$day,levels=c("dom.","lun.","mar.","mi�.","jue.","vie.","s�b."))
#barplot(week$viajes,names.arg = week$day)
ggplot(data=week, aes(x=day,y=viajes))+
  geom_bar(stat = 'identity', fill = "Steelblue")+
  labs(title = "Viajes totales por D�a de la Semana",
       subtitle = "",
       x="D�a",
       y="Viejes")+
  theme_minimal()

# Se generar� una tabla con los d�as de la semana y el promedio de segundos de espera
# para observar si el tr�fico disminuye dependiendo del d�a
week <- mutate(data, day = format(pickup_date, "%a"), date = format(pickup_date, "%Y-%m-%d"))
week <- week %>% group_by(date,day) %>% summarise(wait_sec = mean(wait_sec))
week <- week %>% group_by(day) %>% summarise (wait_sec = mean(wait_sec))
week$day <- factor(week$day,levels=c("dom.","lun.","mar.","mi�.","jue.","vie.","s�b."))
ggplot(data=week, aes(x=day,y=wait_sec))+
  geom_bar(stat = 'identity', fill = "Steelblue")+
  labs(title = "Tiempo de espera promedio por D�a de la Semana",
       subtitle = "",
       x="D�a",
       y="Tiempo de Espera")+
  theme_minimal()

# *************************************************************************************
# En esta secci�n se har� una regresi�n lineal multivariable para observar si se puede predecir el 
# tiempo de espera, se especula que las variables municipio_origen, dist_meter (distancia al destino)
# dia_semana(se agregar�) mes(se agregar�), y la hora(1-12)

# Todas las variables que se asumen que son significativas son categ�ricas, por lo tanto se 
# tiene que hacer un tratamiento de datos previo a la realizaci�n de la regresi�n

tmp <- c(1,1,1,1,2,2,2,2,3,3,3,3)
# Como son muy pocas las entradas con trasnporte de Uber, esta funci�n resume todas las
# categorias de Ubers en una
fun <- function(x,namestc,name)
{
  y = c()
  for (i in 1:length(x))
  {
    if (x[i] %in% namestc)
    {
      y[i] <- name
    }
    else
    {
      y[i] <- x[i]
    }
  }
  y
}


lmData <- mutate(data, dia_semana = format(pickup_date, "%a"), mes = format(pickup_date,"%b"), hora = as.integer(hour(hms(as.character(factor(pickup_time))))) )
lmData <- mutate(lmData, rango_tiempo = hora, velocidad = dist_meters/trip_duration)

lmData <- select(lmData,Transporte,municipios_origen,dia_semana,mes,hora,wait_sec,dist_meters,velocidad)
lmData <- mutate(lmData, Transporte = fun(Transporte,uNames,"Uber"))

lmData <- fastDummies::dummy_cols(lmData, remove_first_dummy = TRUE)

attach(lmData)

m1 <- lm(wait_sec ~ hora
         +dist_meters
         +velocidad
         +`Transporte_Taxi de Sitio`
         +`Transporte_Taxi Libre`
         +Transporte_Uber
         +dia_semana_lun.
         +dia_semana_mar.
         +dia_semana_mi�.
         +dia_semana_jue.
         +dia_semana_vie.
         +dia_semana_s�b.
         +mes_ene.
         +mes_feb.
         +mes_mar.
         +mes_may.
         +mes_jun.
         +mes_jul.
         +mes_ago.
         +mes_sep.
         +mes_oct.
         +mes_nov.
         +mes_dic.
         +municipios_origen_Ahome
         +`municipios_origen_�lvaro Obreg�n`
         +`municipios_origen_Atizap�n de Zaragoza`
         +municipios_origen_Azcapotzalco
         +`municipios_origen_Benito Ju�rez`
         +municipios_origen_Chalco
         +municipios_origen_Chimalhuac�n
         +`municipios_origen_Coacalco de Berrioz�bal`
         +municipios_origen_Coyoac�n
         +`municipios_origen_Cuajimalpa de Morelos`
         +municipios_origen_Cuauht�moc
         +municipios_origen_Cuautitl�n
         +`municipios_origen_Cuautitl�n Izcalli`
         +`municipios_origen_Ecatepec de Morelos`
         +`municipios_origen_Emiliano Zapata`
         +`municipios_origen_G�mez Palacio`
         +`municipios_origen_Gustavo A. Madero`
         +municipios_origen_Huixquilucan
         +municipios_origen_Ixtapaluca
         +municipios_origen_Iztacalco
         +municipios_origen_Iztapalapa
         +municipios_origen_Kanas�n
         +`municipios_origen_La Magdalena Contreras`
         +`municipios_origen_La Paz`
         +municipios_origen_M�rida
         +`municipios_origen_Miguel Hidalgo`
         +`municipios_origen_Milpa Alta`
         +`municipios_origen_Naucalpan de Ju�rez`
         +municipios_origen_Nezahualc�yotl
         +municipios_origen_Quer�taro
         +municipios_origen_Tec�mac
         +municipios_origen_Tl�huac
         +`municipios_origen_Tlalnepantla de Baz`
         +municipios_origen_Tlalpan
         +`municipios_origen_Tulancingo de Bravo`
         +municipios_origen_Tultepec
         +municipios_origen_Tultitl�n
         +`municipios_origen_Valle de Chalco Solidaridad`
         +`municipios_origen_Venustiano Carranza`
         +municipios_origen_Veracruz
         +municipios_origen_Xochimilco)

summary(m1)


m2 <- lm(wait_sec
         ~hora
         +dist_meters
         +velocidad
         +`Transporte_Taxi de Sitio`
         +`Transporte_Taxi Libre`
         +Transporte_Uber
         +dia_semana_lun.
         +dia_semana_mar.
         +dia_semana_mi�.
         +dia_semana_jue.
         +dia_semana_vie.
         +mes_mar.
         +mes_dic.
         +mes_sep.
         +mes_oct.
         +mes_ago.)
summary(m2)

# Como era previsto, la regresi�n lineal hecha no predice con exactitud el tiempo de espera,
# su calificaci�n de R-squared es de tan solo 0.15. Las aplicaci�nes que trazan la ruta m�s
# corta de un lugar a otro y predicen con exactitud la int�nsidad del tr�fico usan mod�los y 
# algoritmos mucho mas complejos que una regresi�n lineal.

# Sin embargo, de las variables que resultaron significativas para el modelo, est�n dias de 
# lunes a viernes, que coincide con la gr�fica de promedio de segundos parados por d�a de la semana
# en la que se nota un aumento de tiempo parado en los d�as de lunes a viernes

# Otra coincidencia es que los meses de marzo, agosto, septiembre y octubre parecen influir
# en el tiempo de espera durante el viaje, estos meses coinciden con periodos vacacionales o 
# dias festivos, para corroborar esta correlaci�n har�a falta m�s datos y un estudio m�s 
# a fondo


