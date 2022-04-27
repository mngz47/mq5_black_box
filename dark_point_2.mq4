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
// Trade USTECH M5             |
//+------------------------------------------------------------------+

 
int OnInit()
  {
  
  double indicator =  iCustom(Symbol(), PERIOD_CURRENT, "Dark Point", 0, 0, 0);
      
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

int total_order = 0;

void OnTick()
  {
  
    //take profit
    string obj_name = ObjectName(ObjectsTotal()-1);
    double tp_price = ObjectGet(obj_name, OBJPROP_PRICE1);
    
    //stop loss
    int sl_object_index = ((ObjectsTotal()-4)/11)+6;
    obj_name = ObjectName(sl_object_index);
    double sl =  ObjectGet(obj_name, OBJPROP_PRICE1);
    
    //Print(sl+";"+tp_price);
    
    bool orderType =  tp_price>sl;  //buy condition  
    
    double PRICE = (Ask+Bid)/2;    
    
    //Print(PRICE+"<>"+total_order);
    
  if((orderType? (PRICE<tp_price) : (PRICE>tp_price))){
  
    if((TotalOrder(MAGIC)<NO_OF_TRADES) && total_order<NO_OF_TRADES){ // Limit number of trades per signal 
      
    
         Print("(orderType,"+obj_name+",tp)SIGNAL("+(orderType?"buy":"Sell")+","+sl+","+tp_price+")");
    
         // OrderSend(Symbol(),(orderType?OP_BUY:OP_SELL),LOT,Ask,0,sl,tp_price,0,MAGIC,0,clrBlack);
          
          
         total_order++;   
    }
 }else{
 
         total_order=0;
         
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
