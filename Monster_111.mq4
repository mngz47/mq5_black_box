//+------------------------------------------------------------------+
//|                                                   Monster_111.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Monster Corp"
#property link      "https://product--lists.herokuapp.com"
#property version   "1.00"
#property strict
//--- input parameters

/*
SETUP 1 (use at night)
Use Martingale in sideways market
Use Martingale TP
LOT_MULTIPLIER=4
Martingale will auto SWITCH OFF if market condition changes.

SETUP 2 (during the day)
Increase max order in clear direction market.
MAX_ORDER=4
Using 0 TP
Using MarketConditionTP


__________________Martin Off/On Senario from 1am-6am

martin gale is off and market is sides ways

from 1am to 5am there are three orders consolidating
on negetive,

at 6am there is impulse/clear direction in the negetive
therefore close Sidewaystradeswill stop further loss

If the martin is on there will be positive trades from 1 - 5am
then close Sidewaystrades will stop further loss at 6am during
start of clear direction.

Martin makes more money-

________________________Martin Off/On Senario from 2.30pm

Chart will shoot in our direction and martin is off.
Stacked trades will be closed at next reversal

In clear direction if target pip not reached and direction changes
to opposite direction, order is closed.

Latency in detecting the trend factors the loss.
False clear direction results in martingale activating.

Stack and hold makes more money-

_________________________Martin Off/On Senario from 4.30pm

Volitility goes even higher



____________________________Martin Off/On Senario from 21:00pm


Volitility Starts to drops



_________________________________
Conclusion__________________

Lot Multiplier - More risk less money (SETUP1)

Stack and Hold - Less risk makes more money (SETUP2)

Leverage allows to take higher profit depending on CURRENCY

Inputs To Use
Use leverage 10 for gold USD account
Max order 3
Martingale OFF

________________________________

*/

//input string   OPTION1 = "EURAUD-EURNZD, M1, $30";
//input string   OPTION2 = "GOLD, M5, $30";
// "GBPJPY, H4, $7";

input string   INFO = "Click Cancel (Auto magic number will reset)";

input int      FastMAPeriod = 2;
input int      SlowMAPeriod = 30;
input string   INFO1 = "Used to detect entry.";
input float    LOT=0.01;
input int      LOT_MULTIPLIER=3;
input string   INFO3 = "Used by Martingale to make back loss.";
input float    draw_down_limit = -5;
input string   INFO4 = "The amount of drawdown allowed before placing orders.";
input float    direction_confirm_profit = 100;
input string   INFO5 = "The amount of profit before increasing max_order.";

enum MODEOPTION 
  {
   USE_MARTINGALE=1,
   MARKET_CONDITION_TP=2,
  };
//--- input parameters
input MODEOPTION MODE=MARKET_CONDITION_TP;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int      MAGIC;
int      martin_runs = 7;
//Martin runs are the max number of LOT multiplied orders before exit or martin_max
int      MAX_ORDER = 3;
//Used in clear direction market to maximize profits
bool     martin_max = true;
//string   INFO4 = "Martin max will remove least loss order and add new order with a multiplied lot until TP is reached.";
int      CURRENCY_LEVERAGE = 10;
//string   INFO6 = "Less leverage will increase TP target suitable for volatile chart.";
int      bar_num = 11;
//string   INFO7 = "The market_depth is the number of bars determining market condition.";
bool     USE_MARTINGALE = (MODE==1);
//input string   INFO2 = "Use in consolidating market.";
bool     MARKET_CONDITION_TP = (MODE==2); 
//input string   INFO5 = "Use in impulsive market, Switch OFF Martingale before hand.";
int      target_pips = 45;

int OnInit()
  {
//---
    
    MAGIC = MathRand();
    Print("Magic Number: "+MAGIC);
    
    //MAX_ORDER = StrToInteger(ObjectDescription("max_order_val"));
    Print("MAX_ORDER: "+MAX_ORDER);
    Print("Used in clear direction market to maximize profits.");
    
    //martin_runs = StrToInteger(ObjectDescription("martin_runs"));
    Print("MARTIN_RUNS: "+martin_runs);
    Print("Martin runs are the max number of LOT multiplied orders before exit or martin_max");
    
    //CURRENCY_LEVERAGE = StrToInteger(ObjectDescription("leverage_val"));
    Print("CURRENY_LEVERAGE: "+CURRENCY_LEVERAGE);
    Print("Less leverage will increase TP target suitable for volatile chart.");  
     
    //bar_num = StrToInteger(ObjectDescription("depth_val"));
    Print("MARKET_DEPTH: "+bar_num);
    Print("The market_depth is the number of bars determining market condition.");  
      
    USE_MARTINGALE = (MODE==1); 
    if(USE_MARTINGALE){
    Print("Using MARTINGALE");
    } 
    MARKET_CONDITION_TP = (MODE==2);  
    if(MARKET_CONDITION_TP){
    Print("Using MARKET_CONDITION_TP");
    }
      
    drawMarketCondition(true,getMarketCondition(marketDirection()),volatility(),Ask-Bid);
    drawMarketTrendFactors();
   
   ChartSetInteger(0,CHART_COLOR_BACKGROUND,clrAliceBlue);
   ChartSetInteger(0,CHART_COLOR_FOREGROUND,clrBlack);
   ChartSetInteger(0,CHART_COLOR_GRID,clrRed);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,clrDarkOrange);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,clrOrangeRed);
   
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
     //Analytics
   target_pips = (volatility()/LOT);
      
      CURRENCY_LEVERAGE = StrToInteger(ObjectDescription("leverage_val"));
      
      logMarketCondition();  //will update depth val //will determine drawdown
      
      bar_num = StrToInteger(ObjectDescription("depth_val"));
   
      drawMarketCondition(false,getMarketCondition(marketDirection()),volatility(),Ask-Bid);
      drawMarketTrendFactors();

    //Will enforce max order 1 in sideways market
    //will return max_order to default in clear direction
    
    if(TradingTime()){
    newEntry();
    }
    
    if(USE_MARTINGALE){
    //  if(checkMarketSIDEWAYS()){ //market changing rapidly sideways direction never lasts 
         detectNewBar();    
    //}  
   }else if(MARKET_CONDITION_TP){
         marketConditionTP();  //will escape breakout 
         direction_confirm_max_order(); //confirm direction maximise profits
   }   
  return;
  }
    
   bool TradingTime(){
   
   // Will improve entry accuracy on H4 chart 
   // Uses H4 period moving average to detect entry
   // Trys to make entry start of every 4 hours
   // Estimate trade holding time is 3 - 5 days
   // This will help avoid retest and reduce threshold equity to trade
   
            bool time = false;
            
            if((Hour()==3 || Hour()==7 || Hour()==11 || Hour()==15 || Hour()==19 ||  Hour()==23)){
                  time = true;
            }
            
         return time;
  }
    
  void newEntry(){
  
      int FastMACurrent = iMA(NULL,PERIOD_M5, FastMAPeriod, 1, 0, PRICE_CLOSE, 0);
      int FastMA_Overall = iMA(NULL, PERIOD_H4, FastMAPeriod, 1, 0, PRICE_CLOSE, 0);

      int SlowMACurrent = iMA(NULL, PERIOD_M5, SlowMAPeriod, 1, 0, PRICE_CLOSE, 0);
      int SlowMA_Overall = iMA(NULL, PERIOD_H4, SlowMAPeriod, 1, 0, PRICE_CLOSE, 0);     

        
  if((FastMA_Overall < SlowMA_Overall) && (FastMACurrent > SlowMACurrent))
   if(getMarketCondition(marketDirection())=="UPTREND" && (OrdersTotal()<MAX_ORDER))
     if((MARKET_CONDITION_TP && draw_down>draw_down_limit) || (USE_MARTINGALE && draw_down<draw_down_limit))
   {  
  
   //float tp = (checkMarketSIDEWAYS()?(Ask+target_pips*Point):0);
   
   float tp = (USE_MARTINGALE?(Ask+target_pips*Point):0);  //helps differentiate between martin&MC orders 
   OrderSend(Symbol(),OP_BUY,LOT,Ask,0,0,tp,0,MAGIC,0,clrAliceBlue);
   
   }
   
   if((FastMA_Overall > SlowMA_Overall) && (FastMACurrent < SlowMACurrent))
    if(getMarketCondition(marketDirection())=="DOWNTREND"  && (OrdersTotal()<MAX_ORDER))
      if((MARKET_CONDITION_TP && draw_down>draw_down_limit) || (USE_MARTINGALE && draw_down<draw_down_limit))
   {   
   
   //float tp = (checkMarketSIDEWAYS()?(Bid-target_pips*Point):0);
   float tp = (USE_MARTINGALE?(Bid-target_pips*Point):0);
   OrderSend(Symbol(),OP_SELL,LOT,Bid,0,0,tp,0,MAGIC,0,clrBlack);
 
   }
  }
  
   datetime Old_Time;
   datetime New_Time[1];
    
    void detectNewBar(){ //monitor bar activity
    
// copying the last bar time to the element New_Time[0]
   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0) // ok, the data has been copied successfully
     {
      if(Old_Time!=New_Time[0]) // if old time isn't equal to new bar time
        {
         Print("We have new bar here ",New_Time[0]," old time was ",Old_Time);
          Old_Time=New_Time[0];// saving bar time
           Print("Accessing Martingale...");    
             martingale();  
        }
     }
   else
     {
      Print("Error in copying historical times data, error =",GetLastError());
      ResetLastError();
     }
    }
    
    
        int martin_count = 0;
   void martingale(){
         
       if(OrdersTotal()>0){
         
       OrderSelect((OrdersTotal()-1),SELECT_BY_POS); //currently open order
       int cc = 2;
       while(OrderMagicNumber()!=MAGIC){
            OrderSelect((OrdersTotal()-cc),SELECT_BY_POS); //currently open order
            cc++;
       }
       
      if(OrderProfit()<-(OrderLots()*target_pips) && OrderTakeProfit()!=0){ //negative target pips
         if(martin_count<martin_runs){
         
         double PRICE = (OrderType()==OP_BUY?Bid:Ask);
         float tp = (OrderType()==OP_SELL?PRICE-target_pips*Point:PRICE+target_pips*Point);
        
         if(OrderSend(Symbol(),OrderType(),(OrderLots()*LOT_MULTIPLIER),PRICE,0,0,tp,0,MAGIC,0,clrBlack)){
            for(int a=0;a<(OrdersTotal()-1);a++){
           
           OrderSelect(a,SELECT_BY_POS);
           OrderModify(OrderTicket(),OrderOpenPrice(),0,tp,0,clrAliceBlue);
         
            }
            martin_count+=1;
         }             
         }else{
              // //volitility is too high.
              
              if(martin_max){  // close small loss and setup bigger gain
              
              OrderSelect(0,SELECT_BY_POS);
              double PRICE = (OrderType()==OP_BUY?Bid:Ask);
              OrderClose(OrderTicket(),OrderLots(),PRICE,3,White);
              
              
              OrderSelect((OrdersTotal()-1),SELECT_BY_POS);
              
              PRICE = (OrderType()==OP_BUY?Bid:Ask);
              float tp = (OrderType()==OP_SELL?PRICE-target_pips*Point:PRICE+target_pips*Point);
              OrderSend(Symbol(),OrderType(),(OrderLots()*LOT_MULTIPLIER),PRICE,0,0,tp,0,MAGIC,0,clrBlack);
              
              
              }else{
              closeOrders(OP_SELL); //Stop the loss completely // unless martin max is switched of this in expected not to happen
              }
              
              martin_count=0;
         }
      }
      }
   }
   
   double marketDirection()
  {
      return ((Open[bar_num]-Close[0])/Point/CURRENCY_LEVERAGE);
  }
   
  double volatility() //average open-close difference of the last bar_num
  {

   double avg_price = 0;

   for(int a=0; a<bar_num; a++)
     {

      double movement = Open[a]-Close[a];

      if(movement<0)
        {
         avg_price+=(-movement);
        }
      else
        {
         avg_price+=movement;
        }
     }
   
   avg_price = avg_price/bar_num;
   
   return (avg_price/Point/CURRENCY_LEVERAGE);
  }
   
   
   string getMarketCondition(float trend){
         return (trend>volatility())?"DOWNTREND":((trend<-volatility())?"UPTREND":"SIDEWAYS");
   }
   
   bool checkMarketSIDEWAYS(){
            return (getMarketCondition(marketDirection())=="SIDEWAYS");
   }
   
   void marketConditionTP(){  
   
    /*
    marketConditionTP closes clear direction orders with TP 0.0
    marketConditionTP closes sideways orders if direction changes.
    
    from clear direction to sideways
    martingale will be activated
    Order TP will be altered
    maringale closes the order__
    
    from sideways to clear direction
    martingale will be stopped
    sideways orders will be closed__ Huge False Breakout Loss
    
    from clear direction to opp clear direction
    opp positive trade with tp 0.0 is closed___
    
    */
    
      if(!checkMarketSIDEWAYS()){
      
            if(getMarketCondition(marketDirection())=="UPTREND"){ // From clear direction to oppo clear direction //take small loss if trend is entered late
              // closeOrders(SIDEWAY_DIRECTION,OP_SELL); // From sideways to clear direction run away (Stop Breakout)
              // False breakout causing huge loss. leading to market condition toggle
              // Sideways market needs martingale TP.
               
               closeOrders(OP_SELL); 
               
            }else if(getMarketCondition(marketDirection())=="DOWNTREND"){
              // closeOrders(SIDEWAY_DIRECTION,OP_BUY); // From sideways to clear direction run away
               
               closeOrders(OP_BUY); //Only works during clear direction
            }
       }
      
   }
   
   void direction_confirm_max_order(){
   
       OrderSelect((OrdersTotal()-1),SELECT_BY_POS); //currently open order
       
       int cc = 2;
       while(OrderMagicNumber()!=MAGIC && cc<OrdersTotal()){
            OrderSelect((OrdersTotal()-cc),SELECT_BY_POS); //currently open order
            cc++;
       }
       
       //increase number of orders every 7$ to confirm order direction and maximise profits
       // MAX_ORDER==(OrdersTotal()+1) //avoid max order increment before new order is placed
           
      if(OrderProfit()>direction_confirm_profit && (MAX_ORDER==(OrdersTotal()+1))){ 
        MAX_ORDER+=1;
      }
   }
   
     
  void closeOrders(int orderType) //clear direction trades should be positive
  {

   for(int aa=0; aa<OrdersTotal(); aa++) //close trades according to direction
     {
      OrderSelect(aa,SELECT_BY_POS);

      if(OrderType()==orderType)
        {
         if(OrderMagicNumber()==MAGIC)
           if(OrderProfit()>0 || OrderProfit()<2.5) //stop slippage
           {
            double PRICE = (OrderType()==OP_BUY?Bid:Ask);
            OrderClose(OrderTicket(),OrderLots(),PRICE,MAGIC,White);
           }
       }
    }
  } 
   
   
   string current_trend; //monitor trend
   int current_minute; // monitor minutes
   int trend_duration = 0; //in minutes
   
   double delta_trend = 0;
   double delta_minutes = 0; //minute increment
   
   double draw_down = 0;
   
   void logMarketCondition(){
   
         detectTrendChange();
         
         detectMinuteChange();
         //renders data on chart
         renderTrendFactors();
         
  }
  
  
  void detectTrendChange(){
   if(current_trend==NULL){
            current_trend = getMarketCondition(marketDirection()); 
         }else if(current_trend==getMarketCondition(marketDirection())){
        
         }else{//log trend change
         
            //current_trend,trend duration,datetime,price
            string data =  Symbol()+","+current_trend+","+trend_duration+","+__DATETIME__+","+Close[0];
         
            //Print("Market Condition --  ("+data+")");
            
            //writeCSVFile(data);
            
            trend_duration = 0;
            current_trend = getMarketCondition(marketDirection());
             
            delta_trend+=1; 
         }
  }
  
void detectMinuteChange(){

              
                  if(!current_minute){ //count trend duration in minutes.
                 
                  current_minute = Minute();
                 
                  }else if(current_minute==Minute()){
                  
                  }else if( current_minute==59 ? (Minute()==0) : ((current_minute+1)==Minute()) ){
                           
                            if(Minute()==0){
                            Print("DrawDown: ("+draw_down+")");
                                 current_minute=0;
                            }else{
                                 trend_duration+=1;
                                 delta_minutes+=1;
                                 current_minute+=1;
                            }
                  }
         }
  
void renderTrendFactors(){

   if(delta_minutes>0 && delta_minutes<60){
                  
               double pulse = NormalizeDouble((delta_trend/delta_minutes),4);
               int new_depth = (40*pulse+4); //depth increases profit increases they are proportional
               double pulse_profit = NormalizeDouble((pulse*-10.599+0.883),4); //pulse decreases profit increases (inversly proportional)
               draw_down = pulse_profit;
  
               //For good market conditions - pulse must be less than 5/60 
               //A bigger the pulse_profit indicates more money in the market
               //Big pulse represents instability in market
               
               newLabel(10,50,"delta_trend","ΔTREND",-1,5,CORNER_RIGHT_LOWER,ANCHOR_RIGHT_LOWER);
               newInput(50,45,40,40,"delta_trend_val",""+delta_trend,20,CORNER_RIGHT_LOWER,ANCHOR_RIGHT_LOWER);
               newLabel(60,50,"delta_minutes","ΔMINUTES",-1,5,CORNER_RIGHT_LOWER,ANCHOR_RIGHT_LOWER);
               newInput(100,45,40,40,"delta_minutes_val",""+delta_minutes,20,CORNER_RIGHT_LOWER,ANCHOR_RIGHT_LOWER);
               newLabel(120,50,"pulse","PULSE",-1,5,CORNER_RIGHT_LOWER,ANCHOR_RIGHT_LOWER);
               newInput(150,45,40,40,"pulse_val",""+pulse,20,CORNER_RIGHT_LOWER,ANCHOR_RIGHT_LOWER);
              
               bool trade_drawdown = ((MARKET_CONDITION_TP && draw_down>draw_down_limit) || (USE_MARTINGALE && draw_down<draw_down_limit));
              
               newLabel(160,50,"pulse_profit","Draw_Down",(trade_drawdown?clrGreen:clrRed),5,CORNER_RIGHT_LOWER,ANCHOR_RIGHT_LOWER);
               newInput(200,45,40,40,"pulse_profit_val",""+pulse_profit,20,CORNER_RIGHT_LOWER,ANCHOR_RIGHT_LOWER);
               ObjectSetString(0,"depth_val",OBJPROP_TEXT,""+new_depth);
                  
         }else{
               delta_trend = 1;
               delta_minutes = 1;
         } 
  }
  
   
void drawMarketTrendFactors(){
          if(USE_MARTINGALE){ 
          //martin toggle true then market condition is ignored
          //market condition should be used with MC TP
             ObjectSetInteger(0, "martingale", OBJPROP_COLOR, clrGreen);
             martin_runs = StrToInteger(ObjectDescription("martin_runs"));
             MAX_ORDER=1;  //one order at a time during sidewayS market    
             ObjectSetInteger(0, "max_order_lb", OBJPROP_COLOR, clrRed);   
          }else{
               MAX_ORDER = StrToInteger(ObjectDescription("max_order_val"));//capitalize on clear direction market
               ObjectSetInteger(0, "martingale", OBJPROP_COLOR, clrRed);
               ObjectSetInteger(0, "max_order_lb", OBJPROP_COLOR, clrGreen);
          }
   }
   
   
   void drawMarketCondition(bool ini,string trend,float volatility,float spread){
   
      string text= "SPREAD("+MathRound(spread/Point)+")";
      
      newLabel(10,1,"spread",text,clrOrangeRed,10,CORNER_LEFT_LOWER,ANCHOR_LEFT_LOWER);
   
      newLabel(1,20,"trend","("+trend+")",clrDarkOrange,11,CORNER_LEFT_LOWER,ANCHOR_LEFT_LOWER);
   
      newLabel(135,1,"martingale","MAX_MARTIN",-1,10,CORNER_LEFT_LOWER,ANCHOR_LEFT_LOWER);
   
      if(ini){
      newInput(245,20,30,18,"martin_runs","7",10,CORNER_LEFT_LOWER,ANCHOR_LEFT_LOWER);
      }
      
      newLabel(135,20,"max_order_lb","MAX_ORDER",-1,10,CORNER_LEFT_LOWER,ANCHOR_LEFT_LOWER);
     
      if(ini){
      newInput(245,40,30,18,"max_order_val","1",10,CORNER_LEFT_LOWER,ANCHOR_LEFT_LOWER);
      }
       
      text ="PIPS("+NormalizeDouble(volatility/LOT,2)+")";
      newLabel(280,1,"retracement",text,clrOrangeRed,10,CORNER_LEFT_LOWER,ANCHOR_LEFT_LOWER);
      
      text = "PROFIT($"+(NormalizeDouble(volatility,4))+")";
      
      newLabel(280,20,"volatility",text,clrDarkOrange,10,CORNER_LEFT_LOWER,ANCHOR_LEFT_LOWER);
       
      newLabel(390,1,"leverage_lb","LEVERAGE",-1,10,CORNER_LEFT_LOWER,ANCHOR_LEFT_LOWER);
         
      if(ini){
      newInput(480,20,30,18,"leverage_val","10",10,CORNER_LEFT_LOWER,ANCHOR_LEFT_LOWER);
      }
      
      newLabel(420,20,"depth_lb","DEPTH",-1,10,CORNER_LEFT_LOWER,ANCHOR_LEFT_LOWER);
       
      if(ini){
      newInput(480,40,30,18,"depth_val","11",10,CORNER_LEFT_LOWER,ANCHOR_LEFT_LOWER);
      }
   }
   
  
  void newLabel(int xpos,int ypos,string name,string text,int clr,int size,int corner,int anchor){
  
  ObjectDelete(0,name);
      if (ObjectFind(0, name)==-1) {
         ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE,xpos);
         ObjectSetInteger(0, name, OBJPROP_YDISTANCE,ypos);
         
         ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
         ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
         
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
         if(clr!=-1){
         ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
         }
         ObjectSetString(0, name, OBJPROP_FONT, "Arial");
         ObjectSetString(0, name, OBJPROP_TEXT, text);
      }
  }  
   
  void newInput(int xpos,int ypos,int width,int height,string name,string text,int size,int corner,int anchor){
     int chart_ID = 0;
      ObjectDelete(chart_ID,name);
      if (ObjectFind(chart_ID, name)==-1) {
            ObjectCreate(chart_ID,name,OBJ_EDIT,0,0,0);
//--- set object coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,xpos);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,ypos);
//--- set object size
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,"Arial");
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,size);
//--- set the type of text alignment in the object
//--- enable (true) or cancel (false) read-only mode
   ObjectSetInteger(chart_ID,name,OBJPROP_READONLY,false);
//--- set the chart's corner, relative to which object coordinates are defined
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
//--- set text color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clrBlack);
//--- set background color
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,clrWhite);
//--- set border color
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,clrBlack);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,false);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,false);
      }
  } 
   
  void writeCSVFile(string data){
  string InpFileName="Market_Condition.csv";
  
  int file_handle=FileOpen(InpFileName,FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI);
   if(file_handle!=INVALID_HANDLE)
     {

      string inFile = FileReadString(file_handle,FileSize(file_handle));
      FileWriteString(file_handle,inFile+"\r\n"+data);
      FileClose(file_handle);
     
     }else{
         Print("Market_Condition.csv Error: "+GetLastError());
     } 
  } 
  
//+------------------------------------------------------------------+
