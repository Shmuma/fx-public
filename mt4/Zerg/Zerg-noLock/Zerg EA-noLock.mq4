#property copyright "Zerg TLP-noLock"
#property link      ""

#include <stdlib.mqh>


extern string MM_Settings = "================ Money Management";
extern bool MM_UseMoneyManagement = TRUE;
extern double MM_LotSize = 0.01;
extern double MM_PerHowMuchEquity = 2000.0;
extern string MM_Note1 = "MM must be FALSE to use FixedLots";
extern double FixedLots = 0.01;
extern string Grid_Settings = "================ Grid Settings";
extern int MaxOpenOrders = 60;
extern int GridOrderGapPips = 5;
extern int StopLoss = 240;
extern int MagicNumber = 20121102;
extern int Slippage = 3;
double expertVersion;
double firstEnvelopeDev;
double secondEnvelopeDev;
double maxDrawDownSeenInPercent;
double last_high_envelope;
double last_low_envelope;
double last_close;
double lots_to_trade;
double symbolPoint;

bool closeLongGrid_requested;
bool closeShortGrid_requested;
bool risk_increase_alert_shown;
int firstEnvelopePeriod;
int secondEnvelopePeriod;
bool Gi_272;
int gridProfitTarget;
bool resend_order;
int resend_kind;
int nextLongOrderIndex;
int nextShortOrderIndex;


int init() {
   if (!IsDllsAllowed())
       Alert("You have to enable DLLs in order to work with this product");

   expertVersion = 1.0;
   firstEnvelopePeriod = 80;
   firstEnvelopeDev = 0.35;
   secondEnvelopePeriod = 10;
   secondEnvelopeDev = 0.3;
   maxDrawDownSeenInPercent = 0.0;
   Gi_272 = TRUE; // some mode, switches envelopes shift (false adds one extra bar to shift)
   gridProfitTarget = 85; // profit target in grid
   resend_order = FALSE;
   resend_kind = 0;
   last_high_envelope = 0.0;
   last_low_envelope = 0.0;
   last_close = 0.0;
   nextLongOrderIndex = 0;
   nextShortOrderIndex = 0;
   closeLongGrid_requested = FALSE;
   closeShortGrid_requested = FALSE;
   risk_increase_alert_shown = FALSE;
   
   if (Digits == 5)
       Slippage *= 10;

   if (Digits == 5)
       symbolPoint = 0.0001;
   else {
      if (Digits == 3)
          symbolPoint = 0.01;
      else
          symbolPoint = Point;
   }
   HideTestIndicators(TRUE);
   last_high_envelope = iEnvelopes(NULL, 0, secondEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, secondEnvelopeDev, MODE_UPPER, 0);
   last_low_envelope = iEnvelopes(NULL, 0, secondEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, secondEnvelopeDev, MODE_LOWER, 0);
   last_close = iClose(NULL, 0, 0);
   HideTestIndicators(FALSE);
   Comment("");
   if (ObjectFind("WTF_BKGR") != -1) ObjectDelete("WTF_BKGR");
   if (ObjectFind("WTF_BKGR2") != -1) ObjectDelete("WTF_BKGR2");
   if (ObjectFind("WTF_BKGR3") != -1) ObjectDelete("WTF_BKGR3");
   if (ObjectFind("WTF_BKGR4") != -1) ObjectDelete("WTF_BKGR4");
   if (ObjectFind("WTF_BKGR5") != -1) ObjectDelete("WTF_BKGR5");
   if (ObjectFind("WTF_BKGR6") != -1) ObjectDelete("WTF_BKGR6");
   if (ObjectFind("WTF_BKGR7") != -1) ObjectDelete("WTF_BKGR7");
   if (ObjectFind("WTF_BKGR8") != -1) ObjectDelete("WTF_BKGR8");
   if (ObjectFind("WTF_BKGR9") != -1) ObjectDelete("WTF_BKGR9");
   if (ObjectFind("WTF_BKGR10") != -1) ObjectDelete("WTF_BKG10");
   if (ObjectFind("WTF_BKGR11") != -1) ObjectDelete("WTF_BKGR11");
   if (ObjectFind("WTF_BKGR12") != -1) ObjectDelete("WTF_BKGR12");
   if (ObjectFind("WTF_BKGR13") != -1) ObjectDelete("WTF_BKGR13");
   if (ObjectFind("WTF_BKGR14") != -1) ObjectDelete("WTF_BKGR14");
   if (ObjectFind("WTF_BKGR15") != -1) ObjectDelete("WTF_BKGR15");
   if (ObjectFind("WTF_BKGR16") != -1) ObjectDelete("WTF_BKGR16");
   if (ObjectFind("WTF_BKGR17") != -1) ObjectDelete("WTF_BKGR17");
   if (ObjectFind("WTF_BKGR18") != -1) ObjectDelete("WTF_BKGR18");
   if (ObjectFind("WTF_BKGR19") != -1) ObjectDelete("WTF_BKGR19");
   if (ObjectFind("WTF_BKGR20") != -1) ObjectDelete("WTF_BKGR20");
   if (ObjectFind("WTF_BKGR21") != -1) ObjectDelete("WTF_BKGR21");
   if (ObjectFind("WTF_BKGR22") != -1) ObjectDelete("WTF_BKGR22");
   if (ObjectFind("WTF_BKGR23") != -1) ObjectDelete("WTF_BKGR23");
   if (ObjectFind("WTF_BKGR24") != -1) ObjectDelete("WTF_BKGR24");
   if (ObjectFind("WTF_BKGR25") != -1) ObjectDelete("WTF_BKGR25");
   if (ObjectFind("WTF_BKGR26") != -1) ObjectDelete("WTF_BKGR26");
   if (ObjectFind("WTF_BKGR27") != -1) ObjectDelete("WTF_BKGR27");
   if (ObjectFind("WTF_BKGR28") != -1) ObjectDelete("WTF_BKGR28");
   if (ObjectFind("WTF_LV") != -1) ObjectDelete("WTF_LV");
   if (!GlobalVariableCheck("WTF_MaxDD") && IsVisualMode())
       GlobalVariableSet("WTF_MaxDD", maxDrawDownSeenInPercent);

   return (0);
}


// 52D46093050F38C27267BCE42543EF60
void deinit() {
   Comment("");
   if (ObjectFind("WTF_BKGR") != -1) ObjectDelete("WTF_BKGR");
   if (ObjectFind("WTF_BKGR2") != -1) ObjectDelete("WTF_BKGR2");
   if (ObjectFind("WTF_BKGR3") != -1) ObjectDelete("WTF_BKGR3");
   if (ObjectFind("WTF_BKGR4") != -1) ObjectDelete("WTF_BKGR4");
   if (ObjectFind("WTF_BKGR5") != -1) ObjectDelete("WTF_BKGR5");
   if (ObjectFind("WTF_BKGR6") != -1) ObjectDelete("WTF_BKGR6");
   if (ObjectFind("WTF_BKGR7") != -1) ObjectDelete("WTF_BKGR7");
   if (ObjectFind("WTF_BKGR8") != -1) ObjectDelete("WTF_BKGR8");
   if (ObjectFind("WTF_BKGR9") != -1) ObjectDelete("WTF_BKGR9");
   if (ObjectFind("WTF_BKGR10") != -1) ObjectDelete("WTF_BKGR10");
   if (ObjectFind("WTF_BKGR11") != -1) ObjectDelete("WTF_BKGR11");
   if (ObjectFind("WTF_BKGR12") != -1) ObjectDelete("WTF_BKGR12");
   if (ObjectFind("WTF_BKGR13") != -1) ObjectDelete("WTF_BKGR13");
   if (ObjectFind("WTF_BKGR14") != -1) ObjectDelete("WTF_BKGR14");
   if (ObjectFind("WTF_BKGR15") != -1) ObjectDelete("WTF_BKGR15");
   if (ObjectFind("WTF_BKGR16") != -1) ObjectDelete("WTF_BKGR16");
   if (ObjectFind("WTF_BKGR17") != -1) ObjectDelete("WTF_BKGR17");
   if (ObjectFind("WTF_BKGR18") != -1) ObjectDelete("WTF_BKGR18");
   if (ObjectFind("WTF_BKGR19") != -1) ObjectDelete("WTF_BKGR19");
   if (ObjectFind("WTF_BKGR20") != -1) ObjectDelete("WTF_BKGR20");
   if (ObjectFind("WTF_BKGR21") != -1) ObjectDelete("WTF_BKGR21");
   if (ObjectFind("WTF_BKGR22") != -1) ObjectDelete("WTF_BKGR22");
   if (ObjectFind("WTF_BKGR23") != -1) ObjectDelete("WTF_BKGR23");
   if (ObjectFind("WTF_BKGR24") != -1) ObjectDelete("WTF_BKGR24");
   if (ObjectFind("WTF_BKGR25") != -1) ObjectDelete("WTF_BKGR25");
   if (ObjectFind("WTF_BKGR26") != -1) ObjectDelete("WTF_BKGR26");
   if (ObjectFind("WTF_BKGR27") != -1) ObjectDelete("WTF_BKGR27");
   if (ObjectFind("WTF_BKGR28") != -1) ObjectDelete("WTF_BKGR28");
   if (ObjectFind("WTF_LV") != -1) ObjectDelete("WTF_LV");
}


// EA2B2676C28C0DB26D39331A336C6B92
void start() {
   if (Symbol() != "AUDNZD") {
      Comment("ERROR: EA will only run on AUDNZD");
      return;
   }
   if (Period() != PERIOD_M15) {
      Comment("ERROR: EA will only run on the M15 Chart");
      return;
   }
   double lotstep = MarketInfo(Symbol(), MODE_LOTSTEP);
   if (MM_UseMoneyManagement && MM_LotSize < lotstep) {
      Comment("ERROR: Your MM_LotSize setting is lower than your brokers LotStep value. Your MM_LotSize must be at least " + DoubleToStr(lotstep, 2));
      return;
   }
   init_market_info();
   double longGridProfit = 0.0;
   double shortGridProfit = 0.0;
   longGridProfit = currentGridProfit(MagicNumber, 1);
   shortGridProfit = currentGridProfit(MagicNumber, 2);
   int long_max_index = -1;
   int short_max_index = -1;
   for (int i = 0; i < OrdersTotal(); i++) {
      OrderSelect(i, SELECT_BY_POS);
      if (OrderMagicNumber() == MagicNumber) {
         if (OrderSymbol() == Symbol()) {
            int order_index = StrToInteger(StringSubstr(OrderComment(), 7));

            if (OrderType() == OP_BUY) {
               long_max_index = i;
               nextLongOrderIndex = MathMax(nextLongOrderIndex, order_index);
            }
            if (OrderType() == OP_SELL) {
               short_max_index = i;
               nextShortOrderIndex = MathMax(nextShortOrderIndex, order_index);
            }
         }
      }
   }

   if (long_max_index < 0)
       nextLongOrderIndex = 0;
   if (short_max_index < 0)
       nextShortOrderIndex = 0;

   // profit target reached on long grid
   if (longGridProfit >= gridProfitTarget)
       closeLongGrid_requested = TRUE;
   // profit target reached on short grid
   if (shortGridProfit >= gridProfitTarget)
       closeShortGrid_requested = TRUE;

   if (!closeLongGrid_requested)
       increase_long_grid_if_needed(long_max_index, MagicNumber);
   else
       closeLongGrid(MagicNumber);

   if (!closeShortGrid_requested)
       increase_short_grid_if_needed(short_max_index, MagicNumber);
   else
       closeShortGrid(MagicNumber);

   if (!IsTesting() && !IsVisualMode())
       updateBanner();

   HideTestIndicators(TRUE);
   last_high_envelope = iEnvelopes(NULL, 0, secondEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, secondEnvelopeDev, MODE_UPPER, 0);
   last_low_envelope = iEnvelopes(NULL, 0, secondEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, secondEnvelopeDev, MODE_LOWER, 0);
   last_close = iClose(NULL, 0, 0);
   HideTestIndicators(FALSE);
}


// 78BAA8FAE18F93570467778F2E829047
void increase_long_grid_if_needed(int grid_size, int magic) {
   int ticket;
   double SL_level = 0.0;
   int error;

   if (StopLoss > 0.0)
       SL_level = Ask - StopLoss * symbolPoint;

   if (grid_size < 0) {
       if (initialSignal() == 1 || (resend_order && resend_kind == 1)) {
          ticket = OrderSend(Symbol(), OP_BUY, lots_to_trade, Ask, Slippage, 0, 0,
                             "WTF000 " + (nextLongOrderIndex + 1), magic, 0, Blue);
         if (ticket < 0) {
            error = GetLastError();
            Print("Error Opening Buy Order(", error, "): ", ErrorDescription(error));
            resend_order = TRUE;
            resend_kind = 1;
         } else {
            OrderSelect(ticket, SELECT_BY_TICKET);
            OrderModify(OrderTicket(), OrderOpenPrice(), SL_level, 0.0, 0, Blue);
            resend_order = FALSE;
         }
      }
   } else {
       OrderSelect(grid_size, SELECT_BY_POS);
       if (OrderSymbol() == Symbol()) {
           if (OrderType() == OP_BUY) {
               // very rare condition (close on opposite signal?)
               if (closeSignal() == 2)
                   closeLongGrid_requested = TRUE;

               if (increaseGridCheck(grid_size) > 0) {
                   if (nextLongOrderIndex < MaxOpenOrders) {
                       ticket = OrderSend(Symbol(), OP_BUY, lots_to_trade, Ask, Slippage, 0, 0,
                                          "WTF000 " + (nextLongOrderIndex + 1), magic, 0, Blue);
                       if (ticket < 0) {
                           error = GetLastError();
                           Print("Error Opening Buy Order(", error, "): ", ErrorDescription(error));
                       } else {
                           OrderSelect(ticket, SELECT_BY_TICKET);
                           OrderModify(OrderTicket(), OrderOpenPrice(), SL_level, 0.0, 0, Blue);
                       }
                   }
               }
           }
       }
   }
}


// 50257C26C4E5E915F022247BABD914FE
void increase_short_grid_if_needed(int grid_size, int magic) {
   int ticket;
   double SL_level;
   int error;

   if (StopLoss > 0)
       SL_level = Bid + StopLoss * symbolPoint;
   else
       SL_level = 0.0;

   if (grid_size < 0) {
       if (initialSignal() == 2 || (resend_order && resend_kind == 2)) {
          ticket = OrderSend(Symbol(), OP_SELL, lots_to_trade, Bid, Slippage, 0, 0,
                             "WTF000 " + (nextShortOrderIndex + 1), magic, 0, Red);
         if (ticket < 0) {
            error = GetLastError();
            Print("Error Opening Sell Order(", error, "): ", ErrorDescription(error));
            resend_order = TRUE;
            resend_kind = 2;
         } else {
            OrderSelect(ticket, SELECT_BY_TICKET);
            OrderModify(OrderTicket(), OrderOpenPrice(), SL_level, 0.0, 0, Red);
            resend_order = FALSE;
         }
      }
   } else {
      OrderSelect(grid_size, SELECT_BY_POS);
      if (OrderSymbol() == Symbol()) {
         if (OrderType() == OP_SELL) {
             if (closeSignal() == 1)
                closeShortGrid_requested = TRUE;

            if (increaseGridCheck(grid_size) > 0) {
               if (nextShortOrderIndex < MaxOpenOrders) {
                   ticket = OrderSend(Symbol(), OP_SELL, lots_to_trade, Bid, Slippage, 0, 0,
                                      "WTF000 " + (nextShortOrderIndex + 1), magic, 0, Red);
                  if (ticket < 0) {
                     error = GetLastError();
                     Print("Error Opening Sell Order(", error, "): ", ErrorDescription(error));
                  } else {
                     OrderSelect(ticket, SELECT_BY_TICKET);
                     OrderModify(OrderTicket(), OrderOpenPrice(), SL_level, 0.0, 0, Red);
                  }
               }
            }
         }
      }
   }
}


// 689C35E4872BA754D7230B8ADAA28E48
int increaseGridCheck(int Ai_0) {
   OrderSelect(Ai_0, SELECT_BY_POS);
   if (OrderType() == OP_BUY) {
       if (OrderOpenPrice() - Ask >= GridOrderGapPips * symbolPoint)
           return (1);
   }
   if (OrderType() == OP_SELL)
       if (Bid - OrderOpenPrice() >= GridOrderGapPips * symbolPoint)
           return (2);
   return (0);
}


// 09CBB5F5CE12C31A043D5C81BF20AA4A
int initialSignal() {
   HideTestIndicators(TRUE);

   double upper_2_back = iEnvelopes(NULL, 0, firstEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, firstEnvelopeDev, MODE_UPPER, 2);
   double lower_2_back = iEnvelopes(NULL, 0, firstEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, firstEnvelopeDev, MODE_LOWER, 2);
   double close_2_back = iClose(NULL, 0, 2);
   double upper_prev = iEnvelopes(NULL, 0, firstEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, firstEnvelopeDev, MODE_UPPER, 1);
   double lower_prev = iEnvelopes(NULL, 0, firstEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, firstEnvelopeDev, MODE_LOWER, 1);
   double close_prev = iClose(NULL, 0, 1);
   HideTestIndicators(FALSE);

   if (lower_2_back < close_2_back)
      if (lower_prev > close_prev)
          return (1);
   if (upper_2_back > close_2_back)
      if (upper_prev < close_prev)
          return (2);

   // TODO: if reverse first conditions, results are better
   // UPD: in long-term, results are worse
/*
   if (lower_2_back > close_2_back)
      if (lower_prev > close_prev)
          return (1);
   if (upper_2_back < close_2_back)
      if (upper_prev < close_prev)
          return (2);
 */

   return (0);
}


// D1DDCE31F1A86B3140880F6B1877CBF8
int closeSignal() {
   double Ld_0;
   double Ld_8;
   double Ld_16;
   double Ld_24;
   double Ld_32;
   double close_prev;
   HideTestIndicators(TRUE);
   if (!Gi_272) {
      Ld_24 = iEnvelopes(NULL, 0, secondEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, secondEnvelopeDev, MODE_UPPER, 1);
      Ld_32 = iEnvelopes(NULL, 0, secondEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, secondEnvelopeDev, MODE_LOWER, 1);
      close_prev = iClose(NULL, 0, 1);
      Ld_0 = iEnvelopes(NULL, 0, secondEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, secondEnvelopeDev, MODE_UPPER, 0);
      Ld_8 = iEnvelopes(NULL, 0, secondEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, secondEnvelopeDev, MODE_LOWER, 0);
      Ld_16 = iClose(NULL, 0, 0);
   } else {
      Ld_24 = iEnvelopes(NULL, 0, secondEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, secondEnvelopeDev, MODE_UPPER, 2);
      Ld_32 = iEnvelopes(NULL, 0, secondEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, secondEnvelopeDev, MODE_LOWER, 2);
      close_prev = iClose(NULL, 0, 2);
      Ld_0 = iEnvelopes(NULL, 0, secondEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, secondEnvelopeDev, MODE_UPPER, 1);
      Ld_8 = iEnvelopes(NULL, 0, secondEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, secondEnvelopeDev, MODE_LOWER, 1);
      Ld_16 = iClose(NULL, 0, 1);
   }
   HideTestIndicators(FALSE);

   // not sure
/*
   if (MqlLock_50BEBD01_7_I1IiIIIii1(Ld_32, close_prev))
      if (MqlLock_50BEBD01_7_1ii11Ii1I1(last_low_envelope, last_close, Gi_272, Ld_8, Ld_16)) return (1);
   if (MqlLock_50BEBD01_7_III1IiIIii(Ld_24, close_prev))
      if (MqlLock_50BEBD01_7_11IIIII1Ii(last_high_envelope, last_close, Gi_272, Ld_0, Ld_16)) return (2);
*/

   if (Ld_32 < close_prev)
       if (!((last_low_envelope < last_close && !Gi_272) || (Gi_272 && Ld_8 < Ld_16)))
           return (1);
   if (Ld_24 > close_prev)
       if (!((last_high_envelope > last_close && !Gi_272) || (Gi_272 && Ld_0 > Ld_16)))
           return (2);

   return (0);
}


// 58B0897F29A3AD862616D6CBF39536ED
void closeLongGrid(int Ai_0) {
   int lastIndex = -1;
   for (int i = 0; i < OrdersTotal(); i++) {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() == Ai_0) {
         if (OrderSymbol() == Symbol()) {
            if (OrderType() == OP_BUY) {
               lastIndex = i;
               OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, Green);
            }
            if (OrderType() == OP_BUYLIMIT) OrderDelete(OrderTicket());
            if (OrderType() == OP_BUYSTOP) OrderDelete(OrderTicket());
         }
      }
   }
   if (lastIndex < 0) {
      closeLongGrid_requested = FALSE;
      nextLongOrderIndex = 0;
   }
}


// 28EFB830D150E70A8BB0F12BAC76EF35
void closeShortGrid(int Ai_0) {
   int lastIndex = -1;
   for (int Li_8 = 0; Li_8 < OrdersTotal(); Li_8++) {
      OrderSelect(Li_8, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() == Ai_0) {
         if (OrderSymbol() == Symbol()) {
            if (OrderType() == OP_SELL) {
               lastIndex = Li_8;
               OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, Green);
            }
            if (OrderType() == OP_SELLLIMIT) OrderDelete(OrderTicket());
            if (OrderType() == OP_SELLSTOP) OrderDelete(OrderTicket());
         }
      }
   }
   if (lastIndex < 0) {
      closeShortGrid_requested = FALSE;
      nextShortOrderIndex = 0;
   }
}


// 5710F6E623305B2C1458238C9757193B
// current profit on grid
double currentGridProfit(int magic, int orderKind) {
   double res = 0.0;
   for (int Li_16 = 0; Li_16 < OrdersTotal(); Li_16++) {
      OrderSelect(Li_16, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() == magic) {
          if (OrderSymbol() == Symbol()) {
             if (OrderType() == OP_BUY && orderKind == 1)
                 res += (Bid - OrderOpenPrice()) / symbolPoint;
             if (OrderType() == OP_SELL && orderKind == 2)
                 res += (OrderOpenPrice() - Ask) / symbolPoint;
         }
      }
   }
//   Print("currentGridProfit: kind=" + orderKind + ", res=" + res);
   return (res);
}

// AA5EA51BFAC7B64E723BF276E0075513
void init_market_info() {
   double min_lot = MarketInfo(Symbol(), MODE_MINLOT);
   double max_lot = MarketInfo(Symbol(), MODE_MAXLOT);

   if (MM_UseMoneyManagement) {
      if (AccountEquity() < MM_PerHowMuchEquity) {
         lots_to_trade = MM_LotSize;
         if (lots_to_trade < min_lot)
             lots_to_trade = min_lot;
         if (lots_to_trade > max_lot)
             lots_to_trade = max_lot;
      }
      else
          lots_to_trade = MM_LotSize * MathFloor(AccountEquity() / MM_PerHowMuchEquity);
      lots_to_trade = MathRound(lots_to_trade / min_lot) * min_lot;
      if (lots_to_trade < min_lot) {
         lots_to_trade = min_lot;
         if (!risk_increase_alert_shown) {
            Alert("Your risk has increased! Your risk settings are lower than the minimum lot value of " + min_lot);
            Alert("EA will now use " + DoubleToStr(min_lot, 2) + " lots per trade!");
            risk_increase_alert_shown = TRUE;
         }
      }
      if (lots_to_trade > max_lot)
          lots_to_trade = max_lot;
   } else {
      lots_to_trade = FixedLots;
      if (lots_to_trade < min_lot) {
         lots_to_trade = min_lot;
         if (!risk_increase_alert_shown) {
            Alert("Your risk has increased! Your risk settings are lower than the minimum lot value of " + min_lot);
            Alert("EA will now use " + DoubleToStr(min_lot, 2) + " lots per trade!");
            risk_increase_alert_shown = TRUE;
         }
      }
      if (lots_to_trade > max_lot)
          lots_to_trade = max_lot;
   }
}


// A9B24A824F70CC1232D1C2BA27039E8D
double current_profit() {
   double res = 0.0;
   for (int i = OrdersTotal()-1; i >= 0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
             res += OrderProfit() + OrderSwap() + OrderCommission();
   }
   return (res);
}


// 945D754CB0DC06D04243FCBA25FC0802
void updateBanner() {
   int spread_div;
   double current_dd = -(current_profit() + AccountCredit()) / AccountBalance();
   if (current_dd < 0.0)
       current_dd = 0.0;
   if (GlobalVariableGet("WTF_MaxDD") < current_dd)
       GlobalVariableSet("WTF_MaxDD", current_dd);
   if (Digits == 5)
       spread_div = 10;
   else
       spread_div = 1;

   string banner = "\n";
   banner = banner + "                                          ";
   banner = banner + "Lots: " + DoubleToStr(lots_to_trade, 2);
   banner = banner + "   |   MaxOpenOrders: " + MaxOpenOrders;
   banner = banner + "   |   GridOrderGapPips: " + GridOrderGapPips;
   banner = banner + "   |   Spread: " + DoubleToStr(MarketInfo(Symbol(), MODE_SPREAD) / spread_div, 1) + " pips";
   banner = banner + "\n";
   banner = banner + "                                          ";
   banner = banner + "    Maximum DrawDown: " + DoubleToStr(100.0 * GlobalVariableGet("WTF_MaxDD"), 2) + "%";
   banner = banner + "      |              Current DrawDown: " + DoubleToStr(100.0 * current_dd, 2) + "%";
   banner = banner 
   + "\n";
   Comment(banner);

   int Li_12 = 19;
   if (ObjectFind("WTF_BKGR") < 0) {
      ObjectCreate("WTF_BKGR", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR", "g", 22, "Webdings", DarkSeaGreen);
      ObjectSet("WTF_BKGR", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR", OBJPROP_XDISTANCE, 5);
      ObjectSet("WTF_BKGR", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR2") < 0) {
      ObjectCreate("WTF_BKGR2", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR2", "g", 22, "Webdings", DarkSeaGreen);
      ObjectSet("WTF_BKGR2", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR2", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR2", OBJPROP_XDISTANCE, 34);
      ObjectSet("WTF_BKGR2", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR3") < 0) {
      ObjectCreate("WTF_BKGR3", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR3", "g", 22, "Webdings", DarkSeaGreen);
      ObjectSet("WTF_BKGR3", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR3", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR3", OBJPROP_XDISTANCE, 63);
      ObjectSet("WTF_BKGR3", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR4") < 0) {
      ObjectCreate("WTF_BKGR4", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR4", "g", 22, "Webdings", DarkSeaGreen);
      ObjectSet("WTF_BKGR4", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR4", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR4", OBJPROP_XDISTANCE, 92);
      ObjectSet("WTF_BKGR4", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_LV") < 0) {
      ObjectCreate("WTF_LV", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_LV", "WTF EA v" + DoubleToStr(expertVersion, 1), 9, "Tahoma Bold", White);
      ObjectSet("WTF_LV", OBJPROP_CORNER, 0);
      ObjectSet("WTF_LV", OBJPROP_BACK, FALSE);
      ObjectSet("WTF_LV", OBJPROP_XDISTANCE, 13);
      ObjectSet("WTF_LV", OBJPROP_YDISTANCE, Li_12 + 7);
   }
   if (ObjectFind("WTF_BKGR5") < 0) {
      ObjectCreate("WTF_BKGR5", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR5", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR5", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR5", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR5", OBJPROP_XDISTANCE, 121);
      ObjectSet("WTF_BKGR5", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR6") < 0) {
      ObjectCreate("WTF_BKGR6", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR6", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR6", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR6", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR6", OBJPROP_XDISTANCE, 150);
      ObjectSet("WTF_BKGR6", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR7") < 0) {
      ObjectCreate("WTF_BKGR7", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR7", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR7", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR7", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR7", OBJPROP_XDISTANCE, 179);
      ObjectSet("WTF_BKGR7", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR8") < 0) {
      ObjectCreate("WTF_BKGR8", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR8", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR8", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR8", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR8", OBJPROP_XDISTANCE, 208);
      ObjectSet("WTF_BKGR8", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR9") < 0) {
      ObjectCreate("WTF_BKGR9", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR9", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR9", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR9", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR9", OBJPROP_XDISTANCE, 237);
      ObjectSet("WTF_BKGR9", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR10") < 0) {
      ObjectCreate("WTF_BKGR10", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR10", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR10", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR10", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR10", OBJPROP_XDISTANCE, 266);
      ObjectSet("WTF_BKGR10", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR11") < 0) {
      ObjectCreate("WTF_BKGR11", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR11", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR11", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR11", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR11", OBJPROP_XDISTANCE, 295);
      ObjectSet("WTF_BKGR11", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR12") < 0) {
      ObjectCreate("WTF_BKGR12", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR12", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR12", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR12", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR12", OBJPROP_XDISTANCE, 324);
      ObjectSet("WTF_BKGR12", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR13") < 0) {
      ObjectCreate("WTF_BKGR13", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR13", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR13", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR13", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR13", OBJPROP_XDISTANCE, 353);
      ObjectSet("WTF_BKGR13", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR14") < 0) {
      ObjectCreate("WTF_BKGR14", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR14", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR14", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR14", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR14", OBJPROP_XDISTANCE, 382);
      ObjectSet("WTF_BKGR14", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR15") < 0) {
      ObjectCreate("WTF_BKGR15", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR15", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR15", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR15", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR15", OBJPROP_XDISTANCE, 411);
      ObjectSet("WTF_BKGR15", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR16") < 0) {
      ObjectCreate("WTF_BKGR16", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR16", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR16", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR16", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR16", OBJPROP_XDISTANCE, 440);
      ObjectSet("WTF_BKGR16", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR17") < 0) {
      ObjectCreate("WTF_BKGR17", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR17", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR17", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR17", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR17", OBJPROP_XDISTANCE, 123);
      ObjectSet("WTF_BKGR17", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR18") < 0) {
      ObjectCreate("WTF_BKGR18", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR18", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR18", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR18", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR18", OBJPROP_XDISTANCE, 153);
      ObjectSet("WTF_BKGR18", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR19") < 0) {
      ObjectCreate("WTF_BKGR19", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR19", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR19", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR19", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR19", OBJPROP_XDISTANCE, 183);
      ObjectSet("WTF_BKGR19", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR20") < 0) {
      ObjectCreate("WTF_BKGR20", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR20", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR20", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR20", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR20", OBJPROP_XDISTANCE, 213);
      ObjectSet("WTF_BKGR20", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR21") < 0) {
      ObjectCreate("WTF_BKGR21", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR21", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR21", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR21", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR21", OBJPROP_XDISTANCE, 243);
      ObjectSet("WTF_BKGR21", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR22") < 0) {
      ObjectCreate("WTF_BKGR22", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR22", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR22", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR22", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR22", OBJPROP_XDISTANCE, 273);
      ObjectSet("WTF_BKGR22", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR23") < 0) {
      ObjectCreate("WTF_BKGR23", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR23", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR23", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR23", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR23", OBJPROP_XDISTANCE, 303);
      ObjectSet("WTF_BKGR23", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR24") < 0) {
      ObjectCreate("WTF_BKGR24", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR24", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR24", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR24", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR24", OBJPROP_XDISTANCE, 333);
      ObjectSet("WTF_BKGR24", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR25") < 0) {
      ObjectCreate("WTF_BKGR25", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR25", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR25", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR25", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR25", OBJPROP_XDISTANCE, 363);
      ObjectSet("WTF_BKGR25", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR26") < 0) {
      ObjectCreate("WTF_BKGR26", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR26", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR26", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR26", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR26", OBJPROP_XDISTANCE, 393);
      ObjectSet("WTF_BKGR26", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR27") < 0) {
      ObjectCreate("WTF_BKGR27", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR27", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR27", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR27", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR27", OBJPROP_XDISTANCE, 423);
      ObjectSet("WTF_BKGR27", OBJPROP_YDISTANCE, Li_12);
   }
   if (ObjectFind("WTF_BKGR28") < 0) {
      ObjectCreate("WTF_BKGR28", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("WTF_BKGR28", "g", 22, "Webdings", DimGray);
      ObjectSet("WTF_BKGR28", OBJPROP_CORNER, 0);
      ObjectSet("WTF_BKGR28", OBJPROP_BACK, TRUE);
      ObjectSet("WTF_BKGR28", OBJPROP_XDISTANCE, 453);
      ObjectSet("WTF_BKGR28", OBJPROP_YDISTANCE, Li_12);
   }
}
