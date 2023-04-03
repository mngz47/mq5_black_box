//+------------------------------------------------------------------+
//|                                                 Price_Action.mq4 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//--- input parameters
input float    LOT=0.01;
input int      NO_OF_TRADES=3;
input int      MAGIC=838;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   
   ChartSetInteger(0,CHART_COLOR_BACKGROUND,clrAliceBlue);
   ChartSetInteger(0,CHART_COLOR_FOREGROUND,clrBlack);
   ChartSetInteger(0,CHART_COLOR_GRID,clrGreen);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,clrRed);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,clrGreen);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
  
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
    
  bool rejectionWickRoof(int index){
   
   float open_close = (Open[index]>Close[index]?Open[index]:Close[index]);
   float wick = High[index]-open_close;
   return (((Open[index]-Close[index])<wick) && Open[index+1]<High[index]); 
   
   }
   
   bool rejectionWickFloor(int index){
   
   float open_close = (Open[index]<Close[index]?Open[index]:Close[index]);
   float wick = open_close-Low[index];
   return (((Close[index]-Open[index])<wick) && Open[index+1]>Low[index]);
    
   }
   
   bool doubleBarRoof(int index){
   return (Low[index+1]>=Low[index] && Open[index+2]<High[index]);
   }
   
   bool doubleBarFloor(int index){
   return (High[index+1]<=High[index] && Open[index+2]>Low[index]);
   }
    
    void newEntry(){
   if((TotalOrder(MAGIC)<NO_OF_TRADES)){ 
    double Price  = (Ask+Bid)/2;
   if(rejectionWickFloor(1) || doubleBarFloor(1)){
      closeAllTrades(MAGIC);
      float sl = Low[1];
      float tp = 0;
      OrderSend(Symbol(),OP_BUY,LOT,Ask,0,sl,tp,0,MAGIC,0,clrGreen);
      isNewBar = false;
   }else if (rejectionWickRoof(1) || doubleBarRoof(1)){ 
      closeAllTrades(MAGIC);
      float sl = High[1];
      float tp = 0;
      OrderSend(Symbol(),OP_SELL,LOT,Bid,0,sl,tp,0,MAGIC,0,clrRed);
      isNewBar = false;
   }
   }
   }
   
   void closeAllTrades(int magic){
    for(int aa=0;aa<OrdersTotal();aa++){
         OrderSelect(aa,SELECT_BY_POS);
        if(OrderMagicNumber() == magic && OrderProfit()>0)
         {
        double PRICE = (OrderType()==OP_BUY?Bid:Ask);
        OrderClose(OrderTicket(),OrderLots(),PRICE,3,White);
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