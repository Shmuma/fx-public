
#property copyright "Shmuma"
#property link      ""

#include <stdlib.mqh>

extern double MM_LotSize = 0.01;
extern double TP_Pips = 500;
extern double SL_Pips = 500;
extern int MagicNumber = 152925;
extern int Slippage = 30;


int firstEnvelopePeriod;
int secondEnvelopePeriod;

double firstEnvelopeDev;
double secondEnvelopeDev;



int init()
{
    firstEnvelopePeriod = 80;
    firstEnvelopeDev = 0.35;
    secondEnvelopePeriod = 10;
    secondEnvelopeDev = 0.3;
    return (0);
}

void deinit ()
{
}


void start ()
{
    int ticket, error;
    double sl, tp;

    if (ordersCount (MagicNumber, OP_BUY) == 0) {
        // check entry condition
        if (entrySignal() == 1) {
            ticket = OrderSend (Symbol(), OP_BUY, MM_LotSize, Ask, Slippage, 0, 0, "", MagicNumber, 0, Blue);
            if (ticket < 0) {
                error = GetLastError();
                Print("Error Opening Buy Order(", error, "): ", ErrorDescription(error));
            }
            else {
                OrderSelect(ticket, SELECT_BY_TICKET);
                sl = Ask - SL_Pips*Point;
                tp = Ask + TP_Pips*Point;

                if (SL_Pips == 0)
                    sl = 0.0;
                if (TP_Pips == 0)
                    tp = 0.0;
                OrderModify(OrderTicket(), OrderOpenPrice(), sl, tp, 0, Blue);               
            }
        }
    }

    if (ordersCount (MagicNumber, OP_SELL) == 0) {
        if (entrySignal() == 2) {
            ticket = OrderSend (Symbol(), OP_SELL, MM_LotSize, Bid, Slippage, 0, 0, "", MagicNumber, 0, Red);
            if (ticket < 0) {
                error = GetLastError();
                Print("Error Opening Sell Order(", error, "): ", ErrorDescription(error));
            }
            else {
                OrderSelect(ticket, SELECT_BY_TICKET);
                sl = Bid + SL_Pips*Point;
                tp = Bid - TP_Pips*Point;

                if (SL_Pips == 0)
                    sl = 0.0;
                if (TP_Pips == 0)
                    tp = 0.0;
                OrderModify(OrderTicket(), OrderOpenPrice(), sl, tp, 0, Red);
            }
        }
    }
}


int ordersCount (int magic, int type)
{
    int res = 0;
    for (int i = 0; i < OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic && OrderType() == type)
                res++;
    } 

    return (res);
}


int entrySignal ()
{
   double upper_2_back = iEnvelopes(NULL, 0, firstEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, firstEnvelopeDev, MODE_UPPER, 2);
   double lower_2_back = iEnvelopes(NULL, 0, firstEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, firstEnvelopeDev, MODE_LOWER, 2);
   double close_2_back = iClose(NULL, 0, 2);
   double upper_prev = iEnvelopes(NULL, 0, firstEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, firstEnvelopeDev, MODE_UPPER, 1);
   double lower_prev = iEnvelopes(NULL, 0, firstEnvelopePeriod, MODE_SMA, 0, PRICE_CLOSE, firstEnvelopeDev, MODE_LOWER, 1);
   double close_prev = iClose(NULL, 0, 1);

   if (lower_2_back < close_2_back)
      if (lower_prev > close_prev)
          return (2);
   if (upper_2_back > close_2_back)
      if (upper_prev < close_prev)
          return (1);

    return (0);
}

