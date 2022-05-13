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
//       Expert initialization function                  
//       US30   H1
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

int total_order = 1;

double lastTP = 0; //keep track of successful tp to prevent repeat entry (in consolidating market)
double lastSL = 0;

void OnTick()
  {
  
    //take profit
    string obj_name = ObjectName(ObjectsTotal()-1);
    double tp_price = ObjectGet(obj_name, OBJPROP_PRICE1);
    
    int tp2_object_index = ((ObjectsTotal()-4)/9*3);
    obj_name = ObjectName(tp2_object_index);
    double tp2 =  ObjectGet(obj_name, OBJPROP_PRICE1);
    
    int tp1_object_index = ((ObjectsTotal()-4)/9*2);
    obj_name = ObjectName(tp1_object_index);
    double tp1 =  ObjectGet(obj_name, OBJPROP_PRICE1);
    
    int sl_object_index = ((ObjectsTotal()-4)/9);
    obj_name = ObjectName(sl_object_index);
    double sl =  ObjectGet(obj_name, OBJPROP_PRICE1);
    
    
   // Print(sl+";"+tp_price);
    
    bool orderType =  tp_price>sl;  //buy condition  
    
    double PRICE = (Ask+Bid)/2;    
    
    //Print(PRICE+"<>"+total_order);
    
  if((orderType? (PRICE<tp_price && PRICE>sl) : (PRICE>tp_price && PRICE<sl))){
  if((TotalOrder(MAGIC)<=NO_OF_TRADES) && total_order<=NO_OF_TRADES){ // Limit number of trades per signal 
      if((lastTP!=tp_price) && (lastSL!=sl)){
      
      tp_price = (total_order==2?tp2:(total_order==3?tp1 : tp_price));
      
         Print("(orderType,"+obj_name+",tp)SIGNAL("+(orderType?"buy":"Sell")+","+sl+","+tp_price+")");
         //OrderSend(Symbol(),(orderType?OP_BUY:OP_SELL),LOT,Ask,0,sl,tp_price,0,MAGIC);//0,clrBlack
         total_order++;   
      }
    }
   }else{
      if((lastTP!=tp_price) && (lastSL!=sl)){
            total_order=0;
            lastTP = tp_price;
            lastSL = sl; 
            Print("Total Order Reset");
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