//+------------------------------------------------------------------+
//|                                                 Price_Action.mq4 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input float    LOT=0.01;
input int      NO_OF_TRADES=1;
input int      MAGIC=838;

int OnInit()
  {
   
   ChartSetInteger(0,CHART_COLOR_BACKGROUND,clrAliceBlue);
   ChartSetInteger(0,CHART_COLOR_FOREGROUND,clrBlack);
   ChartSetInteger(0,CHART_COLOR_GRID,clrGreen);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,clrRed);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,clrGreen);
   return(INIT_SUCCEEDED);
  }
    
  datetime NewCandleTime = TimeCurrent();
bool IsNewCandle()
{
   if (NewCandleTime == iTime(Symbol(), 0, 0)) return false;
   else
   {
      NewCandleTime = iTime(Symbol(), 0, 0);
      return true;
   }
}

void OnTick()
  {
  if(IsNewCandle()){
   newEntry();
   }
  }
    
   float volume = 0;
   bool getMomentum(float wick){//movement strength towards specific direction
       if(wick>=volume){
         volume=wick;
       }
       return (wick>=volume);
   }
    
   float upBar(int index){//direction of candle going up
    return Close[index]-Open[index];
   }
   
   bool upReverse(int i2,int i1){//confirm change in direction
   return Open[i2]<Open[i1];
   }
    
   float downBar(int index){ //direction of candle going down
   return Open[index]-Close[index];
   }
  
   bool downReverse(int i2,int i1){//confirm change in direction
   return Open[i2]>Open[i1];
   }
  
   bool rejectionWickRoof(int index){
   float wick = High[index]-Close[index];
   return ((upBar(index)<wick) && upReverse(index+1,index) && getMomentum(wick)); 
   }
   
   bool rejectionWickFloor(int index){
   float wick = Close[index]-Low[index];
   return ((downBar(index)<wick) && downReverse(index+1,index) && getMomentum(wick));
   }
   
   bool doubleBarRoof(int index){
   bool lowBreak = Close[index+1]>Close[index];
   return (lowBreak && upReverse(index+2,index) && getMomentum(downBar(index)));
   }
   
   bool doubleBarFloor(int index){
   bool highBreak = Close[index+1]<Close[index];
   return (highBreak && downReverse(index+2,index) && getMomentum(upBar(index)));
   }
 
    void newEntry(){
   if(rejectionWickFloor(1) || doubleBarFloor(1)){
      closeTrades(MAGIC,OP_SELL);
         while((TotalOrder(MAGIC)<NO_OF_TRADES)){ 
            OrderSend(Symbol(),OP_BUY,LOT,Ask,0,0,0,0,MAGIC,0,clrGreen);
         }
   }else if (rejectionWickRoof(1) || doubleBarRoof(1)){ 
      closeTrades(MAGIC,OP_BUY);
         while((TotalOrder(MAGIC)<NO_OF_TRADES)){ 
            OrderSend(Symbol(),OP_SELL,LOT,Bid,0,0,0,0,MAGIC,0,clrRed);
         }
   }
   }
   
   void closeTrades(int magic,int type){
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
