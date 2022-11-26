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
input float    LOT=0.01;
input int      NO_OF_TRADES=3;
input int      MAGIC=838;

int OnInit()
  {
  
 indicator  =  iCustom(Symbol(), PERIOD_CURRENT, "Order-Block-Indicator-for-MT4", 0, 0, 0);
      
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

double lastTP = 0; //keep track of successful tp to prevent repeat entry (in consolidating market)
double lastSL = 0;

double indicator = 0;

void OnTick()
  {
  
  
   detectNewBar();
   if(isNewBar){
   
    indicator  =  iCustom(Symbol(), PERIOD_CURRENT, "Order-Block-Indicator-for-MT4", 0, 0, 0);
   
      if(indicator){
      
      }else{
            Print("Fix Indicator");
      }
      isNewBar = false;
   }
   
      // if(TradingTime()){
   NewOrder();
      //}
   
  }
  
  bool TradingTime(){
  
            bool time = false;
            
            if((Hour()>19 || Hour()<6)){
                  time = true;
            }
            
         return time;
  }
  
  void NewOrder(){
  
    //take profit
    string obj_name = ObjectName(0);
    double sell_price = ObjectGet(obj_name, OBJPROP_PRICE1);
    
    obj_name = ObjectName(3);
    double buy_price =  ObjectGet(obj_name, OBJPROP_PRICE1);
    
     
    double PRICE = (Ask+Bid)/2;    
    
    if((TotalOrder(MAGIC)<NO_OF_TRADES) && total_order<NO_OF_TRADES){ // Limit number of trades per signal 
    if(PRICE>=sell_price){
    
    OrderSend(Symbol(),OP_SELL,LOT,Ask,0,0,buy_price,0,MAGIC);
    
    }else if(PRICE<=buy_price){
    
    OrderSend(Symbol(),OP_BUY,LOT,Ask,0,0,sell_price,0,MAGIC);
    
       } 
     }
  }
  
  
  void CloseOrders(int max,int magic){
       for(int a=0;a<max;a++){
      OrderSelect(a,SELECT_BY_POS);
           if(OrderMagicNumber() == magic)
         {
         OrderSelect(a,SELECT_BY_POS);
         double PRICE = (OrderType()==OP_BUY?Bid:Ask);
         OrderClose(OrderTicket(),OrderLots(),PRICE,3,CLR_NONE);
         }  
      }
  }
  
  
  void ModifyOrders(double sl,double tp,int magic){
      for(int a=0;a<OrdersTotal();a++){
      OrderSelect(a,SELECT_BY_POS);
           if(OrderMagicNumber() == magic)
         {
           OrderSelect(a,SELECT_BY_POS);
         OrderModify(OrderTicket(),OrderOpenPrice(),sl,tp,0);//,clrBlack
           //Print("(sl,tp)MODIFY("+sl+","+tp+")");
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