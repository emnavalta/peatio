#ifndef K_PG_H_
#define K_PG_H_

namespace K {
  mPosition pgPos;
  mSafety pgSafety;
  map<double, mTrade> pgBuys;
  map<double, mTrade> pgSells;
  double pgTargetBasePos = 0;
  string pgSideAPR = "";
  class PG {
    public:
      static void main() {
        load();
        ev_gwDataWallet = [](mWallet k) {
          if (argDebugEvents) FN::log("DEBUG", string("EV PG ev_gwDataWallet mWallet ") + ((json)k).dump());
          calcWallet(k);
        };
        ev_ogOrder = [](mOrder k) {
          if (argDebugEvents) FN::log("DEBUG", string("EV PG ev_ogOrder mOrder ") + ((json)k).dump());
          calcWalletAfterOrder(k);
          FN::screen_refresh();
        };
        ev_mgTargetPosition = []() {
          if (argDebugEvents) FN::log("DEBUG", "EV PG ev_mgTargetPosition");
          calcTargetBasePos();
        };
        UI::uiSnap(uiTXT::Position, &onSnapPos);
        UI::uiSnap(uiTXT::TradeSafetyValue, &onSnapSafety);
        UI::uiSnap(uiTXT::TargetBasePosition, &onSnapTargetBasePos);
      };
      static void calcSafety() {
        if (empty() or !mgFairValue) return;
        mSafety safety = nextSafety();
        pgMutex.lock();
        if (pgSafety.buyPing == -1
          or abs(safety.combined - pgSafety.combined) > 1e-3
          or abs(safety.buyPing - pgSafety.buyPing) >= 1e-2
          or abs(safety.sellPong - pgSafety.sellPong) >= 1e-2
        ) {
          pgSafety = safety;
          pgMutex.unlock();
          UI::uiSend(uiTXT::TradeSafetyValue, safety, true);
        } else pgMutex.unlock();
      };
      static void calcTargetBasePos() {
        static string pgSideAPR_ = "!=";
        if (empty()) { FN::logWar("QE", "Unable to calculate TBP, missing market data."); return; }
        pgMutex.lock();
        double value = pgPos.value;
        pgMutex.unlock();
        double targetBasePosition = ((mAutoPositionMode)QP::getInt("autoPositionMode") == mAutoPositionMode::Manual)
          ? (QP::getBool("percentageValues")
            ? QP::getDouble("targetBasePositionPercentage") * value / 1e+2
            : QP::getDouble("targetBasePosition"))
          : ((1 + mgTargetPos) / 2) * value;
        if (pgTargetBasePos and abs(pgTargetBasePos - targetBasePosition) < 1e-4 and pgSideAPR_ == pgSideAPR) return;
        pgTargetBasePos = targetBasePosition;
        pgSideAPR_ = pgSideAPR;
        ev_pgTargetBasePosition();
        json k = {{"tbp", pgTargetBasePos}, {"sideAPR", pgSideAPR}};
        UI::uiSend(uiTXT::TargetBasePosition, k, true);
        DB::insert(uiTXT::TargetBasePosition, k);
        stringstream ss;
        ss << (int)(pgTargetBasePos / value * 1e+2) << "% = " << setprecision(8) << fixed << pgTargetBasePos;
        FN::log("TBP", ss.str() + " " + gw->base);
      };
      static void addTrade(mTrade k) {
        mTrade k_(k.price, k.quantity, k.time);
        if (k.side == mSide::Bid) pgBuys[k.price] = k_;
        else pgSells[k.price] = k_;
      };
      static bool empty() {
        lock_guard<mutex> lock(pgMutex);
        return !pgPos.value;
      };
    private:
      static void load() {
        json k = DB::load(uiTXT::TargetBasePosition);
        if (k.size()) {
          k = k.at(0);
          pgTargetBasePos = k.value("tbp", 0.0);
          pgSideAPR = k.value("sideAPR", "");
        }
        stringstream ss;
        ss << setprecision(8) << fixed << pgTargetBasePos;
        FN::log("DB", string("loaded TBP = ") + ss.str() + " " + gw->base);
      };
      static json onSnapPos() {
        lock_guard<mutex> lock(pgMutex);
        return { pgPos };
      };
      static json onSnapSafety() {
        lock_guard<mutex> lock(pgMutex);
        return { pgSafety };
      };
      static json onSnapTargetBasePos() {
        return {{{"tbp", pgTargetBasePos}, {"sideAPR", pgSideAPR}}};
      };
      static mSafety nextSafety() {
        pgMutex.lock();
        double value          = pgPos.value,
               baseAmount     = pgPos.baseAmount,
               baseHeldAmount = pgPos.baseHeldAmount;
        pgMutex.unlock();
        double buySize = QP::getBool("percentageValues")
          ? QP::getDouble("buySizePercentage") * value / 100
          : QP::getDouble("buySize");
        double sellSize = QP::getBool("percentageValues")
          ? QP::getDouble("sellSizePercentage") * value / 100
          : QP::getDouble("sellSize");
        double totalBasePosition = baseAmount + baseHeldAmount;
        if (QP::getBool("buySizeMax") and (mAPR)QP::getInt("aggressivePositionRebalancing") != mAPR::Off)
          buySize = fmax(buySize, pgTargetBasePos - totalBasePosition);
        if (QP::getBool("sellSizeMax") and (mAPR)QP::getInt("aggressivePositionRebalancing") != mAPR::Off)
          sellSize = fmax(sellSize, totalBasePosition - pgTargetBasePos);
        double widthPong = QP::getBool("widthPercentage")
          ? QP::getDouble("widthPongPercentage") * mgFairValue / 100
          : QP::getDouble("widthPong");
        map<double, mTrade> tradesBuy;
        map<double, mTrade> tradesSell;
        for (vector<mTrade>::iterator it = tradesMemory.begin(); it != tradesMemory.end(); ++it)
          if (it->side == mSide::Bid)
            tradesBuy[it->price] = *it;
          else tradesSell[it->price] = *it;
        double buyPing = 0;
        double sellPong = 0;
        double buyQty = 0;
        double sellQty = 0;
        if ((mPongAt)QP::getInt("pongAt") == mPongAt::ShortPingFair
          or (mPongAt)QP::getInt("pongAt") == mPongAt::ShortPingAggressive
        ) {
          matchBestPing(&tradesBuy, &buyPing, &buyQty, sellSize, widthPong, true);
          matchBestPing(&tradesSell, &sellPong, &sellQty, buySize, widthPong);
          if (!buyQty) matchFirstPing(&tradesBuy, &buyPing, &buyQty, sellSize, widthPong*-1, true);
          if (!sellQty) matchFirstPing(&tradesSell, &sellPong, &sellQty, buySize, widthPong*-1);
        } else if ((mPongAt)QP::getInt("pongAt") == mPongAt::LongPingFair
          or (mPongAt)QP::getInt("pongAt") == mPongAt::LongPingAggressive
        ) {
          matchLastPing(&tradesBuy, &buyPing, &buyQty, sellSize, widthPong);
          matchLastPing(&tradesSell, &sellPong, &sellQty, buySize, widthPong, true);
        }
        if (buyQty) buyPing /= buyQty;
        if (sellQty) sellPong /= sellQty;
        clean();
        double sumBuys = sum(&pgBuys);
        double sumSells = sum(&pgSells);
        return mSafety(
          sumBuys / buySize,
          sumSells / sellSize,
          (sumBuys + sumSells) / (buySize + sellSize),
          buyPing,
          sellPong
        );
      };
      static void matchFirstPing(map<double, mTrade>* trades, double* ping, double* qty, double qtyMax, double width, bool reverse = false) {
        matchPing(QP::matchPings(), true, true, trades, ping, qty, qtyMax, width, reverse);
      };
      static void matchBestPing(map<double, mTrade>* trades, double* ping, double* qty, double qtyMax, double width, bool reverse = false) {
        matchPing(QP::matchPings(), true, false, trades, ping, qty, qtyMax, width, reverse);
      };
      static void matchLastPing(map<double, mTrade>* trades, double* ping, double* qty, double qtyMax, double width, bool reverse = false) {
        matchPing(QP::matchPings(), false, true, trades, ping, qty, qtyMax, width, reverse);
      };
      static void matchPing(bool matchPings, bool near, bool far, map<double, mTrade>* trades, double* ping, double* qty, double qtyMax, double width, bool reverse = false) {
        int dir = width > 0 ? 1 : -1;
        if (reverse) for (map<double, mTrade>::reverse_iterator it = trades->rbegin(); it != trades->rend(); ++it) {
          if (matchPing(matchPings, near, far, ping, width, qty, qtyMax, dir * mgFairValue, dir * it->second.price, it->second.quantity, it->second.price, it->second.Kqty, reverse))
            break;
        } else for (map<double, mTrade>::iterator it = trades->begin(); it != trades->end(); ++it)
          if (matchPing(matchPings, near, far, ping, width, qty, qtyMax, dir * mgFairValue, dir * it->second.price, it->second.quantity, it->second.price, it->second.Kqty, reverse))
            break;
      };
      static bool matchPing(bool matchPings, bool near, bool far, double *ping, double width, double* qty, double qtyMax, double fv, double price, double qtyTrade, double priceTrade, double KqtyTrade, bool reverse) {
        if (reverse) { fv *= -1; price *= -1; width *= -1; }
        if (*qty < qtyMax
          and (far ? fv > price : true)
          and (near ? (reverse ? fv - width : fv + width) < price : true)
          and (!matchPings or KqtyTrade < qtyTrade)
        ) matchPing(ping, qty, qtyMax, qtyTrade, priceTrade);
        return *qty >= qtyMax;
      };
      static void matchPing(double* ping, double* qty, double qtyMax, double qtyTrade, double priceTrade) {
        double qty_ = fmin(qtyMax - *qty, qtyTrade);
        *ping += priceTrade * qty_;
        *qty += qty_;
      };
      static void clean() {
        if (pgBuys.size()) expire(&pgBuys);
        if (pgSells.size()) expire(&pgSells);
        skip();
      };
      static void expire(map<double, mTrade>* k) {
        unsigned long now = FN::T();
        for (map<double, mTrade>::iterator it = k->begin(); it != k->end();)
          if (it->second.time + QP::getDouble("tradeRateSeconds") * 1e+3 > now) ++it;
          else it = k->erase(it);
      };
      static void skip() {
        while (pgBuys.size() and pgSells.size()) {
          mTrade buy = pgBuys.rbegin()->second;
          mTrade sell = pgSells.begin()->second;
          if (sell.price < buy.price) break;
          double buyQty = buy.quantity;
          buy.quantity = buyQty - sell.quantity;
          sell.quantity = sell.quantity - buyQty;
          if (buy.quantity < gw->minSize)
            pgBuys.erase(--pgBuys.rbegin().base());
          if (sell.quantity < gw->minSize)
            pgSells.erase(pgSells.begin());
        }
      };
      static double sum(map<double, mTrade>* k) {
        double sum = 0;
        for (map<double, mTrade>::iterator it = k->begin(); it != k->end(); ++it)
          sum += it->second.quantity;
        return sum;
      };
      static void calcWallet(mWallet k) {
        static mutex walletMutex,
                     profitMutex;
        static map<string, mWallet> pgWallet;
        static vector<mProfit> pgProfit;
        walletMutex.lock();
        if (k.currency!="") pgWallet[k.currency] = k;
        if (!mgFairValue or pgWallet.find(gw->base) == pgWallet.end() or pgWallet.find(gw->quote) == pgWallet.end()) {
          walletMutex.unlock();
          return;
        }
        mWallet baseWallet = pgWallet[gw->base];
        //mWallet baseWallet = "5000";
        baseWallet.amount = 100000;
        mWallet quoteWallet = pgWallet[gw->quote];
        //quoteWallet.amount = ;
        walletMutex.unlock();
        double baseValue = baseWallet.amount + quoteWallet.amount / mgFairValue + baseWallet.held + quoteWallet.held / mgFairValue;
        double quoteValue = baseWallet.amount * mgFairValue + quoteWallet.amount + baseWallet.held * mgFairValue + quoteWallet.held;
        unsigned long now = FN::T();
        profitMutex.lock();
        pgProfit.push_back(mProfit(baseValue, quoteValue, now));
        for (vector<mProfit>::iterator it = pgProfit.begin(); it != pgProfit.end();)
          if (it->time + (QP::getDouble("profitHourInterval") * 36e+5) > now) ++it;
          else it = pgProfit.erase(it);
        mPosition pos(
          baseWallet.amount,
          quoteWallet.amount,
          baseWallet.held,
          quoteWallet.held,
          baseValue,
          quoteValue,
          ((baseValue - pgProfit.begin()->baseValue) / baseValue) * 1e+2,
          ((quoteValue - pgProfit.begin()->quoteValue) / quoteValue) * 1e+2,
          mPair(gw->base, gw->quote),
          gw->exchange
        );
        profitMutex.unlock();
        bool eq = true;
        if (!empty()) {
          pgMutex.lock();
          eq = abs(pos.value - pgPos.value) < 2e-6;
          if(eq
            and abs(pos.quoteValue - pgPos.quoteValue) < 2e-2
            and abs(pos.baseAmount - pgPos.baseAmount) < 2e-6
            and abs(pos.quoteAmount - pgPos.quoteAmount) < 2e-2
            and abs(pos.baseHeldAmount - pgPos.baseHeldAmount) < 2e-6
            and abs(pos.quoteHeldAmount - pgPos.quoteHeldAmount) < 2e-2
            and abs(pos.profitBase - pgPos.profitBase) < 2e-2
            and abs(pos.profitQuote - pgPos.profitQuote) < 2e-2
          ) { pgMutex.unlock(); return; }
        } else pgMutex.lock();
        pgPos = pos;
        pgMutex.unlock();
        if (!eq) calcTargetBasePos();
        UI::uiSend(uiTXT::Position, pos, true);
      };
      static void calcWalletAfterOrder(mOrder k) {
        if (empty()) return;
        double heldAmount = 0;
        pgMutex.lock();
        double amount = k.side == mSide::Ask
          ? pgPos.baseAmount + pgPos.baseHeldAmount
          : pgPos.quoteAmount + pgPos.quoteHeldAmount;
        pgMutex.unlock();
        ogMutex.lock();
        for (map<string, mOrder>::iterator it = allOrders.begin(); it != allOrders.end(); ++it) {
          if (it->second.side != k.side) continue;
          double held = it->second.quantity * (it->second.side == mSide::Bid ? it->second.price : 1);
          if (amount >= held) {
            amount -= held;
            heldAmount += held;
          }
        }
        ogMutex.unlock();
        calcWallet(mWallet(amount, heldAmount, k.side == mSide::Ask
          ? k.pair.base : k.pair.quote
        ));
      };
  };
}

#endif
