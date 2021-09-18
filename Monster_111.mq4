//+------------------------------------------------------------------+
//|                                                   Monster_23.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Monster Corp, EURAUD-EURNZD, M1, $30"
#property link      "https://product--lists.herokuapp.com"
#property version   "1.00"
#property strict
//--- input parameters

/*

Use Martingale in sideways market
Use Martingale TP
Martingale will auto SWITCH OFF if market condition changes.

Increase max order in clear direction market.
Using 0 TP
Using MarketConditionTP

*/

input int      MAGIC=63;

input int      FastMAPeriod = 2;
input int      SlowMAPeriod = 30;

input float    LOT=0.02;
input int      MAX_ORDER=1;

input bool     USE_MARTINGALE=true;
input int      LOT_MULTIPLIER=3;
input int      martin_runs = 2;
input bool     martin_max = true;

input string   MARKET_CONDITION = "------------";
input int      CURRENCY_LEVERAGE = 15;
input int      MARKET_DEPTH = 30;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int TIMEFRAME = (PERIOD_CURRENT==PERIOD_M5?3:(PERIOD_CURRENT==PERIOD_M15?1:(PERIOD_CURRENT==PERIOD_M30?1:(PERIOD_CURRENT==PERIOD_H1?1:(PERIOD_CURRENT==PERIOD_H4?1:6)))));
   

int OnInit()
  {
//---
   
   
    TIMEFRAME = (PERIOD_CURRENT==PERIOD_M5?3:(PERIOD_CURRENT==PERIOD_M15?1:(PERIOD_CURRENT==PERIOD_M30?1:(PERIOD_CURRENT==PERIOD_H1?1:(PERIOD_CURRENT==PERIOD_H4?1:6)))));
   
    drawMarketCondition(getMarketCondition(marketDirection()),volatility(),Ask-Bid);
   
    if(USE_MARTINGALE){
         if(MAX_ORDER==1){
         }else{
               Alert("Martingale Only Works MAX_ORDER=1");
         }
   }
   ChartSetInteger(0,CHART_COLOR_BACKGROUND,clrAliceBlue);
   ChartSetInteger(0,CHART_COLOR_FOREGROUND,clrBlack);
   ChartSetInteger(0,CHART_COLOR_GRID,clrRed);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,clrDarkOrange);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,clrOrangeRed);
   
   
   
   
      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

       int target_pips = 45;
      
void OnTick()
  {
//---
      target_pips = (volatility()/LOT);
      
      int FastMACurrent = iMA(NULL,PERIOD_M5, FastMAPeriod, 1, 0, PRICE_CLOSE, 0);
      int FastMA_Overall = iMA(NULL, PERIOD_H4, FastMAPeriod, 1, 0, PRICE_CLOSE, 0);

      int SlowMACurrent = iMA(NULL, PERIOD_M5, SlowMAPeriod, 1, 0, PRICE_CLOSE, 0);
      int SlowMA_Overall = iMA(NULL, PERIOD_H4, SlowMAPeriod, 1, 0, PRICE_CLOSE, 0);     

        
  if((FastMA_Overall < SlowMA_Overall) && (FastMACurrent > SlowMACurrent) && (OrdersTotal()<MAX_ORDER))
   {  
  
   float tp = (checkMarketSIDEWAYS()?(Ask+target_pips*Point):0);
   OrderSend(Symbol(),OP_BUY,LOT,Ask,0,0,tp,0,MAGIC,0,clrAliceBlue);
   
   }
   
   if((FastMA_Overall > SlowMA_Overall) && (FastMACurrent < SlowMACurrent) && (OrdersTotal()<MAX_ORDER))
   {   
   
   float tp = (checkMarketSIDEWAYS()?(Bid-target_pips*Point):0);
   OrderSend(Symbol(),OP_SELL,LOT,Bid,0,0,tp,0,MAGIC,0,clrBlack);
 
   }
   
   
   if(USE_MARTINGALE){
         if(MAX_ORDER==1){ //one order at a time only
            if(checkMarketSIDEWAYS()){ //trade sideways only
                   martingale();
            }  
         }
   }
   
   
   drawMarketCondition(getMarketCondition(marketDirection()),volatility(),Ask-Bid);
   
   marketConditionTP();   
       
   return;
  }
    
    
   int martin_count = 0;
   void martingale(){
         
       if(OrdersTotal()>0){
         
      OrderSelect((OrdersTotal()-1),SELECT_BY_POS); //currently open order
      if(OrderProfit()<-(OrderLots()*target_pips)){ //negative target pips
         if(martin_count<martin_runs){
         
         double PRICE = (OrderType()==OP_BUY?Bid:Ask);
         float tp = (OrderType()==OP_SELL?PRICE-target_pips*Point:PRICE+target_pips*Point);
        
         if(OrderSend(Symbol(),OrderType(),(OrderLots()*LOT_MULTIPLIER),PRICE,0,0,tp,0,MAGIC,0,clrBlack)){
            for(int a=0;a<(OrdersTotal()-1);a++){
           
           OrderSelect(a,SELECT_BY_POS);
           OrderModify(OrderTicket(),OrderOpenPrice(),0,tp,0,clrAliceBlue);
         
            }
            martin_count+=1;
         }             
         }else{
              // //volitility is too high.
              
              if(martin_max){  // close small loss and setup bigger gain
              
              OrderSelect(0,SELECT_BY_POS);
              double PRICE = (OrderType()==OP_BUY?Bid:Ask);
              OrderClose(OrderTicket(),OrderLots(),PRICE,3,White);
              
              
              OrderSelect((OrdersTotal()-1),SELECT_BY_POS);
              
              PRICE = (OrderType()==OP_BUY?Bid:Ask);
              float tp = (OrderType()==OP_SELL?PRICE-target_pips*Point:PRICE+target_pips*Point);
              OrderSend(Symbol(),OrderType(),(OrderLots()*LOT_MULTIPLIER),PRICE,0,0,tp,0,MAGIC,0,clrBlack);
              
              
              }else{
              closeSideWayOrders(); //Stop the loss
              }
              
              martin_count=0;
         }
      }
      }
   }
  
  
   
   
   
   
 int bar_num = MARKET_DEPTH;
   
   double marketDirection()
  {
      return ((Open[bar_num]-Close[0])/Point/CURRENCY_LEVERAGE);
  }
   
  double volatility() //average open-close difference of the last bar_num
  {

   double avg_price = 0;

   for(int a=0; a<bar_num; a++)
     {

      double movement = Open[a]-Close[a];

      if(movement<0)
        {
         avg_price+=(-movement);
        }
      else
        {
         avg_price+=movement;
        }
     }
   
   avg_price = avg_price/bar_num;
   
   return (avg_price/Point/CURRENCY_LEVERAGE);
  }
   
   
   string getMarketCondition(float trend){
         return (trend>volatility())?"DOWNTREND":((trend<-volatility())?"UPTREND":"SIDEWAYS");
   }
   
   bool checkMarketSIDEWAYS(){
            return (getMarketCondition(marketDirection())=="SIDEWAYS");
   }
   
   void marketConditionTP(){  
   
    /*
    marketConditionTP closes clear direction orders with TP 0.0
    marketConditionTP closes sideways orders if direction changes.
    
    from clear direction to sideways
    martingale will be activated
    Order TP will be altered
    maringale closes the order__
    
    from sideways to clear direction
    martingale will be stopped
    sideways orders will be closed__
    
    from clear direction to opp clear direction
    opp positive trade with tp 0.0 is closed___
    
    */
    
      if(!checkMarketSIDEWAYS()){
      
             closeSideWayOrders(); // From sideways to clear direction run away
      
            if(getMarketCondition(marketDirection())=="UPTREND"){ // From clear direction to oppo clear direction
               closeClearDirectionOrders(OP_SELL); 
            }else if(getMarketCondition(marketDirection())=="DOWNTREND"){
               closeClearDirectionOrders(OP_BUY);
            }
      }
   }
   
   void drawMarketCondition(string trend,float volatility,float spread){
   
   int x=0; int y=0;
   string name;
   string text;
   
   name = "trend";
   text="("+trend+")";
   ObjectDelete(0,name);
      if (ObjectFind(0, name)==-1) {
         ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x+1);
         ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y+1);
         ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_LOWER);
         ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
         ObjectSetInteger(0, name, OBJPROP_COLOR, clrDarkOrange);
         ObjectSetString(0, name, OBJPROP_FONT, "Arial");
         ObjectSetString(0, name, OBJPROP_TEXT, text);
      }
      
      name = "retracement";
      text ="PIPS("+(volatility/LOT)+")";
      ObjectDelete(0,name);
      if (ObjectFind(0, name)==-1) {
         ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x+120);
         ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y+1);
         ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_LOWER);
         ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
         ObjectSetInteger(0, name, OBJPROP_COLOR, clrOrangeRed);
         ObjectSetString(0, name, OBJPROP_FONT, "Arial");
         ObjectSetString(0, name, OBJPROP_TEXT, text);
      }
      
      name = "volatility";
      text = "PROFIT ($"+(volatility)+")";
      ObjectDelete(0,name);
      if (ObjectFind(0, name)==-1) {
         ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x+245);
         ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y+1);
         ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_LOWER);
         ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
         ObjectSetInteger(0, name, OBJPROP_COLOR, clrDarkOrange);
         ObjectSetString(0, name, OBJPROP_FONT, "Arial");
         ObjectSetString(0, name, OBJPROP_TEXT, text);
      }
      name = "spread";
      text= "SPREAD("+MathRound(spread/Point)+")";
      ObjectDelete(0,name);
      if (ObjectFind(0, name)==-1) {
         ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x+400);
         ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y+1);
         ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_LOWER);
         ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
         ObjectSetInteger(0, name, OBJPROP_COLOR, clrOrangeRed);
         ObjectSetString(0, name, OBJPROP_FONT, "Arial");
         ObjectSetString(0, name, OBJPROP_TEXT, text);
      }
   }
  
  
  void closeSideWayOrders(){
    for(int aa=0; aa<OrdersTotal(); aa++) //close all positive opposite trades
     {
      OrderSelect(aa,SELECT_BY_POS);
      if(OrderTakeProfit()!=0){
            double PRICE = (OrderType()==OP_BUY?Bid:Ask);
            OrderClose(OrderTicket(),OrderLots(),PRICE,3,White);
      }
     }
   }
   
  void closeClearDirectionOrders(int orderType)
  {

   for(int aa=0; aa<OrdersTotal(); aa++) //close all positive opposite trades
     {
      OrderSelect(aa,SELECT_BY_POS);

      if(OrderType()==orderType)
        {
         if(OrderProfit()>0 && OrderTakeProfit()==0)
           {
            double PRICE = (OrderType()==OP_BUY?Bid:Ask);
            OrderClose(OrderTicket(),OrderLots(),PRICE,3,White);
           }
        }
     }

  } 
  
//+------------------------------------------------------------------+
