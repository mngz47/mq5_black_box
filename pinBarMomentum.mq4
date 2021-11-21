//+------------------------------------------------------------------+
//|                                              pinBarEngulfing.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- input parameters
input float    LOT=0.02;
input int      TARGET_PIPS=40;
input int      NO_OF_TRADES=1;
input int      MAGIC=838;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
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
void OnTick()
  {
  
  
  detectNewBar();
   if(isNewBar){
   newEntry();
   }
  
//---
   
  }

   //PIN BAR 
   
   bool pinBar(int index){
  
   float open_close = (Open[index]>Close[index]?Open[index]:Close[index]); //used to determine wick size and stop-loss
   float wick = High[index]-open_close; //size of wick of prevoius bar
  
   open_close = (Open[index]<Close[index]?Open[index]:Close[index]);
   float rejection_wick = open_close-Low[index];
   
   if(!((wick/Point>TARGET_PIPS) || (rejection_wick/Point>TARGET_PIPS))){ //check if target pips are available in market either wick of bar
    Print("USE Target PIPS ("+ (wick/Point) +") - ("+ (rejection_wick/Point) +")");
   }
   
   return ((wick/Point>TARGET_PIPS) || (rejection_wick/Point>TARGET_PIPS));
     
   }
   
    //Engulfing candle
    
    
    const int P_CANDLE = 1;
    const int N_CANDLE = 0;
    
    
   bool engulfingCandle(int index,int candle_type){
   
   float candle = (Open[index]>Close[index]? Open[index]-Close[index]: Close[index]-Open[index]);
   return ((candle/Point>TARGET_PIPS) && (candle_type==N_CANDLE?Open[index]>Close[index]:(candle_type==P_CANDLE?Open[index]<Close[index]:false)));
   
   } 
    
    double getCandle(){
      int index = (isDojiReverse()?2:1);
      return (Open[index]>Close[index]? Open[index]-Close[index]: Close[index]-Open[index]);
    
    }
    
    bool isDojiReverse(){
         return (pinBar(1));  
    }
    
    bool Doji(int candle_type){
         return (isDojiReverse()?pinBar(1) && engulfingCandle(2,candle_type):pinBar(2) && engulfingCandle(1,candle_type));
    }
    
    //take profit low/high of 
    //stop loss low/high of wick/pinBar
    
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
  
   datetime Old_Time;
   datetime New_Time[1];
   
   bool isNewBar = true;
    
    void detectNewBar(){ //monitor bar activity
    
// copying the last bar time to the element New_Time[0]
   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0) // ok, the data has been copied successfully
     {
      if(Old_Time!=New_Time[0]) // if old time isn't equal to new bar time
        {
         Print("We have new bar here ",New_Time[0]," old time was ",Old_Time);
          Old_Time=New_Time[0];// saving bar time
          isNewBar = true;
        }
     }
   else
     {
      Print("Error in copying historical times data, error =",GetLastError());
      ResetLastError();
     }
    }
    
    void newEntry(){
    
   if((TotalOrder(MAGIC)<NO_OF_TRADES)){ //limiting total number of trades during price break
   
    double Price  = (Ask+Bid)/2;
   
   if((Price>High[1]) && (Price<(High[1]+20*Point)) && Doji(P_CANDLE)){ //specific price target range (20pips) above high
   
      //stoploss at pinBar
      float sl = Low[2];//(T0ARGET_PIPS?Ask-TARGET_PIPS*Point:open_close);   
      float tp = (Ask+(getCandle()/LOT)*Point);
      OrderSend(Symbol(),OP_BUY,LOT,Ask,0,sl,tp,0,MAGIC,0,clrAliceBlue);
      isNewBar = false;
   
  
   }else if ((Price<Low[1]) && (Price>(Low[1]-20*Point)) && Doji(N_CANDLE)){ //specific price target range below low
   
      float sl = High[2];//(TARGET_PIPS?Bid+TARGET_PIPS*Point:open_close); 
      float tp = (Bid-(getCandle()/LOT)*Point);
      OrderSend(Symbol(),OP_SELL,LOT,Bid,0,sl,tp,0,MAGIC,0,clrBlack);
      isNewBar = false;
  
   }
   }
   }