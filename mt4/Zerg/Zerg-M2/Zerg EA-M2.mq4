#property copyright "Zerg TLP"
#property link      ""

#include <stdlib.mqh>

// Zerg EA changelog:

// M1
// 1. explicit TP levels
// 2. compensated swap and commission in price targets
// 3. option to disable close of grid on opposite signal

// M2 changes
// 1. increase grid on profit

extern string Control_options = "================ Control options";
extern bool noMoreNewGrids = FALSE;

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
extern bool setExplicitTP = FALSE;
extern int gridProfitTarget = 85;
extern bool compensateSwapAndCommission = TRUE;

extern string M2_IncreaseOnProfit = "==================== Increase on profit";
extern bool increaseOnProfit = FALSE;
extern int increaseOnProfitGap = 1;
extern int increaseMaxOrders = 4;

extern string M2_EntryByTrend = "==================== Entry by trend";
extern bool entryByTrend = FALSE;
extern int entryByTrend_TF = 1440;
extern int entryByTrend_FastMAPeriod = 5;
extern int entryByTrend_MidMAPeriod = 5;
extern int entryByTrend_SlowMAPeriod = 10;

extern bool entryOptUseIndex = FALSE;
extern int entryOptMaxN = 30;
extern int entryOptIndex = 0;

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
bool resend_order;
int resend_kind;
int nextLongOrderIndex;
int nextShortOrderIndex;
bool tp_update_request;


void translateIndexIntoVals(int N, int index, int& a, int& b, int& c)
{
    int i = 0;
    for (a = 1; a <= N; a++)
        for (b = a+1; b <= N; b++)
            for (c = b+1; c <= N; c++) {
                if (i == index)
                    return;
                i++;
            }
}



int translateValsIntoIndex(int N, int a1, int b1, int c1)
{
    int i = 0;
    for (int a = 1; a <= N; a++)
        for (int b = a+1; b <= N; b++)
            for (int c = b+1; c <= N; c++) {
                if (a == a1 && b == b1 && c == c1)
                    return (i);
                i++;
            }

    return (-1);
}



int init() {
   if (!IsDllsAllowed())
       Alert("You have to enable DLLs in order to work with this product");

   // translate index
   if (entryOptUseIndex) {
       int a, b, c;

       translateIndexIntoVals(entryOptMaxN, entryOptIndex, a, b, c);
       Print("Opt index " + entryOptIndex + " with N=" + entryOptMaxN + " gives (" + a + "," + b + "," + c + ")");
       entryByTrend_FastMAPeriod = a;
       entryByTrend_MidMAPeriod = b;
       entryByTrend_SlowMAPeriod = c;
   }
   else {
       Print("MA settings gives index " + translateValsIntoIndex(entryOptMaxN, entryByTrend_FastMAPeriod, entryByTrend_MidMAPeriod, entryByTrend_SlowMAPeriod) + " with N=" + entryOptMaxN);
   }

   // check entry by trend MA settings
   if (entryByTrend) {
       if (!(entryByTrend_FastMAPeriod <= entryByTrend_MidMAPeriod && entryByTrend_MidMAPeriod <= entryByTrend_SlowMAPeriod)) {
           Print("Inconsistent entryByTrend MA periods");
           return (-1);
       }
   }

   expertVersion = 1.0;
   firstEnvelopePeriod = 80;
   firstEnvelopeDev = 0.35;
   secondEnvelopePeriod = 10;
   secondEnvelopeDev = 0.3;
   maxDrawDownSeenInPercent = 0.0;
   Gi_272 = TRUE; // some mode, switches envelopes shift (false adds one extra bar to shift)
//   gridProfitTarget = 85; // profit target in grid
   resend_order = FALSE;
   tp_update_request = TRUE;
   if (!setExplicitTP)
       turnOffTakeProfits();
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

   // every hour update TP leves to reflect possible extra swap
   static int prev_hour = 0;
   if (prev_hour != Hour()) {
       if (setExplicitTP && compensateSwapAndCommission)
           tp_update_request = TRUE;
       prev_hour = Hour();
   }

   // determine both grids settings
   int max_long_index = -1, min_long_index = -1;
   int max_short_index = -1, min_short_index = -1;
   int long_count, short_count;

   long_count  = get_grid_params(OP_BUY, min_long_index, max_long_index);
   short_count = get_grid_params(OP_SELL, min_short_index, max_short_index);

   nextLongOrderIndex = long_count;
   nextShortOrderIndex = short_count;

   if (!setExplicitTP) {
       double longGridProfit = currentGridProfit(MagicNumber, OP_BUY);
       double shortGridProfit = currentGridProfit(MagicNumber, OP_SELL);

       // profit target reached on long grid
       if (longGridProfit >= gridProfitTarget)
           closeLongGrid_requested = TRUE;
       // profit target reached on short grid
       if (shortGridProfit >= gridProfitTarget)
           closeShortGrid_requested = TRUE;
   }
   else
       if (tp_update_request) {
           if (updateTPLevels(OP_BUY) && updateTPLevels(OP_SELL))
               tp_update_request = FALSE;
       }

   if (!closeLongGrid_requested)
       increase_long_grid_if_needed(long_count, min_long_index, max_long_index);
   else
       closeLongGrid(MagicNumber);

   if (!closeShortGrid_requested)
       increase_short_grid_if_needed(short_count, min_short_index, max_short_index);
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



// Determine count of orders and index of orders with min and max price in a
// grid of this kind.
int get_grid_params (int orderType, int& min_index, int& max_index)
{
    int count = 0;
    int i;
    double min_price, max_price;

    min_index = -1;
    max_index = -1;

    for (i = 0; i < OrdersTotal(); i++) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;

        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber || OrderType() != orderType)
            continue;

        count++;
        if (min_index == -1 || OrderOpenPrice() < min_price) {
            min_index = i;
            min_price = OrderOpenPrice();
        }

        if (max_index == -1 || OrderOpenPrice() > max_price) {
            max_index = i;
            max_price = OrderOpenPrice();
        }
    }
    return (count);
}


// 78BAA8FAE18F93570467778F2E829047
void increase_long_grid_if_needed(int grid_size, int min_index, int max_index)
{
   int ticket;
   double SL_level = 0.0;
   int error;

   if (StopLoss > 0.0)
       SL_level = Ask - StopLoss * symbolPoint;

   if (grid_size == 0) {
       if (noMoreNewGrids)
           return;
       if (initialSignal() == 1 || (resend_order && resend_kind == 1)) {
          ticket = OrderSend(Symbol(), OP_BUY, lots_to_trade, Ask, Slippage, 0, 0,
                             "WTF000 " + (nextLongOrderIndex + 1), MagicNumber, 0, Blue);
         if (ticket < 0) {
            error = GetLastError();
            Print("Error Opening Buy Order(", error, "): ", ErrorDescription(error));
            resend_order = TRUE;
            resend_kind = 1;
         } else {
            OrderSelect(ticket, SELECT_BY_TICKET);
            OrderModify(OrderTicket(), OrderOpenPrice(), SL_level, 0.0, 0, Blue);
            resend_order = FALSE;
            tp_update_request = TRUE;
         }
      }
   } else {
       // very rare condition (close on opposite signal?)
       if (closeSignal() == 2)
           closeLongGrid_requested = TRUE;

       if (grid_size > MaxOpenOrders)
           return;

       if (increaseGridCheck(grid_size, TRUE, min_index, max_index)) {
           ticket = OrderSend(Symbol(), OP_BUY, lots_to_trade, Ask, Slippage, 0, 0,
                              "WTF000 " + (nextLongOrderIndex + 1), MagicNumber, 0, Blue);
           if (ticket < 0) {
               error = GetLastError();
               Print("Error Opening Buy Order(", error, "): ", ErrorDescription(error));
           } else {
               OrderSelect(ticket, SELECT_BY_TICKET);
               OrderModify(OrderTicket(), OrderOpenPrice(), SL_level, 0.0, 0, Blue);
               tp_update_request = TRUE;
           }
       }
   }
}


// 50257C26C4E5E915F022247BABD914FE
void increase_short_grid_if_needed(int grid_size, int min_index, int max_index)
{
   int ticket;
   double SL_level = 0.0;
   int error;

   if (StopLoss > 0)
       SL_level = Bid + StopLoss * symbolPoint;

   if (grid_size == 0) {
       if (noMoreNewGrids)
           return;
       if (initialSignal() == 2 || (resend_order && resend_kind == 2)) {
          ticket = OrderSend(Symbol(), OP_SELL, lots_to_trade, Bid, Slippage, 0, 0,
                             "WTF000 " + (nextShortOrderIndex + 1), MagicNumber, 0, Red);
         if (ticket < 0) {
            error = GetLastError();
            Print("Error Opening Sell Order(", error, "): ", ErrorDescription(error));
            resend_order = TRUE;
            resend_kind = 2;
         } else {
            OrderSelect(ticket, SELECT_BY_TICKET);
            OrderModify(OrderTicket(), OrderOpenPrice(), SL_level, 0.0, 0, Red);
            resend_order = FALSE;
            tp_update_request = TRUE;           
         }
      }
   } else {
       if (closeSignal() == 1)
           closeShortGrid_requested = TRUE;

       if (grid_size > MaxOpenOrders)
           return;

       if (increaseGridCheck(grid_size, FALSE, min_index, max_index)) {
           ticket = OrderSend(Symbol(), OP_SELL, lots_to_trade, Bid, Slippage, 0, 0,
                              "WTF000 " + (nextShortOrderIndex + 1), MagicNumber, 0, Red);
           if (ticket < 0) {
               error = GetLastError();
               Print("Error Opening Sell Order(", error, "): ", ErrorDescription(error));
           } else {
               OrderSelect(ticket, SELECT_BY_TICKET);
               OrderModify(OrderTicket(), OrderOpenPrice(), SL_level, 0.0, 0, Red);
               tp_update_request = TRUE;
           }
       }
   }
}


// 689C35E4872BA754D7230B8ADAA28E48
bool increaseGridCheck(int grid_size, bool long_grid, int min_index, int max_index)
{
   if (long_grid) {
       OrderSelect(min_index, SELECT_BY_POS);
       if (OrderType() == OP_BUY) {
           if (OrderOpenPrice() - Ask >= GridOrderGapPips * symbolPoint)
               return (TRUE);
       }

       OrderSelect(max_index, SELECT_BY_POS);
       if (increaseOnProfit) {
           if (Ask - OrderOpenPrice() >= increaseOnProfitGap * symbolPoint)
               if (grid_size < increaseMaxOrders)
                   return (TRUE);
       }
   }
   else {
       OrderSelect(max_index, SELECT_BY_POS);
       if (OrderType() == OP_SELL) {
           if (Bid - OrderOpenPrice() >= GridOrderGapPips * symbolPoint)
               return (TRUE);
       }

       OrderSelect(min_index, SELECT_BY_POS);
       if (increaseOnProfit) {
           if (OrderOpenPrice() - Bid >= increaseOnProfitGap * symbolPoint)
               if (grid_size < increaseMaxOrders)
                   return (TRUE);
       }
   }

   return (FALSE);
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

   int result = 0;

   if (lower_2_back < close_2_back)
      if (lower_prev > close_prev)
          result = 1;

   if (result == 0) {
       if (upper_2_back > close_2_back)
           if (upper_prev < close_prev)
               result = 2;
   }

   // check for trend direction if needed
   if (result != 0 && entryByTrend) {
       double fast = iMA(NULL, entryByTrend_TF, entryByTrend_FastMAPeriod, 1, MODE_SMA, PRICE_CLOSE, 0);
       double mid  = iMA(NULL, entryByTrend_TF, entryByTrend_MidMAPeriod,  1, MODE_SMA, PRICE_CLOSE, 0);
       double slow = iMA(NULL, entryByTrend_TF, entryByTrend_SlowMAPeriod, 1, MODE_SMA, PRICE_CLOSE, 0);

       int ma_signal = 0;

       // long signal if slow under mid and mid under fast
       if (slow <= mid && mid <= fast)
           ma_signal = 1;
       else
           // short signal if slow above mid and mid above fast
           if (slow >= mid && mid >= fast)
               ma_signal = -1;

       // result == 1 means long grid signal. If we have an opposite signal from MA, do not open
       if (result == 1 && ma_signal == -1) {
           result = 0;
       }
       // result == 2 means short grid signal. 
       if (result == 2 && ma_signal == 1) {
           result = 0;
       }
   }

   return (result);
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


double getCompensationMove(int orderType)
{
    double extra = 0.0, profit = 0.0, move = 0.0;

    if (!compensateSwapAndCommission)
        return (0.0);

    for (int i = 0; i < OrdersTotal(); i++) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if (OrderMagicNumber() == MagicNumber) {
            if (OrderSymbol() == Symbol()) {
                if (OrderType() == orderType && orderType == OP_BUY) {
                    move += (Bid - OrderOpenPrice()) / symbolPoint;
                    extra += OrderSwap() + OrderCommission();
                    profit += OrderProfit();
                }
                if (OrderType() == orderType && orderType == OP_SELL) {
                    move += (OrderOpenPrice() - Ask) / symbolPoint;
                    extra += OrderSwap() + OrderCommission();
                    profit += OrderProfit();
                }
            }
        }
    }

    if (MathAbs(profit) < 0.001 || MathAbs(move) < 0.001)
        return (0.0);

    // point price can be negative during spread compensations
    if (profit / move > 0.0) {
        double extra_points = -extra * move / profit;

        extra_points = MathMax(extra_points, 0.0);
        return (extra_points);
    }

    return (0.0);
}


// 5710F6E623305B2C1458238C9757193B
// current profit on grid
double currentGridProfit(int magic, int orderType) {
   double res = 0.0;
   for (int i = 0; i < OrdersTotal(); i++) {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() == magic) {
          if (OrderSymbol() == Symbol()) {
              if (OrderType() == orderType && orderType == OP_BUY)
                 res += (Bid - OrderOpenPrice()) / symbolPoint;
              if (OrderType() == orderType && orderType == OP_SELL)
                 res += (OrderOpenPrice() - Ask) / symbolPoint;
         }
      }
   }

   double comp = getCompensationMove(orderType);
   res -= comp;
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


// disables TP on all our orders
void turnOffTakeProfits()
{
    for (int i = 0; i < OrdersTotal(); i++) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;

        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
            continue;

        if (OrderTakeProfit() > Point)
            OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), 0.0, 0);
    }
}


// Recalculates and updates (if needed) TP levels of orders with specified type
// Return true if update was sucessfull
bool updateTPLevels(int order_type)
{
    int extr_order_index = -1;
    double extr_order_price = 0.0;
    int i;

    // look for extremum order index (topmost for long and lowers for short)
    for (i = 0; i < OrdersTotal(); i++) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;

        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber || OrderType() != order_type)
            continue;

        bool extremum = FALSE;

        if (extr_order_index < 0)
            extremum = TRUE;
        else {
            if (order_type == OP_BUY && OrderOpenPrice() > extr_order_price)
                extremum = TRUE;
            if (order_type == OP_SELL && OrderOpenPrice() < extr_order_price)
                extremum = TRUE;
        }

        if (extremum) {
            extr_order_index = i;
            extr_order_price = OrderOpenPrice();
        }
    }

    // we have extremum order, calculate distance all other orders to it
    double extremum_distance = 0, grid_size = 0;

    for (i = 0; i < OrdersTotal(); i++) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;

        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber || OrderType() != order_type)
            continue;

        grid_size++;

        if (i == extr_order_index)
            continue;

        if (order_type == OP_BUY)
            extremum_distance += (extr_order_price - OrderOpenPrice()) / Point;

        if (order_type == OP_SELL)
            extremum_distance += (OrderOpenPrice() - extr_order_price) / Point;
    }

    if (grid_size == 0)
        return (TRUE);

    int profit_target = (gridProfitTarget + getCompensationMove(order_type)) * (symbolPoint / Point);
    int extra_distance = MathCeil((profit_target - extremum_distance) / grid_size);
    double tp_level;

    if (order_type == OP_BUY)
        tp_level = extr_order_price + extra_distance * Point;
    if (order_type == OP_SELL)
        tp_level = extr_order_price - extra_distance * Point;

    // Print("grid_size = " + grid_size + ", extra_distance = " + extra_distance +
    //       ", extremum_distance = " + extremum_distance +
    //       ", profit_target = " + profit_target + ", tp_level = " + tp_level);

    bool result = TRUE;

    for (i = 0; i < OrdersTotal(); i++) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;

        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber || OrderType() != order_type)
            continue;      

        if (MathAbs(OrderTakeProfit() - tp_level) > Point)
            if (!OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), tp_level, 0))
                result = FALSE;
    }

    return (result);
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
