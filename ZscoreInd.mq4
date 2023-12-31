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
#property indicator_color1 clrGreen
#property indicator_color2 clrViolet

input    int      NumCand              = 100;         // Numero candele

string   Symbol1              = Symbol();    // Cross 1
input    string   Symbol2              = "EURCHF";    // Cross 2

input    int      DevPeriod            = 100;         // STD Deviation Period

//--- indicator buffers
double         S1Zscore[];
double         S2Zscore[];
datetime       last_t;
bool           rebuilt = false;
string         short_name = "";
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
   short_name = "zScore_ " + Symbol1 + Symbol2;
   IndicatorShortName(short_name);

//--- indicator buffers mapping
   SetIndexBuffer(0, S1Zscore);
   SetIndexBuffer(1, S2Zscore);

   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2);


   SetIndexLabel(0, "S1 Zscore");
   SetIndexLabel(1, "S2 Zscore");


//
   IndicatorSetInteger(INDICATOR_LEVELS, 7);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 3);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, 2);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 2, 1);

   IndicatorSetDouble(INDICATOR_LEVELVALUE, 3, 0);


   IndicatorSetDouble(INDICATOR_LEVELVALUE, 4, -1);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 5, -2);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 6, -3);

   drawLabelLine0L(Symbol1 + "_label", 4, 20, 0, Symbol1, indicator_color1, 10);
   drawLabelLine0L(Symbol2 + "_label", 4 + 80, 20, 0, Symbol2, indicator_color2, 10);


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

   double z1, z2;


   for(int i = 0; i < NumCand; i++) {
      if(i + 1 > Bars) return -1;

      z1 = GetZscore(Symbol1, i);
      z2 = GetZscore(Symbol2, i);

      S1Zscore[i] = z1;
      S2Zscore[i] = z2;
   }


//--- return value of prev_calculated for next call
   return(rates_total);
}






//+------------------------------------------------------------------+
//| Funzioni Ausiliarie                                              |


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetZscore(string symbol, int cand) {
   double X = iClose(symbol, Period(), cand);
   double avg = GetAverage(symbol, cand);

   double stdDev = GetStandardDev(symbol, cand, avg);

   return (X - avg) / stdDev;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetStandardDev(string symbol, int cand, double avg) {
   double count = 0;
   double diffSum = 0;

   for(int i = cand; i < cand + DevPeriod; i++) {
      diffSum += MathPow(iClose(symbol, Period(), i) - avg, 2);
      count += 1;
   }
   return MathSqrt(diffSum / count);

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetAverage(string symbol, int idx) {
   double res = 0;
   int count = 0;

   for(int i = idx; i < idx + DevPeriod; i++) {
      if(i >= Bars) break;
      res += iClose(symbol, Period(), i);
      count ++;
   }

   return count > 0 ? res / count : 0;
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
//|                                                                  |
//+------------------------------------------------------------------+
void drawLabelLine0L(string name, int startposx, int startposy, int Line, string labelText, color Color, int fontsize) {
   ObjectDelete(0, name);
   int winIndex = WindowFind(short_name);
   ObjectCreate(0, name, OBJ_LABEL, winIndex, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, startposx);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, startposy + ((fontsize + 5)*Line));
   ObjectSetInteger(0, name, OBJPROP_COLOR, Color);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontsize);
   ObjectSetString(0, name, OBJPROP_FONT, "Helvetica");
   ObjectSetString(0, name, OBJPROP_TEXT, labelText);
}
//+------------------------------------------------------------------+

