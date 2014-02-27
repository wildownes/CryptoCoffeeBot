###
YOUR BOT NAME v0.1 - username / email
    BTC xxxxxxxxxxxxxxxxxxx
In this state the bot does Simple EMA trades
but provides a base framework to begin a
new algorithm that includes: 

****Module Credits**** (PLEASE KEEP UPDATED)
OpenSettings module v0.1 by wild0wnes
    BTC 1FCmfke28oSjJA7VCMLFnoCxqSQaGRaW7b

SimplePlot module v1 by wild0wnes
    BTC 1FCmfke28oSjJA7VCMLFnoCxqSQaGRaW7b

TryTrade module v1 by wild0wnes
    BTC 1FCmfke28oSjJA7VCMLFnoCxqSQaGRaW7b

class ALG which is based on the Simple EMA example
###

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# OpenSettings - v0.1 by wild0wnes
# BTC - 1FCmfke28oSjJA7VCMLFnoCxqSQaGRaW7b
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class OpenSettings
  @module_disabler: (context, data)->
    context.OS_module1 = true #SimplePlot True/False
    context.OS_module2 = true #SimpleEMA True/False
    context.OS_deepLog = true #True = more debugs

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SimplePlot module v1 by wild0wnes
# BTC - 1FCmfke28oSjJA7VCMLFnoCxqSQaGRaW7b
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class SimplePlot
  @handle: (context, data)->
    instrument = data.instruments[0]
    Close = instrument.close[instrument.close.length - 1]
    High = instrument.high[instrument.high.length - 1]
    Low = instrument.low[instrument.low.length - 1]
    plot
      Close: Close
      High: High
      Low: Low


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TryTrade module v1 by wild0wnes
# BTC - 1FCmfke28oSjJA7VCMLFnoCxqSQaGRaW7b
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class TT
  @tryToBuy: (instr,price) ->
      CURRENCY = portfolio.positions[instr.curr()].amount
      if CURRENCY > .01
         if buy(instr,price)
             info "buy success"
         else 
             debug "buy fail"    
             
  @tryToSell: (instr,price) ->
      ASSETS = portfolio.positions[instr.asset()].amount
      if ASSETS > .01
         if sell(instr,price)
             warn "sell success"
         else 
             debug "sell fail"    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SimplePlot module v1 by wild0wnes
# BTC - 1FCmfke28oSjJA7VCMLFnoCxqSQaGRaW7b
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class CCB #CryptoCoffeeBot Method v0.1 

    #configurable settings
     pTick = true
    

    #CryptoCoffeeBot Functions 
     @pTick_init: () -> 
         if pTick == true
             debug "initializing..."
             context.pTick = 0 #	
     @pTick_handle: () ->
         if pTick == true
             context.pTick += 1
             debug "pTick  " + context.pTick unless context.OS_deepLog == false
     @pTick_serialize: () ->
         if pTick == true
             debug "serializing..."
             pTick:context.pTick
     @pTick_finalize: () ->
         if pTick == true
             debug "finalize...."
             info "Total Processed Ticks " + context.pTick


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#>>>>>>>>>>>>>>>>>>>>>> END MODULES >>>>>>>>>>>>>>>>>>>>



#>>>>>>>>>>>>>>>>>>>>>> START ALGORITM >>>>>>>>>>>>>>>>>>>>

# HERE IS A PLACE TO PUT ALGORITM CODE
# Example is a recreation of the Simple EMA code
class ALG
  @compute: () ->
      context.buy_treshold = 0.25
      context.sell_treshold = 0.25
      instrument = data.instruments[0]
      short = instrument.ema(10)
      long = instrument.ema(21)
      plot
        short: short
        long: long
      diff = 100 * (short - long) / ((short + long) / 2)
      if diff > context.buy_treshold          
         #buy instrument
         debug "buysignal"unless context.OS_deepLog == false
         TT.tryToBuy(instrument, instrument.price)  
      else
         if diff < -context.sell_treshold
             #sell instrument
             debug "sellsignal"unless context.OS_deepLog == false
             TT.tryToSell(instrument, instrument.price)

#>>>>>>>>>>>>>>>>>>>>>> END ALGORITM >>>>>>>>>>>>>>>>>>>>




#>>>>>>>>>>>>>>>>>>>>>> BEGIN CORE METHODS >>>>>>>>>>>>>>>>>>>>
# Initialization method called before a bot starts.
# Context object holds script data and will be passed to 'handle' method.
init: (context)->
    OpenSettings.module_disabler(context)
    CCB.pTick_init()

#This method allows variables to persist after a restart
serialize: (context)->
    CCB.pTick_serialize()

# This method is called for each tick
handle: (context, data)->
    instrument = data.instruments[0]
    SimplePlot.handle(context, data) unless context.OS_module1 == false
    ALG.compute() unless context.OS_module2 == false
    CCB.pTick_handle()

# This method is only run at the end of a simulation on cryptotrader.org
finalize: (context)->
    CCB.pTick_finalize()
