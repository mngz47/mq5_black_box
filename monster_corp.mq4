//+------------------------------------------------------------------+
//|                                     Copyright 2021, Monster Corp
//+------------------------------------------------------------------+


#property copyright "Copyright 2021, Monster Corp"
#property link      "http://www.mql5.com"
#property version   "1.00"


//#include <Trade\Trade.mqh>

//--- input parameters
input int      StopLoss=0;      // Stop Loss
input int      TakeProfit=30;   // Take Profit
input int      ADX_Period=8;     // ADX Period
input int      MA_Period=8;      // Moving Average Period
input int      EA_Magic=12345;   // EA Magic Number


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

  double FastMACurrent;
  double FastMA_Overall;
  double SlowMACurrent;
  double SlowMA_Overall;
  
  
  int findNextPeak(int mode,int count,int startBar){
  if(startBar<0){
  count +=startBar;
  startBar = 0;
  }
  return (mode==MODE_HIGH?
  iHighest(Symbol(),Period(),(ENUM_SERIESMODE)mode,count,startBar):
  iLowest(Symbol(),Period(),(ENUM_SERIESMODE)mode,count,startBar));
  }
  
   int findPeak(int mode,int count,int startBar){
   
         if(mode!=MODE_HIGH && mode!=MODE_LOW) return(-1);
         
         int currentBar = startBar;
         int foundBar = findNextPeak(mode, count*2+1, currentBar-count);
         
         while (foundBar!=currentBar){
         currentBar = findNextPeak(mode, count, currentBar+1);
         foundBar = findNextPeak(mode, count*2+1, currentBar-count);
         }
      return currentBar;         
  }
  
  void drawAnalysisLines(){
  
  int bar1 = findPeak(MODE_HIGH,5,0);
  int bar2 = findPeak(MODE_HIGH,5,bar1+1);
  
  ObjectDelete(0,"high");
  ObjectCreate(0, "high", OBJ_HLINE,0,iTime(Symbol(),Period(),bar2),iHigh(Symbol(),Period(),bar2));
  ObjectSetInteger(0, "high", OBJPROP_COLOR, clrPink);
  ObjectSetInteger(0, "high", OBJPROP_WIDTH, 3);
  
  ObjectDelete(0,"upper");
  ObjectCreate(0, "upper", OBJ_TREND, 0, iTime(Symbol(),Period(),bar2),iHigh(Symbol(),Period(),bar2),iTime(Symbol(),Period(),bar1),iHigh(Symbol(),Period(),bar1));
  ObjectSetInteger(0, "upper", OBJPROP_COLOR, clrBlue);
  ObjectSetInteger(0, "upper", OBJPROP_WIDTH, 3);
  ObjectSetInteger(0, "upper", OBJPROP_RAY_RIGHT, true);
  
  bar1 = findPeak(MODE_LOW,5,0);
  bar2 = findPeak(MODE_LOW,5,bar1+1);
  
  ObjectDelete(0,"low");
  ObjectCreate(0, "low", OBJ_HLINE,0,iTime(Symbol(),Period(),bar1),iLow(Symbol(),Period(),bar1));
  ObjectSetInteger(0, "low", OBJPROP_COLOR, clrPink);
  ObjectSetInteger(0, "low", OBJPROP_WIDTH, 3);
  
  
  ObjectDelete(0,"lower");
  ObjectCreate(0, "lower", OBJ_TREND, 0, iTime(Symbol(),Period(),bar2),iHigh(Symbol(),Period(),bar2),iTime(Symbol(),Period(),bar1),iHigh(Symbol(),Period(),bar1));
  ObjectSetInteger(0, "lower", OBJPROP_COLOR, clrBlue);
  ObjectSetInteger(0, "lower", OBJPROP_WIDTH, 3);
  ObjectSetInteger(0, "lower", OBJPROP_RAY_RIGHT, true);
  
  }
  
int OnInit()
  {
  
  int FastMAPeriod = 2;
  int SlowMAPeriod = 30;
  
  FastMACurrent = iMA(NULL,PERIOD_CURRENT, FastMAPeriod, 0, 0, 0, 0);
  FastMA_Overall = iMA(NULL, PERIOD_H4, FastMAPeriod, 0, 0, 0, 0);
  
  SlowMACurrent = iMA(NULL, PERIOD_CURRENT, SlowMAPeriod, 0, 0, 0, 0);
  SlowMA_Overall = iMA(NULL, PERIOD_H4, SlowMAPeriod, 0, 0, 0, 0);
  
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

 //CTrade m_trade;
 
 int Oxygen = 0;
 
 int base = 20;
 
 int inhale = base+7; //  profit intake period - increases profit potential by waiting for price to increase even more
 int exhale = base+49; //  -profit intake period - equity neutralize period - REDUCES profit to reduce equity reduce breath 
 
 int scrape = base+99; //Scraper does same job as position correction(open space for new potential positions)
 // kept high to increase overall profit pontential
 // main target is to force market movement and not subsitute target profit
 // is a form of inhale
 

double acc_red = -700; // danger zone indicator - to start reversing margin on account.


int bar_num = 21;

double volatility(){//average open-close difference of the last bar_num

double avg_price = 0;

for(int a=0;a<bar_num;a++){

   double movement = Open[a]-Close[a];
   
  if( movement<0){
  avg_price+=(-movement);
  }else{
  avg_price+=movement;
  }
}
avg_price = avg_price/bar_num;
return avg_price;
}


double volatility_2(){//average of highest and lowest price in the last bar_num
   double Highest = High[0];
   double Lowest = Low[0];
   
   // Scan the bar_num candles and update the values of the highest and lowest.
   for (int i = 0; i <= bar_num; i++)
   {
      if (High[i] > Highest) Highest = High[i];
      if (Low[i] < Lowest) Lowest = Low[i];
   }
   return (Highest-Lowest)/2;
}

double profit = ((volatility()+volatility_2())/2)/Point; //31


double marketDirection(){ 
   return (Open[bar_num]-Close[0]);
}

double priceRegion = 0.0002;

bool isPullBackHigh(double price){ //check if current price is in region of last highest price for bar_num
   
  int bar1 = findPeak(MODE_HIGH,5,0);
  double Highest = bar1;
  return (((Highest-priceRegion)<price));//((Highest+priceRegion)>price) && checking last highest price region

}

bool isPullBackLow(double price){ //check if current price is in region of last lowest price for bar_num
   
   int bar1 = findPeak(MODE_LOW,5,0);
   double Lowest = bar1;
   return (((Lowest+priceRegion)>price));// && ((Lowest-priceRegion)<price) checking last lowest price region

}

void OnTick()
  {
//--- Do we have enough bars to work with
   if(Bars(_Symbol,_Period)<20) // if total bars is less than 60 bars
     {
      Print("We have less than 20 bars, EA will now exit!!");
      return;
     }  

// We will use the static Old_Time variable to serve the bar time.
// At each OnTick execution we will check the current bar time with the saved one.
// If the bar time isn't equal to the saved time, it indicates that we have a new tick.

   static datetime Old_Time;
   datetime New_Time[1];
   bool IsNewBar=false;

// copying the last bar time to the element New_Time[0]
   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0) // ok, the data has been copied successfully
     {
      if(Old_Time!=New_Time[0]) // if old time isn't equal to new bar time
        {
         IsNewBar=true;   // if it isn't a first call, the new bar has appeared
         if(IsTesting()) // Print("We have new bar here ",New_Time[0]," old time was ",Old_Time);
         Old_Time=New_Time[0];            // saving bar time
        }
     }
   else
     {
      Alert("Error in copying historical times data, error =",GetLastError());
      ResetLastError();
      return;
     }

//--- EA should only check for new trade if we have a new bar
   if(IsNewBar==false)
     {
      return;
     }
 
//--- Do we have enough bars to work with
   int Mybars=Bars(_Symbol,_Period);
   if(Mybars<30) // if total bars is less than 30 bars
     {
      Alert("We have less than 30 bars, EA will now exit!!");
      return;
     }

//--- Define some MQL5 Structures we will use for our trade
   
   MqlTick latest_price;      // To be used for getting recent/latest price quotes
   
    profit = ((volatility()+volatility_2())/2)/Point; //31
   
    drawAnalysisLines();

//--- Get the last price quote using the MQL5 MqlTick Structure
   if(!SymbolInfoTick(_Symbol,latest_price))
     {
      Alert("Error getting the latest price quote - error:",GetLastError(),"!!");
      return;
     }
           
            for(int a=0;a<OrdersTotal();a++){
   
                 OrderSelect(a,SELECT_BY_POS);
                 
                 double PRICE = (OrderType()==OP_BUY?Bid:Ask);
                 
            if(AccountInfoDouble(ACCOUNT_PROFIT)>1000 && (Oxygen%inhale==0)){ 
             
            Print(OrderTicket()," Profit From Position: ",(OrderProfit()));
            
            //OrderDelete(OrderTicket());
           OrderClose(OrderTicket(),OrderLots(),PRICE,3,White);
             //m_trade.PositionClose(PositionGetTicket(a)); // close trade of position if profit greater than 11 dollars
              
            }else if(OrderProfit()>=profit && (Oxygen%inhale==0)){
        
            Print(OrderTicket()," Profit From Position: ",(OrderProfit()));
           
           // m_trade.PositionClose(PositionGetTicket(a)); // close trade of position if profit greater than 11 dollars
            //OrderDelete(OrderTicket());
           OrderClose(OrderTicket(),OrderLots(),PRICE,3,White);
            pump_oxygen();
           
            }else if((OrderProfit())<-profit && (Oxygen%exhale==0)){
            
            if(AccountInfoDouble(ACCOUNT_PROFIT)<acc_red){
            Print(OrderTicket()," Profit From Position: ",(OrderProfit()));
            OrderClose(OrderTicket(),OrderLots(),PRICE,3,White);
           //OrderDelete(OrderTicket());
           // m_trade.PositionClose(PositionGetTicket(a)); 
            pump_oxygen();
            }
           
            }else if(OrderProfit()>11 && (Oxygen%scrape==0)){
            //(open space for new potential positions)
            //Scraper takes profit below normal target to accomodate stagnant market
           
             Print(OrderTicket()," Profit From Position: ",(OrderProfit()));
            //OrderDelete(OrderTicket());
            OrderClose(OrderTicket(),OrderLots(),PRICE,3,White);
            // m_trade.PositionClose(PositionGetTicket(a)); 
             pump_oxygen();
            
            }else if((OrderProfit()<=-(profit+5)) && (Oxygen%exhale==0)){// && OrderProfit()>=-15 && (Oxygen%exhale==0)
            //Position correction - take loss before it gets out of hand 
            
            Print(OrderTicket()," Profit From Position: ",(OrderProfit()));
            //OrderClose(OrderTicket());
            OrderClose(OrderTicket(),OrderLots(),PRICE,3,White);
            //OrderDelete(OrderTicket());
            //m_trade.PositionClose(OrderTicket()); 
            pump_oxygen();
            }
            
               }
     pump_oxygen(); // tick related movement      
   
   double LLot = 0.01;
   // dont place more than 2 orders at once for accont balance less than 100 dollars - prevent account from reaching 0 equity
    
           if(AccountInfoDouble(ACCOUNT_BALANCE)<=100){
           if(OrdersTotal()>=2){
                 return;
           }else{
                LLot=0.01; 
           }
           }else if(AccountInfoDouble(ACCOUNT_BALANCE)>10000){
           if(OrdersTotal()>=21){
                 return;
           }else{
                LLot=0.7; 
           }
           }else if(AccountInfoDouble(ACCOUNT_BALANCE)>5000){
           if(OrdersTotal()>=41){
                 return;
           }else{
                LLot=0.3; 
           }
           }
          
          
     if(!isRisk(OP_BUY))
     if(isPullBackLow(Ask))
     if(marketDirection()<0)// buy action - going up
     if((FastMA_Overall < SlowMA_Overall) && (FastMACurrent > SlowMACurrent))//|| 
     if(order_max())
         if(OrderSend(Symbol(),OP_BUY, LLot,Ask,3,0,0,"",EA_Magic,0,Blue)) //Request is completed or order placed
           {
           //Ask+profit*Point
         //Bid-profit*2*Point
      
           closePositiveOppTrade(OP_SELL);
            Print("A Buy order has been successfully placed !!");
           }
         else
           {
            Print("The Buy order request could not be completed - error:",GetLastError());
            ResetLastError();           
            return;
           }
     
         if(!isRisk(OP_SELL))
         if(isPullBackHigh(Bid))
         if(marketDirection()>0) // sell action - going down
         if((FastMA_Overall > SlowMA_Overall) && (FastMACurrent < SlowMACurrent)) // confirm overall direction of chart on 4h timeframe
         if(order_max())
         if(OrderSend(Symbol(),OP_SELL, LLot,Bid,3,0,0,"",EA_Magic,0,Red)) //Request is completed or order placed
           {
           //Bid-profit*Point
           //Bid+profit*2*Point
            closePositiveOppTrade(OP_BUY);
          
            Print("A Sell order has been successfully placed !!");
            
           }
         else
           {
            Print("The Sell order request could not be completed - error:",GetLastError());
            ResetLastError();
            return;
           }
        
     
   return;
  }
    
    
    void closePositiveOppTrade(int orderType){
    
     for(int aa=0;aa<OrdersTotal();aa++){//close all positive opposite trades
                 OrderSelect(aa,SELECT_BY_POS);
                  
                 if(OrderType()==orderType){
                     if(OrderProfit()>0){
                    double PRICE = (OrderType()==OP_BUY?Bid:Ask);
                      OrderClose(OrderTicket(),OrderLots(),PRICE,3,White);
                     }
                 }
                 }
    
    }
    
     void pump_oxygen(){
  if(Oxygen>=1000){
                Oxygen=0;
               }else{
                 Oxygen++;
               }
      }
    
    
     bool order_max(){
    int max = 14;
    
    if(AccountInfoDouble(ACCOUNT_BALANCE)<=100){
    max = 2;
    }else if(AccountInfoDouble(ACCOUNT_BALANCE)<=300){
    max = 3;
    }else if(AccountInfoDouble(ACCOUNT_BALANCE)<=500){
    max = 4;
    }else if(AccountInfoDouble(ACCOUNT_BALANCE)<=1000){
    max = 7;
    }else if(AccountInfoDouble(ACCOUNT_BALANCE)<=5000){
    max = 10;
    }
    
    return (OrdersTotal()<max);
    }
    
    
    void closeAllTrades(){
    for(int aa=0;aa<OrdersTotal();aa++){
        OrderSelect(aa,SELECT_BY_POS);
        double PRICE = (OrderType()==OP_BUY?Bid:Ask);
        OrderClose(OrderTicket(),OrderLots(),PRICE,3,White);
    }
    }
    
    
    bool isRisk(int orderType){ //more opportunity equals more risk
   
    double profit = 0;
    for(int aa=0;aa<OrdersTotal();aa++){// measure profit
        OrderSelect(aa,SELECT_BY_POS);
        profit += OrderProfit();
    }
    
    if(profit<0){//detect negetive profit
    profit = -profit;
    double loss = (profit/AccountInfoDouble(ACCOUNT_BALANCE)*100);//loss percentage
    
     if (loss>=30){//measure account risk of 30% threshold
    // closeAllTrades(); // exhausts the flow of oxygen
     return true;//account is at risk
     }else{
     return false;//no risk detected
     }
    }else{
    return (marketOpportunity(orderType)>=9); 
    // >=30% clarity is a risk avoiding trades in this region helps make money faster 1.09 profit
    // >=60% clarity is a risk because it is too far in the trend. opp direction region 1.08 profit
    // >=90% clarity has the most risk trade long gone 1.12 profit
    }
    }
    
    int marketOpportunity(int orderType){ //market opportunity - make more money with less trades
    int clarity = 0;
  
    for (int i = 0; i < 10; i++)
   {
    double  FastMACurrent = iMA(NULL,PERIOD_CURRENT, 2, 0, 0, 0, i);
    double  SlowMACurrent = iMA(NULL, PERIOD_CURRENT, 30, 0, 0, 0, i);
      if(OrderType()==OP_BUY){
         if(FastMACurrent > SlowMACurrent){
             clarity+=1;
         }else{
         break;
         }
      }else if(OrderType()==OP_SELL){
         if(FastMACurrent < SlowMACurrent){
            clarity+=1;
         }else{
         break;
         }
      }
   }
    return (clarity);
    }
    
//+-------------------
