#20210716 This R script will connect the ERP server
#Get shipment records and save to a RData for FWT dashboard

library("writexl")
require(RODBC)
#20180720測試:連結大帳省ERP資料庫
#除了上面用merge方式取得ERP出貨資料, 亦可直接使用sql語法直接讀取出貨資料
#open the ODBC connection
ch <- odbcConnect("N_ERP",uid="sa",pwd="intron")
#台北的資料庫為Icompany8
sqlResult <- sqlQuery(ch, "SELECT 
                     Pact.actDate AS 'shipdate',
                     Card.no As 'ClientNo',
                     Card.name AS 'client', 
                     SubShip.name AS 'partno', 
                     vary.amountUI*ship.moneyDB AS 'samt', 
                     Vary.vol*-1 AS 'sqty', 
                     Vary.cost AS 'Runitprice', 
                     vary.vol*vary.cost*-1 AS 'scost', 
                     Ship.agent AS 'salesno', 
                     Card_1.name AS 'salesman'  
                     FROM ICompany8.dbo.Card Card,                                         ICompany8.dbo.Card Card_1, 
                     ICompany8.dbo.Pact Pact, 
                     ICompany8.dbo.Ship Ship, 
                     ICompany8.dbo.SubShip SubShip,                                        ICompany8.dbo.Vary Vary  
                     WHERE Ship.pact = Pact.pact AND                                       Vary.vary = SubShip.vary AND 
                     Vary.pact = Pact.pact AND 
                     Card.card = Ship.who AND 
                     Ship.agent = Card_1.card 
                     AND 
                     ((Card.kind=-1) AND 
                      (Pact.ui=30) AND 
                      (Pact.actDate>={ts '2021-01-01 00:00:00'})
                     )")


#讀取HK資料庫Icompany13
sqlResult13 <- sqlQuery(ch, "SELECT Pact.actDate AS 'shipdate', 
                        Card.no As 'ClientNo',
                        Card.name AS 'client', 
                        SubShip.name AS 'partno', 
                        vary.amountUI*ship.moneyDB AS 'samt', 
                        Vary.vol*-1 AS 'sqty', 
                        Vary.cost AS 'Runitprice', 
                        vary.vol*vary.cost*-1 AS 'scost', 
                        Ship.agent AS 'salesno', 
                        Card_1.name AS 'salesman'  
                        FROM ICompany13.dbo.Card Card, 
                        ICompany13.dbo.Card Card_1, 
                        ICompany13.dbo.Pact Pact, 
                        ICompany13.dbo.Ship Ship, 
                        ICompany13.dbo.SubShip SubShip, 
                        ICompany13.dbo.Vary Vary  
                        WHERE Ship.pact = Pact.pact AND 
                        Vary.vary = SubShip.vary AND 
                        Vary.pact = Pact.pact AND 
                        Card.card = Ship.who AND 
                        Ship.agent = Card_1.card AND 
                        ((Card.kind=-1) AND (Pact.ui=30) AND 
                         (Pact.actDate>={ts '2021-01-01 00:00:00'})
                        )")

# merge the output of TP and HK
sqlResultall <- rbind(sqlResult, sqlResult13)
# subset the 
sqlResultall7 <- subset(sqlResultall, sqlResultall$shipdate >='2021-07-01 00:00:00')
# close the ODBC connection
odbcClose(ch)
# To save the objects (sqlResultall,sqlResultall7) to a RData file
save(sqlResultall,sqlResultall7,  file = "C:/Users/elvis/Documents/fwt_reports/fwtdata.RData")
# To load the data again
#load("C:/Users/elvis/Documents/fwt_reports/fwtdata.RData")

# update the Rmd file
rmarkdown::render("fwt_dashboards.Rmd")
######################