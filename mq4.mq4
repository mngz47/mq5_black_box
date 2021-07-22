//+------------------------------------------------------------------+
//|                                                  My_First_EA.mq5 |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+


#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"


//#include <Trade\Trade.mqh>

//--- input parameters
input int      StopLoss=0;      // Stop Loss
input int      TakeProfit=30;   // Take Profit
input int      ADX_Period=8;     // ADX Period
input int      MA_Period=8;      // Moving Average Period
input int      EA_Magic=12345;   // EA Magic Number
// input double   Adx_Min=23.0;     // Minimum ADX Value

//--- Other parameters
int adxHandle; // handle for our ADX indicator
int maHandle;  // handle for our Moving Average indicator
double plsDI[],minDI[],maVal[]; // Dynamic arrays to hold the values of +DI, -DI and ADX values for each bars
int STP, TKP;   // To be used for Stop Loss & Take Profit values
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

  double FastMACurrent;
  double FastMAPrevious;
  double FastMA_Overall;
  double SlowMACurrent;
  double SlowMAPrevious;
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
  
  bool goingDown;
  bool goingUp;
  
int OnInit()
  {
  
  int FastMAPeriod = 2;
  int SlowMAPeriod = 30;
  
  //iMA(NULL,0,13,6,MODE_SMA,PRICE_CLOSE,0);
  //iMA(NULL,PERIOD_CURRENT, FastMAPeriod, 0, 0, 0, 0);
  
  FastMACurrent = iMA(NULL,PERIOD_CURRENT, FastMAPeriod, 0, 0, 0, 0);
  FastMAPrevious = iMA(NULL, 0, FastMAPeriod,6,MODE_SMA,PRICE_CLOSE, 1);
  
  FastMA_Overall = iMA(NULL, PERIOD_H4, FastMAPeriod, 0, 0, 0, 0);
  
  SlowMACurrent = iMA(NULL, PERIOD_CURRENT, SlowMAPeriod, 0, 0, 0, 0);
  SlowMAPrevious = iMA(NULL, 0, SlowMAPeriod, 6,MODE_SMA,PRICE_CLOSE, 1);
  
  SlowMA_Overall = iMA(NULL, PERIOD_H4, SlowMAPeriod, 0, 0, 0, 0);
  
  
  int bar1 = findPeak(MODE_HIGH,5,0);
  int bar2 = findPeak(MODE_HIGH,5,bar1+1);
  
  goingDown = ((bar2-bar1)>0);
  
  ObjectDelete(0,"upper");
  ObjectCreate(0, "upper", OBJ_TREND, 0, iTime(Symbol(),Period(),bar2),iHigh(Symbol(),Period(),bar2),iTime(Symbol(),Period(),bar1),iHigh(Symbol(),Period(),bar1));
  ObjectSetInteger(0, "upper", OBJPROP_COLOR, clrBlue);
  ObjectSetInteger(0, "upper", OBJPROP_WIDTH, 3);
  ObjectSetInteger(0, "upper", OBJPROP_RAY_RIGHT, true);
  
  bar1 = findPeak(MODE_LOW,5,0);
  bar2 = findPeak(MODE_LOW,5,bar1+1);
  
  goingUp = ((bar2-bar1)<0);
  
  ObjectDelete(0,"lower");
  ObjectCreate(0, "lower", OBJ_TREND, 0, iTime(Symbol(),Period(),bar2),iHigh(Symbol(),Period(),bar2),iTime(Symbol(),Period(),bar1),iHigh(Symbol(),Period(),bar1));
  ObjectSetInteger(0, "lower", OBJPROP_COLOR, clrBlue);
  ObjectSetInteger(0, "lower", OBJPROP_WIDTH, 3);
  ObjectSetInteger(0, "lower", OBJPROP_RAY_RIGHT, true);
  
//--- Get handle for ADX indicator
 //  adxHandle=iADX(NULL,0,8,PRICE_HIGH,MODE_PLUSDI,0);
//--- Get the handle for Moving Average indicator
 //  maHandle=iMA(NULL,0,8,8,MODE_SMMA,PRICE_MEDIAN,NULL);
//--- What if handle returns Invalid Handle
   if(adxHandle<0 || maHandle<0)
     {
      Alert("Error Creating Handles for indicators - error: ",GetLastError(),"!!");
      return(-1);
     }

//--- Let us handle currency pairs with 5 or 3 digit prices instead of 4
   STP = StopLoss;
   TKP = TakeProfit;
   if(_Digits==5 || _Digits==3)
     {
      STP = STP*10;
      TKP = TKP*10;
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- Release our indicator handles
   //IndicatorRelease(adxHandle);
   //IndicatorRelease(maHandle);
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
   return (Open[5]-Close[0]);
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
   
// the ADX DI+values array
   ArraySetAsSeries(plsDI,true);
// the ADX DI-values array
   ArraySetAsSeries(minDI,true);
// the MA-8 values arrays
   ArraySetAsSeries(maVal,true);


//--- Get the last price quote using the MQL5 MqlTick Structure
   if(!SymbolInfoTick(_Symbol,latest_price))
     {
      Alert("Error getting the latest price quote - error:",GetLastError(),"!!");
      return;
     }


//--- Copy the new values of our indicators to buffers (arrays) using the handle
  
  //ArrayCopy(plsDI,adxHandle,1,0,3)
  
  int adxHandleList[1];
     adxHandleList[0]= adxHandle;
   if(ArrayCopy(plsDI,adxHandleList,1,0,3)<0 || ArrayCopy(minDI,adxHandleList,2,0,3)<0)
     {
      Alert("Error copying ADX indicator Buffers - error:",GetLastError(),"!!");
      ResetLastError();
      return;
     }
     
     int maHandleList[1];
     maHandleList[0]= maHandle;
     if(ArrayCopy(maVal,maHandleList,0,0,3)<0)
     {
      Alert("Error copying Moving Average indicator buffer - error:",GetLastError());
      ResetLastError();
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
          

        //  if((ArraySize(maVal)>2) && (maVal[0]>maVal[1])  && (maVal[1]>maVal[2])) // MA-8 Increasing upwards 
   // if((plsDI[0]>minDI[0]))   // +DI greater than -DI
    
    // if((FastMACurrent > SlowMACurrent))//&& (FastMAPrevious < SlowMAPrevious)
    // if(goingUp)
     if(marketDirection()<0)// buy action - going up
     if((FastMA_Overall < SlowMA_Overall) && (FastMACurrent > SlowMACurrent))//|| 
     if(!sym_max(_Symbol))
         if(OrderSend(Symbol(),OP_BUY, LLot,Ask,3,0,0,"",EA_Magic,0,Blue)) //Request is completed or order placed
           {
           //Ask+profit*Point
         //Bid-profit*2*Point
      //  m_trade.Buy(LLot,_Symbol,latest_price.ask,NormalizeDouble(latest_price.ask - STP*_Point,_Digits),NormalizeDouble(latest_price.ask + TKP*_Point,_Digits),NULL)   
          closePositiveOppTrade(OP_SELL);
            Print("A Buy order has been successfully placed !!");
           }
         else
           {
            Print("The Buy order request could not be completed - error:",GetLastError());
            ResetLastError();           
            return;
           }
     
     
   //if((ArraySize(maVal)>2) && (maVal[0]<maVal[1]) && (maVal[1]<maVal[2]))//MA-8 decreasing downwards
      //  if((plsDI[0]<minDI[0]))  // -DI greater than +DI
         
         FastMA_Overall = iMA(NULL, PERIOD_H1, 2, 0, 0, 0, 0);
         SlowMA_Overall = iMA(NULL, PERIOD_H1, 30, 0, 0, 0, 0);
         
         //if((FastMACurrent < SlowMACurrent)) // correspond direction with current timeframe && (FastMAPrevious > SlowMAPrevious)
       //if(goingDown)
         if(marketDirection()>0) // sell action - going down
         if((FastMA_Overall > SlowMA_Overall) && (FastMACurrent < SlowMACurrent)) // confirm overall direction of chart on 4h timeframe
         if(!sym_max(_Symbol))
         if(OrderSend(Symbol(),OP_SELL, LLot,Bid,3,0,0,"",EA_Magic,0,Red)) //Request is completed or order placed
           {
           //Bid-profit*Point
            //Bid+profit*2*Point
       //  m_trade.Sell(LLot,_Symbol,NormalizeDouble(latest_price.bid,_Digits),NormalizeDouble(latest_price.bid + STP*_Point,_Digits), NormalizeDouble(latest_price.bid - TKP*_Point,_Digits),NULL)  
           
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
    
     bool sym_max(string sym){
    int aa = 0;
    for(int a=(OrdersTotal()-1);a>-1;a--){
    if(OrderSymbol()==sym){
         aa++;
    }
    }
    return aa>=11;
    }
    
//+-------------------
