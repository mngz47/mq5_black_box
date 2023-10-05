//+------------------------------------------------------------------+
//|                                              weekly_bias.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//                      Use on weekly timeframe
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- input parameters
input float    LOT=0.01;
input int      NO_OF_TRADES=1;
input int      MAGIC=838;
input int      SL=70;

int OnInit()
  {
//---
   
   ChartSetInteger(0,CHART_COLOR_BACKGROUND,clrAliceBlue);
   ChartSetInteger(0,CHART_COLOR_FOREGROUND,clrBlack);
   ChartSetInteger(0,CHART_COLOR_GRID,clrGreen);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,clrBlack);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,clrYellow);
   
//---
   return(INIT_SUCCEEDED);
  }

void OnTick()
  {
  
  lastWeekHighBreak();
  lastWeekLowBreak();
  
   if(TradingTime()){
   newEntry();
   }
  }

   bool highBreak = false;
   
   void lastWeekHighBreak(){
   double Price  = (Ask+Bid)/2;
   highBreak = (Price>High[1]);
     
   }
   
   bool lowBreak = false;
   
   void lastWeekLowBreak(){
   double Price  = (Ask+Bid)/2;
   lowBreak = (Price<Low[1]);
     
   }
   
     bool TradingTime(){
  
            bool time = false;
            
            if((Hour()>6 && Hour()<7)){
                  time = true;
            }
            
         return time;
  }
   
    void newEntry(){
    
   if((TotalOrder(MAGIC)<NO_OF_TRADES)){ //limiting total number of trades during price break
   if(lowBreak){ 
   
      float sl = Ask-SL*Point; 
      float tp = 0;
      OrderSend(Symbol(),OP_BUY,LOT,Ask,0,sl,tp,0,MAGIC,0,clrAliceBlue);
     
   
   }else if(highBreak){ 
   
      float sl = Bid+SL*Point;
      float tp = 0;
      OrderSend(Symbol(),OP_SELL,LOT,Bid,0,sl,tp,0,MAGIC,0,clrBlack);
    
  
   }
   }
   }
   
     double TotalOrder(int magic)
  {   
   double GetTotalOrder = 0;
   for(int cnt = 0; cnt < OrdersTotal(); cnt++)
     {
       OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
       if(OrderMagicNumber() == magic)
         {
           GetTotalOrder += (OrdersTotal());
         }   
     }
   return(GetTotalOrder);
  }
  
