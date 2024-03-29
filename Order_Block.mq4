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
input int      SL=70;

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
double sell_price2;
double buy_price;
double buy_price2;
string obj_name;

void OnTick()
  {
  
  
   detectNewBar();
   if(isNewBar){
   
     indicator  =  iCustom(Symbol(), PERIOD_CURRENT, "Order-Block-Indicator-for-MT4", 0, 0, 0);
   
     obj_name = ObjectName(0);
     sell_price = ObjectGet(obj_name, OBJPROP_PRICE1);
     
     obj_name = ObjectName(1);
     sell_price2 =  ObjectGet(obj_name, OBJPROP_PRICE1);
    
     obj_name = ObjectName(3);
     buy_price =  ObjectGet(obj_name, OBJPROP_PRICE1);
     
      obj_name = ObjectName(4);
     buy_price2 =  ObjectGet(obj_name, OBJPROP_PRICE1);
   
      if(indicator){
      
      }else{
            Print("Fix Indicator");
      }
      
     
      ModifyOrders();
      
      isNewBar = false;
   }
   
   ModifyLastSL();
   NewOrder();
   
  }
  
  
    void ModifyOrders(){
      for(int a=0;a<OrdersTotal();a++){
      OrderSelect(a,SELECT_BY_POS);
           if(OrderMagicNumber() == MAGIC)
         {
           OrderSelect(a,SELECT_BY_POS);
           
           double m_price = (OrderType()==OP_BUY? (lastSL<buy_price?sell_price:sell_price2) : (lastSL>sell_price?buy_price:buy_price2) );
       
           OrderModify(OrderTicket(),OrderOpenPrice(),lastSL,m_price,0);
           lastTP = m_price;
           
         }  
      }
  }
  
  void ModifyLastSL(){
  
  double PRICE = (Ask+Bid)/2;
  
  if(OrdersTotal()>0){
      OrderSelect(0,SELECT_BY_POS);
           if(OrderMagicNumber() == MAGIC)
         {
           OrderSelect(0,SELECT_BY_POS);
           if(OrderType()==OP_BUY){
           
           if(PRICE>=lastTP){
           
           lastSL = 0;
           
           }
           
           }else{
           
           if(PRICE<=lastTP){
           
           lastSL = 0;
           
           }
          }
        }
     }
  }
  
  double lastSL = 0;
  double lastTP = 0;
  
  void NewOrder(){
  
    double PRICE = (Ask+Bid)/2;    
    
    if((TotalOrder(MAGIC)<NO_OF_TRADES)){ // Limit number of trades per signal 
    if(PRICE>=sell_price){
    
    if(lastSL!=0 && PRICE>=(lastSL)){
    
    OrderSend(Symbol(),OP_BUY,LOT,Ask,0,lastSL,sell_price2,0,MAGIC);
    lastTP = sell_price2;
    
    }else{
    lastSL = Bid+SL*Point;
    
    OrderSend(Symbol(),OP_SELL,LOT,Bid,0,lastSL,buy_price,0,MAGIC);
    lastTP = buy_price;
    
    }
    
    }else if(PRICE<=buy_price){
    
    if(lastSL!=0 && PRICE<=(lastSL)){
    
    OrderSend(Symbol(),OP_SELL,LOT,Ask,0,lastSL,buy_price2,0,MAGIC);
    lastTP = buy_price2;
    
    }else{
    lastSL = Ask-SL*Point;
    
    OrderSend(Symbol(),OP_BUY,LOT,Ask,0,lastSL,sell_price,0,MAGIC);
    lastTP = sell_price;
    
    }
    
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
