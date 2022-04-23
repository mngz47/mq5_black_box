//+------------------------------------------------------------------+
//|                                                   dark_point.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- input parameters
input float    LOT=0.02;
input int      NO_OF_TRADES=3;
input int      MAGIC=838;


//+------------------------------------------------------------------+
//| Expert initialization function                   
// Trade US30 H4             |
//+------------------------------------------------------------------+
int OnInit()
  {
  
   double indicator =  iCustom(Symbol(), PERIOD_CURRENT, "Dark Point", 0, 0, 0);
      
  }
   
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
  
  double indicator =  iCustom(Symbol(), PERIOD_CURRENT, "Dark Point", 0, 0, 0);
  if(indicator){
  
  string obj_name = ObjectName(ObjectsTotal()-1);
  
  datetime signal_time  =  ObjectGet(obj_name, OBJPROP_TIME1);
  
  if((signal_time+10*60) < TimeCurrent()){ // Use signal within 10 minutes of being released
  if((TotalOrder(MAGIC)<NO_OF_TRADES)){ // Limit number of trades per signal
  
    double tp_price = ObjectGet(obj_name, OBJPROP_PRICE1);
    
    bool orderType =  tp_price>PRICE_OPEN; //buy if condition is true
     
    double sl_object_index = ObjectsTotal()/5*2;
    
    obj_name = ObjectName(sl_object_index);
    
    double sl =  ObjectGet(obj_name, OBJPROP_PRICE1);
    
    Print("(time,orderType,sl,tp)SIGNAL("+signal_time+","+(orderType?"buy":"Sell")+","+sl+","+tp_price+")");
    
    OrderSend(Symbol(),(orderType?OP_BUY:OP_SELL),LOT,(orderType?Bid:Ask),0,sl,tp_price,0,MAGIC,0,clrAliceBlue);
 
 }
  }
   }
//---
   
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
