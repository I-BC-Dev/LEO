//+------------------------------------------------------------------+
//|                                                      I-BC EA.mq4 |
//|                            Copyright © 2022, I-BC - 4NEXT S.r.l. |
//|                                               http://www.i-bc.it |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2023, I-BC - 4NEXT S.r.l."
#property link      "http://www.i-bc.it"
#property icon      "\\Images\\favicon.ico"
#property strict
#property show_inputs
#property indicator_buffers 1
#property indicator_plots 1
#property indicator_separate_window
#property indicator_color1 clrYellow

input    int      NumCand              = 100;         // Numero candele

input    string   Symbol1              = "EURUSD";    // Cross 1
input    string   Symbol2              = "EURCHF";    // Cross 2

//--- indicator buffers
double         diffBuffer[];
double         NegBuffer[];
datetime       last_t;
bool           rebuilt = false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0, diffBuffer);
//SetIndexBuffer(1, NegBuffer);

   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2);
//SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2);


   SetIndexLabel(0, "% Difference");
 
//   IndicatorSetDouble(INDICATOR_MAXIMUM, 1.2);
//   IndicatorSetDouble(INDICATOR_MINIMUM, -1.2);
//
//   IndicatorSetInteger(INDICATOR_LEVELS, 3);
//   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 1);
//   IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, -1);
//   IndicatorSetDouble(INDICATOR_LEVELVALUE, 2, 0);

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {

// Protezione DEMO
//ObjectDelete(0, "Scadenza");
//if (iTime(Symbol(), PERIOD_D1, 0) > D'15.04.2022') {
//   ObjectsDeleteAll();
//   drawLabelLine0L("Scadenza", 280, 30, 0, "EA Scaduto. Contattare I-BC: info@i-bc.it ", clrRed, 14);
//   return(0);
//}


   for(int i = 0; i < NumCand; i++) {
      if(i + 1 > Bars) return -1;

      double perc1 = (iClose(Symbol1, Period(), i) - iClose(Symbol1, Period(), i + 1)) / iClose(Symbol1, Period(), i + 1);
      double perc2 = (iClose(Symbol2, Period(), i) - iClose(Symbol2, Period(), i + 1)) / iClose(Symbol2, Period(), i + 1);

      double diff = MathAbs(perc1 - perc2) *100;

      diffBuffer[i] = diff;
   }




//--- return value of prev_calculated for next call
   return(rates_total);
}






//+------------------------------------------------------------------+
//| Funzioni Ausiliarie                                              |



//+------------------------------------------------------------------+
//| Stampa il contenuto di un array(solo tipi primitivi)             |
//+------------------------------------------------------------------+
template<typename T>
void ArrayPrint(T & arr[]) {
   string str = "";
   for(int i = 0; i < ArraySize(arr); i++) {
      str += string(arr[i]) + " - ";
   }
   Print(str);
}

//+------------------------------------------------------------------+
//| Aggiunge tutti gli elementi dell'array src nell'array dst        |
//+------------------------------------------------------------------+
template<typename T>
void ArrayBulkLoad(T & src[], T & dst[]) {
   for(int i = 0; i < ArraySize(src); i++) {
      ArrayAddElem(dst, src[i]);
   }
}

//+------------------------------------------------------------------+
//| Cerca un elemento all'interno di un array                        |
//+------------------------------------------------------------------+
template<typename T>
bool ArraySearch(T & arr[], T elem) {
   for(int i = 0; i < ArraySize(arr); i++) {
      if(arr[i] == elem)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Aggiunge un elemento all'internoi di un array                    |
//+------------------------------------------------------------------+
template<typename T>
void ArrayAddElem(T & arr[], T & elem) {
   int size = ArraySize(arr);
   ArrayResize(arr, size + 1);
   arr[size] = elem;
}


//+------------------------------------------------------------------+
//| Rimuove un elemento all'indice specificato                       |
//+------------------------------------------------------------------+
template<typename T>
void ArrayRemoveElem(T & src[], int index) {
   T tmp[];
   for(int i = 0; i < ArraySize(src); i++) {
      if(i != index) {
         ArrayAddElem(tmp, src[i]);
      }
   }
   ArrayFree(src);
   for(int i = 0; i < ArraySize(tmp); i++) {
      ArrayAddElem(src, tmp[i]);
   }
}


//+------------------------------------------------------------------+
//|Scrive nell'angolo alto SX con allineamento a SX                  |
//+------------------------------------------------------------------+
void drawLabelLine0L(string name, int startposx, int startposy, int Line, string labelText, color Color, int fontsize) {
   ObjectDelete(name);
   ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
   ObjectSet(name, OBJPROP_CORNER, 0);
   ObjectSet(name, OBJPROP_XDISTANCE, startposx);
   ObjectSet(name, OBJPROP_YDISTANCE, startposy + ((fontsize + 5)*Line));

   ObjectSetText(name, labelText, fontsize, "ArialNarrow", Color);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CheckLoadHistory(string symbol, ENUM_TIMEFRAMES period, datetime start_date) {
   datetime first_date = 0;
   datetime times[100];

//--- check if symbol is selected in the Market Watch
   if(!SymbolInfoInteger(symbol, SYMBOL_SELECT)) {
      if(GetLastError() == ERR_UNKNOWN_SYMBOL) return(-1);
      SymbolSelect(symbol, true);
   }
//--- check if data is present
   SeriesInfoInteger(symbol, period, SERIES_FIRSTDATE, first_date);
   if(first_date > 0 && first_date <= start_date) return(1);


//--- second attempt
   if(SeriesInfoInteger(symbol, PERIOD_M1, SERIES_TERMINAL_FIRSTDATE, first_date)) {
      //--- there is loaded data to build timeseries
      if(first_date > 0) {
         //--- force timeseries build
         CopyTime(symbol, period, first_date + PeriodSeconds(period), 1, times);
         //--- check date
         if(SeriesInfoInteger(symbol, period, SERIES_FIRSTDATE, first_date))
            if(first_date > 0 && first_date <= start_date) return(2);
      }
   }
//--- max bars in chart from terminal options
   int max_bars = TerminalInfoInteger(TERMINAL_MAXBARS);
//--- load symbol history info
   datetime first_server_date = 0;
   while(!SeriesInfoInteger(symbol, PERIOD_M1, SERIES_SERVER_FIRSTDATE, first_server_date) && !IsStopped())
      Sleep(5);
//--- fix start date for loading
   if(first_server_date > start_date) start_date = first_server_date;
   if(first_date > 0 && first_date < first_server_date)
      Print("Warning: first server date ", first_server_date, " for ", symbol,
            " does not match to first series date ", first_date);
//--- load data step by step
   int fail_cnt = 0;
   while(!IsStopped()) {
      //--- wait for timeseries build
      while(!SeriesInfoInteger(symbol, period, SERIES_SYNCHRONIZED) && !IsStopped())
         Sleep(5);
      //--- ask for built bars
      int bars = Bars(symbol, period);
      if(bars > 0) {
         if(bars >= max_bars) return(-2);
         //--- ask for first date
         if(SeriesInfoInteger(symbol, period, SERIES_FIRSTDATE, first_date))
            if(first_date > 0 && first_date <= start_date) return(0);
      }
      //--- copying of next part forces data loading
      int copied = CopyTime(symbol, period, bars, 100, times);
      if(copied > 0) {
         //--- check for data
         if(times[0] <= start_date)  return(0);
         if(bars + copied >= max_bars) return(-2);
         fail_cnt = 0;
      } else {
         //--- no more than 100 failed attempts
         fail_cnt++;
         if(fail_cnt >= 100) return(-5);
         Sleep(10);
      }
   }
//--- stopped
   return(-3);
}
//+------------------------------------------------------------------+
