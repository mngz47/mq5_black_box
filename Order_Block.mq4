//+------------------------------------------------------------------+
//|                                                   order_block.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- input parameters
input float    LOT=0.01;
input int      NO_OF_TRADES=3;
input int      MAGIC=838;
input int      SL=30;

int OnInit()
  {
  
     indicator  =  iCustom(Symbol(), PERIOD_CURRENT, "Order-Block-Indicator-for-MT4", 0, 0, 0);
      
     obj_name = ObjectName(0);
     sell_price = ObjectGet(obj_name, OBJPROP_PRICE1);
    
     obj_name = ObjectName(3);
     buy_price =  ObjectGet(obj_name, OBJPROP_PRICE1);     
      
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
   
  }
  
double indicator = 0;
double sell_price;
double buy_price;
string obj_name;

void OnTick()
  {
  
  
   detectNewBar();
   if(isNewBar){
   
     indicator  =  iCustom(Symbol(), PERIOD_CURRENT, "Order-Block-Indicator-for-MT4", 0, 0, 0);
   
     obj_name = ObjectName(0);
     sell_price = ObjectGet(obj_name, OBJPROP_PRICE1);
    
     obj_name = ObjectName(3);
     buy_price =  ObjectGet(obj_name, OBJPROP_PRICE1);
   
      if(indicator){
      
      }else{
            Print("Fix Indicator");
      }
      isNewBar = false;
   }
   
   NewOrder();
   
  }
  
  void NewOrder(){
  
    double PRICE = (Ask+Bid)/2;    
    
    if((TotalOrder(MAGIC)<NO_OF_TRADES)){ // Limit number of trades per signal 
    if(PRICE>=sell_price){
    
    double sl = Bid+SL*Point;
    
    OrderSend(Symbol(),OP_SELL,LOT,Bid,0,sl,buy_price,0,MAGIC);
    
    }else if(PRICE<=buy_price){
    
    double sl = Ask-SL*Point;
    
    OrderSend(Symbol(),OP_BUY,LOT,Ask,0,sl,sell_price,0,MAGIC);
    
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
           GetTotalOrder++;
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
