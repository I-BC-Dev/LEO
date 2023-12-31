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
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_separate_window
#property indicator_color1 clrBlue
#property indicator_color2 clrRed

input    int      NumCand              = 100;         // Numero candele
string   Symbol1              = Symbol();    // Cross 1
input    string   Symbol2              = "EURCHF";    // Cross 2
input    int      PeriodCorr           = 100;         // Correlation Period
input    ENUM_APPLIED_PRICE Price      = PRICE_CLOSE; // Price

//--- indicator buffers
double         PosBuffer[];
double         NegBuffer[];
datetime       last_t;
bool           rebuilt = false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0, PosBuffer);
   SetIndexBuffer(1, NegBuffer);

   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2);


   SetIndexLabel(0, "Positive Correlation");
   SetIndexLabel(1, "Negative Correlation");

   IndicatorSetDouble(INDICATOR_MAXIMUM, 1.2);
   IndicatorSetDouble(INDICATOR_MINIMUM, -1.2);

   IndicatorSetInteger(INDICATOR_LEVELS, 3);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 1);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, -1);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 2, 0);

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
//---
   double corr;

// Protezione DEMO
//ObjectDelete(0, "Scadenza");
//if (iTime(Symbol(), PERIOD_D1, 0) > D'15.04.2022') {
//   ObjectsDeleteAll();
//   drawLabelLine0L("Scadenza", 280, 30, 0, "EA Scaduto. Contattare I-BC: info@i-bc.it ", clrRed, 14);
//   return(0);
//}


   for(int i = 0; i <= NumCand; i++) {
      if(i > Bars - PeriodCorr) break;

      corr = GetCorrelation(i);

      if(corr >= 0) {
         PosBuffer[i] = corr;
         NegBuffer[i] = EMPTY_VALUE;
      }
      if(corr < 0) {
         NegBuffer[i] = corr;
         PosBuffer[i] = EMPTY_VALUE;
      }

   }




//--- return value of prev_calculated for next call
   return(rates_total);
}




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetCorrelation(int cand) {
   double corr = 0;
   double avgX = 0;
   double avgY = 0;
   double X = 0;
   double Y = 0;
   double num = 0;
   double den = 0;

   double sumXmAvg2 = 0;
   double sumYmAvg2 = 0;

   avgX = GetAverage(Symbol1, cand);
   avgY = GetAverage(Symbol2, cand);

   for(int i = cand; i < cand + PeriodCorr; i++) {
      if(i >= Bars) break;

      X = GetPrice(Symbol1, i);
      Y = GetPrice(Symbol2, i);

      num += ((X - avgX) * (Y - avgY));

      sumXmAvg2 += MathPow((X - avgX), 2);
      sumYmAvg2 += MathPow((Y - avgY), 2);
   }

   den = MathSqrt(sumXmAvg2) * MathSqrt(sumYmAvg2);

   if(den != 0) {
      corr = num / den;
   } else corr = EMPTY_VALUE;
   return corr;

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetAverage(string symbol, int idx) {
   double res = 0;
   int count = 0;

   for(int i = idx; i < idx + PeriodCorr; i++) {
      if(i >= Bars) break;
      res += GetPrice(symbol, i);
      count ++;
   }

   return count > 0 ? res / count : 0;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetPrice(string symbol, int idx) {
   if(Price == PRICE_CLOSE) return iClose(symbol, Period(), idx);
   if(Price == PRICE_OPEN) return iOpen(symbol, Period(), idx);
   if(Price == PRICE_HIGH) return iHigh(symbol, Period(), idx);
   if(Price == PRICE_LOW) return iLow(symbol, Period(), idx);

   return 0;
}

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
