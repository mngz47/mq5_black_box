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
input int      NO_OF_TRADES=1;
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
  
 bool isNewBar = false;
   void detectNewBar(){
    if(Hour()==3 || Hour()==7 || Hour()==11 || Hour()==15 || Hour()==19 || Hour()==23){
         isNewBar = true;
    }else{
         isNewBar = false;
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
   
   float wick = High[index]-Close[index];
   float upBar = Close[index]-Open[index];
   bool upReverse = Open[index+1]<Open[index];
   
   return ((upBar<wick) && upReverse); 
   }
   
   bool rejectionWickFloor(int index){
   
   float wick = Close[index]-Low[index];
   float downBar = Open[index]-Close[index];
   bool downReverse = Open[index+1]>Open[index];
   
   return ((downBar<wick) && downReverse);
   }
   
   bool doubleBarRoof(int index){
      bool lowBreak = Close[index+1]>Close[index];
      bool upReverse = Open[index+2]<Open[index];
   
   return (lowBreak && upReverse);
   }
   
   bool doubleBarFloor(int index){
      bool highBreak = Close[index+1]<Close[index];
      bool downReverse = Open[index+2]>Open[index];
   
   return (highBreak && downReverse);
   }
 
    void newEntry(){
   while((TotalOrder(MAGIC)<NO_OF_TRADES)){ 
   if(rejectionWickFloor(1) || doubleBarFloor(1)){
      closeAllTrades(MAGIC,OP_SELL);
      float sl = Low[1];
      float tp = 0;
      OrderSend(Symbol(),OP_BUY,LOT,Ask,0,sl,tp,0,MAGIC,0,clrGreen);
   }else if (rejectionWickRoof(1) || doubleBarRoof(1)){ 
      closeAllTrades(MAGIC,OP_BUY);
      float sl = High[1];
      float tp = 0;
      OrderSend(Symbol(),OP_SELL,LOT,Bid,0,sl,tp,0,MAGIC,0,clrRed);
   }
   }
   }
   
   void closeAllTrades(int magic,int type){
    for(int aa=0;aa<OrdersTotal();aa++){
         OrderSelect(aa,SELECT_BY_POS);
        if(OrderMagicNumber()==magic && OrderType()==type)
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
       OrderSelect(cnt, SELECT_BY_POS);
       if(OrderMagicNumber() == magic)
         {
           GetTotalOrder+=1;
         }   
     }
   return(GetTotalOrder);
  }
